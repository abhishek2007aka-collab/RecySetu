import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_providers.dart';
import '../../data/models/records.dart';

/// Where the user is in onboarding. Stored on the phone so the app opens
/// offline with only the PIN after the first online login.
class Session {
  const Session({
    this.languageChosen = false,
    this.pinHash,
    this.unlocked = false,
    this.role,
    this.recyclerId,
    this.splashDone = false,
    this.appliedAsRecycler = false,
  });

  final bool languageChosen;
  final String? pinHash;

  /// Only in memory: every cold start asks for the PIN again.
  final bool unlocked;
  final UserRole? role;
  final String? recyclerId;

  /// Only in memory: the branded loading screen shows once per app start,
  /// right after the PIN.
  final bool splashDone;

  /// Sent a recycler application that is still being checked.
  final bool appliedAsRecycler;

  Session copyWith({
    bool? languageChosen,
    String? pinHash,
    bool? unlocked,
    UserRole? role,
    String? recyclerId,
    bool? splashDone,
    bool? appliedAsRecycler,
  }) => Session(
    languageChosen: languageChosen ?? this.languageChosen,
    pinHash: pinHash ?? this.pinHash,
    unlocked: unlocked ?? this.unlocked,
    role: role ?? this.role,
    recyclerId: recyclerId ?? this.recyclerId,
    splashDone: splashDone ?? this.splashDone,
    appliedAsRecycler: appliedAsRecycler ?? this.appliedAsRecycler,
  );
}

/// The PIN is never stored, only a SHA-256 of it mixed with the user id.
/// (A 4-digit PIN is a convenience lock for this phone, not strong security.)
String hashPin(String uid, String pin) =>
    sha256.convert(utf8.encode('kc-pin-v1|$uid|$pin')).toString();

class SessionNotifier extends Notifier<Session> {
  static const _language = 'language_chosen';
  static const _pin = 'pin_hash';
  static const _role = 'role';
  static const _recycler = 'recycler_id';
  static const _applied = 'applied_as_recycler';

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  Session build() {
    final p = ref.watch(sharedPrefsProvider);
    final role = p.getString(_role);
    return Session(
      languageChosen: p.getBool(_language) ?? false,
      pinHash: p.getString(_pin),
      role: role == null ? null : UserRole.values.byName(role),
      recyclerId: p.getString(_recycler),
      appliedAsRecycler: p.getBool(_applied) ?? false,
    );
  }

  void chooseLanguage(String code) {
    ref.read(languageProvider.notifier).select(code);
    _prefs.setBool(_language, true);
    state = state.copyWith(languageChosen: true);
  }

  void setPin(String uid, String pin) {
    final h = hashPin(uid, pin);
    _prefs.setString(_pin, h);
    state = state.copyWith(pinHash: h, unlocked: true);
  }

  /// Returns false for a wrong PIN.
  bool unlock(String uid, String pin) {
    if (hashPin(uid, pin) != state.pinHash) return false;
    state = state.copyWith(unlocked: true);
    return true;
  }

  /// Recycler application sent (or withdrawn when [applied] is false).
  void setApplied(bool applied) {
    _prefs.setBool(_applied, applied);
    state = state.copyWith(appliedAsRecycler: applied);
  }

  void finishSplash() => state = state.copyWith(splashDone: true);

  void setRole(UserRole role, {String? recyclerId}) {
    _prefs.setString(_role, role.name);
    if (recyclerId != null) _prefs.setString(_recycler, recyclerId);
    state = state.copyWith(role: role, recyclerId: recyclerId);
  }

  /// Forget this phone's login data (keeps the language).
  Future<void> reset() async {
    await Future.wait([
      _prefs.remove(_pin),
      _prefs.remove(_role),
      _prefs.remove(_recycler),
      _prefs.remove(_applied),
    ]);
    state = Session(languageChosen: state.languageChosen);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Session>(
  SessionNotifier.new,
);
