-- Profile photo storage. Files are keyed by `avatars/{auth.uid()}/...` so the RLS policies on
-- storage.objects can scope write access to "your own folder" using the same
-- foldername(name)[1] = auth.uid()::text pattern Supabase's own docs recommend for user uploads.
-- Bucket is public-read (avatar URLs are shown in plain <img>/Image widgets across the app with
-- no signed-URL plumbing) but public read of a profile photo is not sensitive health data.

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "avatars: public read" on storage.objects
  for select using (bucket_id = 'avatars');

create policy "avatars: own folder upload" on storage.objects
  for insert with check (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars: own folder update" on storage.objects
  for update using (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars: own folder delete" on storage.objects
  for delete using (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );
