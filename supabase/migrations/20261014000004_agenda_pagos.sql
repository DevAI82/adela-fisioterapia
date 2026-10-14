-- =============================================================================
-- Spec 005 · Migración 004: disponibilidad, citas y pagos
-- Las citas y los pagos los crea el SERVIDOR (webhook de Stripe con service_role):
-- siempre se paga antes de reservar (D-009) y el cliente no puede falsear pagos (CA-10).
-- =============================================================================

-- Franjas de consulta (inicial: martes y jueves 16:00–20:00, D-013).
create table public.availability (
  id          uuid primary key default gen_random_uuid(),
  weekday     smallint not null check (weekday between 0 and 6),   -- 0 = domingo
  start_time  time not null,
  end_time    time not null,
  break_min   smallint not null default 15 check (break_min between 0 and 60),
  check (start_time < end_time)
);

create table public.payments (
  id                     uuid primary key default gen_random_uuid(),
  patient_id             uuid not null references public.patients (id) on delete restrict,
  product                text not null check (product in ('primera', 'sesion', 'rutinas', 'premium')),
  amount_cents           integer not null check (amount_cents > 0),
  currency               text not null default 'eur' check (currency = 'eur'),
  method                 text not null check (method in ('bizum', 'card')),
  status                 text not null check (status in ('pendiente', 'pagado', 'fallido', 'reembolsado')),
  stripe_payment_intent  text unique,
  stripe_subscription    text,
  created_at             timestamptz not null default now(),
  -- Bizum solo para pagos únicos (D-009).
  constraint payments_bizum_only_one_off check (not (method = 'bizum' and product in ('rutinas', 'premium')))
);

create table public.payment_links (
  id          uuid primary key default gen_random_uuid(),
  patient_id  uuid not null references public.patients (id) on delete restrict,
  product     text not null check (product in ('sesion', 'rutinas', 'premium')),
  channel     text not null check (channel in ('whatsapp', 'email', 'portal')),
  url         text,
  status      text not null default 'pendiente' check (status in ('pendiente', 'pagado', 'caducado')),
  payment_id  uuid references public.payments (id) on delete restrict,
  created_by  uuid not null default auth.uid() references public.profiles (id) on delete restrict,
  created_at  timestamptz not null default now()
);

create table public.appointments (
  id            uuid primary key default gen_random_uuid(),
  patient_id    uuid not null references public.patients (id) on delete restrict,
  kind          text not null check (kind in ('primera', 'sesion', 'premium')),
  starts_at     timestamptz not null,
  duration_min  smallint not null check (duration_min in (25, 45)),
  break_min     smallint not null default 15,
  status        text not null default 'confirmada'
                check (status in ('confirmada', 'realizada', 'no_presentado', 'reagendada', 'cancelada')),
  payment_id    uuid references public.payments (id) on delete restrict,
  meet_url      text,
  blocked       tstzrange,          -- [inicio, fin + descanso): lo calcula el trigger
  created_at    timestamptz not null default now(),
  constraint appointments_primera_25 check (kind <> 'primera' or duration_min = 25),
  constraint appointments_paid check (kind = 'premium' or payment_id is not null)
);

create function public.appointments_set_blocked()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.blocked := tstzrange(
    new.starts_at,
    new.starts_at + make_interval(mins => new.duration_min + new.break_min),
    '[)'
  );
  return new;
end;
$$;

create trigger appointments_blocked
  before insert or update of starts_at, duration_min, break_min on public.appointments
  for each row execute function public.appointments_set_blocked();

-- Dos citas confirmadas no pueden solaparse, contando el descanso de 15 min.
alter table public.appointments
  add constraint appointments_no_overlap
  exclude using gist (blocked with &&) where (status = 'confirmada');

alter table public.availability enable row level security;
alter table public.payments enable row level security;
alter table public.payment_links enable row level security;
alter table public.appointments enable row level security;

-- Disponibilidad: pública en lectura (la web muestra los huecos); la fisio la edita.
create policy "availability: lectura pública"
  on public.availability for select to anon, authenticated
  using (true);

create policy "availability: la fisio gestiona"
  on public.availability for all to authenticated
  using ((select public.is_fisio())) with check ((select public.is_fisio()));

-- Pagos: solo lectura para clientes. Escritura exclusiva del servidor (service_role).
create policy "payments: lectura propia o de la fisio"
  on public.payments for select to authenticated
  using (patient_id = (select public.current_patient_id()) or (select public.is_fisio()));

create policy "payment_links: lectura propia o de la fisio"
  on public.payment_links for select to authenticated
  using (patient_id = (select public.current_patient_id()) or (select public.is_fisio()));

create policy "payment_links: la fisio los crea"
  on public.payment_links for insert to authenticated
  with check ((select public.is_fisio()) and status = 'pendiente' and payment_id is null);

-- Citas: el paciente ve las suyas; la fisio gestiona (marcar no presentado, reagendar).
create policy "appointments: lectura propia o de la fisio"
  on public.appointments for select to authenticated
  using (patient_id = (select public.current_patient_id()) or (select public.is_fisio()));

create policy "appointments: la fisio gestiona"
  on public.appointments for update to authenticated
  using ((select public.is_fisio())) with check ((select public.is_fisio()));

insert into public.availability (weekday, start_time, end_time) values
  (2, '16:00', '20:00'),   -- martes
  (4, '16:00', '20:00');   -- jueves
