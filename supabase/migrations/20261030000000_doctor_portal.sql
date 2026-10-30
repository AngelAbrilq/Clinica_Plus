-- =============================================================
-- Clinica Plus · Migración 006: portal médico e historia clínica
-- · get_doctor_agenda: citas del médico autenticado en un día
-- · get_consultation: datos de una cita + su registro clínico
-- · start_consultation / complete_consultation: flujo de la consulta
-- · get_patient_history: historia previa (queda AUDITADA)
-- · get_my_medical_records: historia del paciente autenticado
-- =============================================================

-- El médico autenticado debe ser el asignado a la cita. Devuelve su id.
create or replace function private.assert_doctor_owns(p_appointment_id bigint)
returns bigint
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_doctor_id bigint := public.get_my_doctor_id();
begin
  if v_doctor_id is null or public.get_my_role() is distinct from 'doctor' then
    raise exception 'Solo los médicos pueden realizar esta acción' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.appointments where id = p_appointment_id and doctor_id = v_doctor_id
  ) then
    raise exception 'Esta cita no está asignada a ti' using errcode = '42501';
  end if;
  return v_doctor_id;
end;
$$;

-- Edad en años cumplidos (null si no hay fecha de nacimiento).
create or replace function private.age_in_years(p_birth_date date)
returns integer
language sql
stable
set search_path = ''
as $$
  select extract(year from age(current_date, p_birth_date))::integer;
$$;

-- -------------------------------------------------------------
-- Agenda del médico (todas sus sedes). Rango sargable sobre el índice
-- (doctor_id, starts_at).
-- -------------------------------------------------------------
create or replace function public.get_doctor_agenda(p_date date)
returns table (
  id             bigint,
  starts_at      timestamptz,
  ends_at        timestamptz,
  status         public.appointment_status,
  checked_in_at  timestamptz,
  patient_name   text,
  patient_age    integer,
  site_name      text,
  specialty_name text,
  symptoms       text,
  has_record     boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_doctor_id bigint := public.get_my_doctor_id();
  v_day_start timestamptz := p_date::timestamp at time zone 'America/Bogota';
  v_day_end   timestamptz := (p_date + 1)::timestamp at time zone 'America/Bogota';
begin
  if v_doctor_id is null or public.get_my_role() is distinct from 'doctor' then
    raise exception 'Solo los médicos pueden ver su agenda' using errcode = '42501';
  end if;

  return query
  select a.id, a.starts_at, a.ends_at, a.status, a.checked_in_at,
         coalesce(nullif(pp.full_name, ''), pp.email),
         private.age_in_years(pp.birth_date),
         si.name, sp.name, a.symptoms,
         exists (select 1 from public.medical_records mr where mr.appointment_id = a.id)
  from public.appointments a
  join public.profiles pp on pp.id = a.patient_id
  join public.sites si on si.id = a.site_id
  join public.specialties sp on sp.id = a.specialty_id
  where a.doctor_id = v_doctor_id
    and a.starts_at >= v_day_start
    and a.starts_at <  v_day_end
    and a.status <> 'cancelled'
  order by a.starts_at;
end;
$$;

-- -------------------------------------------------------------
-- Una cita con los datos del paciente y su registro clínico (si existe).
-- -------------------------------------------------------------
create or replace function public.get_consultation(p_appointment_id bigint)
returns table (
  id                    bigint,
  starts_at             timestamptz,
  ends_at               timestamptz,
  status                public.appointment_status,
  checked_in_at         timestamptz,
  patient_name          text,
  patient_document      text,
  patient_age           integer,
  specialty_name        text,
  site_name             text,
  symptoms              text,
  record_id             bigint,
  reason                text,
  clinical_notes        text,
  diagnosis_code        text,
  diagnosis_description text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.assert_doctor_owns(p_appointment_id);

  return query
  select a.id, a.starts_at, a.ends_at, a.status, a.checked_in_at,
         coalesce(nullif(pp.full_name, ''), pp.email),
         case when pp.document_type is null then null
              else pp.document_type::text || ' ' || pp.document_number end,
         private.age_in_years(pp.birth_date),
         sp.name, si.name, a.symptoms,
         mr.id, mr.reason, mr.clinical_notes, mr.diagnosis_code, mr.diagnosis_description
  from public.appointments a
  join public.profiles pp on pp.id = a.patient_id
  join public.specialties sp on sp.id = a.specialty_id
  join public.sites si on si.id = a.site_id
  left join public.medical_records mr on mr.appointment_id = a.id
  where a.id = p_appointment_id;
end;
$$;

-- -------------------------------------------------------------
-- Iniciar consulta: el paciente debe estar en sala (check-in hecho) y
-- el médico no puede tener otra consulta abierta.
-- -------------------------------------------------------------
create or replace function public.start_consultation(p_appointment_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_doctor_id  bigint := private.assert_doctor_owns(p_appointment_id);
  v_status     public.appointment_status;
  v_open_name  text;
begin
  select status into v_status from public.appointments
  where id = p_appointment_id for update;

  if v_status = 'in_progress' then
    return; -- idempotente: ya estaba iniciada
  end if;
  if v_status <> 'checked_in' then
    raise exception 'El paciente aún no ha hecho check-in en recepción' using errcode = 'P0001';
  end if;

  select coalesce(nullif(pp.full_name, ''), pp.email) into v_open_name
  from public.appointments a
  join public.profiles pp on pp.id = a.patient_id
  where a.doctor_id = v_doctor_id and a.status = 'in_progress' and a.id <> p_appointment_id
  limit 1;
  if v_open_name is not null then
    raise exception 'Ya tienes una consulta en curso con %. Finalízala primero.', v_open_name
      using errcode = 'P0001';
  end if;

  update public.appointments set status = 'in_progress' where id = p_appointment_id;
end;
$$;

-- -------------------------------------------------------------
-- Finalizar consulta: guarda el registro clínico y cierra la cita en
-- UNA transacción (o se guarda todo, o nada). Devuelve el id del registro.
-- -------------------------------------------------------------
create or replace function public.complete_consultation(
  p_appointment_id        bigint,
  p_reason                text,
  p_clinical_notes        text,
  p_diagnosis_code        text,
  p_diagnosis_description text
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_doctor_id  bigint := private.assert_doctor_owns(p_appointment_id);
  v_status     public.appointment_status;
  v_patient_id uuid;
  v_record_id  bigint;
  v_code       text := nullif(upper(trim(p_diagnosis_code)), '');
begin
  select status, patient_id into v_status, v_patient_id
  from public.appointments where id = p_appointment_id for update;

  if v_status <> 'in_progress' then
    raise exception 'Inicia la consulta antes de finalizarla' using errcode = 'P0001';
  end if;
  if nullif(trim(p_reason), '') is null then
    raise exception 'El motivo de consulta es obligatorio' using errcode = '22023';
  end if;
  if v_code is null then
    raise exception 'El diagnóstico (CIE-10) es obligatorio' using errcode = '22023';
  end if;
  if v_code !~ '^[A-Z][0-9]{2}(\.?[0-9A-Z]{1,4})?$' then
    raise exception 'Código CIE-10 no válido: % (ejemplo correcto: J06.9)', v_code using errcode = '22023';
  end if;

  insert into public.medical_records
    (appointment_id, patient_id, doctor_id, reason, clinical_notes, diagnosis_code, diagnosis_description)
  values
    (p_appointment_id, v_patient_id, v_doctor_id, trim(p_reason),
     nullif(trim(p_clinical_notes), ''), v_code, nullif(trim(p_diagnosis_description), ''))
  on conflict (appointment_id) do update
    set reason = excluded.reason,
        clinical_notes = excluded.clinical_notes,
        diagnosis_code = excluded.diagnosis_code,
        diagnosis_description = excluded.diagnosis_description
  returning id into v_record_id;

  update public.appointments set status = 'completed' where id = p_appointment_id;
  return v_record_id;
end;
$$;

-- -------------------------------------------------------------
-- Historia previa del paciente de esta cita. Solo el médico asignado.
-- Cada consulta se registra en audit_logs (quién, cuándo, de quién).
-- -------------------------------------------------------------
create or replace function public.get_patient_history(p_appointment_id bigint)
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
  v_patient_id uuid;
begin
  perform private.assert_doctor_owns(p_appointment_id);
  select patient_id into v_patient_id from public.appointments where id = p_appointment_id;

  insert into public.audit_logs (actor_id, action, table_name, record_id)
  values (auth.uid(), 'READ_HISTORY', 'profiles', v_patient_id::text);

  return query
  select mr.id, a.starts_at, sp.name,
         coalesce(nullif(dp.full_name, ''), 'Médico'),
         mr.reason, mr.clinical_notes, mr.diagnosis_code, mr.diagnosis_description
  from public.medical_records mr
  join public.appointments a on a.id = mr.appointment_id
  join public.specialties sp on sp.id = a.specialty_id
  join public.doctors d on d.id = mr.doctor_id
  join public.profiles dp on dp.id = d.profile_id
  where mr.patient_id = v_patient_id
    and mr.appointment_id <> p_appointment_id
  order by a.starts_at desc;
end;
$$;

-- -------------------------------------------------------------
-- Historia clínica del paciente autenticado (derecho de acceso).
-- -------------------------------------------------------------
create or replace function public.get_my_medical_records()
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
language sql
stable
security definer
set search_path = ''
as $$
  select mr.id, a.starts_at, sp.name,
         coalesce(nullif(dp.full_name, ''), 'Médico'),
         mr.reason, mr.clinical_notes, mr.diagnosis_code, mr.diagnosis_description
  from public.medical_records mr
  join public.appointments a on a.id = mr.appointment_id
  join public.specialties sp on sp.id = a.specialty_id
  join public.doctors d on d.id = mr.doctor_id
  join public.profiles dp on dp.id = d.profile_id
  where mr.patient_id = auth.uid()
  order by a.starts_at desc;
$$;

revoke execute on all functions in schema private from public, anon, authenticated;
revoke execute on function public.get_doctor_agenda(date) from anon, public;
revoke execute on function public.get_consultation(bigint) from anon, public;
revoke execute on function public.start_consultation(bigint) from anon, public;
revoke execute on function public.complete_consultation(bigint, text, text, text, text) from anon, public;
revoke execute on function public.get_patient_history(bigint) from anon, public;
revoke execute on function public.get_my_medical_records() from anon, public;
grant execute on function public.get_doctor_agenda(date) to authenticated;
grant execute on function public.get_consultation(bigint) to authenticated;
grant execute on function public.start_consultation(bigint) to authenticated;
grant execute on function public.complete_consultation(bigint, text, text, text, text) to authenticated;
grant execute on function public.get_patient_history(bigint) to authenticated;
grant execute on function public.get_my_medical_records() to authenticated;
