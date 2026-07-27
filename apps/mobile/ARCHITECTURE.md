# App Architecture

Read `pubspec.yaml` first for the dependency choices and their reasoning. This file covers how
`lib/` is organized. Written now, ahead of Flutter being installed, so real Dart code can start
immediately once `flutter create` backfills the `android/`, `ios/`, `web/` folders — no design
decisions left to make in that moment.

## Folder structure

```
lib/
  main.dart                    App entry: loads .env, initializes Supabase, wraps app in
                                ProviderScope (Riverpod) and MaterialApp.router (go_router)

  core/
    theme/app_theme.dart        Color scheme + typography — BLUEPRINT.md §4.4: blue/green/soft-
                                 white palette, tabular figures for lab values/dosages
    router/app_router.dart      go_router config — see Navigation shell below
    supabase/supabase_client.dart   Thin wrapper exposing the initialized Supabase client via a
                                 Riverpod Provider, so screens never call Supabase.instance
                                 directly (keeps testing/mocking possible)
    widgets/                    Shared widgets (loading states, error states, empty states —
                                 BLUEPRINT.md UI/UX section calls these out explicitly)

  features/
    auth/                      Phone+OTP (primary), Google Sign-In (secondary) — BLUEPRINT.md §2.3
    onboarding/                Consent screens implementing docs/consent-flow-draft.md exactly
    home/                      Dashboard — entry point after auth, surfaces upcoming
                                 appointments/monitoring calls and recent vitals at a glance
    learn/                     Health Knowledge Library + Blogs + Seminars (reads
                                 health_articles/seminars tables — public read, no auth required
                                 for browsing per the RLS policies in supabase/migrations/0007)
    care/                      Doctor Calls + Daily Monitoring Calls — booking, call screens,
                                 named-provider continuity display (BLUEPRINT.md §4.2: don't
                                 silently swap providers)
    track/                     Health Data Monitoring (vitals entry/trends) + Daily Meal Guidance
                                 + Medicine Reminders + Health Device (HealthKit/Health Connect)
                                 sync — presented as one connected loop, not separate tabs,
                                 per BLUEPRINT.md §4.4
    labs/                      Laboratory Test Support + results vault
    profile/                   Account settings, consent management (withdrawal per
                                 docs/consent-flow-draft.md), family/dependent profiles,
                                 language selection

  models/                      Plain Dart classes mirroring the Postgres schema in
                                 supabase/migrations/ — one file per table, hand-kept in sync
                                 (no codegen yet; revisit if this becomes error-prone)

  services/                     One service per feature area wrapping Supabase queries (e.g.
                                 VitalsService, AppointmentService) — screens call services, never
                                 raw Supabase queries, so RLS-dependent query logic lives in one
                                 place per feature

test/                          Mirrors lib/ structure; every service gets a unit test against a
                                 mocked Supabase client
```

## Navigation shell

Bottom-tab shell with 5 top-level destinations, per BLUEPRINT.md §4.4 (a flat nav across 10+
modules doesn't scale — this is the direct fix):

1. **Home** — dashboard
2. **Care** — Doctor Calls + Monitoring Calls (nested: upcoming, book, call history)
3. **Learn** — Health Knowledge Library + Blogs + Seminars
4. **Track** — Vitals + Meal Guidance + Medicine Reminders + Device sync
5. **Profile** — account, consent, family profiles, settings

Implemented as a `StatefulShellRoute` in go_router so each tab keeps its own navigation stack
(switching tabs doesn't lose your place in a nested flow) — this is the specific go_router
feature that motivated choosing it in `pubspec.yaml`.

## State management convention

- Data fetching/mutation: `AsyncNotifierProvider` per feature (e.g. `VitalsNotifier`), backed by
  a `services/` class — never call Supabase directly from a widget.
- Realtime (e.g. live appointment status): `StreamProvider` wrapping the relevant Supabase
  realtime channel.
- Pure UI state (form input, toggles): local `StateProvider` or plain `StatefulWidget` where
  Riverpod would be overkill — don't reach for global state management for things that are
  genuinely local to one screen.

## What's intentionally not decided yet

- Exact design tokens (spacing scale, exact hex values) — belongs in `core/theme/app_theme.dart`
  once written, not this doc; will follow BLUEPRINT.md §4.4's color/typography direction.
- Whether a codegen tool (freezed, json_serializable) is worth adopting for `models/` — start
  hand-written since the schema is still young; revisit once models get numerous/error-prone.
