-- Extends Realtime (see 0008's note on why this is a separate gate from RLS) to the tables that
-- were still fetch-once: a doctor/admin editing a meal plan, toggling a reminder, updating a lab
-- order/result, or publishing a seminar previously only reached the patient on next manual
-- refresh. health_articles is intentionally excluded — the Learn tab's search/category filtering
-- needs more filter flexibility than `.stream()` supports well, so it stays fetch-on-demand.

alter publication supabase_realtime add table public.meal_plans;
alter publication supabase_realtime add table public.medicine_reminders;
alter publication supabase_realtime add table public.lab_orders;
alter publication supabase_realtime add table public.lab_results;
alter publication supabase_realtime add table public.seminars;
alter publication supabase_realtime add table public.vitals;
