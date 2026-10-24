# Training photos for the scrap recogniser

Put photos in the folder that matches what is in the photo:

| Folder | What goes in it |
|---|---|
| PCB | Circuit boards (green boards from TVs, computers, phones, radios) |
| CABLE_CU | Wires, cables, chargers' cords, copper coils |
| BATTERY_LI | Phone / power-bank / laptop / small lithium batteries |
| BATTERY_PB | Car / bike / inverter batteries (big, heavy, lead-acid) |
| CRT | Old box-type (CRT) TVs and computer monitors |
| MOTOR | Motors from fans, mixers, pumps, washing machines |
| PLASTIC_MIX | Plastic casings and broken plastic parts of electronics |
| PHONE | Old mobile phones (whole) |
| OTHER | Anything that is NOT scrap: floor, hands, bags, tables, people, walls |

Tips:
- At least 30 photos per folder, 50+ is better. Keep the folders roughly equal.
- Vary angle, distance, lighting and background. Real, dirty scrap is best.
- One kind of object per photo. JPG or PNG.

Then run (from the project root):

    .venv-ml/bin/python scripts/train_classifier.py

It holds back 20% of the photos for an honest accuracy check, writes
`analysis/classifier_report.md`, and copies the model into `app/assets/models/`.
