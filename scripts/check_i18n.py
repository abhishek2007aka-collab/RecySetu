"""Checks the language files and recorded audio clips.

Reports:
- keys present in Hindi (the reference) but missing in another language, and extras
- languages still marked TODO (a Hindi copy waiting for translation)
- for recorded-only languages: missing clips in app/assets/audio/<lang>/

Run from the project root:
    python3 scripts/check_i18n.py
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
I18N = ROOT / "app" / "assets" / "i18n"
AUDIO = ROOT / "app" / "assets" / "audio"

# Languages with no Android TTS voice: every key needs a recorded clip.
RECORDED_ONLY = {"gbm"}
NUMBER_CLIPS = [f"num/{n}" for n in range(100)] + [
    "hundred", "thousand", "lakh", "rupees", "kilo", "about",
]


def load(code: str) -> dict:
    return json.loads((I18N / f"{code}.json").read_text(encoding="utf-8"))


def main() -> int:
    reference = {k for k in load("hi") if not k.startswith("_")}
    problems = 0
    for path in sorted(I18N.glob("*.json")):
        code = path.stem
        data = load(code)
        keys = {k for k in data if not k.startswith("_")}
        missing, extra = reference - keys, keys - reference
        if "_todo" in data:
            print(f"[{code}] TODO: {data['_todo']}")
        if missing:
            problems += len(missing)
            print(f"[{code}] missing keys: {', '.join(sorted(missing))}")
        if extra:
            print(f"[{code}] extra keys (not in hi): {', '.join(sorted(extra))}")
        if code in RECORDED_ONLY:
            wanted = sorted(keys) + NUMBER_CLIPS
            absent = [c for c in wanted if not (AUDIO / code / f"{c}.mp3").exists()]
            if absent:
                problems += len(absent)
                print(f"[{code}] {len(absent)} of {len(wanted)} audio clips missing, e.g. {absent[:5]}")
        if not missing and not extra:
            print(f"[{code}] all {len(keys)} keys present")
    print("OK" if problems == 0 else f"{problems} problem(s) found")
    return 0 if problems == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
