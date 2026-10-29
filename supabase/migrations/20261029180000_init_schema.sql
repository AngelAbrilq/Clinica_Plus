-- =============================================================
-- Clinica Plus · Migración 001: esquema base, auth, RLS y auditoría
-- Motor: PostgreSQL (Supabase)
-- =============================================================

-- -------------------------------------------------------------
-- 0. Extensiones y tipos
-- -------------------------------------------------------------
create extension if not exists btree_gist with schema extensions;

create type public.user_role as enum ('patient', 'doctor', 'receptionist', 'admin');

create type public.appointment_status as enum (
  'requested', 'assigned', 'confirmed', 'checked_in',
  'in_progress', 'completed', 'cancelled', 'no_show'
);

create type public.document_type as enum ('CC', 'TI', 'CE', 'PA', 'RC');

-- Mantiene updated_at en cada UPDATE
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- -------------------------------------------------------------
-- 1. Tablas
-- -------------------------------------------------------------
create table public.app_settings (
  key        text primary key,
  value      text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.sites (
  id         bigint generated always as identity primary key,
  name       text not null unique,
  address    text not null,
  phone      text,
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.specialties (
  id           bigint generated always as identity primary key,
  name         text not null unique,
  description  text,
  slot_minutes smallint not null default 20 check (slot_minutes between 10 and 120),
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- role NULL = cuenta de personal pendiente de aprobación por el admin
create table public.profiles (
  id                    uuid primary key references auth.users (id) on delete cascade,
  email                 text not null unique,
  role                  public.user_role,
  full_name             text not null default '',
  document_type         public.document_type,
  document_number       text check (document_number ~ '^[0-9A-Za-z]{4,20}$'),
  phone                 text check (phone ~ '^\+?[0-9]{7,15}$'),
  birth_date            date check (birth_date <= current_date),
  no_show_count         smallint not null default 0,
  booking_blocked_until timestamptz,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  constraint profiles_document_unique unique (document_type, document_number)
);

create table public.doctors (
  id             bigint generated always as identity primary key,
  profile_id     uuid not null unique references public.profiles (id) on delete cascade,
  specialty_id   bigint not null references public.specialties (id),
  license_number text not null unique,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- weekday ISO: 1 = lunes … 7 = domingo
create table public.doctor_schedules (
  id         bigint generated always as identity primary key,
  doctor_id  bigint not null references public.doctors (id) on delete cascade,
  site_id    bigint not null references public.sites (id),
  weekday    smallint not null check (weekday between 1 and 7),
  start_time time not null,
  end_time   time not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint doctor_schedules_time_check check (end_time > start_time)
);

create table public.appointments (
  id                 bigint generated always as identity primary key,
  patient_id         uuid not null references public.profiles (id),
  doctor_id          bigint references public.doctors (id),
  specialty_id       bigint not null references public.specialties (id),
  site_id            bigint not null references public.sites (id),
  starts_at          timestamptz,
  ends_at            timestamptz,
  status             public.appointment_status not null default 'requested',
  symptoms           text check (char_length(symptoms) <= 2000),
  ai_suggested       boolean not null default false,
  cancel_reason      text check (char_length(cancel_reason) <= 500),
  confirmation_token uuid not null default gen_random_uuid() unique,
  checked_in_at      timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  constraint appointments_time_check
    check (ends_at is null or ends_at > starts_at),
  constraint appointments_assignment_check
    check (status in ('requested', 'cancelled')
           or (doctor_id is not null and starts_at is not null and ends_at is not null)),
  -- Un médico nunca tiene dos citas activas solapadas
  constraint appointments_no_overlap exclude using gist (
    doctor_id with =,
    tstzrange(starts_at, ends_at) with &&
  ) where (status in ('assigned', 'confirmed', 'checked_in', 'in_progress'))
);

create table public.medical_records (
  id                    bigint generated always as identity primary key,
  appointment_id        bigint not null unique references public.appointments (id),
  patient_id            uuid not null references public.profiles (id),
  doctor_id             bigint not null references public.doctors (id),
  reason                text not null check (char_length(reason) <= 1000),
  clinical_notes        text check (char_length(clinical_notes) <= 10000),
  diagnosis_code        text check (diagnosis_code ~ '^[A-Z][0-9]{2}(\.?[0-9A-Z]{1,4})?$'),
  diagnosis_description text,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create table public.audit_logs (
  id         bigint generated always as identity primary key,
  actor_id   uuid references auth.users (id) on delete set null,
  action     text not null,
  table_name text not null,
  record_id  text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- -------------------------------------------------------------
-- 2. Índices (FKs + columnas de búsqueda frecuente)
-- -------------------------------------------------------------
create index profiles_role_idx                  on public.profiles (role);
create index doctors_specialty_id_idx           on public.doctors (specialty_id);
create index doctor_schedules_doctor_id_idx     on public.doctor_schedules (doctor_id);
create index doctor_schedules_site_id_idx       on public.doctor_schedules (site_id);
create index appointments_patient_id_idx        on public.appointments (patient_id);
create index appointments_doctor_starts_idx     on public.appointments (doctor_id, starts_at);
create index appointments_specialty_id_idx      on public.appointments (specialty_id);
create index appointments_site_starts_idx       on public.appointments (site_id, starts_at);
create index appointments_status_idx            on public.appointments (status);
create index medical_records_patient_id_idx     on public.medical_records (patient_id);
create index medical_records_doctor_id_idx      on public.medical_records (doctor_id);
create index audit_logs_actor_id_idx            on public.audit_logs (actor_id);
create index audit_logs_table_record_idx        on public.audit_logs (table_name, record_id);

-- -------------------------------------------------------------
-- 3. Triggers updated_at
-- -------------------------------------------------------------
create trigger set_updated_at before update on public.app_settings     for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.sites            for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.specialties      for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.profiles         for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.doctors          for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.doctor_schedules for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.appointments     for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.medical_records  for each row execute function public.set_updated_at();

-- -------------------------------------------------------------
-- 4. Funciones de seguridad (usadas por RLS)
-- -------------------------------------------------------------
create or replace function public.get_my_role()
returns public.user_role
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.get_my_doctor_id()
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select id from public.doctors where profile_id = auth.uid();
$$;

-- Crea el perfil al registrarse.
-- · app_metadata.role (solo lo asigna el service role) → ese rol
-- · correo del dominio de la clínica sin rol            → NULL (pendiente)
-- · cualquier otro correo                               → patient
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_meta         jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_staff_domain text;
  v_role         public.user_role;
begin
  select value into v_staff_domain
  from public.app_settings
  where key = 'staff_email_domain';

  if new.raw_app_meta_data ? 'role' then
    v_role := (new.raw_app_meta_data ->> 'role')::public.user_role;
  elsif v_staff_domain is not null
        and lower(split_part(new.email, '@', 2)) = lower(v_staff_domain) then
    v_role := null;
  else
    v_role := 'patient';
  end if;

  insert into public.profiles (id, email, role, full_name, document_type, document_number, phone)
  values (
    new.id,
    new.email,
    v_role,
    coalesce(v_meta ->> 'full_name', ''),
    nullif(v_meta ->> 'document_type', '')::public.document_type,
    nullif(v_meta ->> 'document_number', ''),
    nullif(v_meta ->> 'phone', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Solo un admin cambia roles (los usuarios no pueden auto-asignarse uno)
create or replace function public.admin_set_user_role(p_user_id uuid, p_role public.user_role)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'Solo un administrador puede asignar roles' using errcode = '42501';
  end if;
  update public.profiles set role = p_role where id = p_user_id;
  if not found then
    raise exception 'Usuario % no existe', p_user_id using errcode = 'P0002';
  end if;
end;
$$;

-- Auditoría de historia clínica
create or replace function public.log_medical_record_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.audit_logs (actor_id, action, table_name, record_id)
  values (auth.uid(), tg_op, tg_table_name, coalesce(new.id, old.id)::text);
  return coalesce(new, old);
end;
$$;

create trigger audit_medical_records
  after insert or update or delete on public.medical_records
  for each row execute function public.log_medical_record_change();

-- -------------------------------------------------------------
-- 5. Permisos de columnas en profiles
--    (el usuario edita sus datos, nunca role / no_show / bloqueo)
-- -------------------------------------------------------------
revoke update on public.profiles from authenticated, anon;
grant update (full_name, document_type, document_number, phone, birth_date)
  on public.profiles to authenticated;

revoke execute on function public.admin_set_user_role(uuid, public.user_role) from anon, public;
grant execute on function public.admin_set_user_role(uuid, public.user_role) to authenticated;

-- -------------------------------------------------------------
-- 6. Row Level Security
-- -------------------------------------------------------------
alter table public.app_settings     enable row level security;
alter table public.sites            enable row level security;
alter table public.specialties      enable row level security;
alter table public.profiles         enable row level security;
alter table public.doctors          enable row level security;
alter table public.doctor_schedules enable row level security;
alter table public.appointments     enable row level security;
alter table public.medical_records  enable row level security;
alter table public.audit_logs       enable row level security;

-- app_settings: lectura autenticada, escritura solo vía SQL/admin
create policy app_settings_select on public.app_settings
  for select to authenticated using (true);

-- Catálogos: todos leen, admin escribe
create policy sites_select on public.sites
  for select to anon, authenticated using (true);
create policy sites_admin_write on public.sites
  for all to authenticated
  using ((select public.get_my_role()) = 'admin')
  with check ((select public.get_my_role()) = 'admin');

create policy specialties_select on public.specialties
  for select to anon, authenticated using (true);
create policy specialties_admin_write on public.specialties
  for all to authenticated
  using ((select public.get_my_role()) = 'admin')
  with check ((select public.get_my_role()) = 'admin');

-- profiles: cada quien ve el suyo; el personal ve todos
create policy profiles_select on public.profiles
  for select to authenticated
  using (
    id = (select auth.uid())
    or (select public.get_my_role()) in ('doctor', 'receptionist', 'admin')
  );
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- doctors / doctor_schedules: lectura autenticada, admin escribe
create policy doctors_select on public.doctors
  for select to authenticated using (true);
create policy doctors_admin_write on public.doctors
  for all to authenticated
  using ((select public.get_my_role()) = 'admin')
  with check ((select public.get_my_role()) = 'admin');

create policy doctor_schedules_select on public.doctor_schedules
  for select to authenticated using (true);
create policy doctor_schedules_admin_write on public.doctor_schedules
  for all to authenticated
  using ((select public.get_my_role()) = 'admin')
  with check ((select public.get_my_role()) = 'admin');

-- appointments
create policy appointments_select on public.appointments
  for select to authenticated
  using (
    patient_id = (select auth.uid())
    or doctor_id = (select public.get_my_doctor_id())
    or (select public.get_my_role()) in ('receptionist', 'admin')
  );
create policy appointments_insert on public.appointments
  for insert to authenticated
  with check (
    (patient_id = (select auth.uid())
       and status = 'requested'
       and (select public.get_my_role()) = 'patient')
    or (select public.get_my_role()) in ('receptionist', 'admin')
  );
create policy appointments_update on public.appointments
  for update to authenticated
  using (
    doctor_id = (select public.get_my_doctor_id())
    or (select public.get_my_role()) in ('receptionist', 'admin')
  )
  with check (
    doctor_id = (select public.get_my_doctor_id())
    or (select public.get_my_role()) in ('receptionist', 'admin')
  );

-- medical_records: paciente lee lo suyo, médico tratante gestiona, admin lee.
-- Recepción NO tiene acceso (privacidad clínica).
create policy medical_records_select on public.medical_records
  for select to authenticated
  using (
    patient_id = (select auth.uid())
    or doctor_id = (select public.get_my_doctor_id())
    or (select public.get_my_role()) = 'admin'
  );
create policy medical_records_insert on public.medical_records
  for insert to authenticated
  with check (doctor_id = (select public.get_my_doctor_id()));
create policy medical_records_update on public.medical_records
  for update to authenticated
  using (doctor_id = (select public.get_my_doctor_id()))
  with check (doctor_id = (select public.get_my_doctor_id()));

-- audit_logs: solo admin lee; se escribe únicamente vía trigger
create policy audit_logs_admin_select on public.audit_logs
  for select to authenticated
  using ((select public.get_my_role()) = 'admin');
