-- =============================================================================
-- Spec 005 · Migración 003: biblioteca de vídeos y voces, rutinas y mini cuestionario
-- Vídeos y voces genéricos en Cloudflare R2; voces personalizadas en el bucket
-- privado `personal-voices` del VPS (D-012).
-- =============================================================================

create table public.library_videos (
  id                uuid primary key default gen_random_uuid(),
  title             text not null check (char_length(title) between 1 and 200),
  tags              text[] not null default '{}',
  duration_seconds  integer check (duration_seconds > 0),
  object_key        text not null unique,          -- clave del objeto en R2
  created_at        timestamptz not null default now()
);

create table public.library_voices (
  id                uuid primary key default gen_random_uuid(),
  title             text not null check (char_length(title) between 1 and 200),
  tags              text[] not null default '{}',
  duration_seconds  integer check (duration_seconds > 0),
  scope             text not null check (scope in ('generic', 'personal')),
  patient_id        uuid references public.patients (id) on delete restrict,
  storage           text not null check (storage in ('r2', 'supabase')),
  object_key        text not null unique,
  created_at        timestamptz not null default now(),
  -- Genérica → R2 y sin paciente. Personalizada → bucket privado del VPS y con paciente.
  constraint library_voices_scope_coherent check (
    (scope = 'generic'  and patient_id is null     and storage = 'r2') or
    (scope = 'personal' and patient_id is not null and storage = 'supabase')
  )
);

create table public.routines (
  id          uuid primary key default gen_random_uuid(),
  patient_id  uuid not null references public.patients (id) on delete restrict,
  title       text not null check (char_length(title) between 1 and 200),
  starts_on   date not null default current_date,
  active      boolean not null default true,
  created_by  uuid not null default auth.uid() references public.profiles (id) on delete restrict,
  created_at  timestamptz not null default now()
);
-- Una sola rutina activa por paciente.
create unique index routines_one_active_per_patient on public.routines (patient_id) where active;

create table public.routine_items (
  id         uuid primary key default gen_random_uuid(),
  routine_id uuid not null references public.routines (id) on delete restrict,
  position   smallint not null check (position >= 1),
  video_id   uuid not null references public.library_videos (id) on delete restrict,
  voice_id   uuid references public.library_voices (id) on delete restrict,
  series     smallint not null check (series between 1 and 10),
  reps       text not null check (char_length(reps) between 1 and 40),
  frequency  text not null check (frequency in ('Diaria', '5 días/semana', '3 días/semana', '2 días/semana', 'Días alternos')),
  duration   text not null check (duration in ('1 semana', '2 semanas', '3 semanas', '4 semanas', 'Hasta revisión')),
  note       text check (char_length(note) <= 1000),
  unique (routine_id, position)
);

-- Mini cuestionario de la sesión completa (CA-3).
create table public.session_feedback (
  id               uuid primary key default gen_random_uuid(),
  patient_id       uuid not null references public.patients (id) on delete restrict,
  routine_id       uuid not null references public.routines (id) on delete restrict,
  exercises_done   smallint not null check (exercises_done >= 0),
  exercises_total  smallint not null check (exercises_total >= 1),
  stiffness        text not null check (stiffness in ('elevada', 'moderada', 'ligera', 'ninguna')),
  pain             smallint not null check (pain between 0 and 10),
  stability        text not null check (stability in ('alta', 'media', 'baja')),
  comment          text check (char_length(comment) <= 2000),
  fisio_reply      text check (char_length(fisio_reply) <= 2000),
  replied_at       timestamptz,
  created_at       timestamptz not null default now(),
  check (exercises_done <= exercises_total)
);

alter table public.library_videos enable row level security;
alter table public.library_voices enable row level security;
alter table public.routines enable row level security;
alter table public.routine_items enable row level security;
alter table public.session_feedback enable row level security;

-- ¿El paciente actual tiene este vídeo/voz en su rutina activa? (CA-14)
create function public.in_my_active_routine(p_video_id uuid, p_voice_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.routine_items ri
    join public.routines r on r.id = ri.routine_id
    where r.active
      and r.patient_id = (select public.current_patient_id())
      and (ri.video_id = p_video_id or ri.voice_id = p_voice_id)
  );
$$;

-- Biblioteca: la fisio gestiona todo; el paciente solo ve lo de su rutina activa.
create policy "library_videos: la fisio gestiona"
  on public.library_videos for all to authenticated
  using ((select public.is_fisio())) with check ((select public.is_fisio()));

create policy "library_videos: el paciente ve los de su rutina"
  on public.library_videos for select to authenticated
  using (public.in_my_active_routine(id, null));

create policy "library_voices: la fisio gestiona"
  on public.library_voices for all to authenticated
  using ((select public.is_fisio())) with check ((select public.is_fisio()));

create policy "library_voices: el paciente ve las de su rutina"
  on public.library_voices for select to authenticated
  using (public.in_my_active_routine(null, id));

-- Rutinas: lectura propia; escritura solo de la fisio.
create policy "routines: lectura propia o de la fisio"
  on public.routines for select to authenticated
  using (patient_id = (select public.current_patient_id()) or (select public.is_fisio()));

create policy "routines: la fisio gestiona"
  on public.routines for all to authenticated
  using ((select public.is_fisio())) with check ((select public.is_fisio()));

create policy "routine_items: lectura propia o de la fisio"
  on public.routine_items for select to authenticated
  using (
    (select public.is_fisio())
    or exists (select 1 from public.routines r
               where r.id = routine_id and r.patient_id = (select public.current_patient_id()))
  );

create policy "routine_items: la fisio gestiona"
  on public.routine_items for all to authenticated
  using ((select public.is_fisio())) with check ((select public.is_fisio()));

-- Mini cuestionario: el paciente lo envía (sin respuesta) y lo lee; la fisio responde.
create policy "session_feedback: lectura propia o de la fisio"
  on public.session_feedback for select to authenticated
  using (patient_id = (select public.current_patient_id()) or (select public.is_fisio()));

create policy "session_feedback: el paciente envía el suyo"
  on public.session_feedback for insert to authenticated
  with check (
    patient_id = (select public.current_patient_id())
    and fisio_reply is null and replied_at is null
    and exists (select 1 from public.routines r
                where r.id = routine_id and r.patient_id = (select public.current_patient_id()))
  );

create policy "session_feedback: la fisio responde"
  on public.session_feedback for update to authenticated
  using ((select public.is_fisio())) with check ((select public.is_fisio()));
