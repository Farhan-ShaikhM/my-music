import '../models/song.dart';

abstract class SongRepository {
  Future<List<Song>> getSongs();

  Future<Song?> getSongById(String id);

  Future<void> insertSong(Song song);

  Future<void> updateSong(Song song);

  Future<void> deleteSong(String id);
}
