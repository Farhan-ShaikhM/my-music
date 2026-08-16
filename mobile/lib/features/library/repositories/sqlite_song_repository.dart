import 'package:sqflite/sqflite.dart';

import '../../../data/database/database_service.dart';
import '../models/song.dart';
import 'song_repository.dart';

class SqliteSongRepository implements SongRepository {
  final DatabaseService _databaseService;

  SqliteSongRepository(this._databaseService);

  @override
  Future<List<Song>> getSongs() async {
    final db = await _databaseService.database;

    final rows = await db.query(
      'songs',
      orderBy: 'title COLLATE NOCASE ASC',
    );

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

    await db.delete(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}