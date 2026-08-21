-- Extends health_articles (0007) for the Blogs & Articles module instead of a new table — it
-- already carries content_type in ('article','blog','news'), category, body, cover image, and
-- published_at (which already doubles as "scheduled publish": the existing RLS policy
-- `published_at <= now()` means a future published_at is invisible to patients until that
-- moment arrives, with zero extra code). Only what didn't already exist is added here.

alter table public.health_articles
  add column featured boolean not null default false,
  add column tags text[] not null default '{}',
  add column external_link text,
  add column youtube_url text;

create index health_articles_featured_idx on public.health_articles (featured, published_at desc)
  where featured;

-- The admin authoring list watches all articles unfiltered (no per-user/category query-shape
-- complexity — that's what kept this table out of 0011's Realtime rollout, for the *patient*
-- search/filter paths specifically), so enabling it here is safe and lets an admin's own edits
-- reflect live across multiple open admin sessions.
alter publication supabase_realtime add table public.health_articles;
