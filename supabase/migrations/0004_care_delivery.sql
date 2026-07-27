-- Core care-loop tables: Doctor Calls, Daily Monitoring Calls, Daily Meal Guidance,
-- Medicine Support (reminders only — see BLUEPRINT.md §3.4 on why sale/dispensing is out of scope).

create type public.appointment_status as enum (
  'requested', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show'
);

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles (id) on delete cascade,
  provider_id uuid not null references public.profiles (id),
  scheduled_at timestamptz not null,
  mode text not null default 'video' check (mode in ('video', 'audio', 'chat')),
  status public.appointment_status not null default 'requested',
  reason text,
  notes text, -- provider-authored consultation notes (BLUEPRINT.md §3.2 record-keeping)
  call_room_id text, -- external video/audio provider's room identifier
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Non-diagnostic wellness/adherence check-ins. Kept structurally separate from `appointments`
-- to preserve the BLUEPRINT.md §3.5 scope boundary (wellness coaching, not clinical monitoring).
create table public.monitoring_calls (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles (id) on delete cascade,
  coach_id uuid not null references public.profiles (id), -- named-provider continuity, §4.4
  scheduled_at timestamptz not null,
  status public.appointment_status not null default 'requested',
  notes text,
  escalated_to_appointment_id uuid references public.appointments (id),
  created_at timestamptz not null default now()
);

create table public.meal_plans (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles (id) on delete cascade,
  created_by uuid not null references public.profiles (id),
  plan_date date not null,
  breakfast text,
  lunch text,
  dinner text,
  notes text,
  created_at timestamptz not null default now(),
  unique (patient_id, plan_date)
);

create table public.medicine_reminders (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles (id) on delete cascade,
  medicine_name text not null,
  dosage text,
  schedule jsonb not null default '[]'::jsonb, -- e.g. [{"time":"08:00","days":["mon","tue"]}]
  active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.appointments enable row level security;
alter table public.monitoring_calls enable row level security;
alter table public.meal_plans enable row level security;
alter table public.medicine_reminders enable row level security;

-- appointments
create policy "appointments: patient own" on public.appointments
  for select using (patient_id = auth.uid());
create policy "appointments: provider own" on public.appointments
  for select using (provider_id = auth.uid());
create policy "appointments: patient create" on public.appointments
  for insert with check (patient_id = auth.uid());
create policy "appointments: provider update own" on public.appointments
  for update using (provider_id = auth.uid());
create policy "appointments: admin manage" on public.appointments
  for all using (public.is_admin()) with check (public.is_admin());

-- monitoring_calls
create policy "monitoring_calls: patient own" on public.monitoring_calls
  for select using (patient_id = auth.uid());
create policy "monitoring_calls: coach own" on public.monitoring_calls
  for all using (coach_id = auth.uid()) with check (coach_id = auth.uid());
create policy "monitoring_calls: admin manage" on public.monitoring_calls
  for all using (public.is_admin()) with check (public.is_admin());

-- meal_plans
create policy "meal_plans: patient read own" on public.meal_plans
  for select using (patient_id = auth.uid());
create policy "meal_plans: creator manage" on public.meal_plans
  for all using (created_by = auth.uid()) with check (created_by = auth.uid());
create policy "meal_plans: admin manage" on public.meal_plans
  for all using (public.is_admin()) with check (public.is_admin());

-- medicine_reminders (patient-owned and managed; no provider/dispensing role at MVP scope)
create policy "medicine_reminders: patient manage own" on public.medicine_reminders
  for all using (patient_id = auth.uid()) with check (patient_id = auth.uid());
create policy "medicine_reminders: admin read" on public.medicine_reminders
  for select using (public.is_admin());
