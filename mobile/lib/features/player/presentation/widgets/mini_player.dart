import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/models/song.dart';
import '../../../library/providers/library_providers.dart';
import '../../providers/music_player_provider.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends ConsumerWidget {
  final Song song;

  const MiniPlayer({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlayingAsync = ref.watch(playerPlayingProvider);

    return Material(
      elevation: 8,
      child: InkWell(
        onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => NowPlayingScreen(song: song),
    ),
  );
},
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              const SizedBox(width: 8),

              ArtworkImage(
                artworkPath: song.localArtworkPath,
                size: 56,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _ArtistName(song: song),
                  ],
                ),
              ),

              isPlayingAsync.when(
                loading: () => const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
                error: (_, _) => IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => _play(ref),
                ),
                data: (isPlaying) {
                  return IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () async {
                      final player =
                          ref.read(musicPlayerServiceProvider);

                      if (isPlaying) {
                        await player.pause();
                      } else {
                        await player.resume();
                      }
                    },
                  );
                },
              ),

              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _play(WidgetRef ref) async {
    final player = ref.read(musicPlayerServiceProvider);
    await player.playSong(song);
  }
}

class _ArtistName extends ConsumerWidget {
  final Song song;

  const _ArtistName({
    required this.song,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync =
        ref.watch(songArtistsProvider(song.id));

    return artistsAsync.when(
      loading: () => const Text(
        'Loading artist...',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      error: (_, _) => const Text(
        'Unknown artist',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      data: (artists) {
        if (artists.isEmpty) {
          return const Text(
            'Unknown artist',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        return Text(
          artists.map((artist) => artist.name).join(', '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}