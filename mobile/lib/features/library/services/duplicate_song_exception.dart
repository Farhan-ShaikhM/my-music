import '../models/song.dart';

class DuplicateSongException implements Exception {
  final Song existingSong;

  DuplicateSongException(this.existingSong);

  @override
  String toString() {
    return 'Song already exists: ${existingSong.title}';
  }
}