"""data/*.csv -> app/assets/seed/*.json (the app's offline fallback on first run).

Run from the project root:
    .venv/bin/python scripts/csv_to_assets.py
"""

import json

from seed_common import ALL, ROOT, placeholder_report

OUT = ROOT / "app" / "assets" / "seed"


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    collections = {name: load() for name, load in ALL.items()}
    for name, rows in collections.items():
        path = OUT / f"{name}.json"
        path.write_text(json.dumps(list(rows.values()), ensure_ascii=False, indent=2) + "\n")
        print(f"wrote {path.relative_to(ROOT)} ({len(rows)} rows)")
    for line in placeholder_report(collections):
        print("NOTE:", line)


if __name__ == "__main__":
    main()
