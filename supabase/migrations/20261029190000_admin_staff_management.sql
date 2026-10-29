-- =============================================================
-- Clinica Plus · Migración 003: gestión de personal por el admin
-- · RPC atómica para registrar médicos (rol + ficha en una transacción)
-- · Al quitar el rol de médico, su ficha queda inactiva
-- · Un médico no puede tener horarios cruzados el mismo día
-- =============================================================

-- Horarios sin cruces: mismo médico + mismo día + rangos que se solapan
alter table public.doctor_schedules
  add constraint doctor_schedules_no_overlap exclude using gist (
    doctor_id with =,
    weekday with =,
    tsrange('2000-01-01'::date + start_time, '2000-01-01'::date + end_time) with &&
  );

-- Reemplaza la versión de la migración 001: ahora desactiva la ficha
-- de médico si el usuario deja de serlo.
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
  if p_user_id = auth.uid() and p_role is distinct from 'admin' then
    raise exception 'No puedes quitarte tu propio rol de administrador' using errcode = '42501';
  end if;

  update public.profiles set role = p_role where id = p_user_id;
  if not found then
    raise exception 'Usuario % no existe', p_user_id using errcode = 'P0002';
  end if;

  if p_role is distinct from 'doctor' then
    update public.doctors set is_active = false where profile_id = p_user_id;
  end if;
end;
$$;

-- Registra (o actualiza) un médico de forma atómica.
-- Devuelve el id de la ficha en public.doctors.
create or replace function public.admin_register_doctor(
  p_user_id        uuid,
  p_specialty_id   bigint,
  p_license_number text
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_doctor_id bigint;
  v_license   text := upper(trim(p_license_number));
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'Solo un administrador puede registrar médicos' using errcode = '42501';
  end if;
  if v_license is null or v_license !~ '^[A-Z0-9-]{3,30}$' then
    raise exception 'Registro médico inválido' using errcode = '22023';
  end if;
  if not exists (select 1 from public.specialties where id = p_specialty_id and is_active) then
    raise exception 'Especialidad no válida' using errcode = '22023';
  end if;

  update public.profiles set role = 'doctor' where id = p_user_id;
  if not found then
    raise exception 'Usuario % no existe', p_user_id using errcode = 'P0002';
  end if;

  insert into public.doctors (profile_id, specialty_id, license_number, is_active)
  values (p_user_id, p_specialty_id, v_license, true)
  on conflict (profile_id) do update
    set specialty_id   = excluded.specialty_id,
        license_number = excluded.license_number,
        is_active      = true
  returning id into v_doctor_id;

  return v_doctor_id;
end;
$$;

revoke execute on function public.admin_register_doctor(uuid, bigint, text) from anon, public;
grant execute on function public.admin_register_doctor(uuid, bigint, text) to authenticated;
