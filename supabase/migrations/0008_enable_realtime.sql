-- Enables Supabase Realtime (Postgres logical replication) for tables the Flutter app
-- subscribes to live via supabase_flutter's `.stream()` (AppointmentService.watchOwnAppointments
-- and watchOwnMonitoringCalls). Without this, `.stream()` throws
-- RealtimeSubscribeException(status: channelError) even though RLS and the query are correct —
-- Realtime and RLS are separate gates, both must pass.

alter publication supabase_realtime add table public.appointments;
alter publication supabase_realtime add table public.monitoring_calls;
