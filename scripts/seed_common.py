"""Shared CSV -> Firestore-shaped records, used by csv_to_assets.py and seed_firestore.py.

The team edits data/*.csv in rupees (easy to type). Here we convert to the app's
units: money in paise (int), weight in grams (int). Never floats for money.
"""

from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"


def rupees_to_paise(value) -> int | None:
    """'210' or 210.5 -> 21000 / 21050. Blank cells -> None."""
    if pd.isna(value) or str(value).strip() == "":
        return None
    return int(round(float(value) * 100))


def _bool(value) -> bool:
    return str(value).strip().lower() in ("true", "1", "yes", "y")


def _text(value) -> str:
    return "" if pd.isna(value) else str(value).strip()


def _read(name: str) -> pd.DataFrame:
    # dtype=str keeps phone numbers like +91... and codes exactly as typed.
    return pd.read_csv(DATA / name, dtype=str, keep_default_na=False)


def load_materials() -> dict[str, dict]:
    out = {}
    for row in _read("materials.csv").to_dict("records"):
        code = _text(row["code"])
        out[code] = {
            "code": code,
            "nameKey": _text(row["name_key"]),
            "iconAsset": _text(row["icon"]),
            "hazard": _text(row["hazard"]) or "none",
            "safetyCardIds": [s for s in _text(row["safety_card_ids"]).split(";") if s],
            "placeholder": _bool(row["placeholder"]),
        }
    return out


def load_prices() -> dict[str, dict]:
    out = {}
    for row in _read("prices.csv").to_dict("records"):
        code = _text(row["material_code"])
        out[code] = {
            "materialCode": code,
            "currentLowPaisePerKg": rupees_to_paise(row["low_rs_per_kg"]),
            "currentHighPaisePerKg": rupees_to_paise(row["high_rs_per_kg"]),
            "weekAgoMidPaisePerKg": rupees_to_paise(row["week_ago_mid_rs_per_kg"]),
            "source": _text(row["source"]) or "field_study",
            "placeholder": _bool(row["placeholder"]),
        }
    return out


def load_recyclers() -> dict[str, dict]:
    out = {}
    df = _read("recyclers.csv")
    rate_cols = [c for c in df.columns if c.startswith("rate_")]
    for row in df.to_dict("records"):
        rid = _text(row["id"])
        rates = {}
        for col in rate_cols:
            paise = rupees_to_paise(row[col])
            if paise is not None:
                rates[col.removeprefix("rate_")] = paise
        out[rid] = {
            "id": rid,
            "name": _text(row["name"]),
            "phone": _text(row["phone"]),
            "lat": float(row["lat"]),
            "lng": float(row["lng"]),
            "address": _text(row["address"]),
            "authorised": _bool(row["authorised"]),
            "authorisationRef": _text(row["authorisation_ref"]),
            "offersPickup": _bool(row["offers_pickup"]),
            "ownerPhone": _text(row["owner_phone"]) or None,
            "ownerUid": None,
            "ratesPaisePerKg": rates,
            "placeholder": _bool(row["placeholder"]),
        }
    return out


def load_areas() -> dict[str, dict]:
    out = {}
    for row in _read("areas.csv").to_dict("records"):
        aid = _text(row["id"])
        out[aid] = {
            "id": aid,
            "nameKey": _text(row["name_key"]),
            "lat": float(row["lat"]),
            "lng": float(row["lng"]),
            "placeholder": _bool(row["placeholder"]),
        }
    return out


ALL = {
    "materials": load_materials,
    "prices": load_prices,
    "recyclers": load_recyclers,
    "areas": load_areas,
}


def placeholder_report(collections: dict[str, dict[str, dict]]) -> list[str]:
    return [
        f"{name}: {sum(1 for r in rows.values() if r.get('placeholder'))} of {len(rows)} rows are placeholders"
        for name, rows in collections.items()
    ]
