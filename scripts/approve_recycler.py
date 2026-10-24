"""Review recycler applications sent from the app.

A recycler who taps "Recycler" but is not linked yet sends an application
(business name + CPCB/SPCB authorisation number). Check that number against
the official list, then approve or reject it here.

Run from the project root (needs scripts/serviceAccount.json):
    .venv/bin/python scripts/approve_recycler.py                  # list pending
    .venv/bin/python scripts/approve_recycler.py --approve UID --recycler RECYCLER_ID
    .venv/bin/python scripts/approve_recycler.py --reject UID

Approving links the applicant's phone to the recycler listing (ownerPhone);
the app then opens recycler mode for them. If the business is not in the
recycler list yet, add a row to data/recyclers.csv, run seed_firestore.py,
and approve with that new id.
"""

import argparse
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

KEY = Path(__file__).resolve().parent / "serviceAccount.json"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--approve", metavar="UID")
    ap.add_argument("--recycler", metavar="RECYCLER_ID", help="listing to link (with --approve)")
    ap.add_argument("--reject", metavar="UID")
    args = ap.parse_args()

    firebase_admin.initialize_app(credentials.Certificate(str(KEY)))
    db = firestore.client()
    apps = db.collection("recycler_applications")

    if args.approve:
        doc = apps.document(args.approve).get()
        if not doc.exists:
            raise SystemExit("No application for that uid.")
        a = doc.to_dict()
        rid = args.recycler or a.get("recyclerId")
        if not rid:
            raise SystemExit("Give --recycler RECYCLER_ID (the business is not linked to a listing).")
        listing = db.collection("recyclers").document(rid)
        if not listing.get().exists:
            raise SystemExit(f"No recycler listing '{rid}'. Add it to data/recyclers.csv and seed first.")
        listing.set({"ownerPhone": a["phone"]}, merge=True)
        apps.document(args.approve).set({"status": "approved", "recyclerId": rid}, merge=True)
        print(f"Approved: {a['phone']} now runs recycler '{rid}'.")
        return

    if args.reject:
        apps.document(args.reject).set({"status": "rejected"}, merge=True)
        print("Rejected.")
        return

    pending = [d for d in apps.stream() if d.to_dict().get("status") == "pending"]
    if not pending:
        print("No pending applications.")
    for d in pending:
        a = d.to_dict()
        print(f"uid={d.id}  phone={a.get('phone')}  listing={a.get('recyclerId') or '-'}\n"
              f"    business: {a.get('businessName')}\n"
              f"    registration: {a.get('authorisationRef')}")


if __name__ == "__main__":
    main()
