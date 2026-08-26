import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/library_providers.dart';
import 'widgets/song_artwork.dart';
import '../providers/library_data_providers.dart';
import '../services/duplicate_song_exception.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch both async state providers at the top of the build tree
    final songsAsync = ref.watch(librarySongsProvider);
    final artistsAsync = ref.watch(libraryArtistsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Music')),
      
      // 2. Wrap the conditional logic block inside an immediate-invoked execution function
      body: () {
        if (songsAsync.isLoading || artistsAsync.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (songsAsync.hasError) {
          return Center(
            child: Text(
              'Failed to load library:\n${songsAsync.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (artistsAsync.hasError) {
          return Center(
            child: Text(
              'Failed to load artists:\n${artistsAsync.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        // Safely extract underlying lists
        final songs = songsAsync.value ?? [];
        final artists = artistsAsync.value ?? [];

        // Build the fast key-value profile mapping for human-readable artist names
        final artistMap = {
          for (final artist in artists) artist.id: artist.name,
        };

        if (songs.isEmpty) {
          return const Center(child: Text('No music in your library yet.'));
        }

        // 3. Render list with actual artist names instead of raw system hashes
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final displayArtistName =
                artistMap[song.artistId] ?? 'Unknown artist';

            return ListTile(
              leading: SongArtwork(artworkPath: song.localArtworkPath),
              title: Text(song.title),
              subtitle: Text(displayArtistName),
            );
          },
        );
      }(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final importService = ref.read(musicImportServiceProvider);

          try {
            final song = await importService.pickAndImportSong();

            if (song != null && context.mounted) {
              await ref.read(librarySongsProvider.notifier).refreshSongs();

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added "${song.title}" to your library'),
                ),
              );
            }
          } on DuplicateSongException catch (error) {
            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '"${error.existingSong.title}" is already in your library.',
                ),
              ),
            );
          } catch (error) {
            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to import song: $error')),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
