import 'package:sqflite/sqflite.dart';

class DatabaseMigrations {
  static Future<void> onCreate(Database db, int version) async {
    await _createSongsTable(db);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Future migrations will be added here.
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
        updated_at TEXT NOT NULL
      )
    ''');
  }
}