import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/models/song.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../../../library/providers/library_providers.dart';
import '../../providers/music_player_provider.dart';
import '../../providers/player_queue_provider.dart';
import '../../models/repeat_mode.dart';
import '../../providers/player_repeat_provider.dart';
import '../../providers/player_shuffle_provider.dart';

class NowPlayingScreen extends ConsumerWidget {
  final Song song;

  const NowPlayingScreen({super.key, required this.song});

  Future<void> _playSong(WidgetRef ref, Song song) async {
    final player = ref.read(musicPlayerServiceProvider);

    await player.playSong(song);

    ref.read(currentSongProvider.notifier).setSong(song);
  }

  // New combined cycle button: Loop Playlist -> Loop Song -> Shuffle
  Widget _buildModeButton(
    BuildContext context,
    WidgetRef ref,
    bool isShuffle,
    RepeatMode repeatMode,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget icon;
    String tooltip;

    // Determine current visual state
    if (isShuffle) {
      tooltip = 'Shuffle';
      icon = Icon(Icons.shuffle, color: colorScheme.primary);
    } else if (repeatMode == RepeatMode.song) {
      tooltip = 'Repeat one';
      icon = Icon(Icons.repeat_one, color: colorScheme.primary);
    } else {
      // Default fallback is Repeat All
      tooltip = 'Repeat all';
      icon = Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.repeat, color: colorScheme.primary),
          Positioned(
            right: -6,
            bottom: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ALL',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return IconButton(
      tooltip: tooltip,
      onPressed: () {
        final repeatNotifier = ref.read(playerRepeatProvider.notifier);
        final shuffleNotifier = ref.read(playerShuffleProvider.notifier);

        if (isShuffle) {
          // Current: Shuffle -> Next: Loop Playlist
          shuffleNotifier.setEnabled(false);
          repeatNotifier.setMode(RepeatMode.playlist);
        } else if (repeatMode == RepeatMode.song) {
          // Current: Loop Song -> Next: Shuffle
          // We set repeat to playlist here so the shuffled queue loops endlessly
          repeatNotifier.setMode(RepeatMode.playlist); 
          shuffleNotifier.setEnabled(true);
        } else {
          // Current: Loop Playlist -> Next: Loop Song
          shuffleNotifier.setEnabled(false);
          repeatNotifier.setMode(RepeatMode.song);
        }
      },
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final displayedSong = currentSong ?? song;

    final repeatMode = ref.watch(playerRepeatProvider);
    final isShuffle = ref.watch(playerShuffleProvider);

    final artistsAsync = ref.watch(songArtistsProvider(displayedSong.id));
    final isPlayingAsync = ref.watch(playerPlayingProvider);
    final positionAsync = ref.watch(playerPositionProvider);
    final durationAsync = ref.watch(playerDurationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),

              // Artwork
              ArtworkImage(
                artworkPath: displayedSong.localArtworkPath,
                size: 300,
              ),

              const SizedBox(height: 32),

              // Song title
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  displayedSong.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 8),

              // Artists
              Align(
                alignment: Alignment.centerLeft,
                child: artistsAsync.when(
                  loading: () => const Text('Loading artist...'),
                  error: (_, _) => const Text('Unknown artist'),
                  data: (artists) {
                    if (artists.isEmpty) {
                      return const Text('Unknown artist');
                    }

                    return Text(
                      artists.map((artist) => artist.name).join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              // Progress Section
              positionAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const LinearProgressIndicator(value: 0),
                data: (position) {
                  final duration = durationAsync.value ?? Duration.zero;

                  final maxMilliseconds = duration.inMilliseconds;
                  final positionMilliseconds = position.inMilliseconds;

                  final progress = maxMilliseconds > 0
                      ? (positionMilliseconds / maxMilliseconds).clamp(0.0, 1.0)
                      : 0.0;

                  return Column(
                    children: [
                      Slider(
                        value: progress,
                        onChanged: maxMilliseconds <= 0
                            ? null
                            : (value) {
                                final newPosition = Duration(
                                  milliseconds:
                                      (maxMilliseconds * value).round(),
                                );

                                ref
                                    .read(musicPlayerServiceProvider)
                                    .seek(newPosition);
                              },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position)),
                          Text(_formatDuration(duration)),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Playback & Mode Controls Row
              isPlayingAsync.when(
                loading: () => const SizedBox(
                  height: 64,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const SizedBox(height: 64),
                data: (isPlaying) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      
                      // 1. Single combined Mode Button
                      _buildModeButton(context, ref, isShuffle, repeatMode),

                      // 2. Previous Button
                      IconButton(
                        onPressed: () async {
                          final previousSong = ref
                              .read(playerQueueProvider.notifier)
                              .previousSong(
                                displayedSong.id,
                                repeatAll: repeatMode == RepeatMode.playlist,
                              );

                          if (previousSong == null) return;

                          try {
                            await _playSong(ref, previousSong);
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $error')),
                            );
                          }
                        },
                        iconSize: 36,
                        icon: const Icon(Icons.skip_previous),
                      ),

                      // 3. Play / Pause Button
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: FilledButton(
                          onPressed: () async {
                            final player = ref.read(musicPlayerServiceProvider);
                            if (isPlaying) {
                              await player.pause();
                            } else {
                              await player.resume();
                            }
                          },
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 32,
                          ),
                        ),
                      ),

                      // 4. Next Button
                      IconButton(
                        onPressed: () async {
                          final nextSong = ref
                              .read(playerQueueProvider.notifier)
                              .nextSong(
                                displayedSong.id,
                                repeatAll: repeatMode == RepeatMode.playlist,
                              );

                          if (nextSong == null) return;

                          try {
                            await _playSong(ref, nextSong);
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $error')),
                            );
                          }
                        },
                        iconSize: 36,
                        icon: const Icon(Icons.skip_next),
                      ),

                      // 5. Invisible Spacer (Matches the width of the Mode Button to keep Play/Pause centered)
                      const SizedBox(width: 48), 
                    ],
                  );
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}