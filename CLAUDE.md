# RecySetu (formerly Kabadiwala Connect) — project rules for Claude Code

## What this is
SIH 2026 problem statement SIH26229 (Ministry of Mines, Clean & Green Technology).
An offline-first, low-literacy, multilingual Android app that helps informal scrap
collectors (kabadiwalas) sell e-waste to authorised recyclers at fair prices, with a
tamper-evident digital handover record and an earnings ledger.

The full build plan is in `docs/PLAN.md`. Read it before starting any phase.
Work ONE phase at a time, in order, unless the user says otherwise.

## Who you are working with
- A team of first-year engineering students. They know basic Python, NOT Dart/Flutter.
- After finishing each phase, write a short plain-English summary: what files you
  created, what each one does, and how to run/test it. Avoid jargon or explain it.
- When the user must do something you cannot (Firebase console, `flutterfire configure`,
  plugging in a phone, recording audio), stop and give numbered steps.

## The one demo that must work
A collector with no signal: photographs scrap -> picks category by picture -> enters
weight -> HEARS a fair price -> sees ranked authorised recyclers -> completes a
handover that produces a verifiable QR reference -> ledger updates -> everything
syncs when internet returns. Never break this flow. Build it before any extras.

## Tech stack (do not change without asking)
- Flutter (stable channel), Dart, Android only. minSdk 23. Target cheap phones (2 GB RAM).
- State management: flutter_riverpod.
- Backend: Firebase (Auth, Cloud Firestore with offline persistence). Free Spark plan only.
- Photos: compressed on-device, queued locally, uploaded when online (see PLAN.md §5).
- Audio: flutter_tts for languages Android TTS supports; recorded clips otherwise.
- Hashing: `crypto` package, SHA-256.
- Python is used only for scripts in `scripts/` and `analysis/` (seed data, unit economics).
- Before adding any package not listed in PLAN.md §3, say why and ask.
- Verify current package versions on pub.dev; don't guess version numbers.

## Hard design rules (low-literacy UX)
1. No screen may REQUIRE reading. Every action = big icon + 1-2 words + audio.
2. Max 4 main choices per screen. Touch targets at least 56 dp.
3. Numbers (₹, kg) shown huge. Prices are always spoken, not just displayed.
4. Colour is never the only signal: green+tick = confirmed, amber+clock = pending,
   red+warning = hazard.
5. Everything works offline after the first login. Show a small sync icon, never block.
6. Cash is a first-class payment option, equal to UPI.
7. All user-facing text comes from `assets/i18n/<lang>.json` — never hard-code strings.

## Code rules
- Folder layout is in PLAN.md §4. Keep features in `lib/features/<feature>/`.
- Core logic (valuation, ranking, hashing, number-to-audio, sync queue) lives in
  plain Dart classes with unit tests in `test/`. No business logic inside widgets.
- Store weight in grams (int) and money in paise (int). Never use double for money.
- Timestamps in UTC; display in local time.
- After every phase run `flutter analyze` and `flutter test` and fix all issues.
- Commit at the end of each phase: `git commit -m "Phase N: <name>"`.
- Never commit secrets or service-account keys. `scripts/serviceAccount.json` is gitignored.
- Keep the release APK small (target under 30 MB). Report the size in Phase 11.

## Data honesty
- Prices, recyclers and materials come from the team's field study (`data/*.csv`).
- If data is missing, use clearly marked placeholder rows (`"placeholder": true`)
  and tell the user. Never invent real business names or phone numbers.
