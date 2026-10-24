import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../core/widgets/number_pad.dart';
import 'session.dart';

/// S3. Set a 4-digit PIN (typed twice), or unlock with it. Works offline.
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key, required this.uid, required this.setting});

  final String uid;

  /// True: create a new PIN. False: unlock.
  final bool setting;

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  String? _first;
  String? _errorKey;

  String get _promptKey => !widget.setting
      ? 'enter_pin'
      : (_first == null ? 'set_pin' : 'confirm_pin');

  void _complete() {
    final session = ref.read(sessionProvider.notifier);
    if (!widget.setting) {
      if (!session.unlock(widget.uid, _pin)) _error('wrong_pin');
      return;
    }
    if (_first == null) {
      setState(() {
        _first = _pin;
        _pin = '';
      });
      ref.speak('confirm_pin');
    } else if (_first == _pin) {
      session.setPin(widget.uid, _pin);
    } else {
      _first = null;
      _error('pin_mismatch');
    }
  }

  void _error(String key) {
    setState(() {
      _errorKey = key;
      _pin = '';
    });
    ref.speak(key);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return KScaffold(
      titleKey: _promptKey,
      instructionKey: _promptKey,
      showSync: false,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.lock, size: 56),
            const SizedBox(height: 12),
            DigitDisplay(value: _pin, length: 4, obscure: true),
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
            const Spacer(),
            NumberPad(
              okLabel: s.t('ok'),
              deleteLabel: s.t('delete'),
              onDigit: (d) {
                if (_pin.length >= 4) return;
                setState(() {
                  _errorKey = null;
                  _pin = '$_pin$d';
                });
                if (_pin.length == 4) _complete();
              },
              onDelete: () {
                if (_pin.isNotEmpty) {
                  setState(() => _pin = _pin.substring(0, _pin.length - 1));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
