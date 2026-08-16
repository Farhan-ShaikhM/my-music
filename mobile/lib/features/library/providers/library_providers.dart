import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database_service.dart';
import '../repositories/song_repository.dart';
import '../repositories/sqlite_song_repository.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final songRepositoryProvider = Provider<SongRepository>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);

  return SqliteSongRepository(databaseService);
});