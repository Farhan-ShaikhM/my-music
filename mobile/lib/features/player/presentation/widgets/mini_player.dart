import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../../providers/player_providers.dart';
import '../screens/now_playing_screen.dart';
import 'queue_sheet.dart';

/// Floating card above the list: artwork, title, play/pause inside a
/// progress ring, and the queue button. Hidden when nothing is loaded.
class MiniPlayer extends ConsumerWidget {
  /// Dark variant for the lyric page on top of the coloured background.
  final bool onDark;

  const MiniPlayer({super.key, this.onDark = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(currentSongProvider);

    if (song == null) {
      return const SizedBox.shrink();
    }

    final background =
        onDark ? Colors.black.withValues(alpha: 0.22) : const Color(0xFFF0F0F3);
    final textColor = onDark ? Colors.white : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        elevation: onDark ? 0 : 2,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onDark ? null : () => openNowPlaying(context),
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                ArtworkImage(
                  artworkPath: song.localArtworkPath,
                  seedId: song.id,
                  size: 72,
                  borderRadius: 0,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                ),
                _PlayPauseRing(color: textColor),
                if (!onDark)
                  IconButton(
                    tooltip: 'Queue',
                    iconSize: 30,
                    icon: Icon(Icons.queue_music_rounded, color: textColor),
                    onPressed: () => showQueueSheet(context),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayPauseRing extends ConsumerWidget {
  final Color color;

  const _PlayPauseRing({required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(playerPlayingProvider).value ?? false;
    final progress = ref.watch(playerProgressProvider);

    return IconButton(
      tooltip: playing ? 'Pause' : 'Play',
      onPressed: () =>
          ref.read(musicPlayerServiceProvider).togglePlayPause(),
      icon: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.5,
                color: color,
                backgroundColor: color.withValues(alpha: 0.18),
              ),
            ),
            Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: color,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

void openNowPlaying(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => const NowPlayingScreen(),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(curved),
          child: child,
        );
      },
    ),
  );
}
