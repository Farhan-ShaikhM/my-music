import '../../../data/files/local_file_service.dart';
import '../repositories/song_repository.dart';

class DuplicateSongCleanupService {
  final SongRepository songRepository;
  final LocalFileService localFileService;

  DuplicateSongCleanupService({
    required this.songRepository,
    required this.localFileService,
  });

  Future<int> removeExactDuplicates() async {
    final songs = await songRepository.getSongs();

    final seenFingerprints = <String>{};
    var deletedCount = 0;

    for (final song in songs) {
      final fingerprint = song.audioFingerprint;

      if (fingerprint == null || fingerprint.isEmpty) {
        continue;
      }

      if (seenFingerprints.contains(fingerprint)) {
        // Delete redundant local audio file first.
        final audioPath = song.localAudioPath;

        if (audioPath != null && audioPath.isNotEmpty) {
          await localFileService.deleteMusicFile(audioPath);
        }

        // Then remove the redundant database record.
        await songRepository.deleteSong(song.id);

        deletedCount++;
      } else {
        seenFingerprints.add(fingerprint);
      }
    }

    return deletedCount;
  }
}