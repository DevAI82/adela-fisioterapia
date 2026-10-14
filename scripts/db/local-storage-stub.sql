-- SOLO PARA PRUEBAS LOCALES sin el servicio de Storage de Supabase.
-- En Supabase real estas tablas y la función las crea storage-api; aquí se imitan
-- con las columnas que usan las migraciones y los tests de RLS.
create table if not exists storage.buckets (
  id                  text primary key,
  name                text not null unique,
  owner               uuid,
  public              boolean default false,
  file_size_limit     bigint,
  allowed_mime_types  text[],
  created_at          timestamptz default now(),
  updated_at          timestamptz default now()
);

create table if not exists storage.objects (
  id          uuid primary key default gen_random_uuid(),
  bucket_id   text references storage.buckets (id),
  name        text,
  owner       uuid,
  metadata    jsonb,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

create or replace function storage.foldername(name text)
returns text[]
language sql immutable
as $$
  select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1];
$$;

alter table storage.objects enable row level security;
grant usage on schema storage to anon, authenticated, service_role;
grant select, insert, update, delete on storage.objects to authenticated, service_role;
grant select on storage.buckets to authenticated, service_role;

-- En Supabase real el rol postgres puede crear buckets y políticas sobre storage.objects
-- desde las migraciones; aquí se le da la propiedad de las tablas imitadas.
alter table storage.buckets owner to postgres;
alter table storage.objects owner to postgres;
alter function storage.foldername(text) owner to postgres;
