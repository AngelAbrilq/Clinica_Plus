-- =============================================================
-- Clinica Plus · Migración 002: datos de referencia (catálogos)
-- Va como migración (no seed.sql) para que también llegue a producción.
-- =============================================================
insert into public.app_settings (key, value) values
  ('staff_email_domain', 'clinicaplus.co')
on conflict (key) do nothing;

insert into public.sites (name, address) values
  ('Sede Principal', 'Dirección por definir'),
  ('Sede Norte',     'Dirección por definir')
on conflict (name) do nothing;

insert into public.specialties (name, description, slot_minutes) values
  ('Medicina General', 'Consulta de primer nivel y orientación inicial', 20),
  ('Pediatría',        'Atención de niños y adolescentes',               30),
  ('Ginecología',      'Salud de la mujer',                              30),
  ('Medicina Interna', 'Enfermedades complejas del adulto',              30),
  ('Odontología',      'Salud oral',                                     30),
  ('Psicología',       'Salud mental y emocional',                       45)
on conflict (name) do nothing;
