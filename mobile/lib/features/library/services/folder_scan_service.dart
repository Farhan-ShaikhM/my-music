import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

import 'duplicate_song_exception.dart';
import 'music_import_service.dart';

class ScanProgress {
  final int done;
  final int total;
  final int added;
  final int skipped;
  final int failed;

  const ScanProgress({
    required this.done,
    required this.total,
    required this.added,
    required this.skipped,
    required this.failed,
  });
}

/// Finds every audio file under a folder the user picks (for example
/// Internal storage/Music) and links it into the library without copying,
/// the way the phone's built-in music app works.
class FolderScanService {
  static const audioExtensions = {
    '.mp3',
    '.m4a',
    '.aac',
    '.flac',
    '.wav',
    '.ogg',
    '.opus',
  };

  final MusicImportService importService;

  FolderScanService({required this.importService});

  /// Android 13+ asks for "Music and audio"; older versions ask for storage.
  Future<bool> requestAudioPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final audio = await Permission.audio.request();

    if (audio.isGranted) {
      return true;
    }

    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  Future<String?> pickFolder() {
    return FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose your music folder',
    );
  }

  Future<List<String>> findAudioFiles(String folder) async {
    final files = <String>[];
    final directory = Directory(folder);

    if (!await directory.exists()) {
      return files;
    }

    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    ).handleError((_) {
      // Unreadable sub-folders (Android/data etc.) are skipped.
    })) {
      if (entity is! File) {
        continue;
      }

      final name = path.basename(entity.path);

      if (name.startsWith('.')) {
        continue;
      }

      final ext = path.extension(entity.path).toLowerCase();

      if (audioExtensions.contains(ext)) {
        files.add(entity.path);
      }
    }

    files.sort();
    return files;
  }

  Stream<ScanProgress> importFiles(List<String> files) async* {
    var added = 0;
    var skipped = 0;
    var failed = 0;

    yield ScanProgress(
      done: 0,
      total: files.length,
      added: 0,
      skipped: 0,
      failed: 0,
    );

    for (var i = 0; i < files.length; i++) {
      try {
        await importService.importSong(files[i], link: true);
        added++;
      } on DuplicateSongException {
        skipped++;
      } catch (_) {
        failed++;
      }

      yield ScanProgress(
        done: i + 1,
        total: files.length,
        added: added,
        skipped: skipped,
        failed: failed,
      );
    }
  }
}
