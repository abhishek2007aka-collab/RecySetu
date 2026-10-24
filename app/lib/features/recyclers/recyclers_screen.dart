import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/format.dart';
import '../../core/geo/location.dart';
import '../../core/geo/recycler_ranking.dart';
import '../../core/theme/app_theme.dart';
import '../../core/valuation/valuation.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../data/providers.dart';
import '../sell_lot/sell_draft.dart';

/// S10. Top 5 authorised recyclers for the lot's material, ranked by rate,
/// distance and pickup (PLAN.md §6.3). Works offline from cached data.
class RecyclersScreen extends ConsumerWidget {
  const RecyclersScreen({super.key, required this.onSelect});

  /// Called when the collector chooses a recycler (opens the handover).
  final void Function(BuildContext context, RankedRecycler choice) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final where = ref.watch(myLocationProvider);
    if (where == null) return const _LocationPrompt();

    final s = ref.watch(appStringsProvider);
    final draft = ref.watch(sellDraftProvider);
    final ranked = rankRecyclers(
      recyclers: ref.watch(recyclersProvider).value ?? const [],
      materialCode: draft.materialCode ?? '',
      from: where,
    );

    return KScaffold(
      titleKey: 'find_recycler',
      instructionKey: ranked.isEmpty ? 'no_recyclers' : 'recyclers_instruction',
      body: Column(
        children: [
          Expanded(
            child: ranked.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.search_off,
                      size: 120,
                      color: AppColors.pending,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: ranked.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _RecyclerCard(
                      rank: i + 1,
                      choice: ranked[i],
                      payoutPaise: ranked[i].ratePaisePerKg == null
                          ? null
                          : Valuation.paiseFor(
                              draft.weightGrams,
                              ranked[i].ratePaisePerKg!,
                            ),
                      onSelect: () => onSelect(context, ranked[i]),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextButton.icon(
              icon: const Icon(Icons.edit_location_alt),
              label: Text(s.t('change_location')),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _LocationPrompt(popWhenDone: true),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecyclerCard extends ConsumerWidget {
  const _RecyclerCard({
    required this.rank,
    required this.choice,
    required this.payoutPaise,
    required this.onSelect,
  });

  final int rank;
  final RankedRecycler choice;

  /// Null when the recycler's rate is not known.
  final int? payoutPaise;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final r = choice.recycler;
    final km = choice.distanceKm.toStringAsFixed(1);
    final rate = choice.ratePaisePerKg;
    final ratePerKg = rate == null ? null : (rate + 50) ~/ 100;
    final payoutRupees = payoutPaise == null
        ? null
        : (payoutPaise! + 50) ~/ 100;

    void speakRow() => ratePerKg == null
        ? ref.speak('recycler_spoken_norate', {'name': r.name, 'km': km})
        : ref.speak('recycler_spoken', {
            'name': r.name,
            'km': km,
            'rate': ratePerKg,
            'amount': payoutRupees!,
          });

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: rank == 1
            ? const BorderSide(color: AppColors.confirmed, width: 3)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: speakRow,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(child: Text('$rank')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Icon(Icons.verified, color: AppColors.confirmed),
                  Text(
                    s.t('authorised'),
                    style: const TextStyle(color: AppColors.confirmed),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Fact(Icons.place, s.t('km', {'km': km})),
                  _Fact(
                    Icons.currency_rupee,
                    ratePerKg == null
                        ? s.t('rate_unknown')
                        : '${Fmt.indian(ratePerKg)}${s.t('per_kg_short')}',
                  ),
                  if (r.offersPickup)
                    _Fact(Icons.local_shipping, s.t('pickup')),
                ],
              ),
              const SizedBox(height: 4),
              if (payoutRupees != null)
                Text(
                  '~₹${Fmt.indian(payoutRupees)}',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.confirmed,
                  ),
                )
              else
                Text(r.address, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.call, size: 28),
                      label: Text(s.t('call')),
                      onPressed: r.phone.isEmpty
                          ? null
                          : () => launchUrl(Uri(scheme: 'tel', path: r.phone)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.confirmed,
                      ),
                      icon: const Icon(Icons.check, size: 28),
                      label: Text(s.t('select')),
                      onPressed: () {
                        ref.speak('select');
                        onSelect();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 24),
      const SizedBox(width: 4),
      Text(text, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

/// Explains (out loud) why location helps, then: GPS, or pick an area.
class _LocationPrompt extends ConsumerStatefulWidget {
  const _LocationPrompt({this.popWhenDone = false});

  final bool popWhenDone;

  @override
  ConsumerState<_LocationPrompt> createState() => _LocationPromptState();
}

class _LocationPromptState extends ConsumerState<_LocationPrompt> {
  bool _busy = false;

  void _done() {
    if (widget.popWhenDone && mounted) Navigator.of(context).pop();
  }

  Future<void> _gps() async {
    setState(() => _busy = true);
    final ok = await ref.read(myLocationProvider.notifier).fromGps();
    if (!mounted) return;
    setState(() => _busy = false);
    ok ? _done() : ref.speak('location_failed');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final areas = ref.watch(areasProvider).value ?? const [];
    return KScaffold(
      titleKey: 'find_recycler',
      instructionKey: 'location_why',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.location_on, size: 80, color: AppColors.brand),
            const SizedBox(height: 12),
            _busy
                ? const CircularProgressIndicator()
                : ActionButton(
                    icon: Icons.my_location,
                    labelKey: 'use_my_location',
                    colour: AppColors.confirmed,
                    onPressed: _gps,
                  ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  for (final a in areas)
                    Card(
                      child: ListTile(
                        minTileHeight: 64,
                        leading: const Icon(Icons.home_work, size: 36),
                        title: Text(
                          s.t(a.nameKey),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        onTap: () {
                          ref.speak(a.nameKey);
                          ref.read(myLocationProvider.notifier).set((
                            lat: a.lat,
                            lng: a.lng,
                          ));
                          _done();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
