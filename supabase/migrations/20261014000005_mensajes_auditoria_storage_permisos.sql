-- =============================================================================
-- Spec 005 · Migración 005: mensajes, registro de accesos, buckets privados y permisos
-- =============================================================================

create table public.messages (
  id           uuid primary key default gen_random_uuid(),
  patient_id   uuid not null references public.patients (id) on delete restrict,
  channel      text not null check (channel in ('whatsapp', 'portal')),
  direction    text not null check (direction in ('in', 'out')),   -- in = del paciente
  body         text not null check (char_length(body) <= 4000),
  external_id  text unique,                                         -- id de Zernio
  created_at   timestamptz not null default now()
);

-- Accesos a datos clínicos desde el panel (CA-16). Solo inserción.
create table public.audit_log (
  id          bigint generated always as identity primary key,
  actor       uuid not null default auth.uid() references public.profiles (id) on delete restrict,
  action      text not null check (action in ('ver_ficha', 'abrir_adjunto', 'exportar', 'restaurar')),
  patient_id  uuid references public.patients (id) on delete restrict,
  detail      text,
  created_at  timestamptz not null default now()
);

alter table public.messages enable row level security;
alter table public.audit_log enable row level security;

-- Mensajes: la fisio ve todos; el paciente solo los del portal (WhatsApp entra por webhook).
create policy "messages: la fisio gestiona"
  on public.messages for all to authenticated
  using ((select public.is_fisio())) with check ((select public.is_fisio()));

create policy "messages: el paciente lee los del portal"
  on public.messages for select to authenticated
  using (channel = 'portal' and patient_id = (select public.current_patient_id()));

create policy "messages: el paciente escribe en el portal"
  on public.messages for insert to authenticated
  with check (channel = 'portal' and direction = 'in' and external_id is null
              and patient_id = (select public.current_patient_id()));

create policy "audit_log: la fisio registra sus accesos"
  on public.audit_log for insert to authenticated
  with check ((select public.is_fisio()) and actor = (select auth.uid()));

create policy "audit_log: la fisio consulta"
  on public.audit_log for select to authenticated
  using ((select public.is_fisio()));

-- ------------------------------------------------------- Almacenamiento privado (CA-12)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('attachments', 'attachments', false, 20971520,
   array['application/pdf', 'image/jpeg', 'image/png', 'image/heic', 'image/webp']),
  ('personal-voices', 'personal-voices', false, 26214400,
   array['audio/mpeg', 'audio/mp4', 'audio/x-m4a', 'audio/aac', 'audio/wav'])
on conflict (id) do nothing;

-- Rutas: <patient_id>/<fichero>. El paciente solo toca su carpeta; la fisio, todas.
create policy "attachments: lectura propia o de la fisio"
  on storage.objects for select to authenticated
  using (bucket_id = 'attachments'
         and ((select public.is_fisio())
              or (storage.foldername(name))[1] = (select public.current_patient_id())::text));

create policy "attachments: el paciente sube a su carpeta"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'attachments'
              and (storage.foldername(name))[1] = (select public.current_patient_id())::text);

create policy "personal-voices: la fisio gestiona"
  on storage.objects for all to authenticated
  using (bucket_id = 'personal-voices' and (select public.is_fisio()))
  with check (bucket_id = 'personal-voices' and (select public.is_fisio()));

create policy "personal-voices: el paciente escucha las suyas"
  on storage.objects for select to authenticated
  using (bucket_id = 'personal-voices'
         and (storage.foldername(name))[1] = (select public.current_patient_id())::text);

-- ---------------------------------------------------------------- Permisos de tabla
-- Supabase concede por defecto TODOS los privilegios (incluido TRUNCATE) a anon y
-- authenticated, y RLS no protege contra TRUNCATE. Se retiran los que no hacen falta.
revoke truncate, references, trigger on all tables in schema public from anon, authenticated;
alter default privileges in schema public revoke truncate, references, trigger on tables from anon, authenticated;

-- Defensa en profundidad: anon no toca ninguna tabla salvo la disponibilidad.
revoke all on all tables in schema public from anon;
alter default privileges in schema public revoke all on tables from anon;
grant select on public.availability to anon;

-- Tablas de solo inserción: nadie desde el cliente puede modificarlas ni borrarlas.
revoke update, delete on public.consents, public.audit_log from authenticated;
-- Los pagos solo los escribe el servidor.
revoke insert, update, delete on public.payments from authenticated;
-- Historia clínica: nadie la borra desde el cliente, ni siquiera la fisio (Ley 41/2002).
-- Las correcciones se hacen con nuevas versiones o baja lógica (patients.deleted_at).
revoke delete on public.patients, public.questionnaires, public.attachments,
  public.consult_notes, public.consult_notes_private, public.routines, public.routine_items,
  public.session_feedback, public.messages, public.appointments, public.payment_links
  from authenticated;

-- Las funciones auxiliares se ejecutan por defecto desde PUBLIC: solo para usuarios autenticados.
revoke execute on function public.is_fisio(), public.current_patient_id(),
  public.in_my_active_routine(uuid, uuid) from public, anon;
grant execute on function public.is_fisio(), public.current_patient_id(),
  public.in_my_active_routine(uuid, uuid) to authenticated, service_role;
