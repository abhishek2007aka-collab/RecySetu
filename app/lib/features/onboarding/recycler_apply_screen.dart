import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../data/models/catalog.dart';
import '../../data/models/records.dart';
import '../../data/providers.dart';
import 'session.dart';

/// "Apply to join as a recycler". The applicant either picks their business
/// from the official list of authorised recyclers, or types its name and
/// authorisation number. Nothing is unlocked here: the team checks the
/// number against the CPCB/SPCB list and approves it.
class RecyclerApplyScreen extends ConsumerStatefulWidget {
  const RecyclerApplyScreen({
    super.key,
    required this.uid,
    required this.phone,
  });

  final String uid;
  final String phone;

  @override
  ConsumerState<RecyclerApplyScreen> createState() =>
      _RecyclerApplyScreenState();
}

class _RecyclerApplyScreenState extends ConsumerState<RecyclerApplyScreen> {
  String? _pickedId;
  final _name = TextEditingController();
  final _reg = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _reg.dispose();
    super.dispose();
  }

  bool get _ready =>
      _pickedId != null ||
      (_name.text.trim().isNotEmpty && _reg.text.trim().isNotEmpty);

  void _send(List<Recycler> listed) {
    final picked = listed.where((r) => r.id == _pickedId).firstOrNull;
    ref
        .read(recordsRepositoryProvider)
        ?.saveRecyclerApplication(
          RecyclerApplication(
            uid: widget.uid,
            phone: widget.phone,
            createdAt: DateTime.now().toUtc(),
            recyclerId: picked?.id,
            businessName: picked?.name ?? _name.text.trim(),
            authorisationRef: picked?.authorisationRef ?? _reg.text.trim(),
          ),
        );
    ref.read(sessionProvider.notifier).setApplied(true);
    ref.speak('apply_sent');
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    // Authorised listings nobody has claimed or been invited to yet.
    final listed = [
      for (final r in ref.watch(recyclersProvider).value ?? const <Recycler>[])
        if (r.authorised && r.ownerUid == null && r.ownerPhone == null) r,
    ];

    return KScaffold(
      titleKey: 'apply_title',
      instructionKey: 'apply_instruction',
      showSync: false,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            s.t('apply_pick'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final r in listed)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  width: _pickedId == r.id ? 3 : 0,
                  color: _pickedId == r.id
                      ? AppColors.confirmed
                      : Colors.transparent,
                ),
              ),
              child: ListTile(
                minTileHeight: 64,
                leading: Icon(
                  _pickedId == r.id ? Icons.check_circle : Icons.factory,
                  color: _pickedId == r.id ? AppColors.confirmed : null,
                  size: 32,
                ),
                title: Text(r.name),
                subtitle: Text(r.address),
                onTap: () =>
                    setState(() => _pickedId = _pickedId == r.id ? null : r.id),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            s.t('apply_not_listed'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            enabled: _pickedId == null,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 20),
            decoration: InputDecoration(
              labelText: s.t('apply_business'),
              prefixIcon: const Icon(Icons.storefront),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reg,
            enabled: _pickedId == null,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 20),
            decoration: InputDecoration(
              labelText: s.t('apply_reg'),
              prefixIcon: const Icon(Icons.verified_outlined),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          ActionButton(
            icon: Icons.send,
            labelKey: 'apply_send',
            colour: AppColors.confirmed,
            speakLabel: false,
            onPressed: _ready ? () => _send(listed) : null,
          ),
        ],
      ),
    );
  }
}
