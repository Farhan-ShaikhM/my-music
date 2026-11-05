import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../../../data/database/database_service.dart';
import '../models/playlist.dart';

/// Favorites, play history, playlists and the song-artist link table in one
/// place, so the UI can load the whole library with a handful of queries
/// instead of two queries per list row.
class LibraryExtrasRepository {
  final DatabaseService _databaseService;

  LibraryExtrasRepository(this._databaseService);

  Future<Database> get _db => _databaseService.database;

  // ---------------------------------------------------------------- links

  /// song_id -> artist ids, for every song.
  Future<Map<String, List<String>>> getAllSongArtistLinks() async {
    final db = await _db;
    final rows = await db.query('song_artists');
    final result = <String, List<String>>{};

    for (final row in rows) {
      final songId = row['song_id'] as String;
      final artistId = row['artist_id'] as String;
      result.putIfAbsent(songId, () => []).add(artistId);
    }

    return result;
  }

  // ------------------------------------------------------------ favorites

  Future<Set<String>> getFavoriteIds() async {
    final db = await _db;
    final rows = await db.query('favorites', columns: ['song_id']);

    return rows.map((row) => row['song_id'] as String).toSet();
  }

  Future<void> setFavorite(String songId, bool favorite) async {
    final db = await _db;

    if (favorite) {
      await db.insert(
        'favorites',
        {
          'song_id': songId,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } else {
      await db.delete('favorites', where: 'song_id = ?', whereArgs: [songId]);
    }
  }

  /// Favorite song ids, most recently liked first.
  Future<List<String>> getFavoriteIdsOrdered() async {
    final db = await _db;
    final rows = await db.query(
      'favorites',
      columns: ['song_id'],
      orderBy: 'created_at DESC',
    );

    return rows.map((row) => row['song_id'] as String).toList();
  }

  // -------------------------------------------------------------- history

  Future<void> addToHistory(String songId) async {
    final db = await _db;

    await db.insert('play_history', {
      'song_id': songId,
      'played_at': DateTime.now().toIso8601String(),
    });

    // Keep the table small.
    await db.execute('''
      DELETE FROM play_history WHERE id NOT IN (
        SELECT id FROM play_history ORDER BY id DESC LIMIT 500
      )
    ''');
  }

  /// Distinct song ids, most recently played first.
  Future<List<String>> getRecentSongIds({int limit = 100}) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT song_id, MAX(id) AS last_id
      FROM play_history
      GROUP BY song_id
      ORDER BY last_id DESC
      LIMIT ?
      ''',
      [limit],
    );

    return rows.map((row) => row['song_id'] as String).toList();
  }

  Future<void> clearHistory() async {
    final db = await _db;
    await db.delete('play_history');
  }

  // ------------------------------------------------------------ playlists

  Future<List<Playlist>> getPlaylists() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT playlists.*, COUNT(playlist_songs.song_id) AS song_count
      FROM playlists
      LEFT JOIN playlist_songs ON playlist_songs.playlist_id = playlists.id
      GROUP BY playlists.id
      ORDER BY playlists.created_at ASC
    ''');

    return rows.map(Playlist.fromMap).toList();
  }

  Future<String> createPlaylist(String name) async {
    final db = await _db;
    final now = DateTime.now();
    final id =
        'playlist-${now.microsecondsSinceEpoch}-${Random().nextInt(1 << 20)}';

    await db.insert('playlists', {
      'id': id,
      'name': name,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    return id;
  }

  Future<void> renamePlaylist(String playlistId, String name) async {
    final db = await _db;
    await db.update(
      'playlists',
      {'name': name, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<void> deletePlaylist(String playlistId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'playlist_songs',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
      await txn.delete('playlists', where: 'id = ?', whereArgs: [playlistId]);
    });
  }

  Future<List<String>> getPlaylistSongIds(String playlistId) async {
    final db = await _db;
    final rows = await db.query(
      'playlist_songs',
      columns: ['song_id'],
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'position ASC',
    );

    return rows.map((row) => row['song_id'] as String).toList();
  }

  /// Returns false when the song was already in the playlist.
  Future<bool> addSongToPlaylist(String playlistId, String songId) async {
    final db = await _db;
    final existing = await db.query(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return false;
    }

    final maxRows = await db.rawQuery(
      'SELECT MAX(position) AS max_position FROM playlist_songs '
      'WHERE playlist_id = ?',
      [playlistId],
    );
    final maxPosition = (maxRows.first['max_position'] as int?) ?? -1;

    await db.insert(
      'playlist_songs',
      {
        'playlist_id': playlistId,
        'song_id': songId,
        'position': maxPosition + 1,
        'added_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    return true;
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final db = await _db;
    await db.delete(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
  }

  // ---------------------------------------------------------------- songs

  Future<void> updateLyricsPath(String songId, String? lyricsPath) async {
    final db = await _db;
    await db.update(
      'songs',
      {
        'local_lyrics_path': lyricsPath,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  /// sqflite does not enforce foreign keys unless PRAGMA foreign_keys is on,
  /// so ON DELETE CASCADE never ran. Remove every row that points at the song.
  Future<void> deleteSongReferences(String songId) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (final table in [
        'song_artists',
        'favorites',
        'play_history',
        'playlist_songs',
      ]) {
        await txn.delete(table, where: 'song_id = ?', whereArgs: [songId]);
      }
    });
  }
}
