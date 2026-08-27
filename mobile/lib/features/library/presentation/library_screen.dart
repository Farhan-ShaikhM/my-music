import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/library/models/import_song_draft.dart';
import 'package:mobile/features/library/presentation/widgets/artwork_image.dart';
import 'package:mobile/features/library/screens/import_song_review_screen.dart';

import '../models/song.dart';
import '../providers/library_providers.dart';
// import 'widgets/song_artwork.dart';
import '../providers/library_data_providers.dart';

// import '../services/duplicate_song_exception.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  Future<void> _deleteSong(
    BuildContext context,
    WidgetRef ref,
    Song song,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete song?'),
          content: Text('Remove "${song.title}" from your library?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final repository = ref.read(songRepositoryProvider);

      await repository.deleteSong(song.id);

      await ref.read(librarySongsProvider.notifier).refreshSongs();

      ref.invalidate(libraryArtistsProvider);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${song.title}" deleted from library')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete song: $error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch both async state providers at the top of the build tree
    final songsAsync = ref.watch(librarySongsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Music')),

      // 2. Wrap the conditional logic block inside an immediate-invoked execution function
      body: () {
        if (songsAsync.hasError) {
          return Center(
            child: Text(
              'Failed to load library:\n${songsAsync.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        // Safely extract underlying lists
        final songs = songsAsync.value ?? [];

        // Build the fast key-value profile mapping for human-readable artist names

        if (songs.isEmpty) {
          return const Center(child: Text('No music in your library yet.'));
        }

        // 3. Render list with actual artist names instead of raw system hashes
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final songArtistsAsync = ref.watch(songArtistsProvider(song.id));

            return ListTile(
              leading: ArtworkImage(
                artworkPath: song.localArtworkPath,
                size: 56,
              ),
              title: Text(song.title),
              subtitle: songArtistsAsync.when(
                loading: () => const Text('Loading artist...'),
                error: (error, stackTrace) => Text(
  'Artist error: $error',
),
                data: (artists) {
                  if (artists.isEmpty) {
  return const Text('No linked artist');
}
                  return Text(artists.map((artist) => artist.name).join(', '));
                },
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete song',
                onPressed: () => _deleteSong(context, ref, song),
              ),
            );
          },
        );
      }(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final importService = ref.read(musicImportServiceProvider);

          try {
            final draft = await importService.pickSongForImport();

            if (draft == null || !context.mounted) {
              return;
            }

            final reviewedDraft = await Navigator.push<ImportSongDraft>(
              context,
              MaterialPageRoute(
                builder: (_) => ImportSongReviewScreen(draft: draft),
              ),
            );

            if (reviewedDraft == null || !context.mounted) {
              return;
            }

            // Import will be connected in the next step.
            await ref.read(librarySongsProvider.notifier).refreshSongs();

            ref.invalidate(libraryArtistsProvider);
            if (!context.mounted) {
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added "${reviewedDraft.title}" to your library'),
              ),
            );
          } catch (error) {
            if (!context.mounted) {
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to prepare song: $error')),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
