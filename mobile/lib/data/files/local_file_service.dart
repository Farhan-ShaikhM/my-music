import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class LocalFileService {
  static const String _musicDirectory = 'music';
  static const String _artworkDirectory = 'artwork';
  static const String _lyricsDirectory = 'lyrics';

  Future<Directory> _getApplicationDirectory() async {
    return getApplicationDocumentsDirectory();
  }

  Future<Directory> getMusicDirectory() async {
    final root = await _getApplicationDirectory();
    final directory = Directory(
      path.join(root.path, _musicDirectory),
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<Directory> getArtworkDirectory() async {
    final root = await _getApplicationDirectory();
    final directory = Directory(
      path.join(root.path, _artworkDirectory),
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<Directory> getLyricsDirectory() async {
    final root = await _getApplicationDirectory();
    final directory = Directory(
      path.join(root.path, _lyricsDirectory),
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<String> getMusicFilePath(
    String songId,
    String extension,
  ) async {
    final directory = await getMusicDirectory();

    return path.join(
      directory.path,
      '$songId.$extension',
    );
  }

  Future<void> copyMusicFile({
    required String sourcePath,
    required String destinationPath,
  }) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'Source audio file does not exist.',
        sourcePath,
      );
    }

    await sourceFile.copy(destinationPath);
  }

  Future<String> getArtworkFilePath(
  String songId,
  String extension,
) async {
  final directory = await getArtworkDirectory();

  return path.join(
    directory.path,
    '$songId.$extension',
  );
}

Future<void> saveArtwork({
  required List<int> bytes,
  required String destinationPath,
}) async {
  final file = File(destinationPath);

  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
}
}