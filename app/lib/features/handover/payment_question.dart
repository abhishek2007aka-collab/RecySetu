import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/records.dart';
import '../ledger/ledger_providers.dart';
import 'handover_screen.dart';

/// "The recycler says they paid you ₹X. Did you get the money?" with a big
/// green Yes and a red No. The deal completes only on Yes. Asks out loud
/// when it first appears.
class PaymentQuestionCard extends ConsumerStatefulWidget {
  const PaymentQuestionCard({
    super.key,
    required this.confirmation,
    this.saidNo = false,
  });

  final Confirmation confirmation;

  /// The collector already answered "not received" once.
  final bool saidNo;

  static Map<String, Object> params(
    Confirmation c,
    String Function(String) t,
  ) => {
    'amount': (c.paidPaise + 50) ~/ 100,
    'mode': t(HandoverScreen.modeKey(c.paymentMode)),
  };

  @override
  ConsumerState<PaymentQuestionCard> createState() =>
      _PaymentQuestionCardState();
}

class _PaymentQuestionCardState extends ConsumerState<PaymentQuestionCard> {
  void _ask() {
    final s = ref.read(appStringsProvider);
    ref.speak(
      'payment_question',
      PaymentQuestionCard.params(widget.confirmation, s.t),
      true,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ask();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final c = widget.confirmation;
    final colour = widget.saidNo ? AppColors.hazard : AppColors.pending;

    Widget answer(bool yes) => Expanded(
      child: SizedBox(
        height: 72,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: yes ? AppColors.confirmed : AppColors.hazard,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          icon: Icon(yes ? Icons.check_circle : Icons.cancel, size: 32),
          label: FittedBox(
            child: Text(s.t(yes ? 'payment_yes' : 'payment_no')),
          ),
          onPressed: () {
            answerPayment(ref, c, received: yes);
            ref.speak(
              yes ? 'payment_received_done' : 'payment_not_received',
              PaymentQuestionCard.params(c, s.t),
              true,
            );
          },
        ),
      ),
    );

    return Card(
      color: colour.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colour, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _ask,
              child: Row(
                children: [
                  Icon(
                    widget.saidNo ? Icons.warning : Icons.schedule,
                    color: colour,
                    size: 40,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.t(
                            widget.saidNo
                                ? 'status_not_received'
                                : 'payment_question_short',
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: colour),
                        ),
                        Text(
                          '${Fmt.rupees(c.paidPaise)} · '
                          '${s.t(HandoverScreen.modeKey(c.paymentMode))}',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.volume_up, size: 32),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                answer(true),
                if (!widget.saidNo) ...[
                  const SizedBox(width: 8),
                  answer(false),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
