-- Learn module CMS hierarchy: Topic -> Subtopic, where each subtopic IS a content page (its
-- body/media fields hold the actual content — "Definition", "Causes", "Symptoms" etc. under
-- "Diabetes" are each one row in learn_subtopics, not a further-nested third table). Replaces
-- the flat free-text `category` browsing on health_articles for structured topic browsing;
-- health_articles/blogs remain separate (they're informal reading, not a curated topic outline).

create table public.learn_topics (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  summary text,
  icon text, -- Material icon name (e.g. 'bloodtype_outlined') rendered on the topic tile
  cover_image_url text,
  sort_order int not null default 0,
  published boolean not null default true,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index learn_topics_sort_idx on public.learn_topics (sort_order) where published;

create table public.learn_subtopics (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references public.learn_topics (id) on delete cascade,
  slug text not null,
  title text not null, -- e.g. 'Definition', 'Causes', 'Symptoms', 'Diet', 'FAQs'
  sort_order int not null default 0,
  published boolean not null default true,
  body_markdown text,
  image_urls text[] not null default '{}',
  pdf_urls text[] not null default '{}',
  -- [{"label": "...", "url": "..."}, ...] — a plain array column can't hold structured
  -- label+url pairs, and a separate join table is overkill for a handful of reference links.
  external_links jsonb not null default '[]',
  youtube_url text,
  references_text text,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (topic_id, slug)
);

create index learn_subtopics_topic_idx on public.learn_subtopics (topic_id, sort_order) where published;

alter table public.learn_topics enable row level security;
alter table public.learn_subtopics enable row level security;

create policy "learn_topics: public read published" on public.learn_topics
  for select using (published);
create policy "learn_topics: staff manage" on public.learn_topics
  for all using (public.is_staff()) with check (public.is_staff());

create policy "learn_subtopics: public read published" on public.learn_subtopics
  for select using (published);
create policy "learn_subtopics: staff manage" on public.learn_subtopics
  for all using (public.is_staff()) with check (public.is_staff());

-- Live data: an admin publishing/editing a topic or subtopic reaches patients without a manual
-- refresh (same Realtime-is-a-second-gate pattern as 0008/0011).
alter publication supabase_realtime add table public.learn_topics;
alter publication supabase_realtime add table public.learn_subtopics;
