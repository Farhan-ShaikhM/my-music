import 'package:sqflite/sqflite.dart';

import '../../../data/database/database_service.dart';
import '../models/album.dart';
import 'album_repository.dart';

class SqliteAlbumRepository implements AlbumRepository {
  final DatabaseService _databaseService;

  SqliteAlbumRepository(this._databaseService);

  @override
  Future<List<Album>> getAlbums() async {
    final db = await _databaseService.database;

    final rows = await db.query(
      'albums',
      orderBy: 'title COLLATE NOCASE ASC',
    );

    return rows.map(Album.fromMap).toList();
  }

  @override
  Future<Album?> getAlbumById(String id) async {
    final db = await _databaseService.database;

    final rows = await db.query(
      'albums',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Album.fromMap(rows.first);
  }

  @override
  Future<void> insertAlbum(Album album) async {
    final db = await _databaseService.database;

    await db.insert(
      'albums',
      album.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateAlbum(Album album) async {
    final db = await _databaseService.database;

    await db.update(
      'albums',
      album.toMap(),
      where: 'id = ?',
      whereArgs: [album.id],
    );
  }

  @override
  Future<void> deleteAlbum(String id) async {
    final db = await _databaseService.database;

    await db.delete(
      'albums',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}