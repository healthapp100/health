-- DPDP Act 2023 scaffolding (BLUEPRINT.md §3.1): consent records with versioning and an
-- append-only audit log. Full enforcement lands ~May 2027 but this is built to the standard now.

create table public.consent_records (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  consent_type text not null, -- e.g. 'privacy_policy', 'health_data_processing', 'marketing_comms'
  policy_version text not null,
  granted boolean not null,
  granted_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create index consent_records_profile_idx on public.consent_records (profile_id, consent_type, created_at desc);

-- Append-only: no update/delete policy is defined below, so writes are insert-only from the
-- service role (audit rows are written by backend logic, never directly by end users).
create table public.audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles (id),
  action text not null, -- e.g. 'appointment.created', 'lab_result.viewed', 'consent.revoked'
  target_table text,
  target_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index audit_log_actor_idx on public.audit_log (actor_id, created_at desc);

alter table public.consent_records enable row level security;
alter table public.audit_log enable row level security;

create policy "consent_records: self read" on public.consent_records
  for select using (profile_id = auth.uid());
create policy "consent_records: self insert" on public.consent_records
  for insert with check (profile_id = auth.uid());
create policy "consent_records: admin read" on public.consent_records
  for select using (public.is_admin());

-- audit_log has no end-user-facing policy: only service_role (which bypasses RLS) writes to it,
-- and only admins may read it.
create policy "audit_log: admin read" on public.audit_log
  for select using (public.is_admin());
