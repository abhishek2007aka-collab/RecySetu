# Kabadiwala Connect — Full Build Plan

SIH26229 · Offline-first, multilingual, low-literacy e-waste app for informal collectors.
Read `CLAUDE.md` first. Build phases in order. Each phase lists: goal, tasks,
files, and "Done when" checks. Do not start the next phase until "Done when" passes.

---

## 1. Product summary

**Users**
- **Collector (kabadiwala):** low literacy, cheap Android phone, patchy internet,
  speaks Hindi or a local language, often paid in cash.
- **Recycler:** authorised e-waste recycler/dismantler. Sets rates, receives lots,
  confirms handovers by scanning a QR code. Uses the same app in "recycler mode".
- **Admin (team):** updates price board and recycler list (Firestore console or
  Python script for the prototype).

**Core loop**
1. Collector photographs a lot of scrap and picks its category from picture tiles.
2. Enters approximate weight with big +/- buttons.
3. App speaks a fair-price estimate from the price board.
4. App shows nearby authorised recyclers ranked by rate, distance, pickup.
5. At handover the app creates a record (photos, weight, GPS, time) and a SHA-256
   hash, shown as a QR code.
6. Recycler scans the QR, the app re-checks the hash, recycler enters measured weight
   and payment (cash/UPI), and confirms.
7. Collector's ledger shows the payment or the money still due.
8. All of this works offline and syncs later.

**Out of scope for the prototype:** real payments, KYC, government integration,
iOS, chat between users, maps SDK (we use a simple distance list instead).

---

## 2. Languages

Language list is decided by the field study. Ship in this order:

| Code | Language | Audio source | Status |
|---|---|---|---|
| `hi` | Hindi | Android TTS + recorded number clips (optional) | Required, default |
| `en` | English | Android TTS | For judges / demo only |
| `mr` | Marathi | Android TTS | Required by the problem statement |
| `LOCAL_1` | e.g. `gbm` Garhwali | Recorded clips only | Set after field study |
| `LOCAL_2` | e.g. `bho` Bhojpuri or `bn` Bengali | Recorded clips (`bn` can use TTS) | Set after field study |

**Rules**
- Do NOT use Flutter's built-in `gen-l10n` locale system for the app's own text,
  because Garhwali/Bhojpuri have no Flutter locale data. Use our own `AppStrings`
  loader reading `assets/i18n/<code>.json`. Keep `MaterialApp.locale` as `hi`
  (or `en` when English is selected) for system widgets.
- Garhwali and Bhojpuri text is written in Devanagari.
- Every string key may have a recorded clip at `assets/audio/<code>/<key>.mp3`.
- Number clips for recorded languages: `assets/audio/<code>/num/<n>.mp3` for
  n = 0..99, plus `hundred.mp3`, `thousand.mp3`, `lakh.mp3`, `rupees.mp3`,
  `kilo.mp3`, `about.mp3`. (Hindi-family number names are irregular, so all 0..99 are
  needed.)

**AudioService.speak(key, {params})** decides in this order:
1. Recorded clip exists for (language, key) -> play it; numbers in `params` are
   composed from number clips.
2. Else, Android TTS supports the language (check `flutter_tts.isLanguageAvailable`)
   -> speak the translated string with params filled in.
3. Else -> speak the Hindi string with Hindi TTS.

---

## 3. Packages (verify latest compatible versions on pub.dev)

| Purpose | Package |
|---|---|
| State | `flutter_riverpod` |
| Firebase | `firebase_core`, `firebase_auth`, `cloud_firestore` |
| Photo upload (only if available on free plan, see §5) | `firebase_storage` |
| Camera | `image_picker` |
| Compression | `flutter_image_compress` |
| Location | `geolocator` |
| Text-to-speech | `flutter_tts` |
| Clip playback | `just_audio` |
| QR create / scan | `qr_flutter`, `mobile_scanner` |
| Hashing | `crypto` |
| Phone call button | `url_launcher` |
| Connectivity | `connectivity_plus` |
| Local key-value | `shared_preferences` |
| Files | `path_provider` |
| IDs | `uuid` |
| Formatting | `intl` |
| Optional AI (Phase 12) | `tflite_flutter` |

Python scripts: `firebase-admin`, `pandas`.

---

## 4. Repository layout

```
kabadiwala-connect/
├── CLAUDE.md
├── docs/
│   ├── PLAN.md
│   └── field-study/            # notes, photos list, interview answers
├── data/                       # field-study data, edited by the team
│   ├── materials.csv
│   ├── prices.csv
│   └── recyclers.csv
├── scripts/
│   ├── seed_firestore.py       # CSV -> Firestore
│   └── csv_to_assets.py        # CSV -> app/assets/seed/*.json (offline fallback)
├── analysis/
│   └── unit_economics.py       # formal vs informal earnings comparison
├── firestore.rules
└── app/                        # Flutter project
    ├── lib/
    │   ├── main.dart
    │   ├── core/
    │   │   ├── i18n/           # AppStrings loader, language list
    │   │   ├── audio/          # AudioService, NumberSpeaker
    │   │   ├── theme/          # big-button theme, colours, icons
    │   │   ├── geo/            # haversine, location helper
    │   │   ├── hash/           # HandoverHasher
    │   │   └── sync/           # PhotoQueue, SyncStatus
    │   ├── data/
    │   │   ├── models/         # Material, Price, Recycler, Lot, Handover, LedgerEntry, AppUser
    │   │   ├── repositories/   # one per collection
    │   │   └── seed/           # load assets/seed/*.json when Firestore cache is empty
    │   └── features/
    │       ├── onboarding/     # language pick, login, PIN, role
    │       ├── home/
    │       ├── sell_lot/
    │       ├── prices/
    │       ├── recyclers/
    │       ├── handover/
    │       ├── ledger/
    │       ├── safety/
    │       └── recycler_mode/  # scan QR, verify, confirm, set rates
    ├── assets/
    │   ├── i18n/               # hi.json, en.json, mr.json, <local>.json
    │   ├── audio/<lang>/       # recorded clips
    │   ├── icons/              # material and action icons (original/open-licence only)
    │   ├── safety/             # safety illustrations
    │   └── seed/               # materials.json, prices.json, recyclers.json
    └── test/
```

---

## 5. Data model (Firestore)

All money in **paise (int)**, all weight in **grams (int)**, all time **UTC**.

**`materials/{code}`**
`code` (e.g. `PCB`, `CABLE_CU`, `BATTERY_LI`, `BATTERY_PB`, `CRT`, `MOTOR`,
`PLASTIC_MIX`, `PHONE`), `iconAsset`, `hazard` (`none|low|high`),
`safetyCardIds` (list), `nameKey` (i18n key).

**`prices/{materialCode}`**
`currentLowPaisePerKg`, `currentHighPaisePerKg`, `weekAgoMidPaisePerKg`,
`updatedAt`, `source` (`field_study|recycler|admin`).

**`recyclers/{id}`**
`name`, `phone`, `lat`, `lng`, `address`, `authorised` (bool),
`authorisationRef` (string, e.g. registration number from the official list),
`offersPickup` (bool), `ratesPaisePerKg` (map materialCode -> int),
`ownerUid` (recycler's login, nullable), `placeholder` (bool).

**`users/{uid}`**
`role` (`collector|recycler|admin`), `phone`, `language`, `name` (optional),
`createdAt`.

**`lots/{id}`** (id = UUID made on device)
`collectorUid`, `materialCode`, `weightGrams`, `estLowPaise`, `estHighPaise`,
`photoHashes` (list of sha256 hex), `photoUrls` (filled after upload),
`lat`, `lng`, `createdAt`, `status` (`draft|ready|handed_over`).

**`handovers/{id}`** (id = UUID made on device)
`lotId`, `collectorUid`, `recyclerId`, `materialCode`, `weightGrams`,
`agreedPaise`, `createdAt`, `lat`, `lng`, `photosHash`, `hash`,
`status` (`pending|confirmed|disputed`),
`confirmedAt`, `measuredWeightGrams`, `paidPaise`, `paymentMode` (`cash|upi|due`),
`flags` (list, e.g. `weight_mismatch`, `hash_mismatch`).

**`ledger/{id}`**
`collectorUid`, `type` (`handover|sold_elsewhere|manual`), `handoverId` (nullable),
`amountPaise`, `paidPaise`, `paymentMode`, `createdAt`, `note`.
(`sold_elsewhere` keeps the ledger honest when they sell to a local dealer.)

**Photos (§ storage decision)**
- At capture: compress to max 1280 px, JPEG quality 70. Save in app documents dir.
  Compute sha256 of the compressed bytes immediately -> `photoHashes`.
- `PhotoQueue` uploads pending photos when online, then writes `photoUrls`.
- Claude Code: check whether Cloud Storage for Firebase is usable on the free
  Spark plan for a NEW project at build time. If it is not, use the fallback:
  store a 480 px, quality 60 thumbnail (keep under 200 KB) as base64 in
  `lots/{id}/photos/{n}` sub-documents. Tell the user which option you used.

**Offline**
- Firestore offline persistence is on by default on Android; keep it on.
- On first launch after login, if `materials/prices/recyclers` cache is empty and
  device is offline, load `assets/seed/*.json`.

**`firestore.rules` (prototype level)**
- Users read/write only their own `users/{uid}`, `lots`, `ledger`.
- `materials`, `prices`, `recyclers`: read for signed-in users; write for admin.
- `handovers`: collector creates; the recycler whose `ownerUid` matches
  `recyclerId` may update only the confirmation fields.

---

## 6. Core logic specs (all unit-tested)

### 6.1 Valuation
```
estLow  = weightGrams * currentLowPaisePerKg  / 1000
estHigh = weightGrams * currentHighPaisePerKg / 1000
spoken  = round((estLow + estHigh) / 2) to nearest ₹10
```
Speech (Hindi example): "लगभग 340 रुपये मिलेंगे" (key `price_estimate`, param `amount`).

### 6.2 Price trend
`mid = (low + high) / 2`. Compare with `weekAgoMidPaisePerKg`:
up if > +5%, down if < -5%, else flat. Show arrow icon + speak "बढ़ा / घटा / वही".

### 6.3 Recycler ranking (for one material)
```
candidates = recyclers where authorised == true and rate for material exists
d          = haversine km from collector
rateScore  = rate / max(rate in candidates)
distScore  = 1 - min(d, 25) / 25
score      = 0.45*rateScore + 0.35*distScore + 0.20*(offersPickup ? 1 : 0)
sort by score desc
```
Show top 5. Unauthorised recyclers are hidden by default (the whole point is
the formal route). Each row: authorised badge, distance, rate per kg,
estimated payout for this lot, big call button, select button.

### 6.4 Handover hash (tamper-evident reference)
```
photosHash = sha256( join(sorted(photoHashes), "") )
canonical  = "v1|" + id + "|" + collectorUid + "|" + recyclerId + "|" +
             materialCode + "|" + weightGrams + "|" + agreedPaise + "|" +
             createdAtEpochSeconds + "|" + lat(5 dp) + "|" + lng(5 dp) + "|" +
             photosHash
hash       = sha256(canonical) as lowercase hex
```
**QR payload** (compact JSON):
`{"v":1,"id":..,"c":..,"r":..,"m":..,"w":..,"a":..,"t":..,"la":..,"lo":..,"ph":photosHash,"h":hash}`
Short reference shown under QR = first 8 chars of hash, uppercase, split 4-4
(e.g. `A3F9-1C2B`) so it can be read aloud over the phone.

Recycler verify: recompute hash from QR fields. Match -> OK. No match -> flag
`hash_mismatch` and show red warning. Note in the UI/docs: this proves the record
was not changed after creation; it is not a legal signature.

### 6.5 Anomaly flags (rule-based)
- `weight_mismatch`: |measured - declared| / declared > 10%.
- `price_outlier`: agreed price outside [0.7 × low, 1.3 × high] of the price board.
- `hazard_unsafe`: material hazard = high and collector has not opened its safety card.

### 6.6 NumberSpeaker (recorded languages)
Turn an integer rupee amount into a list of clip files:
`about` + number parts (lakh, thousand, hundred, 0..99) + `rupees`.
Example 1,340 -> `num/1`, `thousand`, `num/3`, `hundred`, `num/40`, `rupees`.
Unit-test 0, 7, 40, 99, 100, 340, 1000, 1340, 99999, 150000.

---

## 7. Screens

All screens: top bar with speaker button (replays screen instructions) and sync icon.

| # | Screen | Main elements |
|---|---|---|
| S1 | Language pick | Grid of big buttons; tapping plays the language name; second tap selects |
| S2 | Login | Phone number keypad (big), OTP. Use Firebase test phone numbers for dev/demo |
| S3 | PIN set / unlock | 4-digit PIN for quick offline unlock on this device |
| S4 | Role | Collector / Recycler (recycler only if phone matches a recycler `ownerUid` invite) |
| S5 | Home (collector) | 4 tiles: Sell scrap, Today's rates, My earnings, Safety |
| S6 | Sell: photo | Camera button, up to 3 photos, retake |
| S7 | Sell: category | Picture tiles of materials, 2 columns, hazard icon on dangerous ones |
| S8 | Sell: weight | Huge number, buttons -1, -0.5, +0.5, +1, +5 kg; optional keypad |
| S9 | Sell: estimate | Spoken price range, "Find recycler" button |
| S10 | Recyclers | Ranked list (§6.3) |
| S11 | Handover | Summary + QR + short reference; status pending/confirmed |
| S12 | Rates board | Material tiles with ₹/kg and trend arrows; tap = speak |
| S13 | Ledger | Today / this week totals, list of entries, cash/UPI/due icons, "Add sale elsewhere" |
| S14 | Safety | Cards with illustration + audio: no burning cables, don't break CRTs, keep batteries away from fire/water, gloves for PCBs, no acid stripping |
| R1 | Recycler home | Scan QR, My rates, Recent handovers |
| R2 | Scan + verify | Camera scanner, hash check result, enter measured weight, payment mode, confirm |
| R3 | My rates | Edit ₹/kg per material |

---

## 8. Phases

Use plan mode for each phase: first propose the plan, wait for approval, then build.
Suggested prompt to start each phase: **"Read docs/PLAN.md and do Phase N."**

### Phase 0 — Setup and scaffolding
- `flutter create app --org in.kabadiwalaconnect --platforms android`.
- Add packages from §3 (not `tflite_flutter`, not `firebase_storage` yet).
- Create folder layout §4, `.gitignore` (include `scripts/serviceAccount.json`).
- Big-button theme: min touch 56 dp, large font scale, high contrast, Material 3.
- Give the user numbered steps to: create a Firebase project, enable Phone auth
  and add test phone numbers, create Firestore, run `flutterfire configure`.
- **Done when:** app runs on a phone/emulator showing a placeholder home screen,
  Firebase initialises without errors, `flutter analyze` is clean.

### Phase 1 — Data layer and seed data
- Models (§5) with `toMap/fromMap`, repositories with streams.
- CSV templates in `data/` with headers and 2-3 placeholder rows each.
- `scripts/csv_to_assets.py` and `scripts/seed_firestore.py` (Python, pandas,
  firebase-admin; reads `scripts/serviceAccount.json`).
- Seed loader for offline first-run.
- `firestore.rules` (§5).
- **Done when:** seed script fills Firestore; app lists materials and prices from
  Firestore, and from assets when started offline with empty cache; model tests pass.

### Phase 2 — Languages and audio engine
- `AppStrings` loader, language registry (§2), `hi.json`, `en.json`, `mr.json`
  with every key used so far, plus `LOCAL_1.json` copy of Hindi marked TODO.
- `AudioService` with the 3-step fallback (§2) and `NumberSpeaker` (§6.6).
- A hidden debug screen listing every key with a play button (for checking audio).
- Script `scripts/check_i18n.py`: reports keys missing in any language file and
  missing audio clips for recorded languages.
- **Done when:** switching language changes all text instantly; prices are spoken
  in hi/en/mr via TTS; NumberSpeaker tests pass; check_i18n runs.

### Phase 3 — Onboarding and home
- S1–S5. Language choice and PIN stored in `shared_preferences`.
- After first online login, app opens offline with PIN only.
- **Done when:** fresh install -> language -> login with test number -> PIN ->
  home; kill app, airplane mode, reopen -> PIN -> home works.

### Phase 4 — Sell-lot flow
- S6–S9. Photo capture + compression + photo hash (§5). Lot saved as `draft`
  immediately (offline write). Valuation (§6.1) spoken on S9.
- `PhotoQueue` (upload or thumbnail fallback, §5) with retry on connectivity change.
- **Done when:** in airplane mode, full photo->category->weight->spoken price works,
  lot appears in Firestore after reconnecting; valuation tests pass.

### Phase 5 — Rates board
- S12 with trend arrows (§6.2), tap to speak "PCB: 180 to 220 rupees per kilo".
- **Done when:** trend logic tests pass; works offline from cache.

### Phase 6 — Recycler matching
- Location permission flow with audio explanation; if denied, let user pick their
  area from a short list (store area centroid lat/lng in seed data).
- S10 with ranking (§6.3), call button via `url_launcher` (`tel:`).
- **Done when:** ranking tests pass (include ties, missing rates, distance cap);
  list works offline.

### Phase 7 — Handover, hash and QR
- S11: create `handovers/{id}` (status `pending`) + GPS + hash (§6.4) + QR + short
  reference spoken digit by digit.
- Recycler mode R1–R3: scan, verify, measured weight, payment mode
  (cash / UPI / due), confirm; anomaly flags (§6.5).
- Collector screen updates to `confirmed` when the confirmation syncs.
- **Done when:** hash tests pass (same input same hash; any field change changes
  hash); two phones: collector offline creates handover, recycler scans and
  confirms, collector sees confirmed after reconnecting; tampered QR shows red warning.

### Phase 8 — Ledger
- S13. Auto entries from confirmed handovers; `due` shown separately;
  "Add sale elsewhere" with category + amount (keypad) + cash/UPI.
- Speaker button reads "Aaj 640 rupaye mile, 200 rupaye baaki" style summary.
- **Done when:** totals are correct in tests (paise math, dues, week boundary in
  local time); works offline.

### Phase 9 — Safety guide
- S14 cards. Opening a high-hazard material in S7 auto-plays its safety card once.
- Use original simple illustrations (team-drawn or open-licence icons only).
- **Done when:** every high-hazard material links to at least one card with audio.

### Phase 10 — Sync robustness
- Sync icon states: synced / pending (count) / offline.
- Retry with backoff for photos; no duplicate lots or ledger entries (IDs made on
  device, writes are idempotent).
- Written manual test checklist `docs/offline-test.md`: airplane mode at each step,
  app killed mid-flow, phone restarted while pending.
- **Done when:** the whole checklist passes on a real low-end phone.

### Phase 11 — Polish and accessibility
- Check every screen against CLAUDE.md design rules; fix violations.
- Check text fits at largest system font size.
- Build release APK, report size; reduce if over 30 MB (split ABIs, compress assets).
- Startup time and scrolling smooth on a 2 GB RAM phone.
- **Done when:** a non-reader can finish the sell flow using only icons and audio
  (test with a real collector or someone pretending not to read).

### Phase 12 — Optional extras (only after Phase 11)
- **12a On-device material classifier:** team trains a model in Google Teachable
  Machine using field photos (classes = material codes), exports TFLite. App
  pre-selects the predicted tile in S7 if confidence > 0.7; user can always change.
  Report accuracy honestly on a held-out set of photos.
- **12b Admin price editor:** small screen for admin role to update prices.
- **12c Local languages:** load recorded clips for LOCAL_1/LOCAL_2; run check_i18n.
- **12d Unit economics script:** `analysis/unit_economics.py` reads
  `data/prices.csv` (columns: material, informal_dealer_rate, recycler_rate,
  transport_cost_per_kg) and prints a table + chart (matplotlib PNG) of extra
  earnings per kg and per month for a typical collector volume.

### Phase 13 — Demo mode
- Settings toggle "Demo data": loads a scripted set of recyclers near the demo
  venue, sample prices, a reset button.
- Write `docs/demo-script.md`: 3-minute walkthrough, offline the whole time,
  switching between two languages, ending with sync.
- **Done when:** demo runs start-to-finish three times in a row without a bug.

---

## 9. Timeline (8 weeks, team of 6)

| Week | Claude Code phases | Team work outside code |
|---|---|---|
| 1 | 0 | Field study with at least 2 kabadiwalas + 1 aggregator; fill `data/*.csv`; decide local languages |
| 2 | 1, 2 | Paper prototypes tested with collectors; write translations |
| 3 | 3, 4 | Record audio clips for local languages (native speakers) |
| 4 | 5, 6 | Collect authorised recycler list for the region |
| 5 | 7 | Ask one recycler to try recycler mode |
| 6 | 8, 9 | Draw safety illustrations |
| 7 | 10, 11, 12 (pick) | Real-collector usability test, note problems |
| 8 | 13 | PPT, unit-economics slide, demo video, rehearsal |

---

## 10. Field study checklist (docs/field-study/)
- Phone model, Android version, storage free, data pack habits.
- Can they read Hindi? Numbers? Which language do they prefer to LISTEN to?
- What e-waste they get, monthly kg per type, who they sell it to, at what rate.
- How they are paid (cash/UPI), how often they are underpaid or cheated.
- What they know about hazards (burning cables, breaking CRTs, batteries).
- Would they travel to a recycler? How far? Do they need pickup?
- Take photos of real scrap (with permission) for the classifier dataset.
- Record 2-3 quotes (with permission) for the PPT.
