// lib/features/library/providers/library_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/files/audio_fingerprint_service.dart';
import '../models/artist.dart';
import '../models/library_index.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../repositories/library_extras_repository.dart';
import '../services/audio_fingerprint_backfill_service.dart';
import '../services/duplicate_song_cleanup_service.dart';
import 'library_data_providers.dart';

final librarySongsProvider =
    AsyncNotifierProvider<LibrarySongsNotifier, List<Song>>(
  LibrarySongsNotifier.new,
);

final duplicateSongCleanupServiceProvider =
    Provider<DuplicateSongCleanupService>((ref) {
  return DuplicateSongCleanupService(
    songRepository: ref.watch(songRepositoryProvider),
    localFileService: ref.watch(localFileServiceProvider),
    extrasRepository: ref.watch(libraryExtrasRepositoryProvider),
  );
});

final audioFingerprintServiceProvider = Provider<AudioFingerprintService>((
  ref,
) {
  return AudioFingerprintService();
});

final audioFingerprintBackfillServiceProvider =
    Provider<AudioFingerprintBackfillService>((ref) {
  return AudioFingerprintBackfillService(
    songRepository: ref.watch(songRepositoryProvider),
    fingerprintService: ref.watch(audioFingerprintServiceProvider),
  );
});

final libraryExtrasRepositoryProvider = Provider<LibraryExtrasRepository>((
  ref,
) {
  return LibraryExtrasRepository(ref.watch(databaseServiceProvider));
});

class LibrarySongsNotifier extends AsyncNotifier<List<Song>> {
  @override
  Future<List<Song>> build() async {
    final repository = ref.watch(songRepositoryProvider);
    return repository.getSongs();
  }

  /// Reloads songs without flashing the list empty: the previous list stays
  /// on screen until the new one arrives.
  Future<void> refreshSongs() async {
    final next = await AsyncValue.guard(() async {
      final repository = ref.read(songRepositoryProvider);
      return repository.getSongs();
    });
    state = next;
  }
}

final libraryArtistsProvider = FutureProvider<List<Artist>>((ref) async {
  // Re-read whenever the songs change (imports create artists).
  await ref.watch(librarySongsProvider.future);
  final repository = ref.watch(artistRepositoryProvider);
  return repository.getArtists();
});

/// The full library with lookup maps. Rebuilds whenever songs are refreshed.
final libraryIndexProvider = FutureProvider<LibraryIndex>((ref) async {
  final songs = await ref.watch(librarySongsProvider.future);
  final artists = await ref.watch(libraryArtistsProvider.future);
  final albums = await ref.watch(albumRepositoryProvider).getAlbums();
  final links =
      await ref.watch(libraryExtrasRepositoryProvider).getAllSongArtistLinks();

  return LibraryIndex(
    songs: songs,
    artists: artists,
    albums: albums,
    artistIdsBySong: links,
  );
});

/// Kept for screens that still ask per song.
final songArtistsProvider =
    FutureProvider.family<List<Artist>, String>((ref, songId) async {
  final index = await ref.watch(libraryIndexProvider.future);
  final song = index.songsById[songId];

  if (song == null) {
    return const [];
  }

  return index.artistsFor(song);
});

// --------------------------------------------------------------- sorting

class SongSortNotifier extends Notifier<SongSort> {
  @override
  SongSort build() => SongSort.title;

  void set(SongSort sort) => state = sort;
}

final songSortProvider = NotifierProvider<SongSortNotifier, SongSort>(
  SongSortNotifier.new,
);

final sortedSongsProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final sort = ref.watch(songSortProvider);
  return ref.watch(libraryIndexProvider).whenData((index) => index.sorted(sort));
});

// ------------------------------------------------------------- favorites

class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    return ref.watch(libraryExtrasRepositoryProvider).getFavoriteIds();
  }

  Future<void> toggle(String songId) async {
    final current = state.value ?? <String>{};
    final makeFavorite = !current.contains(songId);

    // Update the heart immediately, then persist.
    state = AsyncData(
      makeFavorite ? {...current, songId} : ({...current}..remove(songId)),
    );

    await ref
        .read(libraryExtrasRepositoryProvider)
        .setFavorite(songId, makeFavorite);
    ref.invalidate(favoriteSongsProvider);
  }
}

final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

final isFavoriteProvider = Provider.family<bool, String>((ref, songId) {
  return ref.watch(favoritesProvider).value?.contains(songId) ?? false;
});

final favoriteSongsProvider = FutureProvider<List<Song>>((ref) async {
  final index = await ref.watch(libraryIndexProvider.future);
  final ids =
      await ref.watch(libraryExtrasRepositoryProvider).getFavoriteIdsOrdered();
  return index.songsFromIds(ids);
});

// ---------------------------------------------------------------- recent

final recentSongsProvider = FutureProvider<List<Song>>((ref) async {
  final index = await ref.watch(libraryIndexProvider.future);
  final ids = await ref.watch(libraryExtrasRepositoryProvider).getRecentSongIds();
  return index.songsFromIds(ids);
});

// ------------------------------------------------------------- playlists

final playlistsProvider = FutureProvider<List<Playlist>>((ref) async {
  // Recount when songs are deleted.
  await ref.watch(librarySongsProvider.future);
  return ref.watch(libraryExtrasRepositoryProvider).getPlaylists();
});

final playlistSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, playlistId) async {
  final index = await ref.watch(libraryIndexProvider.future);
  final ids = await ref
      .watch(libraryExtrasRepositoryProvider)
      .getPlaylistSongIds(playlistId);
  return index.songsFromIds(ids);
});
