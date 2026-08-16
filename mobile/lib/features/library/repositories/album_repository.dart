import '../models/album.dart';

abstract class AlbumRepository {
  Future<List<Album>> getAlbums();

  Future<Album?> getAlbumById(String id);

  Future<void> insertAlbum(Album album);

  Future<void> updateAlbum(Album album);

  Future<void> deleteAlbum(String id);
}