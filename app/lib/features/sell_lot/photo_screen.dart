import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/action_button.dart';
import '../../core/widgets/k_scaffold.dart';
import 'category_screen.dart';
import 'sell_draft.dart';

/// S6. Up to 3 photos; tap a photo's X to retake it.
class PhotoScreen extends ConsumerStatefulWidget {
  const PhotoScreen({super.key});

  @override
  ConsumerState<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends ConsumerState<PhotoScreen> {
  bool _busy = false;

  Future<void> _capture() async {
    setState(() => _busy = true);
    try {
      final photo = await ref.read(photoStoreProvider).capture();
      if (photo != null) ref.read(sellDraftProvider.notifier).addPhoto(photo);
    } catch (e) {
      debugPrint('camera: $e');
      ref.speak('photo_failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(sellDraftProvider.select((d) => d.photos));
    final full = photos.length >= SellDraft.maxPhotos;

    return KScaffold(
      titleKey: 'tile_sell',
      instructionKey: 'photo_instruction',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                for (var i = 0; i < SellDraft.maxPhotos; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: i < photos.length
                            ? _Thumb(
                                path: photos[i].path,
                                onRemove: () => ref
                                    .read(sellDraftProvider.notifier)
                                    .removePhoto(photos[i]),
                              )
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: const Icon(
                                  Icons.photo_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Center(
                child: SizedBox.square(
                  dimension: 160,
                  child: FilledButton(
                    style: FilledButton.styleFrom(shape: const CircleBorder()),
                    onPressed: full || _busy ? null : _capture,
                    child: _busy
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.photo_camera, size: 80),
                  ),
                ),
              ),
            ),
            ActionButton(
              icon: Icons.arrow_forward,
              labelKey: 'next',
              colour: AppColors.confirmed,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CategoryScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(path), fit: BoxFit.cover, cacheWidth: 300),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: IconButton.filled(
          style: IconButton.styleFrom(backgroundColor: AppColors.hazard),
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: onRemove,
        ),
      ),
    ],
  );
}
