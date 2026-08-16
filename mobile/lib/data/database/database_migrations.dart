import 'package:sqflite/sqflite.dart';

class DatabaseMigrations {
  static Future<void> onCreate(Database db, int version) async {
    await _createArtistsTable(db);
    await _createAlbumsTable(db);
    await _createGenresTable(db);
    await _createSongsTable(db);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createArtistsTable(db);
      await _createAlbumsTable(db);
      await _createGenresTable(db);
    }
  }

  static Future<void> _createArtistsTable(Database db) async {
    await db.execute('''
      CREATE TABLE artists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        artwork_reference TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createAlbumsTable(Database db) async {
    await db.execute('''
      CREATE TABLE albums (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist_id TEXT,
        artwork_reference TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (artist_id) REFERENCES artists(id)
      )
    ''');
  }

  static Future<void> _createGenresTable(Database db) async {
    await db.execute('''
      CREATE TABLE genres (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
      )
    ''');
  }

  static Future<void> _createSongsTable(Database db) async {
    await db.execute('''
      CREATE TABLE songs (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist_id TEXT,
        album_id TEXT,
        track_number INTEGER,
        disc_number INTEGER,
        duration_ms INTEGER,
        genre TEXT,
        artwork_reference TEXT,
        cloud_audio_reference TEXT,
        cloud_lyrics_reference TEXT,
        local_audio_path TEXT,
        local_artwork_path TEXT,
        local_lyrics_path TEXT,
        download_state TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (artist_id) REFERENCES artists(id),
        FOREIGN KEY (album_id) REFERENCES albums(id)
      )
    ''');
  }
}