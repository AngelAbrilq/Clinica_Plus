-- =============================================================
-- Clinica Plus · Migración 005: recepción
-- · get_reception_agenda: citas de una sede en un día
-- · check_in_by_token / check_in_by_id: registrar llegada del paciente
-- · mark_no_show: inasistencia (3 inasistencias = bloqueo 30 días)
-- Los helpers internos van en el schema "private", que Supabase NO
-- expone por la API: solo se pueden usar desde otras funciones SQL.
-- =============================================================

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- Solo recepción y administración operan la agenda.
create or replace function private.assert_front_desk()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_role public.user_role := public.get_my_role();
begin
  if v_role is null or v_role not in ('receptionist', 'admin') then
    raise exception 'Solo recepción o administración pueden realizar esta acción'
      using errcode = '42501';
  end if;
end;
$$;

-- -------------------------------------------------------------
-- Agenda del día por sede.
-- El filtro usa un RANGO sobre starts_at (no una función sobre la
-- columna) para que Postgres pueda usar el índice (site_id, starts_at).
-- No expone síntomas: son datos clínicos que recepción no necesita.
-- -------------------------------------------------------------
create or replace function public.get_reception_agenda(p_site_id bigint, p_date date)
returns table (
  id               bigint,
  starts_at        timestamptz,
  ends_at          timestamptz,
  status           public.appointment_status,
  checked_in_at    timestamptz,
  patient_name     text,
  patient_document text,
  patient_phone    text,
  specialty_name   text,
  doctor_name      text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_day_start timestamptz := p_date::timestamp at time zone 'America/Bogota';
  v_day_end   timestamptz := (p_date + 1)::timestamp at time zone 'America/Bogota';
begin
  perform private.assert_front_desk();

  return query
  select a.id, a.starts_at, a.ends_at, a.status, a.checked_in_at,
         coalesce(nullif(pp.full_name, ''), pp.email),
         case when pp.document_type is null then null
              else pp.document_type::text || ' ' || pp.document_number end,
         pp.phone,
         sp.name,
         coalesce(nullif(dp.full_name, ''), 'Médico asignado')
  from public.appointments a
  join public.profiles pp on pp.id = a.patient_id
  join public.specialties sp on sp.id = a.specialty_id
  left join public.doctors d on d.id = a.doctor_id
  left join public.profiles dp on dp.id = d.profile_id
  where a.site_id = p_site_id
    and a.starts_at >= v_day_start
    and a.starts_at <  v_day_end
  order by a.starts_at, a.id;
end;
$$;

-- -------------------------------------------------------------
-- Núcleo del check-in (interno). Reglas:
-- · solo citas asignadas/confirmadas
-- · solo el mismo día de la cita
-- · hasta 10 minutos después de la hora (tolerancia de retraso)
-- -------------------------------------------------------------
create or replace function private.check_in(p_appointment_id bigint)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now          timestamptz := now();
  v_status       public.appointment_status;
  v_starts_at    timestamptz;
  v_patient_name text;
  v_specialty    text;
  v_doctor_name  text;
begin
  select a.status, a.starts_at,
         coalesce(nullif(pp.full_name, ''), pp.email),
         sp.name,
         coalesce(nullif(dp.full_name, ''), 'Médico asignado')
    into v_status, v_starts_at, v_patient_name, v_specialty, v_doctor_name
  from public.appointments a
  join public.profiles pp on pp.id = a.patient_id
  join public.specialties sp on sp.id = a.specialty_id
  left join public.doctors d on d.id = a.doctor_id
  left join public.profiles dp on dp.id = d.profile_id
  where a.id = p_appointment_id
  for update of a;

  if not found then
    raise exception 'La cita no existe' using errcode = 'P0002';
  end if;
  if v_status in ('checked_in', 'in_progress') then
    raise exception '% ya hizo check-in', v_patient_name using errcode = 'P0001';
  end if;
  if v_status not in ('assigned', 'confirmed') then
    raise exception 'Esta cita no admite check-in (estado: %)', v_status using errcode = 'P0001';
  end if;
  if (v_starts_at at time zone 'America/Bogota')::date
     <> (v_now at time zone 'America/Bogota')::date then
    raise exception 'La cita es para el %, no para hoy',
      to_char(v_starts_at at time zone 'America/Bogota', 'DD/MM/YYYY "a las" HH12:MI AM')
      using errcode = 'P0001';
  end if;
  if v_now > v_starts_at + interval '10 minutes' then
    raise exception 'El paciente llegó más de 10 minutos tarde. Reprograma la cita o márcala como inasistencia.'
      using errcode = 'P0001';
  end if;

  update public.appointments
  set status = 'checked_in', checked_in_at = v_now
  where id = p_appointment_id;

  return jsonb_build_object(
    'appointment_id', p_appointment_id,
    'patient_name', v_patient_name,
    'specialty_name', v_specialty,
    'doctor_name', v_doctor_name,
    'starts_at', v_starts_at,
    'minutes_until_start', floor(extract(epoch from v_starts_at - v_now) / 60)::integer
  );
end;
$$;

-- Check-in escaneando el QR del paciente (token de la cita).
create or replace function public.check_in_by_token(p_token uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_appointment_id bigint;
begin
  perform private.assert_front_desk();
  select id into v_appointment_id from public.appointments where confirmation_token = p_token;
  if not found then
    raise exception 'Código QR no válido para ninguna cita' using errcode = 'P0002';
  end if;
  return private.check_in(v_appointment_id);
end;
$$;

-- Check-in manual desde la agenda (el paciente no trae el celular).
create or replace function public.check_in_by_id(p_appointment_id bigint)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.assert_front_desk();
  return private.check_in(p_appointment_id);
end;
$$;

-- -------------------------------------------------------------
-- Inasistencia. Solo después de la tolerancia de 10 minutos.
-- Con 3 inasistencias acumuladas se bloquea el agendamiento en línea
-- por 30 días (book_appointment ya respeta booking_blocked_until).
-- -------------------------------------------------------------
create or replace function public.mark_no_show(p_appointment_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_status     public.appointment_status;
  v_starts_at  timestamptz;
  v_patient_id uuid;
begin
  perform private.assert_front_desk();

  select status, starts_at, patient_id into v_status, v_starts_at, v_patient_id
  from public.appointments where id = p_appointment_id
  for update;

  if not found then
    raise exception 'La cita no existe' using errcode = 'P0002';
  end if;
  if v_status not in ('assigned', 'confirmed') then
    raise exception 'Solo se puede marcar inasistencia en citas pendientes' using errcode = 'P0001';
  end if;
  if now() < v_starts_at + interval '10 minutes' then
    raise exception 'Espera 10 minutos después de la hora de la cita para marcar inasistencia'
      using errcode = 'P0001';
  end if;

  update public.appointments set status = 'no_show' where id = p_appointment_id;

  update public.profiles
  set no_show_count = no_show_count + 1,
      booking_blocked_until = case
        when no_show_count + 1 >= 3 then now() + interval '30 days'
        else booking_blocked_until
      end
  where id = v_patient_id;
end;
$$;

revoke execute on all functions in schema private from public, anon, authenticated;
revoke execute on function public.get_reception_agenda(bigint, date) from anon, public;
revoke execute on function public.check_in_by_token(uuid) from anon, public;
revoke execute on function public.check_in_by_id(bigint) from anon, public;
revoke execute on function public.mark_no_show(bigint) from anon, public;
grant execute on function public.get_reception_agenda(bigint, date) to authenticated;
grant execute on function public.check_in_by_token(uuid) to authenticated;
grant execute on function public.check_in_by_id(bigint) to authenticated;
grant execute on function public.mark_no_show(bigint) to authenticated;
