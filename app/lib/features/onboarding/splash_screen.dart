import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/widgets/app_logo.dart';

/// Branded loading screen shown after the PIN: logo, app name, tagline and
/// the team credit. Lasts [duration]; a tap skips it.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    required this.onDone,
    this.duration = const Duration(milliseconds: 2200),
  });

  final VoidCallback onDone;
  final Duration duration;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final Timer _timer = Timer(widget.duration, _finish);
  bool _done = false;

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void initState() {
    super.initState();
    _timer; // start the countdown
  }

  @override
  void dispose() {
    _timer.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final logoIn = CurvedAnimation(parent: _anim, curve: Curves.elasticOut);
    final textIn = CurvedAnimation(
      parent: _anim,
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2E7D32), Color(0xFF0B3D0F)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                ScaleTransition(scale: logoIn, child: const AppLogo(size: 160)),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: textIn,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(textIn),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          FittedBox(
                            child: Text(
                              s.t('brand'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 46,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          // The name in the user's own script (helps TTS
                          // and readers of that script).
                          if (s.t('app_name') != s.t('brand'))
                            Text(
                              s.t('app_name'),
                              style: TextStyle(
                                color: AppLogo.gold,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            s.t('tagline'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      color: AppLogo.gold,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                const Spacer(),
                FadeTransition(opacity: textIn, child: const _TeamCredit()),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Developed by ⚡ ByteStorms" card, with the hackathon line underneath.
class _TeamCredit extends ConsumerWidget {
  const _TeamCredit();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Column(
      children: [
        Text(
          s.t('developed_by'),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: AppLogo.gold.withValues(alpha: 0.8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, color: AppLogo.gold, size: 30),
              const SizedBox(width: 6),
              Text(
                s.t('team_name'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          s.t('hackathon_line'),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
