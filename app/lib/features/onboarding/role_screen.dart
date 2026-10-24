import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/widgets/big_tile.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../data/models/catalog.dart';
import '../../data/models/records.dart';
import '../../data/providers.dart';
import 'session.dart';

/// S4. Recycler mode is offered only when this phone number was invited by
/// a recycler listing (`ownerPhone`). Everyone else is a collector.
class RoleScreen extends ConsumerWidget {
  const RoleScreen({super.key, required this.uid, required this.phone});

  final String uid;
  final String phone;

  static Recycler? invitedRecycler(List<Recycler> all, String phone) {
    for (final r in all) {
      if (r.ownerPhone != null && r.ownerPhone == phone) return r;
    }
    return null;
  }

  void _choose(WidgetRef ref, UserRole role, {Recycler? recycler}) {
    final repo = ref.read(recordsRepositoryProvider);
    repo?.saveUser(
      AppUser(
        uid: uid,
        role: role,
        phone: phone,
        language: ref.read(languageProvider),
        createdAt: DateTime.now().toUtc(),
        recyclerId: recycler?.id,
      ),
    );
    if (recycler != null) repo?.claimRecycler(recycler.id, uid);
    ref.read(sessionProvider.notifier).setRole(role, recyclerId: recycler?.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recyclers = ref.watch(recyclersProvider);
    if (!recyclers.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final invited = invitedRecycler(recyclers.value!, phone);

    if (invited == null) {
      // Not invited: no choice to make, go straight in as a collector.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _choose(ref, UserRole.collector),
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return KScaffold(
      titleKey: 'choose_role',
      instructionKey: 'choose_role',
      showSync: false,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: BigTile(
                icon: Icons.person,
                labelKey: 'role_collector',
                onTap: () => _choose(ref, UserRole.collector),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BigTile(
                icon: Icons.factory,
                labelKey: 'role_recycler',
                onTap: () => _choose(ref, UserRole.recycler, recycler: invited),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
