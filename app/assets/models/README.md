# Scrap recogniser model (optional, Phase 12a)

Put the files exported from Google Teachable Machine here:

- `model.tflite`  (Export Model → TensorFlow Lite → Quantized → Download)
- `labels.txt`    (comes in the same zip)

Class names must be the material codes exactly: PCB, CABLE_CU, BATTERY_LI,
BATTERY_PB, CRT, MOTOR, PLASTIC_MIX, PHONE, plus OTHER for "not scrap".
If these files are missing, the app works as before (no suggestion).
