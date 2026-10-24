"""Train the on-device scrap recogniser (PLAN.md Phase 12a).

Reads photos from data/photos/<CLASS>/ (one folder per material code, plus
OTHER), trains a small MobileNetV2 model by transfer learning, and exports a
quantised TensorFlow Lite model for the app.

Honest evaluation: 20% of the photos (chosen at random, fixed seed) are held
back and never used for training. Accuracy on those photos is written to
analysis/classifier_report.md and printed.

Run from the project root (needs the ML environment, see data/photos/README.md):
    .venv-ml/bin/python scripts/train_classifier.py
"""

from __future__ import annotations

import argparse
import random
from datetime import datetime
from pathlib import Path

import numpy as np
import tensorflow as tf

ROOT = Path(__file__).resolve().parent.parent
PHOTOS = ROOT / "data" / "photos"
OUT_DIR = ROOT / "app" / "assets" / "models"
REPORT = ROOT / "analysis" / "classifier_report.md"

CLASSES = ["PCB", "CABLE_CU", "BATTERY_LI", "BATTERY_PB", "CRT", "MOTOR",
           "PLASTIC_MIX", "PHONE", "OTHER"]
MIN_PHOTOS = 10          # a class with fewer photos is skipped (and reported)
SIZE = 224               # MobileNetV2 input; the app reads it from the model
HOLD_OUT = 0.2
SEED = 42
EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".gif"}


def collect() -> tuple[list[str], list[tuple[Path, int]], dict[str, int]]:
    counts = {c: len([p for p in (PHOTOS / c).glob("*") if p.suffix.lower() in EXTENSIONS])
              for c in CLASSES if (PHOTOS / c).is_dir()}
    used = [c for c in CLASSES if counts.get(c, 0) >= MIN_PHOTOS]
    files = [(p, used.index(c)) for c in used
             for p in sorted((PHOTOS / c).glob("*")) if p.suffix.lower() in EXTENSIONS]
    return used, files, counts


def split(files: list[tuple[Path, int]], n_classes: int):
    """Hold out HOLD_OUT of each class (stratified), fixed seed."""
    rng = random.Random(SEED)
    train, test = [], []
    for k in range(n_classes):
        group = [f for f in files if f[1] == k]
        rng.shuffle(group)
        cut = max(1, round(len(group) * HOLD_OUT))
        test += group[:cut]
        train += group[cut:]
    return train, test


def load_image(path: tf.Tensor) -> tf.Tensor:
    """Decode, shorter side -> SIZE, centre square crop. Matches the app."""
    img = tf.io.decode_image(tf.io.read_file(path), channels=3, expand_animations=False)
    return tf.cast(_resize_short_side_and_crop(img), tf.float32)  # 0..255


def _resize_short_side_and_crop(img: tf.Tensor) -> tf.Tensor:
    shape = tf.cast(tf.shape(img)[:2], tf.float32)
    scale = SIZE / tf.reduce_min(shape)
    new = tf.cast(tf.round(shape * scale), tf.int32)
    img = tf.image.resize(img, new)
    return tf.image.resize_with_crop_or_pad(img, SIZE, SIZE)


def dataset(items, training: bool) -> tf.data.Dataset:
    paths = [str(p) for p, _ in items]
    labels = [k for _, k in items]
    ds = tf.data.Dataset.from_tensor_slices((paths, labels))
    if training:
        ds = ds.shuffle(len(items), seed=SEED, reshuffle_each_iteration=True)
    ds = ds.map(lambda p, y: (load_image(p), y), num_parallel_calls=tf.data.AUTOTUNE)
    if training:
        augment = tf.keras.Sequential([
            tf.keras.layers.RandomFlip("horizontal"),
            tf.keras.layers.RandomRotation(0.1),
            tf.keras.layers.RandomZoom(0.15),
            tf.keras.layers.RandomBrightness(0.2, value_range=(0, 255)),
            tf.keras.layers.RandomContrast(0.2),
        ])
        ds = ds.map(lambda x, y: (augment(x, training=True), y),
                    num_parallel_calls=tf.data.AUTOTUNE)
    return ds.batch(16).prefetch(tf.data.AUTOTUNE)


def build(n_classes: int) -> tuple[tf.keras.Model, tf.keras.Model]:
    base = tf.keras.applications.MobileNetV2(
        input_shape=(SIZE, SIZE, 3), include_top=False, weights="imagenet")
    base.trainable = False
    inputs = tf.keras.Input((SIZE, SIZE, 3))
    x = tf.keras.layers.Rescaling(1 / 127.5, offset=-1)(inputs)  # 0..255 -> -1..1
    x = base(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.3)(x)
    outputs = tf.keras.layers.Dense(n_classes, activation="softmax")(x)
    return tf.keras.Model(inputs, outputs), base


def class_weights(train, n_classes):
    counts = np.bincount([k for _, k in train], minlength=n_classes)
    return {k: len(train) / (n_classes * max(c, 1)) for k, c in enumerate(counts)}


def to_tflite(model, train_items) -> bytes:
    def representative():
        for p, _ in train_items[:200]:
            yield [tf.expand_dims(load_image(tf.constant(str(p))), 0)]
    conv = tf.lite.TFLiteConverter.from_keras_model(model)
    conv.optimizations = [tf.lite.Optimize.DEFAULT]
    conv.representative_dataset = representative
    conv.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    conv.inference_input_type = tf.uint8    # app passes raw RGB bytes
    conv.inference_output_type = tf.uint8   # app de-quantises the scores
    return conv.convert()


def tflite_predict(model_bytes: bytes, items) -> list[int]:
    """Runs the exported model exactly as the phone will (uint8 in/out)."""
    interp = tf.lite.Interpreter(model_content=model_bytes)
    interp.allocate_tensors()
    inp, out = interp.get_input_details()[0], interp.get_output_details()[0]
    preds = []
    for p, _ in items:
        x = load_image(tf.constant(str(p))).numpy()
        scale, zero = inp["quantization"]
        q = np.clip(np.round(x / scale + zero), 0, 255).astype(np.uint8)
        interp.set_tensor(inp["index"], q[None])
        interp.invoke()
        preds.append(int(np.argmax(interp.get_tensor(out["index"])[0])))
    return preds


def report(used, counts, test, preds, skipped, size_kb) -> str:
    n = len(used)
    cm = np.zeros((n, n), dtype=int)
    for (_, y), p in zip(test, preds):
        cm[y, p] += 1
    total = int(cm.trace()) / max(len(test), 1)
    lines = [
        "# Scrap recogniser — accuracy report",
        "",
        f"Trained {datetime.now():%d %b %Y %H:%M}. Model: MobileNetV2 (ImageNet) + new head, "
        f"int8 TensorFlow Lite, {size_kb:.0f} KB.",
        "",
        f"**Overall accuracy on held-out photos: {total:.0%}** "
        f"({int(cm.trace())} of {len(test)} correct). These {len(test)} photos were "
        "never used for training. Measured with the exported .tflite file, the same "
        "one the phone runs.",
        "",
        "| Class | Photos total | Held out | Correct | Accuracy |",
        "|---|---|---|---|---|",
    ]
    for k, c in enumerate(used):
        held = int(cm[k].sum())
        lines.append(f"| {c} | {counts[c]} | {held} | {cm[k, k]} | "
                     f"{(cm[k, k] / held if held else 0):.0%} |")
    lines += ["", "**Confusion matrix** (rows = true class, columns = predicted):", "",
              "| | " + " | ".join(used) + " |", "|---" * (n + 1) + "|"]
    for k, c in enumerate(used):
        lines.append(f"| {c} | " + " | ".join(str(v) for v in cm[k]) + " |")
    if skipped:
        lines += ["", f"Skipped (fewer than {MIN_PHOTOS} photos): "
                  + ", ".join(f"{c} ({counts.get(c, 0)})" for c in skipped)]
    lines += ["", "Caveats: the photos were taken by the team, so real-world accuracy "
              "on other phones, lighting and scrap may be lower. The app only "
              "*suggests* a category when it is at least 70% sure; the collector "
              "always makes the final choice."]
    return "\n".join(lines) + "\n"


def main() -> None:
    global PHOTOS, OUT_DIR, REPORT
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--photos", type=Path, default=PHOTOS)
    ap.add_argument("--out", type=Path, default=OUT_DIR, help="where model.tflite goes")
    ap.add_argument("--report", type=Path, default=REPORT)
    ap.add_argument("--epochs", type=int, default=12)
    args = ap.parse_args()
    PHOTOS, OUT_DIR, REPORT = args.photos, args.out, args.report

    tf.keras.utils.set_random_seed(SEED)
    used, files, counts = collect()
    skipped = [c for c in CLASSES if c not in used]
    print("Photos per class:", counts)
    if len(used) < 2:
        raise SystemExit(f"Need at least 2 classes with {MIN_PHOTOS}+ photos in {PHOTOS}")
    train, test = split(files, len(used))
    print(f"Training on {len(train)} photos, holding out {len(test)} for testing.")

    model, base = build(len(used))
    model.compile(tf.keras.optimizers.Adam(1e-3),
                  "sparse_categorical_crossentropy", metrics=["accuracy"])
    weights = class_weights(train, len(used))
    model.fit(dataset(train, True), epochs=args.epochs, class_weight=weights, verbose=2)

    # Fine-tune the top of the base network gently.
    base.trainable = True
    for layer in base.layers[:-30]:
        layer.trainable = False
    model.compile(tf.keras.optimizers.Adam(1e-5),
                  "sparse_categorical_crossentropy", metrics=["accuracy"])
    model.fit(dataset(train, True), epochs=max(1, args.epochs // 2),
              class_weight=weights, verbose=2)

    tflite = to_tflite(model, train)
    preds = tflite_predict(tflite, test)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "model.tflite").write_bytes(tflite)
    (OUT_DIR / "labels.txt").write_text("".join(f"{i} {c}\n" for i, c in enumerate(used)))
    REPORT.parent.mkdir(exist_ok=True)
    text = report(used, counts, test, preds, skipped, len(tflite) / 1024)
    REPORT.write_text(text)
    print(text)
    print(f"Model written to {OUT_DIR}/ — rebuild the app to use it.")


if __name__ == "__main__":
    main()
