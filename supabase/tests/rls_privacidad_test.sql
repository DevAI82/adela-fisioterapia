-- =============================================================================
-- Spec 005 · CA-17: tests de privacidad (RLS y permisos). Datos 100 % ficticios.
-- Se ejecutan con `supabase test db` (CI) o con scripts/db/test-local.sh.
-- =============================================================================
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(36);

-- ------------------------------------------------------------------ Escenario
-- Fisio F, paciente A, paciente B (creados como administrador).
insert into auth.users (instance_id, id, aud, role, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-000000000000', '11111111-1111-4111-8111-111111111111', 'authenticated', 'authenticated', 'fisio.test@example.com', '{"full_name":"Fisio Test"}'),
  ('00000000-0000-0000-0000-000000000000', '22222222-2222-4222-8222-222222222222', 'authenticated', 'authenticated', 'paciente.a@example.com', '{"full_name":"Paciente A"}'),
  ('00000000-0000-0000-0000-000000000000', '33333333-3333-4333-8333-333333333333', 'authenticated', 'authenticated', 'paciente.b@example.com', '{"full_name":"Paciente B"}');
update public.profiles set role = 'fisio' where id = '11111111-1111-4111-8111-111111111111';

insert into public.patients (id, profile_id, problem_type, status) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', '22222222-2222-4222-8222-222222222222', 'dolor', 'activo'),
  ('bbbbbbbb-0000-4000-8000-00000000000b', '33333333-3333-4333-8333-333333333333', 'linfedema', 'activo');

insert into public.questionnaires (patient_id, answers) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', '{"objetivo":"A"}'),
  ('bbbbbbbb-0000-4000-8000-00000000000b', '{"objetivo":"B"}');

insert into public.consult_notes (id, patient_id, kind, patient_summary, created_by) values
  ('aaaaaaaa-1111-4000-8000-00000000000a', 'aaaaaaaa-0000-4000-8000-00000000000a', 'primera', 'Resumen para A', '11111111-1111-4111-8111-111111111111');
insert into public.consult_notes_private (consult_note_id, private_notes) values
  ('aaaaaaaa-1111-4000-8000-00000000000a', 'Nota privada sobre A');

insert into public.library_videos (id, title, object_key) values
  ('dddddddd-0000-4000-8000-000000000001', 'Vídeo en la rutina de A', 'test/v1.mp4'),
  ('dddddddd-0000-4000-8000-000000000002', 'Vídeo fuera de su rutina', 'test/v2.mp4');
insert into public.routines (id, patient_id, title, created_by) values
  ('ffffffff-0000-4000-8000-00000000000a', 'aaaaaaaa-0000-4000-8000-00000000000a', 'Rutina A', '11111111-1111-4111-8111-111111111111');
insert into public.routine_items (routine_id, position, video_id, series, reps, frequency, duration) values
  ('ffffffff-0000-4000-8000-00000000000a', 1, 'dddddddd-0000-4000-8000-000000000001', 3, '12', 'Diaria', '2 semanas');

insert into public.payments (id, patient_id, product, amount_cents, method, status) values
  ('99999999-0000-4000-8000-00000000000a', 'aaaaaaaa-0000-4000-8000-00000000000a', 'primera', 2250, 'bizum', 'pagado');
insert into public.appointments (patient_id, kind, starts_at, duration_min, payment_id) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', 'primera', '2026-10-20 16:00+02', 25, '99999999-0000-4000-8000-00000000000a');

insert into public.messages (patient_id, channel, direction, body) values
  ('aaaaaaaa-0000-4000-8000-00000000000a', 'portal', 'in', 'Mensaje de A en el portal'),
  ('aaaaaaaa-0000-4000-8000-00000000000a', 'whatsapp', 'in', 'WhatsApp de A');

insert into storage.objects (bucket_id, name) values
  ('attachments', 'aaaaaaaa-0000-4000-8000-00000000000a/resonancia.pdf'),
  ('attachments', 'bbbbbbbb-0000-4000-8000-00000000000b/informe.pdf');

-- Cambiar de usuario dentro de la transacción (compatible con ambas formas de leer el JWT).
create function pg_temp.login(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end $$;

-- ================================================================ Paciente A
select pg_temp.login('22222222-2222-4222-8222-222222222222');

select is((select count(*) from public.patients)::int, 1, 'A solo ve su propia ficha');
select is((select count(*) from public.questionnaires)::int, 1, 'A solo ve su cuestionario');
select is((select count(*) from public.consult_notes)::int, 1, 'A ve el resumen de su consulta');
select is((select count(*) from public.consult_notes_private)::int, 0, 'A NO ve las notas privadas');
select throws_ok(
  $$ insert into public.consult_notes_private (consult_note_id, private_notes) values ('aaaaaaaa-1111-4000-8000-00000000000a', 'x') $$,
  '42501', null, 'A no puede escribir notas privadas');
select is((select count(*) from public.library_videos)::int, 1, 'A solo ve los vídeos de su rutina activa');
select is((select count(*) from public.routine_items)::int, 1, 'A ve los ejercicios de su rutina');
select lives_ok(
  $$ insert into public.session_feedback (patient_id, routine_id, exercises_done, exercises_total, stiffness, pain, stability, comment)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', 'ffffffff-0000-4000-8000-00000000000a', 1, 1, 'ligera', 3, 'media', 'Bien') $$,
  'A envía el mini cuestionario de su sesión');
select throws_ok(
  $$ insert into public.session_feedback (patient_id, routine_id, exercises_done, exercises_total, stiffness, pain, stability, fisio_reply)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', 'ffffffff-0000-4000-8000-00000000000a', 1, 1, 'ligera', 3, 'media', 'Me respondo yo') $$,
  '42501', null, 'A no puede escribir la respuesta de la fisio');
select throws_ok(
  $$ insert into public.session_feedback (patient_id, routine_id, exercises_done, exercises_total, stiffness, pain, stability)
     values ('bbbbbbbb-0000-4000-8000-00000000000b', 'ffffffff-0000-4000-8000-00000000000a', 1, 1, 'ligera', 3, 'media') $$,
  '42501', null, 'A no puede registrar sesiones en nombre de B');
select throws_ok(
  $$ insert into public.payments (patient_id, product, amount_cents, method, status)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', 'premium', 1, 'card', 'pagado') $$,
  '42501', null, 'A no puede crear pagos (solo el servidor)');
select throws_ok(
  $$ update public.profiles set role = 'fisio' where id = '22222222-2222-4222-8222-222222222222' $$,
  '42501', null, 'A no puede hacerse fisio');
select lives_ok(
  $$ update public.profiles set full_name = 'Paciente A (editado)' where id = '22222222-2222-4222-8222-222222222222' $$,
  'A puede editar su nombre');
select is((select count(*) from public.messages)::int, 1, 'A solo ve sus mensajes del portal, no los WhatsApp');
select is((select count(*) from storage.objects where bucket_id = 'attachments')::int, 1, 'A solo ve sus informes adjuntos');
select throws_ok(
  $$ insert into storage.objects (bucket_id, name) values ('attachments', 'bbbbbbbb-0000-4000-8000-00000000000b/intruso.pdf') $$,
  '42501', null, 'A no puede subir ficheros a la carpeta de B');
select throws_ok($$ truncate public.questionnaires $$, '42501', null, 'A no puede vaciar tablas con TRUNCATE');
select throws_ok($$ delete from public.questionnaires $$, '42501', null, 'A no puede borrar historia clínica');
select is((select count(*) from public.audit_log)::int, 0, 'A no ve el registro de accesos');
select throws_ok(
  $$ insert into public.audit_log (action) values ('ver_ficha') $$,
  '42501', null, 'A no puede escribir en el registro de accesos');

-- ================================================================ Paciente B
reset role;
select pg_temp.login('33333333-3333-4333-8333-333333333333');

select is((select count(*) from public.questionnaires where patient_id = 'aaaaaaaa-0000-4000-8000-00000000000a')::int, 0, 'B no ve el cuestionario de A');
select is((select count(*) from public.consult_notes)::int, 0, 'B no ve las consultas de A');
select is((select count(*) from public.appointments)::int, 0, 'B no ve las citas de A');
select is((select count(*) from public.payments)::int, 0, 'B no ve los pagos de A');
select is((select count(*) from public.library_videos)::int, 0, 'B sin rutina no ve vídeos de la biblioteca');

-- ================================================================ Anónimo
reset role;
select set_config('request.jwt.claim.sub', '', true);
set local role anon;
select throws_ok($$ select count(*) from public.patients $$, '42501', null, 'Un anónimo no puede leer pacientes');
select throws_ok($$ select count(*) from public.questionnaires $$, '42501', null, 'Un anónimo no puede leer cuestionarios');
select is((select count(*) from public.availability)::int, 2, 'Un anónimo ve la disponibilidad (martes y jueves)');

-- ================================================================ Fisio
reset role;
select pg_temp.login('11111111-1111-4111-8111-111111111111');

select is((select count(*) from public.patients where id in ('aaaaaaaa-0000-4000-8000-00000000000a', 'bbbbbbbb-0000-4000-8000-00000000000b'))::int, 2, 'La fisio ve a todos los pacientes');
select is((select count(*) from public.consult_notes_private)::int, 1, 'La fisio ve sus notas privadas');
select lives_ok(
  $$ update public.session_feedback set fisio_reply = 'Muy bien', replied_at = now()
     where patient_id = 'aaaaaaaa-0000-4000-8000-00000000000a' $$,
  'La fisio responde al mini cuestionario');
select lives_ok($$ insert into public.audit_log (action, patient_id) values ('ver_ficha', 'aaaaaaaa-0000-4000-8000-00000000000a') $$,
  'La fisio registra un acceso a una ficha');
select throws_ok($$ delete from public.consult_notes $$, '42501', null, 'Ni la fisio puede borrar historia clínica');

-- ================================================================ Reglas de negocio
reset role;
select throws_ok(
  $$ insert into public.appointments (patient_id, kind, starts_at, duration_min, payment_id)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', 'primera', '2026-10-20 16:30+02', 25, '99999999-0000-4000-8000-00000000000a') $$,
  '23P01', null, 'No se pueden solapar citas: 16:00 + 25 min + 15 de descanso bloquea hasta las 16:40');
select throws_ok(
  $$ insert into public.payments (patient_id, product, amount_cents, method, status)
     values ('aaaaaaaa-0000-4000-8000-00000000000a', 'rutinas', 5900, 'bizum', 'pagado') $$,
  '23514', null, 'Bizum no se admite en suscripciones');
select throws_ok(
  $$ delete from public.patients where id = 'aaaaaaaa-0000-4000-8000-00000000000a' $$,
  '23503', null, 'No se borra un paciente con historia clínica (sin cascada)');

select * from finish();
rollback;
