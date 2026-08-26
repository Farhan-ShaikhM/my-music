import 'package:sqflite/sqflite.dart';

import '../../../data/database/database_service.dart';
import '../models/song.dart';
import 'song_repository.dart';

class SqliteSongRepository implements SongRepository {
  final DatabaseService _databaseService;

  SqliteSongRepository(this._databaseService);

  @override
  Future<void> updateLocalArtworkPath(
    String songId,
    String localArtworkPath,
  ) async {
    final db = await _databaseService.database;

    await db.update(
      'songs',
      {'local_artwork_path': localArtworkPath},
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  @override
  Future<List<Song>> getSongs() async {
    final db = await _databaseService.database;

    final rows = await db.query('songs', orderBy: 'title COLLATE NOCASE ASC');

    return rows.map(Song.fromMap).toList();
  }

  @override
  Future<Song?> getSongById(String id) async {
    final db = await _databaseService.database;

    final rows = await db.query(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Song.fromMap(rows.first);
  }

  @override
  Future<void> insertSong(Song song) async {
    final db = await _databaseService.database;

    await db.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateSong(Song song) async {
    final db = await _databaseService.database;

    await db.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  @override
  Future<void> deleteSong(String id) async {
    final db = await _databaseService.database;

    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Song?> getSongByLocalPath(String localAudioPath) async {
    final db = await _databaseService.database;

    final rows = await db.query(
      'songs',
      where: 'local_audio_path = ?',
      whereArgs: [localAudioPath],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Song.fromMap(rows.first);
  }

  @override
  Future<Song?> getSongByAudioFingerprint(String fingerprint) async {
    final db = await _databaseService.database;

    final rows = await db.query(
      'songs',
      where: 'audio_fingerprint = ?',
      whereArgs: [fingerprint],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Song.fromMap(rows.first);
  }

  @override
  Future<void> updateAudioFingerprint(String songId, String fingerprint) async {
    final db = await _databaseService.database;

    await db.update(
      'songs',
      {'audio_fingerprint': fingerprint},
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  @override
  Future<List<Song>> getSongsByAudioFingerprint(String fingerprint) async {
    final db = await _databaseService.database;

    final rows = await db.query(
      'songs',
      where: 'audio_fingerprint = ?',
      whereArgs: [fingerprint],
      orderBy: 'created_at ASC',
    );

    return rows.map(Song.fromMap).toList();
  }
}
