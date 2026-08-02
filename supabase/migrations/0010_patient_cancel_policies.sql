-- Patients had select/insert but no update rights on their own appointments/monitoring_calls
-- (0004_care_delivery.sql only granted update to the provider/coach) — so the existing
-- AppointmentService.cancelAppointment() call would silently fail under RLS. Patients need to be
-- able to cancel a call they booked themselves.

create policy "appointments: patient cancel own" on public.appointments
  for update using (patient_id = auth.uid()) with check (patient_id = auth.uid());

create policy "monitoring_calls: patient cancel own" on public.monitoring_calls
  for update using (patient_id = auth.uid()) with check (patient_id = auth.uid());
