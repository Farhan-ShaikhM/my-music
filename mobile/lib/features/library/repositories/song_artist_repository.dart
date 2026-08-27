import 'package:mobile/features/library/models/artist.dart';

abstract class SongArtistRepository {
  Future<void> addArtistToSong({
    required String songId,
    required String artistId,
  });

  Future<void> removeArtistFromSong({
    required String songId,
    required String artistId,
  });

  Future<void> setArtistsForSong({
    required String songId,
    required List<String> artistIds,
  });

  Future<List<String>> getArtistIdsForSong(String songId);
  Future<List<Artist>> getArtistsForSong(String songId);
}