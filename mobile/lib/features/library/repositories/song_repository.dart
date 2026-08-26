import '../models/song.dart';

abstract class SongRepository {
  Future<List<Song>> getSongs();

  Future<Song?> getSongById(String id);

  Future<void> insertSong(Song song);

  Future<void> updateSong(Song song);

  Future<void> deleteSong(String id);

  Future<Song?> getSongByLocalPath(String localAudioPath);

  Future<Song?> getSongByAudioFingerprint(String fingerprint);

  Future<void> updateAudioFingerprint(String songId, String fingerprint);

  Future<List<Song>> getSongsByAudioFingerprint(String fingerprint);

  Future<void> updateLocalArtworkPath(String songId, String localArtworkPath);
}
