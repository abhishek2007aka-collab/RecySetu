import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../data/models/catalog.dart';
import '../../data/providers.dart';
import '../onboarding/session.dart';

/// R3. The recycler changes their ₹/kg per material with −10/−1/+1/+10.
class MyRatesScreen extends ConsumerStatefulWidget {
  const MyRatesScreen({super.key});

  @override
  ConsumerState<MyRatesScreen> createState() => _MyRatesScreenState();
}

class _MyRatesScreenState extends ConsumerState<MyRatesScreen> {
  /// Edited rates in whole rupees per kg, by material code.
  Map<String, int>? _rupees;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final id = ref.watch(sessionProvider).recyclerId;
    final me = (ref.watch(recyclersProvider).value ?? const <Recycler>[])
        .where((r) => r.id == id)
        .firstOrNull;
    final materials =
        ref.watch(materialsProvider).value ?? const <ScrapMaterial>[];
    final rupees = _rupees ??= me == null
        ? null
        : {
            for (final m in materials)
              m.code: ((me.ratesPaisePerKg[m.code] ?? 0) + 50) ~/ 100,
          };

    return KScaffold(
      titleKey: 'tile_my_rates',
      instructionKey: 'my_rates_instruction',
      body: rupees == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                      for (final m in materials)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: AppIcons.material(
                                    m.iconAsset,
                                    size: 36,
                                  ),
                                  title: Text(s.t(m.nameKey)),
                                  trailing: Text(
                                    '₹${Fmt.indian(rupees[m.code] ?? 0)}${s.t('per_kg_short')}',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    for (final d in const [-10, -1, 1, 10])
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(3),
                                          child: FilledButton.tonal(
                                            onPressed: () => setState(
                                              () => rupees[m.code] =
                                                  ((rupees[m.code] ?? 0) + d)
                                                      .clamp(0, 100000),
                                            ),
                                            child: Text(
                                              d > 0 ? '+$d' : '−${-d}',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ActionButton(
                    icon: Icons.save,
                    labelKey: 'save',
                    colour: AppColors.confirmed,
                    speakLabel: false,
                    onPressed: () {
                      ref.read(recordsRepositoryProvider)?.saveRecyclerRates(
                        id!,
                        {
                          for (final e in rupees.entries)
                            if (e.value > 0) e.key: e.value * 100,
                        },
                      );
                      ref.speak('saved');
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
