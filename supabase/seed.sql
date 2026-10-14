-- =============================================================================
-- Datos de prueba FICTICIOS (spec 005 · CA-18). Nunca datos reales de pacientes.
-- Contraseña de todos los usuarios de prueba: demo-adela-2026
-- =============================================================================

insert into auth.users (instance_id, id, aud, role, email, encrypted_password, confirmed_at, raw_user_meta_data, raw_app_meta_data, created_at, updated_at)
values
  ('00000000-0000-0000-0000-000000000000', 'a0000000-0000-4000-8000-00000000ade1', 'authenticated', 'authenticated',
   'adela.demo@example.com', extensions.crypt('demo-adela-2026', extensions.gen_salt('bf')), now(),
   '{"full_name":"Adela (demo)"}', '{"provider":"email","providers":["email"]}', now(), now()),
  ('00000000-0000-0000-0000-000000000000', 'b0000000-0000-4000-8000-0000000000a1', 'authenticated', 'authenticated',
   'javier.garcia@example.com', extensions.crypt('demo-adela-2026', extensions.gen_salt('bf')), now(),
   '{"full_name":"Javier García","phone":"612 34 56 78"}', '{"provider":"email","providers":["email"]}', now(), now()),
  ('00000000-0000-0000-0000-000000000000', 'b0000000-0000-4000-8000-0000000000a2', 'authenticated', 'authenticated',
   'carmen.ortiz@example.com', extensions.crypt('demo-adela-2026', extensions.gen_salt('bf')), now(),
   '{"full_name":"Carmen Ortiz","phone":"611 22 33 44"}', '{"provider":"email","providers":["email"]}', now(), now());

-- El trigger crea los perfiles como paciente; Adela pasa a fisio (solo posible como administrador).
update public.profiles set role = 'fisio' where id = 'a0000000-0000-4000-8000-00000000ade1';

insert into public.patients (id, profile_id, problem_type, body_zone, diagnosis, status, plan) values
  ('c0000000-0000-4000-8000-0000000000a1', 'b0000000-0000-4000-8000-0000000000a1', 'dolor', 'Zona lumbar', 'Lumbociatalgia L5-S1', 'activo', 'premium'),
  ('c0000000-0000-4000-8000-0000000000a2', 'b0000000-0000-4000-8000-0000000000a2', 'deportiva', 'Hombro', 'Tendinopatía del supraespinoso', 'activo', 'premium');

insert into public.questionnaires (patient_id, answers, comments) values
  ('c0000000-0000-4000-8000-0000000000a1', '{"sensacion":"Opresivo / sordo","desde":"1 a 4 semanas","objetivo":"Trabajar sentado sin dolor"}', 'Empezó al mudarme de casa.'),
  ('c0000000-0000-4000-8000-0000000000a2', '{"objetivo":"Volver a nadar"}', null);

insert into public.library_videos (id, title, tags, duration_seconds, object_key) values
  ('d0000000-0000-4000-8000-000000000001', 'Puente glúteo (elevación pélvica)', '{Lumbar,Glúteo}', 135, 'videos/puente-gluteo.mp4'),
  ('d0000000-0000-4000-8000-000000000002', 'Respiración diafragmática', '{Lumbar,"Suelo pélvico"}', 100, 'videos/respiracion-diafragmatica.mp4'),
  ('d0000000-0000-4000-8000-000000000003', 'Rotación externa con banda elástica', '{Hombro}', 125, 'videos/rotacion-externa-banda.mp4');

insert into public.library_voices (id, title, tags, scope, patient_id, storage, object_key) values
  ('e0000000-0000-4000-8000-000000000001', 'Puente glúteo · explicación general', '{Lumbar}', 'generic', null, 'r2', 'voces/puente-gluteo.mp3'),
  ('e0000000-0000-4000-8000-000000000002', 'Para Javier · puente sin arquear la dorsal', '{Lumbar}', 'personal',
   'c0000000-0000-4000-8000-0000000000a1', 'supabase', 'c0000000-0000-4000-8000-0000000000a1/puente-dorsal.mp3');

insert into public.routines (id, patient_id, title, created_by) values
  ('f0000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-0000000000a1', 'Rehabilitación lumbar · Semana 2', 'a0000000-0000-4000-8000-00000000ade1');

insert into public.routine_items (routine_id, position, video_id, voice_id, series, reps, frequency, duration, note) values
  ('f0000000-0000-4000-8000-000000000001', 1, 'd0000000-0000-4000-8000-000000000002', null, 2, '10 respiraciones', 'Diaria', '2 semanas', 'Suelta el aire despacio.'),
  ('f0000000-0000-4000-8000-000000000001', 2, 'd0000000-0000-4000-8000-000000000001', 'e0000000-0000-4000-8000-000000000002', 3, '12', '5 días/semana', '2 semanas', 'Pausa de 2 segundos arriba.');
