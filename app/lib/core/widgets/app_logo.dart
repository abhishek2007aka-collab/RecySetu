import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The RecySetu logo, drawn in code (no image file): a white circle with the
/// green recycling arrows above a gold arch bridge ("setu") — the bridge
/// between kabadiwalas and authorised recyclers. Same design as the launcher
/// icon (drawn by the team's icon script).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 160});

  final double size;

  static const green = Color(0xFF1B5E20);
  static const gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: size * 0.12,
                  offset: Offset(0, size * 0.04),
                ),
              ],
            ),
          ),
          Positioned(
            top: size * 0.13,
            child: Icon(Icons.recycling, size: size * 0.56, color: green),
          ),
          Positioned.fill(child: CustomPaint(painter: _BridgePainter())),
        ],
      ),
    );
  }
}

/// Gold arch bridge: deck, arch and five hangers.
class _BridgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final d = size.width;
    final cx = d / 2;
    final deckY = d / 2 + d * 0.21 + d * 0.07;
    final half = d * 0.34;
    final rise = d * 0.17;
    final w = math.max(1.5, d * 0.045);
    final paint = Paint()
      ..color = AppLogo.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;

    // Arch: upper half of an ellipse across the span.
    canvas.drawArc(
      Rect.fromLTRB(cx - half, deckY - rise, cx + half, deckY + rise),
      math.pi,
      math.pi,
      false,
      paint,
    );
    // Deck.
    canvas.drawLine(
      Offset(cx - half * 1.12, deckY),
      Offset(cx + half * 1.12, deckY),
      paint..strokeWidth = w * 1.3,
    );
    // Hangers.
    paint.strokeWidth = w * 0.55;
    for (final f in const [-0.6, -0.3, 0.0, 0.3, 0.6]) {
      final x = cx + half * f;
      final yArch = deckY - rise * math.sqrt(1 - f * f);
      canvas.drawLine(Offset(x, yArch + w * 0.4), Offset(x, deckY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
