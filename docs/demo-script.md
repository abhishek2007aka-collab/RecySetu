# RecySetu — 3-minute demo script (SIH26229)

**Team ByteStorms.** Two phones. Airplane mode ON for the whole demo until the last step.

| Phone | Login | Role |
|---|---|---|
| Phone A (collector) | +91 99999 00001 / 123456 | Kabadiwala |
| Phone B (recycler)  | +91 99999 00002 / 123456 | DEMO Recycler |

## Before the judges arrive (5 minutes)
1. Both phones: log in once **with internet**, set the PIN, open every home tile once.
2. Phone A: long-press the logo on home → **Demo tools** → *Show safety cards again* and *Location: Roorkee (demo)*.
3. Phone B: open **Scan QR** once (camera permission granted).
4. Have ready on the table: a **plastic bottle**, a **phone charger cable**, an **old phone**.
5. Volume up. Turn **airplane mode ON** on both phones. Sync icon shows grey: that's the point.

## The demo

**0:00 — The problem (20 s, speak)**
"India made 13.97 lakh tonnes of e-waste last year. 90–95% of recycling is done by kabadiwalas, who often can't read, have cheap phones and patchy internet, and get underpaid. Our app works offline, needs no reading, and speaks."

**0:20 — No reading, any language (20 s)**
- Phone A: PIN → loading screen (logo, *Developed by ByteStorms*) → home. The app **speaks** the instruction.
- Tap the language button → *More languages* → tap **বাংলা** once (it says the name), tap again → whole app is now Bengali. Switch back to **हिन्दी**.

**0:40 — Sell scrap with AI and spoken price (50 s)**
- **कबाड़ बेचें** → take a photo of the **bottle** → Next.
- The AI highlights **मिला प्लास्टिक** with **"सुझाव 9x%"** and **says** it. Point out: on the phone, no internet.
- (Optional: retake with the **cable** or the **phone** to show other categories.)
- Tap it → weight: type **350 ग्राम** on the keypad (or use +/−). Price updates live on the button.
- Next → the app **speaks**: *"लगभग … रुपये मिलेंगे"*. "Prices are from published scrap rates, with sources."

**1:30 — Authorised recyclers, not middlemen (25 s)**
- **रीसाइक्लर खोजें** → ranked list: rate, distance, pickup. The **real authorised recyclers** from the official **CPCB list** for Uttarakhand are shown, with "Rate not known" where they publish none — no invented data.
- Choose **DEMO Recycler**.

**1:55 — Tamper-proof handover (35 s)**
- Phone A shows a **QR receipt** and a short reference (spoken letter by letter), status amber *waiting*.
- Phone B (also offline): **Scan QR** → green **"Record is genuine"**. Explain: SHA-256 fingerprint; change any number and it turns **red**.
- Phone B: adjust measured weight, tap **नकद (Cash)** → **Confirm**.

**2:30 — Sync and earnings (25 s)**
- Turn **airplane mode OFF** on both phones. Sync icon: grey → amber with a number → **green**.
- Phone A's receipt turns **green "Confirmed"** and speaks the payment. **मेरी कमाई (My earnings)** shows today's total and money due.

**2:55 — Close (5 s)**
"Offline, spoken, 12 languages, AI on the phone, real authorised recyclers, tamper-proof receipts. RecySetu, by ByteStorms."

## If something goes wrong
| Problem | Do this |
|---|---|
| AI suggests nothing | Say "it only suggests when it's 70% sure" and tap the tile yourself. |
| GPS slow indoors | Demo tools → *Location: Roorkee (demo)*. |
| No sound | Voice switch on home (🔊), phone volume, or tap the speaker button on the screen. |
| Confirmation slow to appear | Pull up My earnings after 30 s; both phones need internet for the sync step. |
| Safety card doesn't auto-show | Demo tools → *Show safety cards again*, then pick **पुराना टीवी** or a battery. |

## Optional extras (if judges ask)
- **Safety tile:** 5 spoken safety cards; picking a battery or old TV shows its card first.
- **Recycler join flow:** log in as +91 99999 00003, tap Recycler → apply with a registration number → the team approves with `scripts/approve_recycler.py`.
- **AI heat maps:** `docs/images/ai_heatmaps.jpg` shows the AI looks at the object, not the background.
- **Voice off** switch, **logout** that protects unsent data, works at the biggest font size.
