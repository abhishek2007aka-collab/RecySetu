import 'package:flutter/material.dart';

import '../../core/widgets/k_scaffold.dart';

/// Placeholder for screens built in later phases.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.titleKey});

  final String titleKey;

  @override
  Widget build(BuildContext context) => KScaffold(
    titleKey: titleKey,
    instructionKey: 'coming_soon',
    body: const Center(child: Icon(Icons.construction, size: 120)),
  );
}
