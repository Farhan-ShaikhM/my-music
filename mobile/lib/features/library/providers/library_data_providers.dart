// lib/features/library/providers/library_data_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/database_service.dart';
import '../repositories/album_repository.dart';
import '../repositories/artist_repository.dart';
import '../repositories/song_repository.dart';
import '../repositories/sqlite_album_repository.dart';
import '../repositories/sqlite_artist_repository.dart';
import '../repositories/sqlite_song_repository.dart';
import '../../../data/files/local_file_service.dart';
import '../../../services/music_import_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

final songRepositoryProvider = Provider<SongRepository>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return SqliteSongRepository(databaseService);
});

final artistRepositoryProvider = Provider<ArtistRepository>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return SqliteArtistRepository(databaseService);
});

final albumRepositoryProvider = Provider<AlbumRepository>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return SqliteAlbumRepository(databaseService);
});

final localFileServiceProvider = Provider<LocalFileService>((ref) => LocalFileService());

final musicImportServiceProvider = Provider<MusicImportService>((ref) {
  return MusicImportService(
    songRepository: ref.watch(songRepositoryProvider),
    artistRepository: ref.watch(artistRepositoryProvider),
    albumRepository: ref.watch(albumRepositoryProvider),
    localFileService: ref.watch(localFileServiceProvider),
  );
});
