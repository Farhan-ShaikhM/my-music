import 'dart:io';

import '../repositories/song_repository.dart';
import '../../../data/files/audio_fingerprint_service.dart';

class AudioFingerprintBackfillService {
  final SongRepository songRepository;
  final AudioFingerprintService fingerprintService;

  AudioFingerprintBackfillService({
    required this.songRepository,
    required this.fingerprintService,
  });

  Future<void> backfillExistingSongs() async {
    final songs = await songRepository.getSongs();

    for (final song in songs) {
      if (song.audioFingerprint != null &&
          song.audioFingerprint!.isNotEmpty) {
        continue;
      }

      final audioPath = song.localAudioPath;

      if (audioPath == null || audioPath.isEmpty) {
        continue;
      }

      final file = File(audioPath);

      if (!await file.exists()) {
        continue;
      }

      final fingerprint =
          await fingerprintService.calculateFingerprint(audioPath);

      await songRepository.updateAudioFingerprint(
        song.id,
        fingerprint,
      );
    }
  }
}