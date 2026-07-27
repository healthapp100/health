-- Health Knowledge Library, Blogs, and Online Seminars (BLUEPRINT.md §5.1, Phase 1).
-- Public read for published content; only staff/admin can author. Every row is subject to the
-- ASCI/DMR editorial checklist (BLUEPRINT.md §3.6) before publish — enforced by process, not SQL.

create table public.health_articles (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  category text not null, -- e.g. 'diabetes', 'hypertension', 'mental_health'
  content_type text not null default 'article' check (content_type in ('article', 'blog', 'news')),
  body_markdown text not null,
  summary text,
  cover_image_url text,
  reviewed_by uuid references public.profiles (id),
  published_at timestamptz,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index health_articles_category_idx on public.health_articles (category, published_at desc);

create table public.seminars (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  speaker_name text not null,
  speaker_bio text,
  scheduled_at timestamptz not null,
  join_url text,
  recording_url text,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now()
);

create table public.seminar_registrations (
  id uuid primary key default gen_random_uuid(),
  seminar_id uuid not null references public.seminars (id) on delete cascade,
  patient_id uuid not null references public.profiles (id) on delete cascade,
  registered_at timestamptz not null default now(),
  reminded boolean not null default false,
  unique (seminar_id, patient_id)
);

alter table public.health_articles enable row level security;
alter table public.seminars enable row level security;
alter table public.seminar_registrations enable row level security;

create policy "health_articles: public read published" on public.health_articles
  for select using (published_at is not null and published_at <= now());
create policy "health_articles: staff manage" on public.health_articles
  for all using (public.is_staff()) with check (public.is_staff());

create policy "seminars: public read all" on public.seminars
  for select using (true);
create policy "seminars: staff manage" on public.seminars
  for all using (public.is_staff()) with check (public.is_staff());

create policy "seminar_registrations: patient manage own" on public.seminar_registrations
  for all using (patient_id = auth.uid()) with check (patient_id = auth.uid());
create policy "seminar_registrations: staff read" on public.seminar_registrations
  for select using (public.is_staff());
