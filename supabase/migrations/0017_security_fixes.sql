-- Fixes three real bugs found in a pre-production security/correctness audit of 0013-0016:
--
-- 1. monitoring_messages' broadcast-read policy had no `auth.uid() is not null` guard, so an
--    unauthenticated caller (anyone with the public anon key — which is, by design, not a
--    secret) could read every broadcast health message. Unlike health_articles/seminars, this
--    table was never intended to be public (BLUEPRINT.md's Guest role covers marketing-style
--    content, not personal health advice).
-- 2. doctor_contact_info was fully public-read, exposing a doctor's personal phone/email to
--    anonymous internet traffic, not just logged-in patients.
-- 3. seminar registration_limit enforcement (content_service.dart's registerForSeminar) silently
--    never worked: a patient's own RLS view of seminar_registrations only ever shows their own
--    row (`patient_id = auth.uid()`), so a patient-side count of "how many are registered" is
--    always 0 or 1, never the true total. A `security definer` function bypasses that row
--    filtering for exactly one narrow purpose (a count, not the registrant list — no
--    patient-identity leak) so the limit check can see the real number.

drop policy "monitoring_messages: patient read own or broadcast" on public.monitoring_messages;
create policy "monitoring_messages: patient read own or broadcast" on public.monitoring_messages
  for select using (
    auth.uid() is not null and (patient_id is null or patient_id = auth.uid())
  );

drop policy "doctor_contact_info: public read published" on public.doctor_contact_info;
create policy "doctor_contact_info: authenticated read published" on public.doctor_contact_info
  for select using (auth.uid() is not null and published);

create or replace function public.seminar_registration_count(p_seminar_id uuid)
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select count(*) from public.seminar_registrations where seminar_id = p_seminar_id;
$$;

-- Any authenticated user may call this (it returns a number, never row contents), matching the
-- same "authenticated, not anonymous" bar applied above.
revoke all on function public.seminar_registration_count(uuid) from public;
grant execute on function public.seminar_registration_count(uuid) to authenticated;
