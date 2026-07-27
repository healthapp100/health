-- Health Data Monitoring (vitals, periodic 3mo-1yr and device-sourced) + Laboratory Test
-- Support. Plain, well-indexed Postgres per BLUEPRINT.md §2.2 (TimescaleDB deferred until
-- volume actually demands it — a non-disruptive later upgrade since it's a Postgres extension).

create table public.vitals (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles (id) on delete cascade,
  metric_type text not null, -- e.g. 'blood_glucose', 'systolic_bp', 'diastolic_bp', 'weight_kg', 'hba1c'
  value numeric not null,
  unit text not null,
  source text not null default 'manual' check (source in ('manual', 'device', 'lab')),
  recorded_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index vitals_patient_recorded_idx on public.vitals (patient_id, recorded_at desc);

create type public.lab_order_status as enum ('ordered', 'sample_collected', 'in_lab', 'reported', 'cancelled');

create table public.lab_orders (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles (id) on delete cascade,
  ordered_by uuid references public.profiles (id),
  test_name text not null,
  status public.lab_order_status not null default 'ordered',
  scheduled_at timestamptz,
  created_at timestamptz not null default now()
);

-- Feeds the "digital health-records vault" (BLUEPRINT.md §4.3) — results persist here, not just
-- as one-off booking artifacts.
create table public.lab_results (
  id uuid primary key default gen_random_uuid(),
  lab_order_id uuid not null references public.lab_orders (id) on delete cascade,
  patient_id uuid not null references public.profiles (id) on delete cascade,
  result_file_url text,
  result_summary text,
  reported_at timestamptz not null default now(),
  reviewed_by uuid references public.profiles (id)
);

alter table public.vitals enable row level security;
alter table public.lab_orders enable row level security;
alter table public.lab_results enable row level security;

create policy "vitals: patient manage own" on public.vitals
  for all using (patient_id = auth.uid()) with check (patient_id = auth.uid());
create policy "vitals: staff read" on public.vitals
  for select using (public.is_staff());

create policy "lab_orders: patient read own" on public.lab_orders
  for select using (patient_id = auth.uid());
create policy "lab_orders: staff manage" on public.lab_orders
  for all using (public.is_staff()) with check (public.is_staff());

create policy "lab_results: patient read own" on public.lab_results
  for select using (patient_id = auth.uid());
create policy "lab_results: staff manage" on public.lab_results
  for all using (public.is_staff()) with check (public.is_staff());
