import 'dart:typed_data';

class ImportSongDraft {
  final String sourcePath;

  String title;
  String? artistName;
  String? albumName;

  final int? trackNumber;
  final int? discNumber;
  final int? durationMs;
  final String? genre;

  Uint8List? artworkBytes;
  String? artworkMimeType;

  ImportSongDraft({
    required this.sourcePath,
    required this.title,
    this.artistName,
    this.albumName,
    this.trackNumber,
    this.discNumber,
    this.durationMs,
    this.genre,
    this.artworkBytes,
    this.artworkMimeType,
  });
}