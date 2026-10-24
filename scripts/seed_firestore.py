"""data/*.csv -> Cloud Firestore (materials, prices, recyclers, areas).

Needs a service-account key at scripts/serviceAccount.json (never commit it):
Firebase console -> Project settings -> Service accounts -> Generate new private key.

Run from the project root:
    .venv/bin/python scripts/seed_firestore.py
"""

from datetime import datetime, timezone
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

from seed_common import ALL, placeholder_report

KEY = Path(__file__).resolve().parent / "serviceAccount.json"


def main() -> None:
    if not KEY.exists():
        raise SystemExit(f"Missing {KEY}. See the instructions at the top of this file.")
    firebase_admin.initialize_app(credentials.Certificate(str(KEY)))
    db = firestore.client()

    collections = {name: load() for name, load in ALL.items()}
    now = datetime.now(timezone.utc)
    for name, rows in collections.items():
        batch = db.batch()
        for doc_id, data in rows.items():
            if name == "prices":
                data = {**data, "updatedAt": now}
            if name == "recyclers":
                # Never overwrite a recycler's login link made in the app.
                data = {k: v for k, v in data.items() if k != "ownerUid"}
            batch.set(db.collection(name).document(doc_id), data, merge=True)
        batch.commit()
        print(f"{name}: wrote {len(rows)} docs")
    for line in placeholder_report(collections):
        print("NOTE:", line)


if __name__ == "__main__":
    main()
