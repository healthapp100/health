# Security & Scalability

Written after a full pass extending Realtime, adding pagination, offline handling, and
session-expiration handling. This documents what's actually enforced today, not aspirational
policy — every claim below is traceable to a migration file or a specific code path.

**Migrations must be applied for these claims to hold in production.** Every fix described here
(including 0017) lives in `supabase/migrations/*.sql` and only takes effect once run against the
live Supabase project via the SQL Editor or `supabase db push` — this repo has no CI step that
applies migrations automatically.

## 1. Row-Level Security — table-by-table audit

Every table with patient data has RLS enabled (`enable row level security`) and every policy was
re-read for this doc. Summary:

| Table | Patient access | Staff/admin access | Notes |
|---|---|---|---|
| `profiles` | own row only | staff: read patients; admin: read all | `current_user_role()`/`is_staff()`/`is_admin()` are `security definer` helpers — avoids recursive RLS lookups |
| `care_relationships` | own (guardian) rows, full CRUD | admin read | |
| `appointments` | select own, insert own, **update own to cancel** (0010) | provider update own; admin all | Patient update was *missing* until 0010 — cancel button would have silently failed under RLS. Documented as a real bug fixed mid-project. |
| `monitoring_calls` | select own, **update own to cancel** (0010) | coach all; admin all | Same gap, same fix |
| `meal_plans` | read own | creator (coach) manage; admin all | Patient never writes — by design |
| `medicine_reminders` | full CRUD own | admin read | No staff write — reminders are patient-managed |
| `vitals` | full CRUD own | staff read | Patient can log device/manual readings; lab-sourced writes would need a staff-side path (not yet built — see §5) |
| `lab_orders` / `lab_results` | read own | staff manage | Booking intentionally staff-only (BLUEPRINT.md §3.4) |
| `provider_credentials` | n/a (staff-only table) | self insert/read own; admin manage | **Never exposed to patients** — holds `registration_number`/`document_url` |
| `provider_directory` | authenticated read all | written only by a `security definer` trigger | The deliberate public-safe mirror of `provider_credentials`; patients never touch the underlying due-diligence table |
| `health_articles` | public read (published only) | staff manage | `published_at is not null and published_at <= now()` — a staff-authored draft is invisible until publish, not just "hidden in the UI" |
| `seminars` | public read all | staff manage | |
| `seminar_registrations` | full CRUD own | staff read | A patient's own-row RLS scope means a client-side `count` under this policy only ever returns 0 or 1, never the seminar's true registration total — fixed in 0017 via a `security definer` RPC (`seminar_registration_count`) that returns just the count, never row contents |
| `monitoring_messages` | own targeted + broadcast, **logged-in only** (0017) | staff manage | The original policy (`patient_id is null or patient_id = auth.uid()`) had no `auth.uid() is not null` guard, so an anonymous caller satisfied the `is null` branch and could read every broadcast message. Fixed in 0017. |
| `daily_videos` | published + within `available_from`/`available_until` window | staff manage | |
| `lab_directory` / `health_kit_directory` / `medicine_info` | public read (published only) | staff manage | Directory/reference content — deliberately public, consistent with BLUEPRINT.md §5.2's Guest role |
| `doctor_contact_info` | **authenticated read only** (0017), published rows | staff manage | Originally `using (published)` with no auth check — a doctor's personal phone/email was fetchable by an anonymous request. Fixed in 0017 to require `auth.uid() is not null`. |
| `consent_records` | self read/insert | admin read | Append-only in practice: no update/delete policy exists, matching DPDP's audit-trail intent |
| `audit_log` | no access | admin read; writes only via service_role | End users cannot read or write this table at all |

**Known gap, not yet closed:** `vitals` has no distinct "lab-sourced write" path — a `source: 'lab'`
row would need to be inserted by staff, but the RLS policy grants full CRUD to `patient_id =
auth.uid()` only; staff have read-only. If lab-sourced vitals become a real feature, add a
`vitals: staff insert lab-sourced` policy scoped to `source = 'lab'` rather than widening patient
access.

**Full re-audit (0017):** every `select`/`insert`/`update`/`delete`/`all` policy across all 17
migrations was re-read end to end for anonymous-caller behavior ahead of production launch. Write
policies were all sound by construction (equality against `auth.uid()` or the `is_staff()`/
`is_admin()` helpers naturally evaluates false for `auth.uid() = null`). Two real read-side gaps
were found and fixed — see the `monitoring_messages` and `doctor_contact_info` rows above. The
remaining public-read tables (articles, seminars, avatars, learn content, daily videos, lab/health
kit/medicine directories) are intentional per BLUEPRINT.md §5.2, not gaps.

## 2. Realtime is a second gate, not a substitute for RLS

Supabase Realtime (Postgres logical replication) and RLS are independent: a table can have
correct RLS and still throw `RealtimeSubscribeException` if it isn't in the `supabase_realtime`
publication (this was hit twice in this project — 0008 and 0011). Realtime respects the *same*
RLS policies as normal queries — a patient's subscription only ever receives rows their own
`select` policy would return. No additional patient-data exposure is introduced by enabling it.

**Cost/scalability note:** each `.stream()` call opens a persistent WebSocket subscription.
`ownVitalsStreamProvider` deliberately merges what could have been 5 separate per-metric
subscriptions into one (filtered client-side instead) — same pattern applied to
`allSeminarsStreamProvider` (one subscription, upcoming/past derived). At current patient-app
scale this is a non-issue; if this becomes a multi-thousand-concurrent-user product, audit total
open Realtime connections per active user (currently: appointments, monitoring_calls, vitals,
meal_plans, medicine_reminders, lab_orders, lab_results, seminars — 8 channels/patient) against
Supabase's plan-tier connection limits.

## 3. Pagination / unbounded-query audit

- `health_articles` (Learn tab): paginated via `.range()`, 20 rows/page, load-more on scroll
  (`_PaginatedArticlesList`). Previously unbounded — a category with hundreds of articles would
  have loaded them all in one query.
- `vitals`: the live stream caps at 500 rows total (`watchOwnVitals(limit: 500)`), and the vital
  detail history list additionally caps *rendered* rows to the most recent 100 per metric.
  Streams don't support offset pagination the way a one-shot query does, so this is a fixed cap,
  not infinite-scroll — acceptable at the "one patient's own readings" scale this table is
  queried at, but revisit if a metric ever needs more than 500 lifetime readings surfaced.
- `lab_orders`/`lab_results`/`meal_plans`/`medicine_reminders`/`seminars`: all capped at
  reasonable limits (30–500 depending on table) via the same live-stream pattern. None were
  paginated before; none had realistic risk of returning thousands of rows for a single
  patient, but the caps are now explicit rather than implicit.
- `provider_directory` (Care tab's "Find a doctor/nutritionist"): **still unbounded.** Low risk
  today (verified-provider counts are small), but if the provider roster grows into the hundreds,
  this needs the same `.range()` treatment `health_articles` got.

## 4. Session handling

- Router redirect (`app_router.dart`) already sends a signed-out user to `/auth/phone`
  automatically via `authStateChangesProvider`.
- Added: a distinct **"Your session expired — please sign in again"** message for unexpected
  sign-outs (token refresh failure), vs. silence for an intentional "Sign out" tap — disambiguated
  via `AuthService.consumeExpectedSignOut()`, since Supabase's SDK fires the same
  `AuthChangeEvent.signedOut` for both cases and gives no other signal to tell them apart.

## 5. Offline handling

`isOfflineProvider` (device-level connectivity via `connectivity_plus`) drives a slim app-wide
banner. This is a **client-side signal only** — it detects "no network path," not "Supabase is
reachable." A patient can be online with Supabase itself down and would see a generic error, not
the offline banner; that's a real distinction the current implementation doesn't make. Riverpod's
`AsyncValue` naturally keeps the last-successful data visible while a stream is between emissions,
so the app already degrades to "stale but visible" rather than "blank" when connectivity drops —
the banner explains that state rather than creating it.

**Partially built:** an offline write queue (sqflite, native only — no web implementation) now
persists a vital logged with no signal and auto-replays it on reconnect, rather than failing
outright. Every other mutation (canceling an appointment, sending a monitoring reply, admin
content edits, etc.) is still not queued — those fail with a SnackBar error and must be retried
manually once back online. Extending the same queue to other mutation types is worth scoping if
offline writes beyond vitals become a real requirement.

## 6. What this document does not cover

- Server-side rate limiting / abuse prevention on Supabase Auth (OTP send frequency etc.) —
  governed by Supabase project settings, not application code.
- Encryption at rest / in transit — inherited from Supabase's infrastructure, not something this
  codebase configures.
- Formal penetration testing — this is a code-level RLS/architecture audit, not a security
  assessment by a third party.
