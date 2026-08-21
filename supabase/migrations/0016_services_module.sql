-- Services module (BLUEPRINT.md's Services section): Daily Monitoring messages, Daily Videos
-- (with a publish/expiry lifecycle), and three admin-managed reference directories (Lab Test
-- Support, Health Kit Support, Medicines) plus supplementary Doctor contact/availability info.
-- Health Data itself is the existing Track tab (public.vitals) — no new table needed there.

-- Daily Monitoring: patient_id null = broadcast to every patient; set = targeted to just them.
-- Modeled as one table with a nullable FK rather than two tables, since "broadcast vs targeted"
-- is a property of one row, not a structurally different kind of row.
create table public.monitoring_messages (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references public.profiles (id) on delete cascade, -- null = broadcast
  title text not null,
  body text not null,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now()
);

create index monitoring_messages_patient_idx on public.monitoring_messages (patient_id, created_at desc);

-- Daily Videos: publish_at/expires_at define the visible window. "Storage optimization" here
-- means the row (and the YouTube/Drive link it points at) simply stops being selectable once
-- expired — the RLS policy below excludes it, so no separate cleanup job is required to make an
-- expired video unavailable. A periodic hard-delete of long-expired rows (see the note at the
-- bottom of this file) is a separate, optional space-reclaiming step, not what makes it
-- inaccessible.
create table public.daily_videos (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  video_url text not null, -- YouTube or Google Drive link
  thumbnail_url text,
  publish_at timestamptz not null default now(),
  expires_at timestamptz,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now()
);

create index daily_videos_window_idx on public.daily_videos (publish_at, expires_at);

create table public.lab_directory (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  kind text not null default 'diagnostic_center' check (kind in ('clinic', 'diagnostic_center')),
  doctor_name text,
  contact_phone text,
  contact_email text,
  address text,
  services text,
  timings text,
  external_link text,
  published boolean not null default true,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.health_kit_directory (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'device' check (category in ('device', 'kit', 'equipment')),
  description text,
  supplier_name text,
  purchase_link text,
  instructions text,
  image_url text,
  published boolean not null default true,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.medicine_info (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text,
  description text,
  recommendations text,
  external_link text,
  published boolean not null default true,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Supplementary contact/availability info for a doctor, shown alongside the existing
-- provider_directory (booking stays exactly as-is via appointments/provider_directory) — kept
-- separate from provider_directory because that table is trigger-synced from
-- provider_credentials (0003) and isn't meant to be hand-edited directly.
create table public.doctor_contact_info (
  id uuid primary key default gen_random_uuid(),
  provider_profile_id uuid not null references public.profiles (id) on delete cascade,
  contact_phone text,
  contact_email text,
  consultation_fee text,
  availability text,
  notes text,
  published boolean not null default true,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider_profile_id)
);

alter table public.monitoring_messages enable row level security;
alter table public.daily_videos enable row level security;
alter table public.lab_directory enable row level security;
alter table public.health_kit_directory enable row level security;
alter table public.medicine_info enable row level security;
alter table public.doctor_contact_info enable row level security;

create policy "monitoring_messages: patient read own or broadcast" on public.monitoring_messages
  for select using (patient_id is null or patient_id = auth.uid());
create policy "monitoring_messages: staff manage" on public.monitoring_messages
  for all using (public.is_staff()) with check (public.is_staff());

create policy "daily_videos: public read within window" on public.daily_videos
  for select using (
    publish_at <= now() and (expires_at is null or expires_at > now())
  );
create policy "daily_videos: staff manage" on public.daily_videos
  for all using (public.is_staff()) with check (public.is_staff());

create policy "lab_directory: public read published" on public.lab_directory
  for select using (published);
create policy "lab_directory: staff manage" on public.lab_directory
  for all using (public.is_staff()) with check (public.is_staff());

create policy "health_kit_directory: public read published" on public.health_kit_directory
  for select using (published);
create policy "health_kit_directory: staff manage" on public.health_kit_directory
  for all using (public.is_staff()) with check (public.is_staff());

create policy "medicine_info: public read published" on public.medicine_info
  for select using (published);
create policy "medicine_info: staff manage" on public.medicine_info
  for all using (public.is_staff()) with check (public.is_staff());

create policy "doctor_contact_info: public read published" on public.doctor_contact_info
  for select using (published);
create policy "doctor_contact_info: staff manage" on public.doctor_contact_info
  for all using (public.is_staff()) with check (public.is_staff());

-- Live data: admin edits reach patients without a manual refresh (same pattern as 0008/0011/0013).
alter publication supabase_realtime add table public.monitoring_messages;
alter publication supabase_realtime add table public.daily_videos;
alter publication supabase_realtime add table public.lab_directory;
alter publication supabase_realtime add table public.health_kit_directory;
alter publication supabase_realtime add table public.medicine_info;
alter publication supabase_realtime add table public.doctor_contact_info;

-- Optional storage-reclaiming step (not required for "expired = inaccessible", which the RLS
-- policy above already guarantees): periodically run, e.g. via a scheduled Edge Function or
-- pg_cron —
--   delete from public.daily_videos where expires_at is not null and expires_at < now() - interval '90 days';
-- Kept as a comment rather than a pg_cron job here since pg_cron availability/scheduling is a
-- project/plan-level Supabase setting, not something a plain SQL migration can turn on.
