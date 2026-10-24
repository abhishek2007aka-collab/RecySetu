import 'package:flutter/material.dart';

/// The Kabadiwala Connect logo, drawn from built-in icons (no image file):
/// a white circle with the green recycling arrows and a gold rupee coin,
/// meaning "recycle e-waste, get a fair price".
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
          Icon(Icons.recycling, size: size * 0.72, color: green),
          Positioned(
            right: size * 0.02,
            bottom: size * 0.02,
            child: Container(
              width: size * 0.36,
              height: size * 0.36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold,
                border: Border.all(color: Colors.white, width: size * 0.025),
              ),
              child: Icon(
                Icons.currency_rupee,
                size: size * 0.24,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
