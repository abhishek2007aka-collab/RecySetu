import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_providers.dart';
import '../audio/audio_service.dart';
import '../sync/sync_status.dart';

/// Every screen's frame: title, a speaker button that replays the screen's
/// instruction, and the sync icon. The instruction is spoken once when the
/// screen opens, so nobody has to read it.
class KScaffold extends ConsumerStatefulWidget {
  const KScaffold({
    super.key,
    required this.titleKey,
    required this.instructionKey,
    required this.body,
    this.instructionParams = const {},
    this.showSync = true,
    this.onTitleLongPress,
  });

  final String titleKey;
  final String instructionKey;
  final Map<String, Object> instructionParams;
  final Widget body;
  final bool showSync;
  final VoidCallback? onTitleLongPress;

  @override
  ConsumerState<KScaffold> createState() => _KScaffoldState();
}

class _KScaffoldState extends ConsumerState<KScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speak();
    });
  }

  void _speak() => ref.speak(widget.instructionKey, widget.instructionParams);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: widget.onTitleLongPress,
          child: Text(s.t(widget.titleKey)),
        ),
        actions: [
          if (widget.showSync) const SyncIcon(),
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: s.t(widget.instructionKey, widget.instructionParams),
            onPressed: _speak,
          ),
        ],
      ),
      body: SafeArea(child: widget.body),
    );
  }
}
