import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/widgets/big_tile.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../data/models/catalog.dart';
import '../../data/models/records.dart';
import '../../data/providers.dart';
import 'recycler_apply_screen.dart';
import 'session.dart';

/// S4. Everyone chooses: Kabadiwala or Recycler. Recycler mode opens only
/// for a phone number linked to an authorised recycler listing
/// (`ownerPhone`); anyone else who taps Recycler can apply to join, and the
/// team verifies the registration first. Recyclers can confirm payments and
/// set rates, so this must never be open to anyone.
class RoleScreen extends ConsumerWidget {
  const RoleScreen({super.key, required this.uid, required this.phone});

  final String uid;
  final String phone;

  static Recycler? invitedRecycler(List<Recycler> all, String phone) {
    if (phone.isEmpty) return null;
    for (final r in all) {
      if (r.ownerPhone != null && r.ownerPhone == phone) return r;
    }
    return null;
  }

  static void choose(
    WidgetRef ref, {
    required String uid,
    required String phone,
    required UserRole role,
    Recycler? recycler,
  }) {
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
    ref.read(sessionProvider.notifier)
      ..setApplied(false)
      ..setRole(role, recyclerId: recycler?.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recyclers = ref.watch(recyclersProvider).value ?? const <Recycler>[];

    void recyclerTapped() {
      final invited = invitedRecycler(recyclers, phone);
      if (invited != null) {
        choose(
          ref,
          uid: uid,
          phone: phone,
          role: UserRole.recycler,
          recycler: invited,
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RecyclerApplyScreen(uid: uid, phone: phone),
          ),
        );
      }
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
                onTap: () => choose(
                  ref,
                  uid: uid,
                  phone: phone,
                  role: UserRole.collector,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BigTile(
                icon: Icons.factory,
                labelKey: 'role_recycler',
                colour: const Color(0xFF0D47A1),
                onTap: recyclerTapped,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
