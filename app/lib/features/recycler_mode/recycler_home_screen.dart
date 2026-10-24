import 'package:flutter/material.dart';

import '../../core/widgets/k_scaffold.dart';

/// R1 placeholder; Phase 7 adds scan, verify and confirm.
class RecyclerHomeScreen extends StatelessWidget {
  const RecyclerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const KScaffold(
    titleKey: 'role_recycler',
    instructionKey: 'recycler_home_instruction',
    body: Center(child: Icon(Icons.qr_code_scanner, size: 120)),
  );
}
