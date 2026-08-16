import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile/data/database/database_service.dart';
import 'package:mobile/features/library/models/song.dart';
import 'package:mobile/features/library/repositories/sqlite_song_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseService databaseService;
  late SqliteSongRepository repository;

  setUp(() async {
    databaseService = DatabaseService(
      databasePath: inMemoryDatabasePath,
    );

    repository = SqliteSongRepository(databaseService);

    await databaseService.database;
  });

  tearDown(() async {
    await databaseService.close();
  });

  final testSong = Song(
    id: 'song-001',
    title: 'Test Song',
    artistId: 'artist-001',
    albumId: 'album-001',
    trackNumber: 1,
    discNumber: 1,
    durationMs: 210000,
    genre: 'Test',
    artworkReference: null,
    cloudAudioReference: null,
    cloudLyricsReference: null,
    localAudioPath: null,
    localArtworkPath: null,
    localLyricsPath: null,
    downloadState: 'not_downloaded',
    createdAt: DateTime.parse('2026-08-17T00:00:00Z'),
    updatedAt: DateTime.parse('2026-08-17T00:00:00Z'),
  );

  test('inserts and retrieves a song', () async {
    await repository.insertSong(testSong);

    final result = await repository.getSongById('song-001');

    expect(result, isNotNull);
    expect(result!.id, 'song-001');
    expect(result.title, 'Test Song');
    expect(result.artistId, 'artist-001');
  });

  test('updates a song', () async {
    await repository.insertSong(testSong);

    final updatedSong = Song(
      id: testSong.id,
      title: 'Updated Test Song',
      artistId: testSong.artistId,
      albumId: testSong.albumId,
      trackNumber: testSong.trackNumber,
      discNumber: testSong.discNumber,
      durationMs: testSong.durationMs,
      genre: 'Updated',
      artworkReference: testSong.artworkReference,
      cloudAudioReference: testSong.cloudAudioReference,
      cloudLyricsReference: testSong.cloudLyricsReference,
      localAudioPath: testSong.localAudioPath,
      localArtworkPath: testSong.localArtworkPath,
      localLyricsPath: testSong.localLyricsPath,
      downloadState: testSong.downloadState,
      createdAt: testSong.createdAt,
      updatedAt: DateTime.parse('2026-08-17T01:00:00Z'),
    );

    await repository.updateSong(updatedSong);

    final result = await repository.getSongById('song-001');

    expect(result, isNotNull);
    expect(result!.title, 'Updated Test Song');
    expect(result.genre, 'Updated');
  });

  test('returns all songs', () async {
    await repository.insertSong(testSong);

    final songs = await repository.getSongs();

    expect(songs, hasLength(1));
    expect(songs.first.id, 'song-001');
  });

  test('deletes a song', () async {
    await repository.insertSong(testSong);

    await repository.deleteSong('song-001');

    final result = await repository.getSongById('song-001');

    expect(result, isNull);
  });
}