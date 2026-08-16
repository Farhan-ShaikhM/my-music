import '../models/artist.dart';

abstract class ArtistRepository {
  Future<List<Artist>> getArtists();

  Future<Artist?> getArtistById(String id);

  Future<void> insertArtist(Artist artist);

  Future<void> updateArtist(Artist artist);

  Future<void> deleteArtist(String id);
}