import 'package:sqflite/sqflite.dart';

import '../../../data/database/database_service.dart';
import 'song_artist_repository.dart';
import '../models/artist.dart';

class SqliteSongArtistRepository implements SongArtistRepository {
  final DatabaseService _databaseService;

  SqliteSongArtistRepository(this._databaseService);

  @override
  Future<void> addArtistToSong({
    required String songId,
    required String artistId,
  }) async {
    final db = await _databaseService.database;

    await db.insert(
      'song_artists',
      {
        'song_id': songId,
        'artist_id': artistId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<void> removeArtistFromSong({
    required String songId,
    required String artistId,
  }) async {
    final db = await _databaseService.database;

    await db.delete(
      'song_artists',
      where: 'song_id = ? AND artist_id = ?',
      whereArgs: [
        songId,
        artistId,
      ],
    );
  }

  @override
  Future<void> setArtistsForSong({
    required String songId,
    required List<String> artistIds,
  }) async {
    final db = await _databaseService.database;

    await db.transaction((txn) async {
      await txn.delete(
        'song_artists',
        where: 'song_id = ?',
        whereArgs: [songId],
      );

      for (final artistId in artistIds) {
        await txn.insert(
          'song_artists',
          {
            'song_id': songId,
            'artist_id': artistId,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  @override
  Future<List<String>> getArtistIdsForSong(
    String songId,
  ) async {
    final db = await _databaseService.database;

    final rows = await db.query(
      'song_artists',
      columns: ['artist_id'],
      where: 'song_id = ?',
      whereArgs: [songId],
    );

    return rows
        .map((row) => row['artist_id'] as String)
        .toList();
  }

  @override
@override
Future<List<Artist>> getArtistsForSong(
  String songId,
) async {
  final db = await _databaseService.database;

  final rows = await db.rawQuery(
    '''
    SELECT artists.*
    FROM artists
    INNER JOIN song_artists
      ON artists.id = song_artists.artist_id
    WHERE song_artists.song_id = ?
    ORDER BY artists.name COLLATE NOCASE ASC
    ''',
    [songId],
  );

  return rows.map(Artist.fromMap).toList();
}
}