-- Demo/seed data so a freshly-signed-up account has something to show in every tab
-- (Home, Care, Track, Labs, Learn) instead of correct-but-empty states.
--
-- BEFORE RUNNING: replace the two email placeholders below.
--   patient_email — your real login email. This script promotes that same account to
--                   role = 'admin' (safe — no screen in the app gates on the logged-in
--                   user's own role, so all patient-side testing still works unchanged)
--                   and uses it as the author of published content (articles, seminars).
--   doctor_email  — a second account (create via Supabase → Authentication → Users → Add user,
--                   with Auto Confirm User checked — no OTP needed) that this script promotes to
--                   'doctor' and uses for appointments/monitoring calls.
-- Both accounts must already exist as profiles before running this (profiles are only created
-- by the on-signup trigger from migration 0002, which fires for dashboard-created users too).

do $$
declare
  patient_id uuid;
  doctor_id uuid;
  admin_id uuid;
begin
  select id into patient_id from public.profiles where email = 'patient_email@example.com';
  select id into doctor_id from public.profiles where email = 'doctor.demo@example.com';
  admin_id := patient_id;

  if patient_id is null then
    raise exception 'No profile found for patient_email — sign in with that email first, then update the placeholder in this script.';
  end if;
  if doctor_id is null then
    raise exception 'No profile found for doctor.demo@example.com — create that user in Supabase → Authentication → Users first.';
  end if;

  update public.profiles
    set role = 'doctor', full_name = coalesce(full_name, 'Dr. Asha Sharma')
    where id = doctor_id;

  update public.profiles
    set role = 'admin'
    where id = admin_id;

  insert into public.health_articles
    (slug, title, category, content_type, body_markdown, summary, published_at, created_by, reviewed_by)
  values
    ('understanding-type-2-diabetes', 'Understanding Type 2 Diabetes', 'diabetes', 'article',
     '# Understanding Type 2 Diabetes' || chr(10) || chr(10) ||
     'Type 2 diabetes affects how your body processes blood sugar. With the right diet, activity, ' ||
     'and monitoring routine, it can be managed effectively.',
     'A beginner-friendly guide to managing type 2 diabetes.',
     now() - interval '2 days', admin_id, doctor_id),
    ('managing-high-blood-pressure', 'Managing High Blood Pressure Naturally', 'hypertension', 'article',
     '# Managing Blood Pressure' || chr(10) || chr(10) ||
     'Small, consistent lifestyle changes — reducing salt, regular walks, and stress management — ' ||
     'make a measurable difference to blood pressure over a few weeks.',
     'Practical lifestyle tips to keep blood pressure in check.',
     now() - interval '5 days', admin_id, doctor_id),
    ('mental-wellness-daily-habits', 'Daily Habits for Mental Wellness', 'mental_health', 'blog',
     '# Mental Wellness' || chr(10) || chr(10) ||
     'A short walk, five minutes of quiet breathing, and a consistent sleep time are simple habits ' ||
     'with an outsized effect on mood and focus.',
     'Simple daily habits that support mental wellbeing.',
     now() - interval '1 day', admin_id, doctor_id)
  on conflict (slug) do nothing;

  insert into public.seminars
    (title, description, speaker_name, speaker_bio, scheduled_at, join_url, created_by)
  values
    ('Living Well with Diabetes',
     'An interactive session on diet, exercise, and home monitoring for people managing diabetes.',
     'Dr. Asha Sharma', 'MBBS, MD Endocrinology · 12 years experience',
     now() + interval '3 days', 'https://meet.example.com/demo-seminar', admin_id);

  insert into public.appointments (patient_id, provider_id, scheduled_at, mode, status, reason)
  values (patient_id, doctor_id, now() + interval '1 day', 'video', 'confirmed', 'Routine diabetes follow-up');

  insert into public.monitoring_calls (patient_id, coach_id, scheduled_at, status, notes)
  values (patient_id, doctor_id, now() + interval '2 days', 'requested', 'Weekly wellness check-in');

  insert into public.vitals (patient_id, metric_type, value, unit, source, recorded_at)
  values
    (patient_id, 'blood_glucose', 118, 'mg/dL', 'manual', now() - interval '1 day'),
    (patient_id, 'blood_glucose', 132, 'mg/dL', 'manual', now() - interval '3 days'),
    (patient_id, 'systolic_bp', 128, 'mmHg', 'manual', now() - interval '1 day'),
    (patient_id, 'diastolic_bp', 82, 'mmHg', 'manual', now() - interval '1 day'),
    (patient_id, 'weight_kg', 74.5, 'kg', 'manual', now() - interval '2 days');

  insert into public.meal_plans (patient_id, created_by, plan_date, breakfast, lunch, dinner, notes)
  values (patient_id, doctor_id, current_date,
          'Vegetable oats + boiled egg', 'Roti, dal, mixed vegetable sabzi, salad',
          'Grilled fish, steamed vegetables', 'Avoid sugary drinks; drink 2L water today.')
  on conflict (patient_id, plan_date) do nothing;

  insert into public.medicine_reminders (patient_id, medicine_name, dosage, schedule, active)
  values (patient_id, 'Metformin', '500mg',
          '[{"time":"08:00","days":["mon","tue","wed","thu","fri","sat","sun"]},
            {"time":"20:00","days":["mon","tue","wed","thu","fri","sat","sun"]}]'::jsonb,
          true);

  insert into public.lab_orders (patient_id, ordered_by, test_name, status, scheduled_at)
  values (patient_id, doctor_id, 'HbA1c', 'ordered', now() + interval '4 days');
end $$;
