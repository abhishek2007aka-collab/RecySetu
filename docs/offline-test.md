# Offline test checklist (Phase 10)

Run this on a real, cheap Android phone before every demo. Tick each box.
Use test number `+91 99999 00001` (collector) and `+91 99999 00002` (recycler).

**Sync icon** (top bar): green cloud with tick = all sent · amber cloud with a
number = that many records waiting · grey crossed cloud = no internet (app still works).

## A. Airplane mode at each step (collector)
- [ ] Turn airplane mode ON. Open the app: PIN screen appears, PIN unlocks, home opens.
- [ ] Sell scrap → photo → category → weight → price is spoken. No error, no spinner forever.
- [ ] Find recycler → list appears (from saved data). Choose → QR receipt appears with amber "waiting".
- [ ] Sync icon shows grey (offline). Tap it: it says the app still works.
- [ ] Today's rates opens and speaks rates. My earnings opens. Safety opens.
- [ ] Turn airplane mode OFF. Within ~30 s the sync icon turns amber with a number, then green.
- [ ] In the Firebase console, the new lot, handover (and photo thumbnails) are present — once each.

## B. App killed in the middle
- [ ] Airplane ON. Start a sale, reach the price screen (lot saved). Swipe the app away (kill it).
- [ ] Reopen → PIN → home. Turn internet ON. The lot reaches Firebase once (no duplicate).
- [ ] Airplane ON. Create a handover (QR). Kill the app. Internet ON, reopen: the handover syncs once.

## C. Phone restarted while records are pending
- [ ] Airplane ON. Make a sale and a "sold elsewhere" ledger entry. Restart the phone.
- [ ] Open the app (still offline): the ledger entry is still there; the sync icon shows a number.
- [ ] Internet ON: everything syncs, counts go to 0, icon turns green. No duplicates in Firebase.

## D. Two phones, both offline (handover)
- [ ] Both phones in airplane mode. Collector makes a handover QR. Recycler scans it: "Record is genuine".
- [ ] Recycler enters weight, taps Cash, Confirm.
- [ ] Internet ON on both. Within a minute the collector's receipt turns green "Confirmed",
      and My earnings shows the payment.

## E. Logout safety
- [ ] Airplane ON, make a sale (unsent). Tap logout: the app refuses and asks to turn internet on first.
- [ ] Internet ON, wait for green tick, logout: allowed.

## F. Tamper check
- [ ] (Optional, for judges) A changed QR (different weight) shows the red "record was changed" warning.
      This is covered by automatic tests in `app/test/handover_hash_test.dart`.

Record the phone model, Android version, date and who tested at the bottom of this file.

| Date | Phone | Android | Tester | Result |
|---|---|---|---|---|
| | | | | |
