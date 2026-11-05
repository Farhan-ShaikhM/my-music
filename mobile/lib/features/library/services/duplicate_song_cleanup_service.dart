import '../../../data/files/local_file_service.dart';
import '../repositories/library_extras_repository.dart';
import '../repositories/song_repository.dart';

class DuplicateSongCleanupService {
  final SongRepository songRepository;
  final LocalFileService localFileService;
  final LibraryExtrasRepository extrasRepository;

  DuplicateSongCleanupService({
    required this.songRepository,
    required this.localFileService,
    required this.extrasRepository,
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
        // Only files inside the app's storage are deleted; a linked song's
        // original file stays on the phone.
        await localFileService.deleteOwnedFile(song.localAudioPath);
        await localFileService.deleteOwnedFile(song.localArtworkPath);
        await localFileService.deleteOwnedFile(song.localLyricsPath);

        await extrasRepository.deleteSongReferences(song.id);
        await songRepository.deleteSong(song.id);

        deletedCount++;
      } else {
        seenFingerprints.add(fingerprint);
      }
    }

    return deletedCount;
  }
}
