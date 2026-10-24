import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/i18n/app_strings.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseReady = await _initFirebase();
  // Hindi is the default language (PLAN.md §2). Phase 3 reads the saved choice.
  final strings = await AppStrings.load('hi');

  runApp(
    ProviderScope(
      overrides: [
        appStringsProvider.overrideWithValue(strings),
        firebaseReadyProvider.overrideWithValue(firebaseReady),
      ],
      child: const KabadiwalaApp(),
    ),
  );
}

/// Never blocks the app: if Firebase is not set up yet (or fails), we keep
/// running and show the "not ready" status instead.
Future<bool> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (e) {
    debugPrint('Firebase not ready: $e');
    return false;
  }
}
