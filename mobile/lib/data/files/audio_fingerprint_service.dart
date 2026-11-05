import 'dart:io';

import 'package:crypto/crypto.dart';

class AudioFingerprintService {
  /// SHA-256 of the whole file.
  ///
  /// The file is streamed instead of loaded with readAsBytes(), so a large
  /// FLAC or a scan of hundreds of songs does not load every file into
  /// memory. The digest is identical to the old implementation, so existing
  /// fingerprints in the database still match.
  Future<String> calculateFingerprint(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileSystemException(
        'Audio file does not exist',
        filePath,
      );
    }

    final digest = await sha256.bind(file.openRead()).first;

    return digest.toString();
  }
}
