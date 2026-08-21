-- Extends seminars (0007) for offline venues, access details, and capacity — the original
-- schema only modeled an online (Google Meet/Zoom) seminar.

alter table public.seminars
  add column mode text not null default 'online' check (mode in ('online', 'offline')),
  add column duration_minutes int,
  add column meeting_password text,
  add column venue text,
  add column banner_url text,
  add column registration_limit int,
  add column status text not null default 'scheduled'
    check (status in ('scheduled', 'cancelled', 'completed')),
  add column notes text;
