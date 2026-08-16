import 'package:sqflite/sqflite.dart';

import '../../../data/database/database_service.dart';
import '../models/artist.dart';
import 'artist_repository.dart';

class SqliteArtistRepository implements ArtistRepository {
  final DatabaseService _databaseService;

  SqliteArtistRepository(this._databaseService);

  @override
  Future<List<Artist>> getArtists() async {
    final db = await _databaseService.database;

    final rows = await db.query(
      'artists',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows.map(Artist.fromMap).toList();
  }

  @override
  Future<Artist?> getArtistById(String id) async {
    final db = await _databaseService.database;

    final rows = await db.query(
      'artists',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Artist.fromMap(rows.first);
  }

  @override
  Future<void> insertArtist(Artist artist) async {
    final db = await _databaseService.database;

    await db.insert(
      'artists',
      artist.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateArtist(Artist artist) async {
    final db = await _databaseService.database;

    await db.update(
      'artists',
      artist.toMap(),
      where: 'id = ?',
      whereArgs: [artist.id],
    );
  }

  @override
  Future<void> deleteArtist(String id) async {
    final db = await _databaseService.database;

    await db.delete(
      'artists',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}