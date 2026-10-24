import 'package:flutter/material.dart';

import '../../core/widgets/big_tile.dart';
import '../../core/widgets/k_scaffold.dart';
import '../../core/widgets/voice_toggle.dart';
import '../onboarding/language_pick_screen.dart';
import '../onboarding/logout_button.dart';
import 'my_rates_screen.dart';
import 'recent_deals_screen.dart';
import 'scan_screen.dart';

/// R1. Recycler home: scan a collector's QR, set my rates, recent deals.
class RecyclerHomeScreen extends StatelessWidget {
  const RecyclerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => screen));

    return KScaffold(
      titleKey: 'role_recycler',
      instructionKey: 'recycler_home_choose',
      extraActions: const [
        VoiceToggleButton(),
        ChangeLanguageButton(),
        LogoutButton(),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: BigTile(
                icon: Icons.qr_code_scanner,
                labelKey: 'tile_scan',
                onTap: () => open(const ScanScreen()),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: BigTile(
                      icon: Icons.currency_rupee,
                      labelKey: 'tile_my_rates',
                      colour: const Color(0xFF0D47A1),
                      onTap: () => open(const MyRatesScreen()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: BigTile(
                      icon: Icons.receipt_long,
                      labelKey: 'tile_recent',
                      colour: const Color(0xFF4A148C),
                      onTap: () => open(const RecentDealsScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
