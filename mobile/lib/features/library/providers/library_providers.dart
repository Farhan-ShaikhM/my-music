// lib/features/library/providers/library_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artist.dart';
import '../models/song.dart';

// 1. ADD THIS IMPORT (pointing to your data/repository provider file)
import 'library_data_providers.dart'; 

final librarySongsProvider =
    AsyncNotifierProvider<LibrarySongsNotifier, List<Song>>(
  LibrarySongsNotifier.new,
);

class LibrarySongsNotifier extends AsyncNotifier<List<Song>> {
  @override
  Future<List<Song>> build() async {
    // This now resolves successfully
    final repository = ref.watch(songRepositoryProvider); 
    return repository.getSongs();
  }

  Future<void> refreshSongs() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(songRepositoryProvider);
      return repository.getSongs();
    });
  }
}

final libraryArtistsProvider = FutureProvider<List<Artist>>((ref) async {
  final repository = ref.watch(artistRepositoryProvider);
  return repository.getArtists();
});
