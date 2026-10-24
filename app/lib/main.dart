import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/app_providers.dart';
import 'core/i18n/app_strings.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final results = await Future.wait([
    _initFirebase(),
    SharedPreferences.getInstance(),
    AppStrings.loadAll(),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        firebaseReadyProvider.overrideWithValue(results[0] as bool),
        sharedPrefsProvider.overrideWithValue(results[1] as SharedPreferences),
        allStringsProvider.overrideWithValue(
          results[2] as Map<String, AppStrings>,
        ),
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
