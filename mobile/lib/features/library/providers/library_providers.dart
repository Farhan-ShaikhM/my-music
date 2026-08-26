// lib/features/library/providers/library_providers.dart
// import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/library/services/audio_fingerprint_backfill_service.dart';

import '../models/artist.dart';
import '../models/song.dart';
import '../../../data/files/audio_fingerprint_service.dart';
import '../services/duplicate_song_cleanup_service.dart';
// import '../../../data/files/local_file_service.dart';

// 1. ADD THIS IMPORT (pointing to your data/repository provider file)
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

class LibrarySongsNotifier extends AsyncNotifier<List<Song>> {
  @override
  Future<List<Song>> build() async {
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
