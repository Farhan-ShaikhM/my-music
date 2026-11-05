import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../player/presentation/widgets/mini_player.dart';
import '../models/song.dart';
import 'widgets/song_options_sheet.dart';
import 'widgets/song_tile.dart';

/// A plain list of songs with the Shuffle header: used for an album, artist,
/// folder, playlist, Favorites and Recent.
class SongListScreen extends ConsumerWidget {
  final String title;
  /// Watches the songs, so the list updates live (e.g. after removing a
  /// song from a playlist).
  final AsyncValue<List<Song>> Function(WidgetRef ref) watchSongs;
  final String emptyMessage;

  /// Optional per-song extra menu action (e.g. remove from playlist).
  final String? extraActionLabel;
  final void Function(Song song)? onExtraAction;
  final List<Widget>? actions;

  const SongListScreen({
    super.key,
    required this.title,
    required this.watchSongs,
    this.emptyMessage = 'No songs here yet.',
    this.extraActionLabel,
    this.onExtraAction,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = watchSongs(ref);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: actions,
      ),
      body: Stack(
        children: [
          songs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    emptyMessage,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 110),
                itemCount: list.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ShuffleHeader(
                      count: list.length,
                      onShuffle: () =>
                          playFromList(context, ref, list, 0, shuffle: true),
                    );
                  }

                  final song = list[index - 1];

                  return SongTile(
                    song: song,
                    onTap: () => playFromList(context, ref, list, index - 1),
                    extraActionLabel: extraActionLabel,
                    onExtraAction:
                        onExtraAction == null ? null : () => onExtraAction!(song),
                  );
                },
              );
            },
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(top: false, child: MiniPlayer()),
          ),
        ],
      ),
    );
  }
}
