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
  });

  final bool languageChosen;
  final String? pinHash;

  /// Only in memory: every cold start asks for the PIN again.
  final bool unlocked;
  final UserRole? role;
  final String? recyclerId;

  Session copyWith({
    bool? languageChosen,
    String? pinHash,
    bool? unlocked,
    UserRole? role,
    String? recyclerId,
  }) => Session(
    languageChosen: languageChosen ?? this.languageChosen,
    pinHash: pinHash ?? this.pinHash,
    unlocked: unlocked ?? this.unlocked,
    role: role ?? this.role,
    recyclerId: recyclerId ?? this.recyclerId,
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
    ]);
    state = Session(languageChosen: state.languageChosen);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Session>(
  SessionNotifier.new,
);
