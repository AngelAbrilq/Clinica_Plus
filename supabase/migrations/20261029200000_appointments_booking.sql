-- =============================================================
-- Clinica Plus · Migración 004: agendamiento de citas
-- · get_available_slots: horas libres por especialidad, sede y fecha
-- · book_appointment: agenda y asigna el médico con menos carga
-- · cancel_appointment: cancelación con regla de 2 horas
-- · get_my_appointments: citas del paciente con nombre del médico
-- Zona horaria de la clínica: America/Bogota
-- =============================================================

-- Los pacientes ya no insertan citas directamente: solo vía book_appointment
-- (que valida disponibilidad y asigna médico). Recepción/admin sí pueden.
drop policy if exists appointments_insert on public.appointments;
create policy appointments_insert on public.appointments
  for insert to authenticated
  with check ((select public.get_my_role()) in ('receptionist', 'admin'));

-- -------------------------------------------------------------
-- Horas disponibles. Cada franja dura slot_minutes de la especialidad
-- y entre franjas hay 5 min de holgura (absorbe retrasos).
-- Devuelve solo horas futuras y cuántos médicos están libres en cada una.
-- -------------------------------------------------------------
create or replace function public.get_available_slots(
  p_specialty_id bigint,
  p_site_id      bigint,
  p_date         date
)
returns table (starts_at timestamptz, ends_at timestamptz, available_doctors integer)
language sql
stable
security definer
set search_path = ''
as $$
  with params as (
    select make_interval(mins => s.slot_minutes)     as slot_length,
           make_interval(mins => s.slot_minutes + 5) as slot_step
    from public.specialties s
    where s.id = p_specialty_id and s.is_active
  ),
  candidate_slots as (
    select d.id as doctor_id,
           (local_start at time zone 'America/Bogota') as slot_start,
           p.slot_length
    from public.doctors d
    join public.doctor_schedules ds on ds.doctor_id = d.id
    cross join params p
    cross join lateral generate_series(
      p_date + ds.start_time,
      p_date + ds.end_time - p.slot_length,
      p.slot_step
    ) as local_start
    where d.specialty_id = p_specialty_id
      and d.is_active
      and ds.site_id = p_site_id
      and ds.weekday = extract(isodow from p_date)
      and p_date between current_date and current_date + 60
  )
  select cs.slot_start, cs.slot_start + cs.slot_length, count(*)::integer
  from candidate_slots cs
  where cs.slot_start > now()
    and not exists (
      select 1
      from public.appointments a
      where a.doctor_id = cs.doctor_id
        and a.status in ('assigned', 'confirmed', 'checked_in', 'in_progress')
        and tstzrange(a.starts_at, a.ends_at) && tstzrange(cs.slot_start, cs.slot_start + cs.slot_length)
    )
  group by cs.slot_start, cs.slot_length
  order by cs.slot_start;
$$;

-- -------------------------------------------------------------
-- Agenda una cita para el paciente autenticado.
-- Elige el médico con MENOS citas ese día. Si dos pacientes piden la
-- misma hora al mismo tiempo, el exclusion constraint rechaza al segundo
-- y se prueba con el siguiente médico disponible.
-- -------------------------------------------------------------
create or replace function public.book_appointment(
  p_specialty_id bigint,
  p_site_id      bigint,
  p_starts_at    timestamptz,
  p_symptoms     text default null
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_patient_id     uuid := auth.uid();
  v_role           public.user_role;
  v_blocked_until  timestamptz;
  v_slot_minutes   smallint;
  v_ends_at        timestamptz;
  v_local_date     date := (p_starts_at at time zone 'America/Bogota')::date;
  v_doctor_id      bigint;
  v_appointment_id bigint;
begin
  select role, booking_blocked_until into v_role, v_blocked_until
  from public.profiles where id = v_patient_id;

  if v_role is distinct from 'patient' then
    raise exception 'Solo los pacientes pueden agendar citas en línea' using errcode = '42501';
  end if;
  if v_blocked_until is not null and v_blocked_until > now() then
    raise exception 'Tu agendamiento en línea está bloqueado hasta el % por inasistencias. Comunícate con la clínica.',
      to_char(v_blocked_until at time zone 'America/Bogota', 'DD/MM/YYYY') using errcode = '42501';
  end if;
  if char_length(coalesce(p_symptoms, '')) > 2000 then
    raise exception 'La descripción de síntomas es demasiado larga' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.get_available_slots(p_specialty_id, p_site_id, v_local_date) s
    where s.starts_at = p_starts_at
  ) then
    raise exception 'Ese horario ya no está disponible. Elige otro.' using errcode = 'P0001';
  end if;

  select slot_minutes into v_slot_minutes from public.specialties where id = p_specialty_id;
  v_ends_at := p_starts_at + make_interval(mins => v_slot_minutes);

  if exists (
    select 1 from public.appointments a
    where a.patient_id = v_patient_id
      and a.status in ('requested', 'assigned', 'confirmed', 'checked_in', 'in_progress')
      and tstzrange(a.starts_at, a.ends_at) && tstzrange(p_starts_at, v_ends_at)
  ) then
    raise exception 'Ya tienes otra cita en ese horario.' using errcode = 'P0001';
  end if;

  for v_doctor_id in
    select d.id
    from public.doctors d
    join public.doctor_schedules ds on ds.doctor_id = d.id
    where d.specialty_id = p_specialty_id
      and d.is_active
      and ds.site_id = p_site_id
      and ds.weekday = extract(isodow from v_local_date)
      and (p_starts_at at time zone 'America/Bogota')::time >= ds.start_time
      and (v_ends_at at time zone 'America/Bogota')::time <= ds.end_time
    order by (
      select count(*) from public.appointments a
      where a.doctor_id = d.id
        and a.status in ('assigned', 'confirmed', 'checked_in', 'in_progress')
        and (a.starts_at at time zone 'America/Bogota')::date = v_local_date
    ), d.id
  loop
    begin
      insert into public.appointments
        (patient_id, doctor_id, specialty_id, site_id, starts_at, ends_at, status, symptoms)
      values
        (v_patient_id, v_doctor_id, p_specialty_id, p_site_id, p_starts_at, v_ends_at,
         'assigned', nullif(trim(p_symptoms), ''))
      returning id into v_appointment_id;
      return v_appointment_id;
    exception when exclusion_violation then
      continue; -- otro paciente tomó a este médico en el mismo instante
    end;
  end loop;

  raise exception 'Ese horario ya no está disponible. Elige otro.' using errcode = 'P0001';
end;
$$;

-- -------------------------------------------------------------
-- Cancela una cita. Paciente: solo las suyas y hasta 2 h antes.
-- Recepción/admin: cualquiera, en cualquier momento.
-- -------------------------------------------------------------
create or replace function public.cancel_appointment(
  p_appointment_id bigint,
  p_reason         text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role        public.user_role := public.get_my_role();
  v_patient_id  uuid;
  v_starts_at   timestamptz;
  v_status      public.appointment_status;
begin
  select patient_id, starts_at, status into v_patient_id, v_starts_at, v_status
  from public.appointments where id = p_appointment_id
  for update;

  if not found then
    raise exception 'La cita no existe' using errcode = 'P0002';
  end if;

  if v_role = 'patient' then
    if v_patient_id is distinct from auth.uid() then
      raise exception 'No puedes cancelar esta cita' using errcode = '42501';
    end if;
    if v_starts_at - now() < interval '2 hours' then
      raise exception 'Solo puedes cancelar hasta 2 horas antes. Comunícate con la clínica.'
        using errcode = 'P0001';
    end if;
  elsif v_role is null or v_role not in ('receptionist', 'admin') then
    raise exception 'No tienes permiso para cancelar citas' using errcode = '42501';
  end if;

  if v_status not in ('requested', 'assigned', 'confirmed') then
    raise exception 'Esta cita ya no se puede cancelar' using errcode = 'P0001';
  end if;

  update public.appointments
  set status = 'cancelled',
      cancel_reason = left(nullif(trim(p_reason), ''), 500)
  where id = p_appointment_id;
end;
$$;

-- -------------------------------------------------------------
-- Citas del paciente autenticado con datos para mostrar.
-- (El paciente no puede leer perfiles de médicos por RLS; esta función
--  expone SOLO el nombre del médico, nada más.)
-- -------------------------------------------------------------
create or replace function public.get_my_appointments()
returns table (
  id                 bigint,
  starts_at          timestamptz,
  ends_at            timestamptz,
  status             public.appointment_status,
  symptoms           text,
  cancel_reason      text,
  confirmation_token uuid,
  specialty_name     text,
  site_name          text,
  site_address       text,
  doctor_name        text
)
language sql
stable
security definer
set search_path = ''
as $$
  select a.id, a.starts_at, a.ends_at, a.status, a.symptoms, a.cancel_reason,
         a.confirmation_token, sp.name, si.name, si.address,
         coalesce(nullif(p.full_name, ''), 'Médico asignado')
  from public.appointments a
  join public.specialties sp on sp.id = a.specialty_id
  join public.sites si on si.id = a.site_id
  left join public.doctors d on d.id = a.doctor_id
  left join public.profiles p on p.id = d.profile_id
  where a.patient_id = auth.uid()
  order by a.starts_at desc nulls last;
$$;

-- Permisos de ejecución: solo usuarios autenticados.
revoke execute on function public.get_available_slots(bigint, bigint, date) from anon, public;
revoke execute on function public.book_appointment(bigint, bigint, timestamptz, text) from anon, public;
revoke execute on function public.cancel_appointment(bigint, text) from anon, public;
revoke execute on function public.get_my_appointments() from anon, public;
grant execute on function public.get_available_slots(bigint, bigint, date) to authenticated;
grant execute on function public.book_appointment(bigint, bigint, timestamptz, text) to authenticated;
grant execute on function public.cancel_appointment(bigint, text) to authenticated;
grant execute on function public.get_my_appointments() to authenticated;
