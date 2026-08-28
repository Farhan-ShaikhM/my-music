import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart' as reader;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../../../../../data/files/audio_fingerprint_service.dart';
import '../../../../../data/files/local_file_service.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/import_song_draft.dart';
import '../models/song.dart';
import '../repositories/album_repository.dart';
import '../repositories/artist_repository.dart';
import '../repositories/song_artist_repository.dart';
import '../repositories/song_repository.dart';
import 'duplicate_song_exception.dart';

class MusicImportService {
  final SongRepository songRepository;
  final ArtistRepository artistRepository;
  final AlbumRepository albumRepository;
  final LocalFileService localFileService;
  final AudioFingerprintService audioFingerprintService;
  final SongArtistRepository songArtistRepository;

  MusicImportService({
    required this.songRepository,
    required this.artistRepository,
    required this.albumRepository,
    required this.localFileService,
    required this.audioFingerprintService,
    required this.songArtistRepository,
  });

  List<String> _splitArtistNames(String? value) {
    if (value == null) {
      return [];
    }

    return value
        .split(',')
        .map((artist) => artist.trim())
        .where((artist) => artist.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<String?> extractAndSaveArtworkForSong(Song song) async {
    final audioPath = song.localAudioPath;

    if (audioPath == null || audioPath.isEmpty) {
      return null;
    }

    final file = File(audioPath);

    if (!await file.exists()) {
      return null;
    }

    final metadata = await readMetadata(audioPath);

    if (metadata.pictures.isEmpty) {
      return null;
    }

    final picture = metadata.pictures.first;

    final extension = _extensionFromMimeType(picture.mimetype);

    final artworkPath = await localFileService.getArtworkFilePath(
      song.id,
      extension,
    );

    await localFileService.saveArtwork(
      bytes: picture.bytes,
      destinationPath: artworkPath,
    );

    await songRepository.updateLocalArtworkPath(song.id, artworkPath);

    return artworkPath;
  }

  Future<Song?> pickAndImportSong() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    return importSong(result.files.single.path!);
  }

  Future<ImportSongDraft?> pickSongForImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    return createDraft(result.files.single.path!);
  }

  Future<ImportSongDraft> createDraft(String sourcePath) async {
    final metadata = await readMetadata(sourcePath);

    final title = _resolveTitle(metadata.title, sourcePath);

    final artistNames = _splitArtistNames(metadata.artist);

    final albumName = _normalizeText(metadata.album);

    Uint8List? artworkBytes;
    String? artworkMimeType;

    if (metadata.pictures.isNotEmpty) {
      final picture = metadata.pictures.first;

      artworkBytes = Uint8List.fromList(picture.bytes);
      artworkMimeType = picture.mimetype;
    }

    return ImportSongDraft(
      sourcePath: sourcePath,
      title: title,
      artistNames: artistNames,
      albumName: albumName,
      trackNumber: metadata.trackNumber,
      discNumber: metadata.discNumber,
      durationMs: metadata.duration?.inMilliseconds,
      genre: metadata.genres.isNotEmpty
          ? _normalizeText(metadata.genres.first)
          : null,
      artworkBytes: artworkBytes,
      artworkMimeType: artworkMimeType,
    );
  }

  Future<Song> importSong(String sourcePath) async {
    final metadata = await readMetadata(sourcePath);

    final fingerprint = await audioFingerprintService.calculateFingerprint(
      sourcePath,
    );

    final existingSong = await songRepository.getSongByAudioFingerprint(
      fingerprint,
    );

    if (existingSong != null) {
      throw DuplicateSongException(existingSong);
    }

    final title = _resolveTitle(metadata.title, sourcePath);

    final artistNames = _splitArtistNames(metadata.artist);

    final albumName = _normalizeText(metadata.album);

    final artists = <Artist>[];

    for (final name in artistNames) {
      final existingOrCreated = await _findOrCreateArtist(name);
      artists.add(existingOrCreated);
    }

    final Artist? primaryArtist = artists.isNotEmpty ? artists.first : null;

    Album? album;

    if (albumName != null) {
      album = await _findOrCreateAlbum(albumName, primaryArtist?.id);
    }

    final songId = _createId(
      sourcePath,
      title,
      primaryArtist?.name,
    );

    final extension = path.extension(sourcePath).replaceFirst('.', '');

    String? localArtworkPath;

    if (metadata.pictures.isNotEmpty) {
      final picture = metadata.pictures.first;

      final artworkExtension = _extensionFromMimeType(picture.mimetype);

      localArtworkPath = await localFileService.getArtworkFilePath(
        songId,
        artworkExtension,
      );

      await localFileService.saveArtwork(
        bytes: picture.bytes,
        destinationPath: localArtworkPath,
      );
    }

    final localAudioPath = await localFileService.getMusicFilePath(
      songId,
      extension,
    );

    await localFileService.copyMusicFile(
      sourcePath: sourcePath,
      destinationPath: localAudioPath,
    );

    final now = DateTime.now();

    final song = Song(
      id: songId,
      title: title,
      artistId: primaryArtist?.id,
      albumId: album?.id,
      trackNumber: metadata.trackNumber,
      discNumber: metadata.discNumber,
      durationMs: metadata.duration?.inMilliseconds,
      genre: metadata.genres.isNotEmpty
          ? _normalizeText(metadata.genres.first)
          : null,
      artworkReference: null,
      cloudAudioReference: null,
      cloudLyricsReference: null,
      localAudioPath: localAudioPath,
      audioFingerprint: fingerprint,
      localArtworkPath: localArtworkPath,
      localLyricsPath: null,
      downloadState: 'available_offline',
      createdAt: now,
      updatedAt: now,
    );

    await songRepository.insertSong(song);

    for (final artist in artists) {
      await songArtistRepository.addArtistToSong(
        songId: song.id,
        artistId: artist.id,
      );
    }

    return song;
  }

  Future<reader.AudioMetadata> readMetadata(String filePath) async {
    final file = File(filePath);
    return reader.readMetadata(file, getImage: true);
  }

  Future<Song> importDraft(ImportSongDraft draft) async {
  String? localAudioPath;
  String? localArtworkPath;

  try {
    // --------------------------------
    // 1. Calculate fingerprint
    // --------------------------------

    final fingerprint =
        await audioFingerprintService.calculateFingerprint(
      draft.sourcePath,
    );

    // --------------------------------
    // 2. Check duplicate
    // --------------------------------

    final existingSong =
        await songRepository.getSongByAudioFingerprint(
      fingerprint,
    );

    if (existingSong != null) {
      throw DuplicateSongException(existingSong);
    }

    // --------------------------------
    // 3. Find/create artists
    // --------------------------------

    final artists = <Artist>[];

    for (final name in draft.artistNames) {
      final normalizedName = name.trim();

      if (normalizedName.isEmpty) {
        continue;
      }

      final existingOrCreated =
          await _findOrCreateArtist(normalizedName);

      artists.add(existingOrCreated);
    }

    final Artist? primaryArtist =
        artists.isNotEmpty ? artists.first : null;

    // --------------------------------
    // 4. Find/create album
    // --------------------------------

    Album? album;

    if (draft.albumName != null &&
        draft.albumName!.trim().isNotEmpty) {
      album = await _findOrCreateAlbum(
        draft.albumName!.trim(),
        primaryArtist?.id,
      );
    }

    // --------------------------------
    // 5. Create song ID
    // --------------------------------

    final songId = _createId(
      draft.sourcePath,
      draft.title,
      primaryArtist?.name,
    );

    // --------------------------------
    // 6. Copy audio
    // --------------------------------

    final extension = path
        .extension(draft.sourcePath)
        .replaceFirst('.', '');

    localAudioPath =
        await localFileService.getMusicFilePath(
      songId,
      extension,
    );

    await localFileService.copyMusicFile(
      sourcePath: draft.sourcePath,
      destinationPath: localAudioPath,
    );

    // --------------------------------
    // 7. Save artwork
    // --------------------------------

    if (draft.artworkBytes != null &&
        draft.artworkBytes!.isNotEmpty) {
      final artworkExtension =
          _extensionFromMimeType(
        draft.artworkMimeType ?? 'image/jpeg',
      );

      localArtworkPath =
          await localFileService.getArtworkFilePath(
        songId,
        artworkExtension,
      );

      await localFileService.saveArtwork(
        bytes: draft.artworkBytes!,
        destinationPath: localArtworkPath,
      );
    }

    // --------------------------------
    // 8. Create Song
    // --------------------------------

    final now = DateTime.now();

    final song = Song(
      id: songId,
      title: draft.title,
      artistId: primaryArtist?.id,
      albumId: album?.id,
      trackNumber: draft.trackNumber,
      discNumber: draft.discNumber,
      durationMs: draft.durationMs,
      genre: draft.genre,
      artworkReference: null,
      cloudAudioReference: null,
      cloudLyricsReference: null,
      localAudioPath: localAudioPath,
      audioFingerprint: fingerprint,
      localArtworkPath: localArtworkPath,
      localLyricsPath: null,
      downloadState: 'available_offline',
      createdAt: now,
      updatedAt: now,
    );

    // --------------------------------
    // 9. Insert song
    // --------------------------------

    await songRepository.insertSong(song);

    // --------------------------------
    // 10. Link all artists
    // --------------------------------

    for (final artist in artists) {
      await songArtistRepository.addArtistToSong(
        songId: song.id,
        artistId: artist.id,
      );
    }

    // --------------------------------
    // 11. Everything succeeded
    // --------------------------------

    return song;
  } catch (error) {
    // --------------------------------
    // Cleanup files created by this
    // import attempt
    // --------------------------------

    if (localArtworkPath != null) {
      final artworkFile = File(localArtworkPath);

      if (await artworkFile.exists()) {
        await artworkFile.delete();
      }
    }

    if (localAudioPath != null) {
      final audioFile = File(localAudioPath);

      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    }

    // Keep the original error so the UI
    // can display the actual reason.
    rethrow;
  }
}
  Future<Artist> _findOrCreateArtist(String name) async {
    final artists = await artistRepository.getArtists();

    final existing = artists.where(
      (artist) => artist.name.toLowerCase() == name.toLowerCase(),
    );

    if (existing.isNotEmpty) {
      return existing.first;
    }

    final now = DateTime.now();

    final artist = Artist(
      id: _createSimpleId('artist', name),
      name: name,
      createdAt: now,
      updatedAt: now,
    );

    await artistRepository.insertArtist(artist);

    return artist;
  }

  Future<Album> _findOrCreateAlbum(String title, String? artistId) async {
    final albums = await albumRepository.getAlbums();

    final existing = albums.where(
      (album) =>
          album.title.toLowerCase() == title.toLowerCase() &&
          album.artistId == artistId,
    );

    if (existing.isNotEmpty) {
      return existing.first;
    }

    final now = DateTime.now();

    final album = Album(
      id: _createSimpleId('album', '$artistId-$title'),
      title: title,
      artistId: artistId,
      createdAt: now,
      updatedAt: now,
    );

    await albumRepository.insertAlbum(album);

    return album;
  }

  String _resolveTitle(String? metadataTitle, String filePath) {
    final title = _normalizeText(metadataTitle);

    if (title != null) {
      return title;
    }

    return path.basenameWithoutExtension(filePath);
  }

  String? _normalizeText(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim();

    return normalized.isEmpty ? null : normalized;
  }

  String _createId(String filePath, String title, String? artist) {
    return _createSimpleId('song', '$filePath|$title|$artist');
  }

  String _createSimpleId(String prefix, String value) {
    final hash = value.hashCode.toUnsigned(32).toRadixString(16);

    return '$prefix-$hash';
  }
}

String _extensionFromMimeType(String mimeType) {
  switch (mimeType.toLowerCase()) {
    case 'image/png':
      return 'png';

    case 'image/webp':
      return 'webp';

    case 'image/gif':
      return 'gif';

    case 'image/jpeg':
    case 'image/jpg':
    default:
      return 'jpg';
  }
}