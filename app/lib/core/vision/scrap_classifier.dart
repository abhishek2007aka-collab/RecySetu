import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Optional on-device scrap recogniser (PLAN.md Phase 12a).
///
/// The team trains an image model in Google Teachable Machine with field
/// photos (one class per material code, plus OTHER) and drops the exported
/// `model.tflite` + `labels.txt` into `assets/models/`. Without those files
/// the feature is simply off. The model only *suggests*; the collector
/// always makes the final choice.
class ScrapClassifier {
  ScrapClassifier._(this._interpreter, this.labels, this._size);

  static const modelAsset = 'assets/models/model.tflite';
  static const labelsAsset = 'assets/models/labels.txt';

  final Interpreter _interpreter;
  final List<String> labels;
  final int _size;

  /// Returns null when no model is bundled (or it cannot be loaded).
  static Future<ScrapClassifier?> load({AssetBundle? bundle}) async {
    try {
      final b = bundle ?? rootBundle;
      final labels = parseLabels(await b.loadString(labelsAsset));
      final model = await b.load(modelAsset);
      final interpreter = Interpreter.fromBuffer(model.buffer.asUint8List());
      final shape = interpreter.getInputTensor(0).shape; // [1, h, w, 3]
      return ScrapClassifier._(interpreter, labels, shape[1]);
    } catch (e) {
      debugPrint('scrap classifier off: $e');
      return null;
    }
  }

  /// Scores (0..1) per label for one photo file.
  Future<Map<String, double>> classify(String photoPath) async {
    final rgb = await _loadRgb(await File(photoPath).readAsBytes(), _size);
    final input = _interpreter.getInputTensor(0);
    final output = _interpreter.getOutputTensor(0);
    final n = output.shape.last;

    final Object inputData = switch (input.type) {
      TensorType.uint8 => rgb,
      // Teachable Machine float models expect pixels scaled to -1..1.
      _ => Float32List.fromList([for (final v in rgb) v / 127.5 - 1]).buffer,
    };

    final List<double> scores;
    if (output.type == TensorType.uint8) {
      final out = Uint8List(n);
      _interpreter.run(inputData, out.buffer);
      final q = output.params;
      scores = [for (final v in out) q.scale * (v - q.zeroPoint)];
    } else {
      final out = Float32List(n);
      _interpreter.run(inputData, out.buffer);
      scores = out.toList();
    }
    return {
      for (var i = 0; i < n && i < labels.length; i++) labels[i]: scores[i],
    };
  }

  void close() => _interpreter.close();

  /// Decodes a JPEG, scales its shorter side to [size] and crops the centre
  /// square (the same framing Teachable Machine uses). Returns RGB bytes.
  static Future<Uint8List> _loadRgb(Uint8List jpeg, int size) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(jpeg);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final w = descriptor.width, h = descriptor.height;
    final scale = size / (w < h ? w : h);
    final codec = await descriptor.instantiateCodec(
      targetWidth: (w * scale).round(),
      targetHeight: (h * scale).round(),
    );
    final image = (await codec.getNextFrame()).image;
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgb = centerCropRgb(
      rgba!.buffer.asUint8List(),
      image.width,
      image.height,
      size,
    );
    image.dispose();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    return rgb;
  }
}

/// Teachable Machine writes `labels.txt` as "0 PCB", "1 CABLE_CU", ...
List<String> parseLabels(String text) => [
  for (final line in text.split('\n'))
    if (line.trim().isNotEmpty)
      line.trim().replaceFirst(RegExp(r'^\d+\s+'), ''),
];

/// Cuts the centre [size]×[size] square out of an RGBA image and drops alpha.
Uint8List centerCropRgb(Uint8List rgba, int width, int height, int size) {
  final left = (width - size) ~/ 2, top = (height - size) ~/ 2;
  final out = Uint8List(size * size * 3);
  var o = 0;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final i = ((top + y) * width + left + x) * 4;
      out[o++] = rgba[i];
      out[o++] = rgba[i + 1];
      out[o++] = rgba[i + 2];
    }
  }
  return out;
}

/// A material the model is fairly sure about.
class Suggestion {
  const Suggestion(this.materialCode, this.confidence);

  final String materialCode;
  final double confidence;
}

/// Averages the scores of all photos of one lot and suggests the best
/// material only if it reaches [threshold] (PLAN.md: 0.7) and is a real
/// material (not OTHER or anything outside [knownCodes]).
Suggestion? pickSuggestion(
  List<Map<String, double>> perPhoto,
  Set<String> knownCodes, {
  double threshold = 0.7,
}) {
  if (perPhoto.isEmpty) return null;
  final sums = <String, double>{};
  for (final scores in perPhoto) {
    scores.forEach((k, v) => sums[k] = (sums[k] ?? 0) + v);
  }
  String? best;
  var bestScore = -1.0;
  sums.forEach((k, v) {
    final avg = v / perPhoto.length;
    if (avg > bestScore) {
      best = k;
      bestScore = avg;
    }
  });
  if (best == null || bestScore < threshold || !knownCodes.contains(best)) {
    return null;
  }
  return Suggestion(best!, bestScore);
}
