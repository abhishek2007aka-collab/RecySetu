import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../data/models/catalog.dart';
import '../../data/models/records.dart';
import '../../data/providers.dart';
import 'logout_button.dart';
import 'role_screen.dart';
import 'session.dart';

/// Shown to someone who applied as a recycler, until the team decides.
/// Approval = the team links this phone number to the recycler listing, so
/// the same check as the role screen opens recycler mode.
class ApplicationStatusScreen extends ConsumerWidget {
  const ApplicationStatusScreen({
    super.key,
    required this.uid,
    required this.phone,
  });

  final String uid;
  final String phone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final application = ref.watch(myRecyclerApplicationProvider).value;
    final invited = RoleScreen.invitedRecycler(
      ref.watch(recyclersProvider).value ?? const <Recycler>[],
      phone,
    );
    final rejected = application?.status == ApplicationStatus.rejected;

    final (icon, colour, key) = invited != null
        ? (Icons.check_circle, AppColors.confirmed, 'apply_status_approved')
        : rejected
        ? (Icons.cancel, AppColors.hazard, 'apply_status_rejected')
        : (Icons.hourglass_top, AppColors.pending, 'apply_status_pending');

    return KScaffold(
      key: ValueKey(key),
      titleKey: 'apply_title',
      instructionKey: key,
      extraActions: const [LogoutButton()],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Icon(icon, size: 120, color: colour),
            const SizedBox(height: 16),
            Text(
              s.t(key),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (application != null) ...[
              const SizedBox(height: 12),
              Text(
                '${application.businessName}\n${application.authorisationRef}',
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
            if (invited != null)
              ActionButton(
                icon: Icons.factory,
                labelKey: 'open_recycler',
                colour: AppColors.confirmed,
                onPressed: () => RoleScreen.choose(
                  ref,
                  uid: uid,
                  phone: phone,
                  role: UserRole.recycler,
                  recycler: invited,
                ),
              ),
            const SizedBox(height: 12),
            ActionButton(
              icon: Icons.person,
              labelKey: 'use_as_collector',
              onPressed: () => RoleScreen.choose(
                ref,
                uid: uid,
                phone: phone,
                role: UserRole.collector,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.read(sessionProvider.notifier).setApplied(false),
              child: Text(s.t('back')),
            ),
          ],
        ),
      ),
    );
  }
}
