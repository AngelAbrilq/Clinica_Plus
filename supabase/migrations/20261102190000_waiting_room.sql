-- =============================================================
-- Clinica Plus · Migración 009: sala de espera en vivo
-- · get_my_queue_status: personas antes que el paciente y hora estimada
-- · Realtime: la tabla appointments publica cambios. La RLS hace que
--   cada paciente reciba SOLO los eventos de sus propias citas.
-- =============================================================

create or replace function public.get_my_queue_status(p_appointment_id bigint)
returns table (
  status            public.appointment_status,
  starts_at         timestamptz,
  people_ahead      integer,
  estimated_start   timestamptz,
  specialty_name    text,
  doctor_name       text,
  site_name         text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_patient_id   uuid;
  v_doctor_id    bigint;
  v_status       public.appointment_status;
  v_starts_at    timestamptz;
  v_slot         interval;
  v_day_start    timestamptz;
  v_day_end      timestamptz;
  v_ahead        integer := 0;
begin
  select a.patient_id, a.doctor_id, a.status, a.starts_at,
         make_interval(mins => sp.slot_minutes + 5)
    into v_patient_id, v_doctor_id, v_status, v_starts_at, v_slot
  from public.appointments a
  join public.specialties sp on sp.id = a.specialty_id
  where a.id = p_appointment_id;

  -- Mismo mensaje si no existe o es ajena: no revela qué ids existen.
  if not found or v_patient_id is distinct from auth.uid() then
    raise exception 'La cita no existe' using errcode = 'P0002';
  end if;

  v_day_start := (v_starts_at at time zone 'America/Bogota')::date::timestamp
                 at time zone 'America/Bogota';
  v_day_end   := v_day_start + interval '1 day';

  -- Antes que el paciente: quien está en consulta con su médico y quienes
  -- ya llegaron con una hora anterior (o igual hora y menor id).
  if v_status in ('assigned', 'confirmed', 'checked_in') then
    select count(*)::integer into v_ahead
    from public.appointments o
    where o.doctor_id = v_doctor_id
      and o.id <> p_appointment_id
      and o.starts_at >= v_day_start
      and o.starts_at <  v_day_end
      and (
        o.status = 'in_progress'
        or (o.status = 'checked_in'
            and (o.starts_at < v_starts_at
                 or (o.starts_at = v_starts_at and o.id < p_appointment_id)))
      );
  end if;

  return query
  select v_status,
         v_starts_at,
         v_ahead,
         case
           when v_status in ('assigned', 'confirmed', 'checked_in')
             then greatest(v_starts_at, now() + v_ahead * v_slot)
           else null
         end,
         sp.name,
         coalesce(nullif(dp.full_name, ''), 'Médico asignado'),
         si.name
  from public.appointments a
  join public.specialties sp on sp.id = a.specialty_id
  join public.sites si on si.id = a.site_id
  left join public.doctors d on d.id = a.doctor_id
  left join public.profiles dp on dp.id = d.profile_id
  where a.id = p_appointment_id;
end;
$$;

revoke execute on function public.get_my_queue_status(bigint) from anon, public;
grant execute on function public.get_my_queue_status(bigint) to authenticated;

-- Publicar cambios de citas en Realtime (solo existe en Supabase).
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'appointments'
     ) then
    alter publication supabase_realtime add table public.appointments;
  end if;
end;
$$;
