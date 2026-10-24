# Scrap recogniser — accuracy report

Trained 24 Oct 2026 21:00. Model: MobileNetV2 (ImageNet) + new head, int8 TensorFlow Lite, 2678 KB.

**Overall accuracy on held-out photos: 80%** (110 of 137 correct). These 137 photos were never used for training. Measured with the exported .tflite file, the same one the phone runs.

| Class | Photos total | Held out | Correct | Accuracy |
|---|---|---|---|---|
| PCB | 78 | 16 | 12 | 75% |
| CABLE_CU | 103 | 21 | 18 | 86% |
| BATTERY_LI | 65 | 13 | 13 | 100% |
| BATTERY_PB | 37 | 7 | 4 | 57% |
| CRT | 55 | 11 | 8 | 73% |
| MOTOR | 42 | 8 | 4 | 50% |
| PLASTIC_MIX | 131 | 26 | 21 | 81% |
| PHONE | 120 | 24 | 19 | 79% |
| OTHER | 56 | 11 | 11 | 100% |

**Confusion matrix** (rows = true class, columns = predicted):

| | PCB | CABLE_CU | BATTERY_LI | BATTERY_PB | CRT | MOTOR | PLASTIC_MIX | PHONE | OTHER |
|---|---|---|---|---|---|---|---|---|---|
| PCB | 12 | 0 | 1 | 0 | 1 | 1 | 0 | 0 | 1 |
| CABLE_CU | 0 | 18 | 0 | 0 | 0 | 2 | 0 | 0 | 1 |
| BATTERY_LI | 0 | 0 | 13 | 0 | 0 | 0 | 0 | 0 | 0 |
| BATTERY_PB | 0 | 0 | 3 | 4 | 0 | 0 | 0 | 0 | 0 |
| CRT | 1 | 0 | 0 | 0 | 8 | 0 | 0 | 0 | 2 |
| MOTOR | 0 | 0 | 0 | 0 | 1 | 4 | 0 | 0 | 3 |
| PLASTIC_MIX | 0 | 0 | 0 | 1 | 0 | 1 | 21 | 0 | 3 |
| PHONE | 0 | 0 | 1 | 1 | 0 | 0 | 1 | 19 | 2 |
| OTHER | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 11 |

Caveats: the photos are a mix of the team's own photos and free Wikimedia Commons photos (credits in data/photos/CREDITS.csv). Several team photos show the same object, so held-out photos can look very like training photos and inflate accuracy; real-world accuracy on other phones, lighting and scrap may be lower. The app only *suggests* a category when it is at least 70% sure; the collector always makes the final choice.

**What the model looks at:** 18 heat-map images of held-out photos are in `analysis/heatmaps/` (left: photo, right: red = the area that decided the answer).
