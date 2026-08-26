import 'dart:io';

import 'package:crypto/crypto.dart';

class AudioFingerprintService {
  Future<String> calculateFingerprint(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileSystemException(
        'Audio file does not exist',
        filePath,
      );
    }

    final bytes = await file.readAsBytes();

    return sha256.convert(bytes).toString();
  }
}