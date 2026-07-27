# Healthcare Platform — Research Report & Implementation Blueprint

**Status:** Research complete, pending your approval. No code has been written.
**Scope agreed:** India-first launch, solo-developer build, real product for real patients, free-tier infrastructure to start.
**Compiled:** 2026-07-27

---

## 0. How to read this document

This is the single blueprint covering research findings, technology decisions (with reasoning and rejected alternatives), compliance requirements, feature scope, architecture, and a phased implementation roadmap. Six parallel research passes fed into it (mobile/web framework, backend/database/auth, Indian healthcare compliance, competitor/UX research, hosting/deployment, app store publishing). Sources are cited inline as links throughout.

**Nothing here is legal advice.** Section 5 flags specific points where you need an actual Indian healthcare/tech lawyer before real patients are onboarded — those are called out explicitly, not buried.

---

## 1. Executive Summary & Key Decisions

| Decision | Choice | One-line reason |
|---|---|---|
| Mobile + Web framework | **Flutter** (mobile) + **Flutter Web** (authenticated app shell) | Only framework offering a genuinely production-viable single codebase across iOS/Android/Web in 2026; stronger low-end-Android headroom; single first-party HealthKit/Health Connect package |
| Database | **Supabase (Postgres)**, region `ap-south-1` (Mumbai) | Health records are relational (patients↔appointments↔labs↔vitals); native Row-Level Security gives per-patient/per-role isolation for free; not legally mandated to be in India but prudent for latency + data sensitivity |
| Backend | **Supabase as primary** (Auth+DB+Storage+Edge Functions) + a **thin custom Node/NestJS service on Render** only for what Supabase can't do (OTP routing to an Indian SMS aggregator, PDF generation, business workflows) | Avoids a solo dev owning a full custom backend from day one; keeps an escape hatch |
| Auth | **Phone+OTP** (via Indian DLT-registered aggregator, e.g. MSG91 — not Supabase's default Twilio) as primary, **Google Sign-In** secondary, **email/magic-link** for staff roles, **Apple Sign-In** only if iOS ships with other social logins | Phone+OTP is the near-universal expectation in Indian consumer health apps; cost/regulatory realities rule out Twilio-for-India |
| Web hosting | **Cloudflare Pages** | Unlimited free bandwidth + genuinely the best India edge presence (6 in-country PoPs) of any free-tier option |
| Mobile CI/CD | GitHub Actions (Android) + a macOS-capable CI (Codemagic free tier) for iOS, since Flutter (not Expo) is the chosen framework | Avoids burning GitHub's 10x-cost macOS minutes; Codemagic ships native Apple signing infra a solo dev doesn't have to own |
| Compliance backbone | Build to **DPDP Act 2023 / DPDP Rules 2025** standards now (full enforcement ~May 2027), structure "doctor calls" as a **technology-intermediary** connecting to independently licensed RMPs, avoid becoming a drug seller, keep "monitoring calls" strictly non-diagnostic | Deadlines are close enough to build for now; several areas (medicine sales, monitoring-call scope) are genuinely gray zones needing real legal review — flagged in §5 |

**What this buys you:** one codebase for three platforms, a backend you can run on free tiers through real early growth, an auth stack that matches how Indian users actually expect to log in, and a feature set validated against what actually made competitors succeed or fail in this exact market — not a generic health-app template.

**What you're trading away:** Dart is a smaller/slightly pricier hiring pool than JS if you ever add engineers; Supabase's free tier has real walls (500MB DB, 7-day auto-pause) you'll hit before you hit real user-scale limits; and two feature areas (medicine sale/delivery, and the "monitoring calls" module) sit in unresolved Indian regulatory gray zones that no architecture choice can fully de-risk — only a lawyer can.

---

## 2. Technology Stack — Detailed Reasoning

### 2.1 Mobile + Web: Flutter, single codebase

**Alternatives compared:** Flutter, React Native (Expo), .NET MAUI.

- **Performance on India's device mix:** India is 95%+ Android with a large budget/mid-range device install base. 2025/2026 low-end-device benchmarks show Flutter/Impeller holding frame budget more reliably than RN, which runs "right at the frame budget... with no safety margin for GC/decodes" under memory pressure. RN's New Architecture (Fabric/JSI) has closed much of the historical gap for typical CRUD/forms/chart screens on **mid-range-and-better** devices — this is real and not one-sided, so treat "Flutter is faster" as true specifically at the low end, not universally.
- **The deciding factor — can one codebase really cover mobile + web:** Flutter Web is genuinely production-viable as of Flutter 3.38 ("Production Era" — hot reload on web now default, WASM support) for **authenticated, app-like screens** (a patient dashboard, records, booking flows) — exactly what this product is. React Native Web, by contrast, is assessed across multiple independent 2025/2026 sources as **1–2 years away** from the same confidence level; the standard real-world RN pattern is Expo (mobile) + a *separate* Next.js web app in a monorepo — i.e., two rendering systems, not one codebase. Since "one codebase, solo maintainable" was an explicit constraint, this alone tips the decision to Flutter.
- **Healthcare-specific tooling:** Flutter has one actively maintained, first-party `health` package covering both **Apple HealthKit and Android Health Connect** (Google Fit's API is deprecated/closed to new signups since May 2024 — Health Connect is now the *only* forward-compatible path on Android, and Flutter's package already targets it). RN has comparable wrappers but with less consolidated, less actively maintained coverage of this specific niche.
- **.NET MAUI** was ruled out: strong for enterprise/regulated *internal* record-viewer apps, but has no real web story, a thin consumer-facing library ecosystem (OCR/doc-scan/offline-sync), and no evidence of a meaningful India hiring pool — a weak fit for a consumer patient-facing app.

**Caveat carried forward, not hidden:** if you ever need a fast, SEO-indexed public marketing site (for organic patient acquisition), keep that as a small separate static page — Flutter Web is not the right tool for that specific job, but that's a few pages, not a rewrite of the product.

**Supporting libraries selected:** `health` (HealthKit/Health Connect), Scanbot SDK or `flutter_doc_scanner` (offline prescription/lab-report scanning), Hive/SQLite + sync queue (offline-first, patchy-connectivity resilience), FCM + `flutter_local_notifications` (push), `fl_chart`/`syncfusion_flutter_charts` (vitals trend charts).

### 2.2 Database & Backend: Supabase (Postgres) + thin custom API layer

**Alternatives compared:** Supabase, Firebase, Appwrite, PocketBase, Neon, Hasura.

- **Relational data shape rules out NoSQL as primary store.** Patients → appointments → lab orders → results → vitals-over-time all have real foreign-key relationships and need ad-hoc reporting joins ("patients with abnormal HbA1c in 90 days who missed follow-up"). Firestore (Firebase) forces denormalization and manual consistency management for exactly this shape of data — a real cost, not a stylistic preference.
- **Supabase over Firebase:** native Postgres Row-Level Security gives per-patient, per-role data isolation essentially for free — critical both for DPDP's "reasonable security safeguards" requirement and for the planned role expansion (doctor/nutritionist/lab-staff/admin). Firebase's phone-auth now *requires* the paid Blaze plan (no free allowance since Sept 2024) and costs $0.01/verification even at its lowest tier — not actually free either.
- **Supabase over Neon:** Neon has an excellent serverless-Postgres free tier but **no India region** (closest is Singapore/Tokyo) and no built-in auth/storage — you'd be assembling more pieces yourself. Ruled out for this reason alone, despite good specs otherwise.
- **Supabase over PocketBase/Appwrite:** PocketBase (SQLite, single-writer, no built-in backup/HA) is not appropriate for real patient production data despite being genuinely free forever. Appwrite is a credible alternative (self-hosted = fully free, flexible SMS provider plumbing) but its permission model is per-collection, not native Postgres RLS, and self-hosting shifts patching/backup ownership onto you — real overhead for a solo dev not present with managed Supabase.
- **Backend architecture:** Supabase as the data/auth/storage backbone, plus a small custom Node/NestJS service (hosted on Render, free tier to start, $7/mo Starter once you have real non-test users, because Render's free tier sleeps after 15 minutes idle — unacceptable once real patients depend on it) for: routing OTP SMS to an Indian DLT-registered aggregator (not Supabase's default Twilio integration, which is roughly **30x more expensive per SMS** in India than a local aggregator like MSG91), PDF/report generation, and DPDP-specific consent/data-rights endpoints that don't map cleanly to BaaS abstractions. A fully custom backend from scratch is not justified until you have dedicated engineering capacity or a contractual reason (e.g. an enterprise/B2B deal) forcing full control — building one now would just mean a solo dev owns auth, migrations, backups, and scaling that Supabase gives for free.
- **Time-series data (vitals/monitoring):** plain, well-indexed Postgres (partitioned by month if needed) is the right call at MVP scale — not corner-cutting. TimescaleDB's real advantages only matter at volumes far beyond an early product, and since it's a Postgres extension, it's a non-disruptive upgrade path later, not a fork-lift migration.

### 2.3 Authentication

- **Phone+OTP is the default identity in Indian consumer apps**, not email. TRAI mandates **DLT (Distributed Ledger Technology) registration** for any business sending transactional/OTP SMS in India — a one-time regulatory step (entity → sender ID → template, ~₹5,900+GST, 1–3 day approval) that is your obligation regardless of which BaaS you use; no platform resolves it for you.
- Route OTP delivery through an Indian DLT-registered aggregator (MSG91 or similar) via a Supabase Auth Hook rather than Supabase's default Twilio integration — the cost difference is roughly 30x per message at any real user volume.
- **Google Sign-In** as a fast secondary option. **Apple Sign-In** only becomes a hard requirement if the iOS app offers other third-party social logins (Apple's Guideline 4.8) — plan to include it once/if Google Sign-In ships on iOS.
- **Email + magic link** for staff-side roles (doctors, nutritionists, lab staff, admins) — avoids SMS cost entirely for the non-patient-facing side, where email reliability is a safe assumption.
- **Passkeys**: not MVP-blocking, but flagged as a real near-term roadmap item — RBI's Authentication Directions 2025 are pushing two-factor beyond SMS OTP for payments by April 2026, and major Indian consumer apps (PhonePe) are already rolling out passkeys. Build auth as a pluggable layer so this can be added without a rework.

### 2.4 Deployment & Hosting

- **Web:** Cloudflare Pages — unlimited free bandwidth removes the most common free-tier cliff, and it has the strongest India edge presence of any option researched (Mumbai, Chennai, Delhi, Bangalore, Hyderabad, Kolkata PoPs). Vercel (which also gained Mumbai/Chennai PoPs in 2025) is the fallback if Next.js-specific features are ever needed for the small marketing site mentioned in §2.1.
- **Backend/API (if/when the thin custom service is needed):** Render to start (free, sleeps after 15 min — acceptable only pre-launch/testing), moving to the $7/mo Starter tier before any real patient depends on it. Railway and Fly.io are explicitly **not** recommended — both killed their free always-on tiers in 2024–2025, and neither has an India region on the free path anyway. Cloudflare Workers (no cold start, free cron triggers) is a good fit for short webhook/orchestration logic but not for anything long-running (e.g. a call-scheduling worker holding open state).
- **Mobile CI/CD:** since Flutter (not Expo) is the chosen framework, use GitHub Actions for Android builds (1x cost multiplier, cheap) and Codemagic's free tier (500 build-minutes/month, native Apple-silicon macOS runners) for iOS — avoids both buying a Mac and burning GitHub's 10x-multiplier macOS minutes.
- **Monitoring:** Sentry free tier (5,000 events/month, shared error+performance pool) — start with performance tracing **disabled** so the full quota is reserved for actual error events; expect to outgrow this within 3–6 months of real usage.
- **Hard, non-optional costs regardless of stack:** Apple Developer Program $99/year (and per §5.1 below, must be enrolled as an **organization**, not an individual, because health/medical apps trigger Guideline 5.1.1(ix)) — register a company entity, even a small one, before starting Apple enrollment. Google Play Console: $25 one-time, and health apps are being migrated to **organization accounts only** as of Jan 2026.
- **Where each free tier breaks first**, so you're not surprised: Supabase's 500MB DB / 50K MAU walls arrive before real user-scale problems do; GitHub Actions' macOS-minute cliff often arrives within the *first month* of active iOS CI use (hence routing iOS to Codemagic instead); Sentry's 5,000-event ceiling is usually the first "real users" cliff you'll hit.

---

## 3. Compliance & Regulatory Landscape (India)

**This is not legal advice — a qualified Indian healthcare/technology lawyer must review the specific points flagged below before any real patient is onboarded.**

### 3.1 Digital Personal Data Protection Act (DPDP), 2023
- DPDP Rules were notified 13 Nov 2025; full operative provisions (consent, privacy notice, security safeguards) take effect **13 May 2027**. Not yet legally binding, but close enough that architecture should be built to this standard now: granular consent flows, plain-language privacy notice, data export/erasure endpoints, breach-notification workflow (72-hour detailed report to the Data Protection Board), and encryption/access controls.
- No formal "sensitive personal data" tier like the old SPDI rules — DPDP applies a uniform consent-fiduciary framework regardless of category, though health data's high harm-potential should still drive an elevated security posture even without a special legal tier.
- Cross-border data transfer is legally permitted by default (not blacklisted) — Mumbai/`ap-south-1` hosting is a **prudent choice for latency and sensitivity**, not a legal requirement.
- **Needs legal review:** how "harm-based" DPDP obligations specifically apply to health data absent a formal sensitive-category tier.

### 3.2 Telemedicine Practice Guidelines 2020 (NMC) — "Doctor Calls" module
- Only a Registered Medical Practitioner (RMP) may consult/prescribe. Schedule X drugs and narcotic/psychotropic substances (NDPS Act) **cannot** be prescribed via telemedicine at all.
- A platform (not itself a clinic) generally preserves **IT Act Section 79 intermediary safe-harbor** status by: verifying every listed doctor's registration, not itself diagnosing/prescribing/directing clinical judgment, and complying with IT (Intermediary Guidelines) Rules 2021 (privacy policy, ToS, grievance officer).
- **Needs legal review:** platform liability is explicitly described in legal commentary as "unclear" once you add value-added services (matching algorithms, payment facilitation, EHR storage) beyond pure connection — get the ToS structured by counsel to preserve intermediary status.
- **MVP approach:** contract with independently licensed RMPs who bear prescribing/record-keeping responsibility under their own professional obligations; ToS explicit that this is a technology platform, not a healthcare provider.

### 3.3 Ayushman Bharat Digital Mission (ABDM) / ABHA
- Voluntary, not a legal mandate. Over 900M ABHA accounts issued as of mid-2026 and becoming a *de facto* user expectation (and possibly mandatory for hospitals by 2027) — a real trust signal and future distribution advantage, but a genuine engineering lift (HIP/HIU roles, consent-manager flows, FHIR bundling, sandbox certification).
- **MVP verdict:** defer to Phase 2/3. Not urgent, no legal risk in deferring.

### 3.4 Medicine Support — the least legally settled module
- No dedicated e-pharmacy law exists in India (2018 draft rules never notified). Governed by extension of the Drugs & Cosmetics Act 1940/Rules 1945 and Pharmacy Act 1948: Schedule H/H1/X drugs require a valid prescription dispensed only by a registered pharmacist; narcotics/psychotropics/Schedule X **cannot be sold online at all**; active 2023–2025 court/regulator pressure (Delhi HC directives, CDSCO enforcement actions) shows this is a genuinely live area, not settled law.
- **MVP verdict:** if "Medicine Support" means reminders/adherence tracking only, standard consumer-app rules apply, no special risk. **The moment actual purchase/dispensing of prescription medicine is facilitated, this needs real legal review** — either partner with a licensed pharmacy holding its own drug license (the common industry model) or don't build the transactional/dispensing piece at MVP stage.

### 3.5 Clinical Establishments Act — "Monitoring Calls" module
- The sharpest gray area in the entire feature set. A "monitoring calls" feature could read as (a) non-diagnostic wellness/adherence check-ins (fine), or (b) something resembling ongoing clinical case management (risks Clinical Establishments Act registration exposure, which is state-by-state, not uniformly adopted).
- **MVP approach:** script monitoring calls strictly as non-diagnostic wellness/medication-adherence support with clear escalation-to-RMP triggers, kept structurally separate from the actual consultation flow.
- **Needs legal review:** the specific script/scope of this feature, and whether any state you operate in requires registration for what's actually being delivered.

### 3.6 Health Knowledge Library / Blogs — content compliance
- Drugs and Magic Remedies (Objectionable Advertisements) Act 1954 bans false/misleading efficacy claims and advertising "cures" for ~56 listed conditions (cancer, diabetes, etc.). ASCI (self-regulatory, increasingly enforcement-adjacent) flags healthcare as one of the *most* advertising-rule-violative sectors.
- **MVP verdict:** cheap to get right and non-negotiable from day one — no "cure"/guarantee language, cite sources for factual claims, "educational only, not medical advice" disclaimer on every article. Have counsel review the standard disclaimer/editorial checklist once; apply it yourself thereafter — this doesn't need per-article legal review.

### Compliance summary table

| Module | Required now | Gray area | Defer | Legal review needed |
|---|---|---|---|---|
| Data/auth | Privacy notice, consent, security safeguards | Health-data-specific harm tier | SDF-level DPO/audits (unless designated) | Breach plan, retention/erasure policy |
| Education content/blogs | DMR Act / ASCI compliance | Educational vs. medical-advice line | — | One-time disclaimer/checklist review |
| Doctor calls | RMP verification, IT-intermediary due diligence | Liability scope beyond pure intermediary | Own credentialing programs | ToS structuring for safe-harbor |
| Monitoring calls | None specific if non-clinical | Clinical-establishment characterization | Clinical case-management features | Script/scope review |
| Medicine support | None if reminders-only | **Actual drug sale/dispensing** | Own pharmacy license | Partnership structure, Schedule H/X handling |
| Lab tests | General consumer-protection rules | ABDM-level result handling | ABDM/ABHA integration | Result-data handling under DPDP |

---

## 4. Competitor & UX Research Findings

### 4.1 What exists today (India)
Practo (doctor discovery/booking, 200K+ doctors), Tata 1mg (medicine + labs, sells aggregated health-behavior data to pharma/insurers as a B2B stream), MediBuddy (heavily distributed via employer/insurer bundling, ABHA-integrated records), Apollo 24|7 (largest multichannel platform, 19-min pharmacy delivery), PharmEasy/Netmeds (pharmacy-only, badly reviewed on fulfillment), HealthifyMe (AI nutrition/coaching), and the **Cult.fit ecosystem's Sugar.fit** — a diabetes-reversal spinout combining CGM + coach calls + meal plans + check-ins, the closest existing India analogue to this platform's planned meal-guidance + monitoring + coaching combination, and worth studying directly as a positive model.

**mfine is the key cautionary tale**, not a model to copy: raised $80M+, then cut 75% of staff amid a large loss-to-revenue ratio — a **unit-economics failure from aggressive discounting**, not a product failure. Directly relevant since "Daily Monitoring Calls" and "Doctor Calls" are exactly the expensive-to-deliver features that broke mfine's model — price and staff these sustainably from day one, don't subsidize them to acquire users.

### 4.2 Recurring failure patterns across the category (apply as "don't do this" list)
- **Payment/activation desync** — "I paid, but nothing happened in the app" is the single most-repeated complaint (Apollo 24|7, Netmeds, HealthifyMe). Treat payment→activation as a zero-tolerance reliability path in engineering terms, not just a UX nicety.
- **Coach/doctor continuity** — HealthifyMe's top complaint is coaches swapped without handoff. Assign a consistent named provider per patient wherever feasible for Monitoring Calls and Doctor Calls.
- **Post-purchase sales-call harassment** — reported against Apollo 24|7; keep upsells in-app/passive only.
- **Feature-creep UX decay** — Practo reviewers specifically flag the app getting *worse* as features were bolted on. With 10 planned modules, information architecture must be designed to scale from day one (see §6.2), not patched later.
- **Fulfillment/refund failures** (PharmEasy, Netmeds) — directly relevant if "Medicine Support" ever includes actual delivery.

### 4.3 Features validated as expected-but-missing from the current module list
Adding these to the mandatory feature set (§6.1) based on real user/market evidence:
1. **ABHA integration** (health-record auto-import, trust signal, increasingly a default expectation) — Phase 2+.
2. **Digital health-records vault** — persistent storage feeding from lab bookings, not one-off test results.
3. **Family/dependent profiles** — Indian households commonly manage an elder's or child's chronic condition from one adult's phone.
4. **Insurance integration/assistance** — MediBuddy's primary distribution channel; a monetization and trust lever.
5. **Ambulance/SOS button** — present in eldercare-focused apps, absent from mainstream ones; a real differentiator for a chronic-disease platform.
6. **Multilingual support** — repeatedly cited as necessary to reach beyond English-fluent metro users.
7. **UPI-first payments** — table stakes, not optional.

### 4.4 UX principles adopted
- **Navigation:** flat bottom-tab nav won't scale to 10+ modules — group into 4–5 top-level tabs (e.g. Home / Care Team & Calls / Learn / Track / Profile) with modules nested underneath.
- **Color/typography:** blues/greens/soft-white read as trustworthy/calm; avoid harsh pure black-on-white for long-form education content (older/at-risk readers); use tabular (fixed-width) figures for lab values/dosages to prevent dosage misreading — a patient-safety detail most competitors skip.
- **Onboarding:** phone-OTP first, 3–5 steps max (each extra step costs 20–30% of remaining users); make ABHA-based auto-import an optional accelerator, not a mandatory gate (adoption is still only 10–15%).
- **Performance:** explicitly test and target sub-3-second loads on ₹10,000/2GB-RAM Android devices — several "onboarding drop-off" complaints in this category are actually load-time issues misdiagnosed as design issues.
- **Integrated modules, not silos:** present Health Data Monitoring + Daily Meal Guidance + Daily Monitoring Calls as one connected loop (log → insight → coach call → adjusted plan) rather than disconnected tabs, following the Sugar.fit pattern.

---

## 5. Complete Feature Set

### 5.1 Mandatory modules (as specified) + evidence-based additions

**Core content:**
- Health Knowledge Library — 20+ disease/wellness topics (diabetes, hypertension, CKD, cancer, heart disease, obesity, thyroid, liver, respiratory, mental health, women's/men's/child/elderly health, nutrition, lifestyle diseases, fitness, preventive care, vaccination, sleep, stress, immunity), each with: overview, symptoms, causes, risk factors, diagnosis, treatment, lifestyle/diet/exercise guidance, prevention, emergency signs, FAQ, myths-vs-facts, doctor advice, latest guideline references, images/infographics, video, citations.
- Blogs / articles / weekly health updates / medical news / awareness content.
- Online seminars — live sessions, registration, reminders, recordings, speaker profiles, calendar integration.

**Care services:**
- Health Data Monitoring (periodic, 3-month to 1-year cadence check-ins).
- Daily Monitoring Calls (non-diagnostic wellness/adherence coaching — see §3.5 scope constraint).
- Daily Meal Guidance (breakfast/lunch/dinner plans), integrated with monitoring data.
- Laboratory Test Support (booking, results feeding into a persistent records vault).
- Health Device / wearable integration (Health Connect + HealthKit via the `health` package).
- Medicine Support — **MVP scope: reminders/adherence tracking only**; actual sale/dispensing deferred pending legal review (§3.4).
- Doctor Calls (RMP-verified, intermediary-model, in-app video/audio).

**Evidence-driven additions (from §4.3):** digital health-records vault, family/dependent profiles, ambulance/SOS button, multilingual support (Hindi + key regional languages), insurance integration (Phase 2+), ABHA integration (Phase 2+).

**Supporting features (from research + standard product expectations):** appointment scheduling, in-app chat (with providers), push + email + SMS notifications, prescription/report upload with OCR, health timeline, goals/progress tracking, AI assistant (content Q&A/triage-adjacent — non-diagnostic), emergency contact, UPI-first payments + subscriptions, referral system, ratings/feedback, admin dashboard with audit logs, offline mode, search, bookmarks, dark mode, accessibility (screen-reader support, WCAG-aligned contrast), QR/barcode support (for lab reports/prescriptions).

### 5.2 User roles
Guest, Patient (User), Doctor (RMP), Nutritionist/Coach, Lab Staff, Support/Moderator, Admin, Super Admin. Justification: the "Doctor Calls" and "Daily Meal Guidance" modules require distinct provider-side accounts with their own permission scope (RLS policies keyed to role), not just a generic "user" — confirmed necessary by both the compliance research (RMP due-diligence obligations) and competitor research (coach-continuity as a top complaint driver).

---

## 6. Roadmap (Phased)

**Phase 0 — Foundation (compliance + architecture scaffolding, no user-facing features)**
Objectives: stand up Supabase project (Mumbai region), RLS policy skeleton for all planned roles, Flutter project scaffold (mobile+web targets), CI/CD pipelines, DPDP-aligned privacy notice + consent flow, company entity registration (needed for Apple's organization-account requirement), TRAI DLT SMS registration.
Risks: DLT approval delay (1-3 days, plan around it); Apple org enrollment can take longer than individual enrollment.
Acceptance: a signed-up test user can authenticate via phone OTP, see an empty dashboard, and revoke consent/export their data.

**Phase 1 — Content & Trust (Health Knowledge Library, Blogs, Seminars)**
Objectives: ship the education content module end-to-end with the ASCI/DMR-compliant editorial checklist applied to a first batch of ~10 topics; blogs; basic seminar registration.
Deliverable: a genuinely useful, safe, non-clinical app people can use before any paid/clinical feature exists — this is your lowest-legal-risk path to first real users and app-store approval practice.

**Phase 2 — Core Care Loop (Monitoring + Meal Guidance + Monitoring Calls)**
Objectives: build the integrated log→insight→coach-call→adjusted-plan loop (per §4.4), scoped strictly non-diagnostic per §3.5, with named-provider continuity.
Risk: this is the module most likely to need a legal-review pass on scope/script before real launch — schedule that review to land before this phase ships to real users, not after.

**Phase 3 — Doctor Calls + Lab Test Support**
Objectives: RMP verification pipeline, video/audio consultation, ToS intermediary-safe-harbor structuring (needs the legal review flagged in §3.2), lab booking + results vault.
Dependency: cannot ship to real patients until the ToS/liability legal review from §3.2 is complete.

**Phase 4 — Store Launch**
Objectives: Apple org enrollment, medical-device declaration assessment, App Privacy nutrition label, demo account for reviewers, Play Store health-app declaration + data-safety form + first-paragraph medical disclaimer, staged rollout on both stores.
Acceptance: passes both stores' review on first or second submission with the checklists in this document followed.

**Phase 5+ — Expansion**
ABHA/ABDM integration, family/dependent profiles, insurance integration, medicine sale/delivery (only after the §3.4 legal review concludes it's viable and a pharmacy partnership is in place), passkey auth, multilingual expansion.

---

## 7. What still needs your input before Phase 0 starts

1. **Legal counsel engagement** — for §3.2 (doctor-call ToS/liability), §3.4 (medicine support scope), and §3.5 (monitoring-call scope). These are flagged, not resolved, in this document.
2. **Company entity** — Apple's organization-account requirement for health apps means you need a registered business entity before Apple Developer Program enrollment; confirm you have one or plan to register one.
3. **Provider sourcing** — who the actual RMPs/nutritionists/lab partners are is a business decision this document doesn't make for you.
4. **Content authorship** — the Health Knowledge Library needs either your own medically-reviewed writing or a licensed content source; this blueprint doesn't write medical content.

---

Once you approve this blueprint (as-is or with changes), Phase 0 implementation can begin: Supabase project setup, Flutter scaffold, and CI/CD pipeline.
