import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/big_tile.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../core/widgets/voice_toggle.dart';
import '../onboarding/language_pick_screen.dart';
import '../onboarding/logout_button.dart';
import '../debug/audio_debug_screen.dart';
import '../ledger/ledger_providers.dart';
import '../ledger/ledger_screen.dart';
import '../prices/rates_board_screen.dart';
import '../sell_lot/photo_screen.dart';
import '../sell_lot/sell_draft.dart';
import 'coming_soon_screen.dart';

/// S5. Collector home: 4 big tiles. Long-press the title for the audio check.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const tiles = [
    (Icons.add_a_photo, 'tile_sell', AppColors.brand),
    (Icons.currency_rupee, 'tile_rates', Color(0xFF0D47A1)),
    (Icons.account_balance_wallet, 'tile_earnings', Color(0xFF4A148C)),
    (Icons.health_and_safety, 'tile_safety', AppColors.hazard),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Turn synced recycler confirmations into ledger entries.
    ref.watch(ledgerAutoWriterProvider);
    void open(Widget screen) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => screen));

    return KScaffold(
      titleKey: 'app_name',
      instructionKey: 'home_instruction',
      onTitleLongPress: () => open(const AudioDebugScreen()),
      extraActions: const [
        VoiceToggleButton(),
        ChangeLanguageButton(),
        LogoutButton(),
      ],
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          for (final (icon, key, colour) in tiles)
            BigTile(
              icon: icon,
              labelKey: key,
              colour: colour,
              onTap: () {
                if (key == 'tile_sell') {
                  ref.read(sellDraftProvider.notifier).start();
                }
                open(screenFor(key));
              },
            ),
        ],
      ),
    );
  }

  /// Later phases replace these placeholders.
  static Widget screenFor(String tileKey) => switch (tileKey) {
    'tile_sell' => const PhotoScreen(),
    'tile_rates' => const RatesBoardScreen(),
    'tile_earnings' => const LedgerScreen(),
    _ => ComingSoonScreen(titleKey: tileKey),
  };
}
