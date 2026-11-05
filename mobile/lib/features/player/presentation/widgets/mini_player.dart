import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../library/models/song.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../../../library/providers/library_providers.dart';
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

    if (onDark) return _DarkMiniPlayer(song: song);

    // Library card: 52dp tall, 10dp radius, cover flush on the left.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Material(
        color: AppColors.miniPlayer,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openNowPlaying(context),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                ArtworkImage(
                  artworkPath: song.localArtworkPath,
                  seedId: song.id,
                  size: 52,
                  borderRadius: 10,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const _PlayPauseRing(color: AppColors.textPrimary),
                IconButton(
                  tooltip: 'Queue',
                  iconSize: 24,
                  icon: const Icon(
                    Icons.queue_music_rounded,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => showQueueSheet(context),
                ),
                const SizedBox(width: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card at the bottom of the LYRIC page: inset cover, title + artist,
/// play ring. 60dp tall on a translucent dark background.
class _DarkMiniPlayer extends ConsumerWidget {
  final Song song;

  const _DarkMiniPlayer({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artist = ref.watch(
      libraryIndexProvider.select((i) => i.value?.artistLabel(song) ?? ''),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            ArtworkImage(
              artworkPath: song.localArtworkPath,
              seedId: '${song.id}-grey',
              size: 40,
              borderRadius: 8,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            const _PlayPauseRing(color: Colors.white),
          ],
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
        width: 28,
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 1.8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.18),
              ),
            ),
            Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: color,
              size: 16,
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
