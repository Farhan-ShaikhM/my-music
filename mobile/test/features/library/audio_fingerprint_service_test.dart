import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/files/audio_fingerprint_service.dart';

// import '../../data/files/audio_fingerprint_service.dart';

void main() {
  test('same file produces the same fingerprint', () async {
    final directory = await Directory.systemTemp.createTemp();

    final file = File(
      '${directory.path}/test_audio.mp3',
    );

    await file.writeAsBytes([
      1,
      2,
      3,
      4,
      5,
    ]);

    final service = AudioFingerprintService();

    final first = await service.calculateFingerprint(
      file.path,
    );

    final second = await service.calculateFingerprint(
      file.path,
    );

    expect(first, equals(second));

    await directory.delete(recursive: true);
  });
}