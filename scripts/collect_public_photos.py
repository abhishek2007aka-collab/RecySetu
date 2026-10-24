"""Downloads openly licensed photos from Wikimedia Commons into data/photos/.

Only free licences (Creative Commons BY / BY-SA / CC0 / public domain) are
kept, and every photo's author and licence are written to
data/photos/CREDITS.csv, as those licences require attribution.

These clean "internet" photos are a starting point. They do NOT replace the
team's own photos of real, dirty scrap — see data/photos/README.md.

Run from the project root (standard library only):
    python3 scripts/collect_public_photos.py --per-class 80
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PHOTOS = ROOT / "data" / "photos"
API = "https://commons.wikimedia.org/w/api.php"
UA = "KabadiwalaConnect-SIH/0.1 (student hackathon project; training data collection)"

# Material code -> Wikimedia Commons categories (checked to contain photos).
SOURCES = {
    "PCB": ["Printed_circuit_boards"],
    "CABLE_CU": ["Copper_wire", "Electric_cables", "Power_cables"],
    "BATTERY_LI": ["Lithium-ion_batteries", "Laptop_batteries", "Mobile_phone_batteries"],
    "BATTERY_PB": ["Lead-acid_batteries"],
    "CRT": ["CRT_television_sets", "CRT_monitors"],
    "MOTOR": ["Electric_motors"],
    "PHONE": ["Mobile_phones", "Nokia_mobile_phones", "Feature_phones"],
    # All plastic items count as mixed plastic (bottles, caps, containers).
    "PLASTIC_MIX": ["Plastic_bottles", "PET_bottles", "Plastic_containers", "Plastic_waste"],
}
FREE = re.compile(r"^(cc[ -]by|cc[ -]by-sa|cc0|public domain|pd)", re.I)
NOT_PHOTO = re.compile(r"diagram|schem|logo|icon|map|chart|graph|drawing|symbol|patent|"
                       r"advert|label|sticker|screenshot", re.I)


def api(params: dict) -> dict:
    url = API + "?" + urllib.parse.urlencode({**params, "format": "json"})
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def strip_html(s: str) -> str:
    return re.sub(r"<[^>]+>", "", s or "").strip()


def files_in(category: str):
    """Yields (title, thumb_url, author, licence, licence_url, page_url)."""
    params = {
        "action": "query", "generator": "categorymembers",
        "gcmtitle": f"Category:{category}", "gcmtype": "file", "gcmlimit": "100",
        "prop": "imageinfo", "iiprop": "url|mime|extmetadata", "iiurlwidth": "500",
    }
    while True:
        data = api(params)
        for page in (data.get("query", {}).get("pages", {}) or {}).values():
            info = (page.get("imageinfo") or [{}])[0]
            meta = info.get("extmetadata", {})
            licence = strip_html(meta.get("LicenseShortName", {}).get("value", ""))
            if info.get("mime") != "image/jpeg" or not FREE.match(licence):
                continue
            if NOT_PHOTO.search(page["title"]):
                continue
            yield (page["title"], info.get("thumburl"), strip_html(meta.get("Artist", {}).get("value", "")),
                   licence, meta.get("LicenseUrl", {}).get("value", ""), info.get("descriptionurl", ""))
        if "continue" not in data:
            return
        params.update(data["continue"])


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--per-class", type=int, default=80)
    args = ap.parse_args()

    credits_path = PHOTOS / "CREDITS.csv"
    seen = set()
    rows = []
    if credits_path.exists():
        with credits_path.open() as f:
            rows = list(csv.DictReader(f))
            seen = {r["file"] for r in rows}

    for code, categories in SOURCES.items():
        folder = PHOTOS / code
        folder.mkdir(parents=True, exist_ok=True)
        have = len([r for r in rows if r["class"] == code])
        for cat in categories:
            for title, url, author, lic, lic_url, page in files_in(cat):
                if have >= args.per_class:
                    break
                name = "wm_" + re.sub(r"[^A-Za-z0-9]+", "_", title[5:])[:60] + ".jpg"
                if name in seen or not url:
                    continue
                try:
                    req = urllib.request.Request(url, headers={"User-Agent": UA})
                    with urllib.request.urlopen(req, timeout=30) as r:
                        (folder / name).write_bytes(r.read())
                except Exception as e:  # skip broken downloads, keep going
                    print("  skip", title, e)
                    continue
                seen.add(name)
                rows.append({"file": name, "class": code, "title": title, "author": author,
                             "licence": lic, "licence_url": lic_url, "source": page})
                have += 1
                time.sleep(0.6)  # be polite to Wikimedia (it rate-limits)
            if have >= args.per_class:
                break
        print(f"{code}: {have} photos")

    with credits_path.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["file", "class", "title", "author", "licence",
                                          "licence_url", "source"])
        w.writeheader()
        w.writerows(rows)
    print(f"Credits for {len(rows)} photos in {credits_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
