import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/models/records.dart';
import 'data/providers.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/application_status_screen.dart';
import 'features/onboarding/language_pick_screen.dart';
import 'features/onboarding/login_screen.dart';
import 'features/onboarding/pin_screen.dart';
import 'features/onboarding/role_screen.dart';
import 'features/onboarding/session.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/recycler_mode/recycler_home_screen.dart';

/// Picks the first screen from the onboarding state:
/// language -> login (needs internet once) -> set PIN -> role -> home.
/// After that, every cold start goes: unlock with PIN -> home (works offline).
class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final auth = ref.watch(authUserProvider);

    if (!session.languageChosen) return const LanguagePickScreen();
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = auth.value;
    if (user == null) return const LoginScreen();
    if (session.pinHash == null) return PinScreen(uid: user.uid, setting: true);
    if (!session.unlocked) return PinScreen(uid: user.uid, setting: false);
    if (!session.splashDone) {
      return SplashScreen(
        onDone: ref.read(sessionProvider.notifier).finishSplash,
      );
    }
    if (session.role == null) {
      final phone = user.phoneNumber ?? '';
      return session.appliedAsRecycler
          ? ApplicationStatusScreen(uid: user.uid, phone: phone)
          : RoleScreen(uid: user.uid, phone: phone);
    }
    return session.role == UserRole.recycler
        ? const RecyclerHomeScreen()
        : const HomeScreen();
  }
}
