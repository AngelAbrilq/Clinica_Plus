-- =============================================================
-- Clinica Plus · Migración 008: "Mis pacientes" del médico
-- · get_my_patients: pacientes con los que el médico tiene o tuvo citas
-- · get_patient_chart: historia completa de uno de ellos (AUDITADA)
-- Un médico solo ve pacientes con los que tiene relación de atención.
-- =============================================================

-- Minúsculas y sin tildes, para buscar "Gomez" y encontrar "Gómez".
create or replace function private.normalize_search(p_value text)
returns text
language sql
immutable
set search_path = ''
as $$
  select translate(lower(coalesce(p_value, '')), 'áéíóúüñ', 'aeiouun');
$$;

create or replace function public.get_my_patients(p_search text default null)
returns table (
  patient_id       uuid,
  patient_name     text,
  patient_document text,
  patient_age      integer,
  completed_visits integer,
  last_visit_at    timestamptz,
  next_visit_at    timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_doctor_id bigint := public.get_my_doctor_id();
  v_search    text := nullif(private.normalize_search(trim(p_search)), '');
begin
  if v_doctor_id is null or public.get_my_role() is distinct from 'doctor' then
    raise exception 'Solo los médicos pueden ver sus pacientes' using errcode = '42501';
  end if;
  if char_length(coalesce(v_search, '')) > 80 then
    raise exception 'La búsqueda es demasiado larga' using errcode = '22023';
  end if;

  return query
  with relation as (
    -- Una fila por paciente: agregados sobre sus citas con este médico.
    select a.patient_id,
           count(*) filter (where a.status = 'completed')::integer as completed_visits,
           max(a.starts_at) filter (where a.status = 'completed') as last_visit_at,
           min(a.starts_at) filter (
             where a.starts_at > now() and a.status in ('assigned', 'confirmed', 'checked_in')
           ) as next_visit_at
    from public.appointments a
    where a.doctor_id = v_doctor_id
      and a.status <> 'cancelled'
    group by a.patient_id
  )
  select p.id,
         coalesce(nullif(p.full_name, ''), p.email),
         case when p.document_type is null then null
              else p.document_type::text || ' ' || p.document_number end,
         private.age_in_years(p.birth_date),
         r.completed_visits, r.last_visit_at, r.next_visit_at
  from relation r
  join public.profiles p on p.id = r.patient_id
  where v_search is null
     or private.normalize_search(p.full_name) like '%' || v_search || '%'
     or coalesce(p.document_number, '') like '%' || v_search || '%'
  order by r.last_visit_at desc nulls last, p.full_name
  limit 100;
end;
$$;

-- -------------------------------------------------------------
-- Historia clínica completa (todas las especialidades) de un paciente,
-- solo si el médico lo ha atendido o lo tiene agendado.
-- -------------------------------------------------------------
create or replace function public.get_patient_chart(p_patient_id uuid)
returns table (
  record_id             bigint,
  consulted_at          timestamptz,
  specialty_name        text,
  doctor_name           text,
  reason                text,
  clinical_notes        text,
  diagnosis_code        text,
  diagnosis_description text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_doctor_id bigint := public.get_my_doctor_id();
begin
  if v_doctor_id is null or public.get_my_role() is distinct from 'doctor' then
    raise exception 'Solo los médicos pueden ver historias clínicas' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.appointments a
    where a.doctor_id = v_doctor_id
      and a.patient_id = p_patient_id
      and a.status <> 'cancelled'
  ) then
    raise exception 'No tienes citas con este paciente' using errcode = '42501';
  end if;

  insert into public.audit_logs (actor_id, action, table_name, record_id)
  values (auth.uid(), 'READ_HISTORY', 'profiles', p_patient_id::text);

  return query
  select mr.id, a.starts_at, sp.name,
         coalesce(nullif(dp.full_name, ''), 'Médico'),
         mr.reason, mr.clinical_notes, mr.diagnosis_code, mr.diagnosis_description
  from public.medical_records mr
  join public.appointments a on a.id = mr.appointment_id
  join public.specialties sp on sp.id = a.specialty_id
  join public.doctors d on d.id = mr.doctor_id
  join public.profiles dp on dp.id = d.profile_id
  where mr.patient_id = p_patient_id
  order by a.starts_at desc;
end;
$$;

revoke execute on all functions in schema private from public, anon, authenticated;
revoke execute on function public.get_my_patients(text) from anon, public;
revoke execute on function public.get_patient_chart(uuid) from anon, public;
grant execute on function public.get_my_patients(text) to authenticated;
grant execute on function public.get_patient_chart(uuid) to authenticated;
