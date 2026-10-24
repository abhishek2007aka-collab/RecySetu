import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../core/widgets/number_pad.dart';
import '../../data/providers.dart';

/// S2. Phone number on a big keypad, then the 6-digit SMS code.
/// For development use the Firebase test numbers (no real SMS is sent).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum _Stage { phone, sending, code }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  _Stage _stage = _Stage.phone;
  String _phone = '';
  String _code = '';
  String? _verificationId;
  String? _errorKey;

  FirebaseAuth? get _auth => ref.read(firebaseAuthProvider);

  void _fail(String key) {
    if (!mounted) return;
    setState(() {
      _errorKey = key;
      _stage = key == 'wrong_code' ? _Stage.code : _Stage.phone;
      _code = '';
    });
    ref.speak(key);
  }

  Future<void> _sendCode() async {
    final auth = _auth;
    if (auth == null) return _fail('need_internet_login');
    setState(() {
      _stage = _Stage.sending;
      _errorKey = null;
    });
    ref.speak('sending_code');
    if (kDebugMode) {
      // Lets Firebase test phone numbers work on emulators and debug builds.
      await auth.setSettings(appVerificationDisabledForTesting: true);
    }
    await auth.verifyPhoneNumber(
      phoneNumber: '+91$_phone',
      verificationCompleted: (credential) async {
        // Android read the SMS by itself.
        await auth.signInWithCredential(credential);
      },
      verificationFailed: (e) {
        debugPrint('verifyPhoneNumber: ${e.code} ${e.message}');
        _fail(
          e.code == 'network-request-failed'
              ? 'need_internet_login'
              : 'login_error',
        );
      },
      codeSent: (verificationId, _) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _stage = _Stage.code;
        });
        ref.speak('enter_otp');
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _checkCode() async {
    final auth = _auth;
    final id = _verificationId;
    if (auth == null || id == null) return;
    try {
      await auth.signInWithCredential(
        PhoneAuthProvider.credential(verificationId: id, smsCode: _code),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('signIn: ${e.code}');
      _fail(
        e.code == 'invalid-verification-code' ? 'wrong_code' : 'login_error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final onCode = _stage == _Stage.code;
    final value = onCode ? _code : _phone;
    final length = onCode ? 6 : 10;

    void edit(String v) => setState(() {
      _errorKey = null;
      onCode ? _code = v : _phone = v;
    });

    return KScaffold(
      key: ValueKey(_stage),
      titleKey: onCode ? 'enter_otp' : 'enter_phone',
      instructionKey: onCode ? 'enter_otp' : 'enter_phone',
      showSync: false,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(onCode ? Icons.sms : Icons.phone_android, size: 56),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!onCode)
                  const Text(
                    '+91 ',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                Flexible(
                  child: DigitDisplay(value: value, length: length),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_errorKey != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, color: AppColors.hazard, size: 32),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      s.t(_errorKey!),
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(color: AppColors.hazard),
                    ),
                  ),
                ],
              ),
            if (_stage == _Stage.sending) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
            const Spacer(),
            if (_stage != _Stage.sending)
              NumberPad(
                okLabel: s.t('ok'),
                deleteLabel: s.t('delete'),
                onDigit: (d) {
                  if (value.length < length) edit('$value$d');
                },
                onDelete: () {
                  if (value.isNotEmpty) {
                    edit(value.substring(0, value.length - 1));
                  }
                },
                onOk: value.length == length
                    ? (onCode ? _checkCode : _sendCode)
                    : null,
              ),
            const SizedBox(height: AppTheme.minTouch / 4),
          ],
        ),
      ),
    );
  }
}
