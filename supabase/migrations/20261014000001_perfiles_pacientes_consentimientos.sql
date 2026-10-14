-- =============================================================================
-- Spec 005 · Migración 001: perfiles, pacientes, consentimientos y funciones de rol
-- Reglas: RLS en todas las tablas; sin borrados en cascada sobre datos clínicos.
-- =============================================================================

create type public.user_role as enum ('fisio', 'paciente');

-- Perfil de cada usuario de Auth. El rol nunca lo decide el cliente.
create table public.profiles (
  id          uuid primary key references auth.users (id) on delete restrict,
  role        public.user_role not null default 'paciente',
  full_name   text not null check (char_length(full_name) between 1 and 200),
  phone       text check (char_length(phone) <= 30),
  created_at  timestamptz not null default now()
);
comment on table public.profiles is 'Usuarios de la plataforma: la fisio (rol fisio) y los pacientes.';

-- Ficha clínica del paciente. Baja lógica con deleted_at (Ley 41/2002: conservar ≥ 5 años).
create table public.patients (
  id            uuid primary key default gen_random_uuid(),
  profile_id    uuid not null unique references public.profiles (id) on delete restrict,
  problem_type  text not null check (problem_type in ('dolor', 'suelo-pelvico', 'linfedema', 'envejecimiento', 'deportiva', 'multiples')),
  body_zone     text,
  diagnosis     text,
  status        text not null default 'nuevo'
                check (status in ('nuevo', 'primera_pagada', 'primera_reservada', 'activo', 'alta', 'baja')),
  plan          text check (plan in ('rutinas', 'premium')),
  created_at    timestamptz not null default now(),
  deleted_at    timestamptz
);
comment on column public.patients.deleted_at is 'Baja lógica: los datos clínicos no se borran (D-005, Ley 41/2002).';

-- ---------------------------------------------------------------- Funciones de rol
-- security definer para poder consultarlas desde las políticas sin recursión de RLS.
create function public.is_fisio()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'fisio'
  );
$$;

create function public.current_patient_id()
returns uuid
language sql stable security definer
set search_path = ''
as $$
  select id from public.patients
  where profile_id = (select auth.uid()) and deleted_at is null;
$$;

-- Alta automática del perfil al registrarse: siempre como paciente.
create function public.handle_new_user()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, role, full_name, phone)
  values (
    new.id,
    'paciente',
    coalesce(nullif(new.raw_user_meta_data ->> 'full_name', ''), 'Paciente'),
    new.raw_user_meta_data ->> 'phone'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- El rol solo lo cambian los roles de administración (nunca anon/authenticated).
create function public.prevent_role_change()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.role is distinct from old.role and current_user in ('anon', 'authenticated') then
    raise exception 'No se puede cambiar el rol de un perfil' using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger profiles_prevent_role_change
  before update on public.profiles
  for each row execute function public.prevent_role_change();

-- Consentimientos: solo inserción, con la versión del texto aceptado (CA-11).
create table public.consents (
  id            uuid primary key default gen_random_uuid(),
  profile_id    uuid not null references public.profiles (id) on delete restrict,
  kind          text not null check (kind in ('datos_salud', 'privacidad', 'whatsapp', 'documentos')),
  text_version  text not null,
  accepted      boolean not null,
  ip            inet,
  created_at    timestamptz not null default now()
);

-- ------------------------------------------------------------------------ RLS
alter table public.profiles enable row level security;
alter table public.patients enable row level security;
alter table public.consents enable row level security;

create policy "profiles: cada uno el suyo; la fisio, todos"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()) or (select public.is_fisio()));

create policy "profiles: cada uno edita el suyo"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy "patients: el paciente su ficha; la fisio, todas"
  on public.patients for select to authenticated
  using (profile_id = (select auth.uid()) or (select public.is_fisio()));

create policy "patients: el paciente crea su propia ficha"
  on public.patients for insert to authenticated
  with check (profile_id = (select auth.uid()) and status = 'nuevo' and plan is null);

create policy "patients: solo la fisio actualiza fichas"
  on public.patients for update to authenticated
  using ((select public.is_fisio()))
  with check ((select public.is_fisio()));

create policy "consents: cada uno registra los suyos"
  on public.consents for insert to authenticated
  with check (profile_id = (select auth.uid()));

create policy "consents: lectura propia o de la fisio"
  on public.consents for select to authenticated
  using (profile_id = (select auth.uid()) or (select public.is_fisio()));
