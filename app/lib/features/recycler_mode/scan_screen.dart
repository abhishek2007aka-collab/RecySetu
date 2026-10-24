import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/widgets/k_scaffold.dart';
import 'verify_screen.dart';

/// R2 (part 1). Camera scanner. The first QR read opens the verify screen;
/// everything after that works offline because the QR carries the record.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (_handled || raw == null) return;
    _handled = true;
    _controller.stop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => VerifyScreen(payload: raw)),
    );
  }

  @override
  Widget build(BuildContext context) => KScaffold(
    titleKey: 'tile_scan',
    instructionKey: 'scan_instruction',
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 4),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ],
    ),
  );
}
