-- =============================================================
-- Clinica Plus · Migración 007: administración
-- · Sedes inactivas ya no ofrecen horas (corrige get_available_slots)
-- · admin_catalog_overview: uso de cada sede y especialidad
-- · admin_get_metrics: indicadores por rango de fechas y sede
-- · admin_get_audit_logs: bitácora legible, paginada por id
-- =============================================================

create or replace function private.assert_admin()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'Solo administración puede ver esta información' using errcode = '42501';
  end if;
end;
$$;

-- -------------------------------------------------------------
-- Corrección: antes una sede desactivada seguía ofreciendo horas.
-- Misma lógica de la migración 004 + filtro si.is_active.
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
    join public.sites si on si.id = p_site_id and si.is_active
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
-- Uso de cada catálogo: sirve para advertir antes de desactivar.
-- -------------------------------------------------------------
create or replace function public.admin_catalog_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.assert_admin();
  return jsonb_build_object(
    'sites', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', si.id,
        'scheduled_doctors', (
          select count(distinct ds.doctor_id) from public.doctor_schedules ds
          join public.doctors d on d.id = ds.doctor_id and d.is_active
          where ds.site_id = si.id),
        'upcoming_appointments', (
          select count(*) from public.appointments a
          where a.site_id = si.id and a.starts_at > now()
            and a.status in ('assigned', 'confirmed'))
      ) order by si.id)
      from public.sites si), '[]'::jsonb),
    'specialties', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', sp.id,
        'active_doctors', (
          select count(*) from public.doctors d
          where d.specialty_id = sp.id and d.is_active),
        'upcoming_appointments', (
          select count(*) from public.appointments a
          where a.specialty_id = sp.id and a.starts_at > now()
            and a.status in ('assigned', 'confirmed'))
      ) order by sp.id)
      from public.specialties sp), '[]'::jsonb)
  );
end;
$$;

-- -------------------------------------------------------------
-- Indicadores entre p_from y p_to (fechas de Bogotá, inclusive).
-- p_site_id null = todas las sedes.
-- Ocupación = minutos agendados / minutos de agenda publicada.
-- -------------------------------------------------------------
create or replace function public.admin_get_metrics(
  p_from    date,
  p_to      date,
  p_site_id bigint default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_start          timestamptz := p_from::timestamp at time zone 'America/Bogota';
  v_end            timestamptz := (p_to + 1)::timestamp at time zone 'America/Bogota';
  v_capacity_min   numeric;
  v_booked_min     numeric;
  v_result         jsonb;
begin
  perform private.assert_admin();
  if p_to < p_from then
    raise exception 'La fecha final debe ser posterior a la inicial' using errcode = '22023';
  end if;
  if p_to - p_from > 366 then
    raise exception 'El rango máximo es de un año' using errcode = '22023';
  end if;

  -- Capacidad: por cada día del rango, los bloques de horario de ese día de la semana.
  select coalesce(sum(extract(epoch from ds.end_time - ds.start_time) / 60), 0)
    into v_capacity_min
  from generate_series(p_from, p_to, interval '1 day') as day
  join public.doctor_schedules ds on ds.weekday = extract(isodow from day)
  join public.doctors d on d.id = ds.doctor_id and d.is_active
  where p_site_id is null or ds.site_id = p_site_id;

  select coalesce(sum(extract(epoch from a.ends_at - a.starts_at) / 60), 0)
    into v_booked_min
  from public.appointments a
  where a.starts_at >= v_start and a.starts_at < v_end
    and (p_site_id is null or a.site_id = p_site_id)
    and a.status not in ('cancelled', 'requested');

  with filtered as (
    select a.*
    from public.appointments a
    where a.starts_at >= v_start and a.starts_at < v_end
      and (p_site_id is null or a.site_id = p_site_id)
  )
  select jsonb_build_object(
    'total',       (select count(*) from filtered),
    'completed',   (select count(*) from filtered where status = 'completed'),
    'cancelled',   (select count(*) from filtered where status = 'cancelled'),
    'no_show',     (select count(*) from filtered where status = 'no_show'),
    'pending',     (select count(*) from filtered
                    where status in ('requested', 'assigned', 'confirmed', 'checked_in', 'in_progress')),
    'capacity_minutes', round(v_capacity_min),
    'booked_minutes',   round(v_booked_min),
    'by_specialty', coalesce((
      select jsonb_agg(row_data order by (row_data->>'total')::int desc)
      from (
        select jsonb_build_object(
          'name', sp.name,
          'total', count(f.id),
          'completed', count(f.id) filter (where f.status = 'completed'),
          'no_show', count(f.id) filter (where f.status = 'no_show'),
          'cancelled', count(f.id) filter (where f.status = 'cancelled')
        ) as row_data
        from filtered f
        join public.specialties sp on sp.id = f.specialty_id
        group by sp.name
      ) grouped), '[]'::jsonb),
    'by_day', coalesce((
      select jsonb_agg(jsonb_build_object('date', day::date, 'total', coalesce(counts.total, 0))
                       order by day)
      from generate_series(p_from, p_to, interval '1 day') as day
      left join (
        select (f.starts_at at time zone 'America/Bogota')::date as local_day, count(*) as total
        from filtered f
        where f.status <> 'cancelled'
        group by 1
      ) counts on counts.local_day = day::date), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;

-- -------------------------------------------------------------
-- Bitácora de auditoría con nombres legibles.
-- Paginación por cursor (p_before_id): estable aunque lleguen registros
-- nuevos, a diferencia de OFFSET.
-- -------------------------------------------------------------
create or replace function public.admin_get_audit_logs(
  p_limit     integer default 30,
  p_before_id bigint  default null,
  p_action    text    default null
)
returns table (
  id           bigint,
  created_at   timestamptz,
  action       text,
  table_name   text,
  actor_name   text,
  actor_role   public.user_role,
  patient_name text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.assert_admin();

  return query
  select l.id, l.created_at, l.action, l.table_name,
         coalesce(nullif(ap.full_name, ''), ap.email, 'Sistema'),
         ap.role,
         coalesce(nullif(pp.full_name, ''), pp.email)
  from public.audit_logs l
  left join public.profiles ap on ap.id = l.actor_id
  -- Lecturas de historia: record_id es el id del paciente.
  -- Cambios en historias: record_id es el id del registro clínico.
  left join public.medical_records mr
    on l.table_name = 'medical_records' and mr.id::text = l.record_id
  left join public.profiles pp
    on pp.id = case
                 when l.table_name = 'profiles' then l.record_id::uuid
                 else mr.patient_id
               end
  where (p_before_id is null or l.id < p_before_id)
    and (p_action is null or l.action = p_action)
  order by l.id desc
  limit least(greatest(coalesce(p_limit, 30), 1), 100);
end;
$$;

revoke execute on all functions in schema private from public, anon, authenticated;
revoke execute on function public.admin_catalog_overview() from anon, public;
revoke execute on function public.admin_get_metrics(date, date, bigint) from anon, public;
revoke execute on function public.admin_get_audit_logs(integer, bigint, text) from anon, public;
grant execute on function public.admin_catalog_overview() to authenticated;
grant execute on function public.admin_get_metrics(date, date, bigint) to authenticated;
grant execute on function public.admin_get_audit_logs(integer, bigint, text) to authenticated;
