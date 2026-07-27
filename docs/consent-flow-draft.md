# Onboarding Consent Flow — Draft

> **Status: DRAFT.** Screen-by-screen copy and logic for the signup consent flow, written to
> DPDP Act 2023 standards (BLUEPRINT.md §3.1: consent must be free, specific, informed,
> unconditional, unambiguous, and revocable as easily as it was given). Pair with
> `privacy-notice-draft.md`. Needs legal sign-off before shipping, same as the notice.

## Design principle

Consent is **layered**, not one giant checkbox: essential-to-function consent is separated from
optional consent, so declining optional items never blocks account creation. This directly
implements DPDP's "unconditional" requirement and BLUEPRINT.md §4.4's onboarding-friction
research (every extra mandatory step costs 20–30% of remaining signups) — optionality here also
protects conversion.

## Screen 1 — Account creation (phone/OTP or Google)

No consent screen yet — just identity. Consent comes immediately after, before any health data
is collected.

## Screen 2 — Essential consent (blocking, required to proceed)

> **Before we get started**
>
> To create your account and keep it secure, we need your agreement to two things:
>
> ☐ I've read and agree to the [Terms of Service] and [Privacy Notice].
> ☐ I understand [App Name] connects me with independent, licensed healthcare professionals and
>   does not itself provide medical diagnosis or treatment. *(links to full disclaimer)*
>
> [Continue] — disabled until both are checked.

Implementation note: writes two rows to `consent_records` (`consent_type = 'terms_of_service'`,
`consent_type = 'platform_role_disclaimer'`), `policy_version` = the currently published version
string, `granted = true`, `granted_at = now()`.

## Screen 3 — Optional consent (skippable, each independently toggleable)

> **A couple of optional things**
>
> ☐ Share my health data with a doctor or coach *only when I book a consultation with them*
>   (you can turn this off later, but you won't be able to book calls without it).
> ☐ Send me appointment reminders and health tips by SMS/WhatsApp.
> ☐ Send me occasional product updates and offers by email.
>
> [Finish setup] — enabled regardless of checkbox state.

Implementation note: each checkbox is its own `consent_records` row
(`health_data_sharing_with_provider`, `reminder_comms`, `marketing_comms`). Declining
`health_data_sharing_with_provider` doesn't block signup, but the booking flow for Doctor
Calls/Monitoring Calls must check this consent and prompt for it at that point if missing,
rather than assuming it was granted at signup.

## Withdrawal path (Settings → Privacy)

Each consent from Screens 2–3 is listed individually with its current status and a toggle.
Turning off `terms_of_service` or `platform_role_disclaimer` triggers an account-deactivation
confirmation (you can't use the Platform without agreeing to these), not silent data deletion —
avoids accidental account loss. Turning off any optional consent takes effect immediately and
writes a new `consent_records` row (`granted = false`, `revoked_at = now()`) rather than mutating
the original row, preserving history for audit purposes.

## What still needs legal input

1. Exact wording of the "platform role disclaimer" checkbox — must match the ToS structuring
   decided for intermediary safe-harbor status (BLUEPRINT.md §3.2).
2. Whether `health_data_sharing_with_provider` consent needs to be re-confirmed per-provider or
   is valid platform-wide once granted — affects both UX and the booking-flow implementation
   note above.
3. Minimum age / parental-consent flow if the Platform allows dependent profiles for minors
   (BLUEPRINT.md §5.1 family/dependent profiles) — DPDP has specific provisions for children's
   data that this draft does not yet address.
