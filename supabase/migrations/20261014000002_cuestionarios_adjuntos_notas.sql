-- =============================================================================
-- Spec 005 · Migración 002: cuestionario clínico, adjuntos médicos y notas de consulta
-- Las notas se dividen en dos tablas (D-014): el resumen que ve el paciente y las
-- notas privadas, que solo ve la fisio.
-- =============================================================================

create table public.questionnaires (
  id          uuid primary key default gen_random_uuid(),
  patient_id  uuid not null references public.patients (id) on delete restrict,
  answers     jsonb not null,
  comments    text check (char_length(comments) <= 5000),
  created_at  timestamptz not null default now()
);

-- Metadatos de informes médicos; el fichero vive en el bucket privado `attachments`
-- con la ruta <patient_id>/<nombre>.
create table public.attachments (
  id            uuid primary key default gen_random_uuid(),
  patient_id    uuid not null references public.patients (id) on delete restrict,
  storage_path  text not null unique,
  file_name     text not null,
  mime_type     text not null check (mime_type in ('application/pdf', 'image/jpeg', 'image/png', 'image/heic', 'image/webp')),
  size_bytes    integer not null check (size_bytes between 1 and 20971520),
  created_at    timestamptz not null default now(),
  constraint attachments_path_in_patient_folder check (storage_path like patient_id::text || '/%')
);

-- Resumen de la consulta: lo ve el paciente en su portal.
create table public.consult_notes (
  id               uuid primary key default gen_random_uuid(),
  patient_id       uuid not null references public.patients (id) on delete restrict,
  kind             text not null check (kind in ('primera', 'sesion', 'revision_escrita')),
  patient_summary  text not null check (char_length(patient_summary) <= 5000),
  consulted_on     date not null default current_date,
  created_by       uuid not null default auth.uid() references public.profiles (id) on delete restrict,
  created_at       timestamptz not null default now()
);

-- Notas clínicas privadas: SOLO la fisio (CA-2, CA-9).
create table public.consult_notes_private (
  consult_note_id  uuid primary key references public.consult_notes (id) on delete restrict,
  private_notes    text not null check (char_length(private_notes) <= 20000),
  updated_at       timestamptz not null default now()
);

alter table public.questionnaires enable row level security;
alter table public.attachments enable row level security;
alter table public.consult_notes enable row level security;
alter table public.consult_notes_private enable row level security;

-- Cuestionarios: el paciente envía y lee los suyos; la fisio lee todos.
create policy "questionnaires: lectura propia o de la fisio"
  on public.questionnaires for select to authenticated
  using (patient_id = (select public.current_patient_id()) or (select public.is_fisio()));

create policy "questionnaires: el paciente envía el suyo"
  on public.questionnaires for insert to authenticated
  with check (patient_id = (select public.current_patient_id()));

-- Adjuntos: igual que los cuestionarios.
create policy "attachments: lectura propia o de la fisio"
  on public.attachments for select to authenticated
  using (patient_id = (select public.current_patient_id()) or (select public.is_fisio()));

create policy "attachments: el paciente registra los suyos"
  on public.attachments for insert to authenticated
  with check (patient_id = (select public.current_patient_id()));

-- Resumen de consulta: el paciente lee el suyo; solo la fisio escribe.
create policy "consult_notes: lectura propia o de la fisio"
  on public.consult_notes for select to authenticated
  using (patient_id = (select public.current_patient_id()) or (select public.is_fisio()));

create policy "consult_notes: la fisio crea"
  on public.consult_notes for insert to authenticated
  with check ((select public.is_fisio()));

create policy "consult_notes: la fisio edita"
  on public.consult_notes for update to authenticated
  using ((select public.is_fisio()))
  with check ((select public.is_fisio()));

-- Notas privadas: ninguna política para pacientes → denegado por defecto.
create policy "consult_notes_private: solo la fisio"
  on public.consult_notes_private for all to authenticated
  using ((select public.is_fisio()))
  with check ((select public.is_fisio()));
