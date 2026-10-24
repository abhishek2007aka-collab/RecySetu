import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/format.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/valuation/valuation.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../data/models/catalog.dart';
import '../../data/providers.dart';
import '../../core/geo/location.dart';
import '../../core/geo/recycler_ranking.dart';
import '../handover/handover_screen.dart';
import '../recyclers/recyclers_screen.dart';
import 'sell_draft.dart';

/// S9. Speaks the fair price ("about ₹340") and saves the lot as a draft.
/// Works fully offline: prices come from the phone's cache or seed data.
class EstimateScreen extends ConsumerStatefulWidget {
  const EstimateScreen({super.key});

  @override
  ConsumerState<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends ConsumerState<EstimateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _save());
  }

  void _save() {
    final price = ref.read(draftPriceProvider);
    final uid = ref.read(currentUidProvider);
    if (price == null || uid == null || ref.read(sellDraftProvider).saved) {
      return;
    }
    final grams = ref.read(sellDraftProvider).weightGrams;
    ref
        .read(sellDraftProvider.notifier)
        .save(collectorUid: uid, estimate: Valuation.estimate(grams, price));
  }

  void _openHandover(BuildContext context, RankedRecycler choice) {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final where = ref.read(myLocationProvider);
    final h = ref
        .read(sellDraftProvider.notifier)
        .handOver(
          collectorUid: uid,
          recyclerId: choice.recycler.id,
          agreedPaise: Valuation.paiseFor(
            ref.read(sellDraftProvider).weightGrams,
            choice.ratePaisePerKg,
          ),
          lat: where?.lat ?? 0,
          lng: where?.lng ?? 0,
        );
    if (h == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            HandoverScreen(handover: h, recyclerName: choice.recycler.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final draft = ref.watch(sellDraftProvider);
    final price = ref.watch(draftPriceProvider);
    final materials = ref.watch(materialsProvider).value ?? const [];
    final material = materials
        .where((m) => m.code == draft.materialCode)
        .firstOrNull;
    final estimate = price == null
        ? null
        : Valuation.estimate(draft.weightGrams, price);

    return KScaffold(
      titleKey: 'estimate_title',
      instructionKey: estimate == null ? 'no_price' : 'price_estimate',
      instructionParams: {'amount': estimate?.spokenRupees ?? 0},
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (material != null)
              ListTile(
                leading: AppIcons.material(material.iconAsset, size: 48),
                title: Text(
                  s.t(material.nameKey),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                trailing: Text(
                  '${Fmt.kg(draft.weightGrams)} ${s.t('kg')}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            if (material?.hazard == Hazard.high)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, color: AppColors.hazard, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    s.t('hazard_warning'),
                    style: const TextStyle(
                      color: AppColors.hazard,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            Expanded(
              child: Center(
                child: estimate == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.help,
                            size: 96,
                            color: AppColors.pending,
                          ),
                          Text(
                            s.t('no_price'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.volume_up, size: 40),
                          FittedBox(
                            child: Text(
                              '~₹${Fmt.indian(estimate.spokenRupees)}',
                              style: const TextStyle(
                                fontSize: 96,
                                fontWeight: FontWeight.w900,
                                color: AppColors.confirmed,
                              ),
                            ),
                          ),
                          Text(
                            '${Fmt.rupees(estimate.lowPaise)} – '
                            '${Fmt.rupees(estimate.highPaise)}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (draft.saved)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.confirmed,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(s.t('saved_offline')),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            ActionButton(
              icon: Icons.factory,
              labelKey: 'find_recycler',
              onPressed: estimate == null
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            RecyclersScreen(onSelect: _openHandover),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
