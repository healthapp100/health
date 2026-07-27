-- Phase 0 foundation: roles, profiles, and the RLS helper used by every later policy.
-- Region note: the hosted project this migration is applied to should be created in
-- ap-south-1 (Mumbai) per BLUEPRINT.md §2.2 (latency + health-data-sensitivity rationale,
-- not a DPDP legal requirement).

create type public.app_role as enum (
  'patient',
  'doctor',
  'nutritionist',
  'lab_staff',
  'support',
  'admin',
  'super_admin'
);

-- One row per auth.users id. Created via a trigger on signup (see 0002).
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role public.app_role not null default 'patient',
  full_name text,
  phone text unique,
  email text unique,
  locale text not null default 'en-IN',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is 'One row per authenticated user; role drives every RLS policy in this schema.';

-- Dependents/family members a patient manages from their own account (BLUEPRINT.md §5.1).
-- A dependent may or may not have their own auth.users row (e.g. a minor child usually won't).
create table public.care_relationships (
  id uuid primary key default gen_random_uuid(),
  guardian_profile_id uuid not null references public.profiles (id) on delete cascade,
  dependent_profile_id uuid references public.profiles (id) on delete cascade,
  dependent_display_name text,
  relationship text not null, -- e.g. 'child', 'parent', 'spouse', 'self'
  created_at timestamptz not null default now(),
  constraint dependent_identity_present check (
    dependent_profile_id is not null or dependent_display_name is not null
  )
);

-- Helper used by every RLS policy below: current caller's role, without recursive RLS lookups.
create or replace function public.current_user_role()
returns public.app_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_user_role() in ('doctor', 'nutritionist', 'lab_staff', 'support', 'admin', 'super_admin');
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_user_role() in ('admin', 'super_admin');
$$;

alter table public.profiles enable row level security;
alter table public.care_relationships enable row level security;

create policy "profiles: self read" on public.profiles
  for select using (id = auth.uid());

create policy "profiles: self update" on public.profiles
  for update using (id = auth.uid());

create policy "profiles: admin full read" on public.profiles
  for select using (public.is_admin());

create policy "profiles: staff read patient profiles" on public.profiles
  for select using (public.is_staff() and role = 'patient');

create policy "care_relationships: guardian manages own" on public.care_relationships
  for all using (guardian_profile_id = auth.uid())
  with check (guardian_profile_id = auth.uid());

create policy "care_relationships: admin read" on public.care_relationships
  for select using (public.is_admin());
