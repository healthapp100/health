-- Provider (RMP/nutritionist/lab staff) credential verification.
-- BLUEPRINT.md §3.2: the platform must perform due diligence on every listed doctor to
-- preserve IT Act s.79 intermediary safe-harbor status — this table is that due-diligence record.

create table public.provider_credentials (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  registration_number text not null,
  registration_council text not null, -- e.g. state medical council name, or NMC
  specialty text,
  years_experience int,
  verified boolean not null default false,
  verified_by uuid references public.profiles (id),
  verified_at timestamptz,
  document_url text, -- storage path to the uploaded registration certificate
  created_at timestamptz not null default now()
);

comment on table public.provider_credentials is
  'Due-diligence record per doctor/nutritionist/lab_staff profile. verified must be true before the provider is bookable.';

alter table public.provider_credentials enable row level security;

create policy "provider_credentials: self read" on public.provider_credentials
  for select using (profile_id = auth.uid());

create policy "provider_credentials: self insert own pending record" on public.provider_credentials
  for insert with check (profile_id = auth.uid());

create policy "provider_credentials: admin manage" on public.provider_credentials
  for all using (public.is_admin()) with check (public.is_admin());

-- Deliberately no blanket "patients can read verified providers" policy on this table: it holds
-- registration_number and document_url, which patients booking a provider don't need to see.
-- Instead, a separate, intentionally narrow table (not a view — RLS-over-views has subtle
-- ownership/security_invoker semantics not worth gambling on for this boundary) is kept in sync
-- via trigger and holds only the fields safe for any authenticated patient to browse.
create table public.provider_directory (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  full_name text not null,
  role public.app_role not null,
  specialty text,
  years_experience int,
  updated_at timestamptz not null default now()
);

comment on table public.provider_directory is
  'Public-safe mirror of verified providers for patient browsing. Kept in sync by sync_provider_directory(); never written to directly by clients.';

create or replace function public.sync_provider_directory()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (tg_op in ('INSERT', 'UPDATE')) then
    if new.verified then
      insert into public.provider_directory (profile_id, full_name, role, specialty, years_experience, updated_at)
      select p.id, p.full_name, p.role, new.specialty, new.years_experience, now()
      from public.profiles p where p.id = new.profile_id
      on conflict (profile_id) do update set
        full_name = excluded.full_name,
        specialty = excluded.specialty,
        years_experience = excluded.years_experience,
        updated_at = now();
    else
      delete from public.provider_directory where profile_id = new.profile_id;
    end if;
    return new;
  elsif (tg_op = 'DELETE') then
    delete from public.provider_directory where profile_id = old.profile_id;
    return old;
  end if;
end;
$$;

create trigger provider_credentials_sync_directory
  after insert or update or delete on public.provider_credentials
  for each row execute function public.sync_provider_directory();

alter table public.provider_directory enable row level security;

create policy "provider_directory: authenticated read all" on public.provider_directory
  for select using (auth.uid() is not null);

-- No insert/update/delete policy: only the security-definer trigger above (which runs as the
-- function owner, bypassing RLS) writes to this table.
