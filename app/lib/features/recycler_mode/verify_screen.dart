import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/format.dart';
import '../../core/hash/anomaly_flags.dart';
import '../../core/hash/handover_hasher.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../data/models/catalog.dart';
import '../../data/models/records.dart';
import '../../data/providers.dart';
import '../handover/handover_screen.dart';
import '../onboarding/session.dart';
import '../sell_lot/weight_screen.dart';

/// R2 (part 2). Checks the QR's hash, then the recycler enters the weight
/// they measured and how they paid, and confirms. Works offline.
class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key, required this.payload});

  final String payload;

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  late final Handover? _h = HandoverHasher.parse(widget.payload);
  late final bool _hashOk = _h != null && HandoverHasher.verify(_h);
  late int _measured = _h?.weightGrams ?? 0;
  PaymentMode? _mode;
  bool _done = false;

  String get _verdictKey {
    final h = _h;
    if (h == null) return 'not_a_handover';
    if (!_hashOk) return 'verify_bad';
    if (h.recyclerId != ref.read(sessionProvider).recyclerId) {
      return 'wrong_recycler';
    }
    return 'verify_ok';
  }

  int get _amount =>
      AnomalyFlags.paidForMeasured(_h!.agreedPaise, _h.weightGrams, _measured);

  List<String> _flags(Price? board) => AnomalyFlags.forConfirmation(
    hashOk: _hashOk,
    declaredGrams: _h!.weightGrams,
    measuredGrams: _measured,
    agreedPaise: _h.agreedPaise,
    board: board,
  );

  void _confirm(Price? board) {
    final h = _h!;
    final recyclerId = ref.read(sessionProvider).recyclerId;
    final repo = ref.read(recordsRepositoryProvider);
    if (recyclerId == null || repo == null || _mode == null) return;
    repo.saveConfirmation(
      Confirmation(
        handoverId: h.id,
        collectorUid: h.collectorUid,
        recyclerId: recyclerId,
        confirmedAt: DateTime.now().toUtc(),
        measuredWeightGrams: _measured,
        amountPaise: _amount,
        paidPaise: _mode == PaymentMode.due ? 0 : _amount,
        paymentMode: _mode!,
        flags: _flags(board),
      ),
    );
    setState(() => _done = true);
    ref.speak('confirmed_done');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final h = _h;
    final verdict = _verdictKey;
    final good = verdict == 'verify_ok';
    final blocked = h == null || verdict == 'wrong_recycler';

    final banner = Card(
      color: (good ? AppColors.confirmed : AppColors.hazard).withValues(
        alpha: 0.15,
      ),
      child: ListTile(
        minTileHeight: 72,
        leading: Icon(
          good ? Icons.verified : Icons.warning,
          color: good ? AppColors.confirmed : AppColors.hazard,
          size: 44,
        ),
        title: Text(
          s.t(verdict),
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: good ? AppColors.confirmed : AppColors.hazard),
        ),
        subtitle: h == null ? null : Text(HandoverHasher.shortRef(h.hash)),
        onTap: () => ref.speak(verdict, const {}, true),
      ),
    );

    if (blocked || _done) {
      return KScaffold(
        titleKey: 'tile_scan',
        instructionKey: _done ? 'confirmed_done' : verdict,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              banner,
              if (_done)
                const Expanded(
                  child: Icon(
                    Icons.check_circle,
                    size: 160,
                    color: AppColors.confirmed,
                  ),
                )
              else
                const Spacer(),
              ActionButton(
                icon: Icons.home,
                labelKey: 'done',
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      );
    }

    final materials =
        ref.watch(materialsProvider).value ?? const <ScrapMaterial>[];
    final material = materials
        .where((m) => m.code == h.materialCode)
        .firstOrNull;
    final board = (ref.watch(pricesProvider).value ?? const <Price>[])
        .where((p) => p.materialCode == h.materialCode)
        .firstOrNull;
    final flags = _flags(board);

    return KScaffold(
      titleKey: 'tile_scan',
      instructionKey: verdict,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          banner,
          ListTile(
            leading: material == null
                ? const Icon(Icons.recycling, size: 40)
                : AppIcons.material(material.iconAsset, size: 40),
            title: Text(
              material == null ? h.materialCode : s.t(material.nameKey),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              '${Fmt.kg(h.weightGrams)} ${s.t('kg')} · '
              '${s.t('agreed')} ${Fmt.rupees(h.agreedPaise)}',
            ),
          ),
          const Divider(),
          _Section(icon: Icons.scale, labelKey: 'measured_weight_instruction'),
          Center(
            child: Text(
              '${Fmt.kg(_measured)} ${s.t('kg')}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
            ),
          ),
          Row(
            children: [
              for (final (delta, label) in WeightScreen.steps)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: SizedBox(
                      height: 60,
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () {
                          setState(
                            () => _measured = (_measured + delta).clamp(
                              0,
                              1000000,
                            ),
                          );
                          ref.speak('weight_spoken', {
                            'weight': Fmt.kg(_measured),
                          });
                        },
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const Divider(),
          _Section(icon: Icons.payments, labelKey: 'payment_instruction'),
          Row(
            children: [
              for (final (mode, icon) in const [
                (PaymentMode.cash, Icons.payments),
                (PaymentMode.upi, Icons.qr_code_2),
                (PaymentMode.due, Icons.schedule),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: SizedBox(
                      height: 88,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: _mode == mode
                              ? AppColors.confirmed.withValues(alpha: 0.2)
                              : null,
                          side: BorderSide(
                            width: _mode == mode ? 3 : 1,
                            color: _mode == mode
                                ? AppColors.confirmed
                                : Colors.grey,
                          ),
                        ),
                        onPressed: () {
                          setState(() => _mode = mode);
                          ref.speak(HandoverScreen.modeKey(mode));
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _mode == mode ? Icons.check_circle : icon,
                              size: 32,
                            ),
                            Text(s.t(HandoverScreen.modeKey(mode))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Center(
            child: Text(
              Fmt.rupees(_amount),
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: AppColors.confirmed,
              ),
            ),
          ),
          for (final f in flags)
            ListTile(
              leading: const Icon(Icons.warning, color: AppColors.hazard),
              title: Text(
                s.t('flag_$f'),
                style: const TextStyle(color: AppColors.hazard),
              ),
              onTap: () => ref.speak('flag_$f', const {}, true),
            ),
          const SizedBox(height: 8),
          ActionButton(
            icon: Icons.check,
            labelKey: 'confirm',
            colour: AppColors.confirmed,
            speakLabel: false,
            onPressed: _mode == null ? null : () => _confirm(board),
          ),
        ],
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({required this.icon, required this.labelKey});

  final IconData icon;
  final String labelKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    leading: Icon(icon, size: 32),
    title: Text(ref.watch(appStringsProvider).t(labelKey)),
    trailing: const Icon(Icons.volume_up),
    onTap: () => ref.speak(labelKey, const {}, true),
  );
}
