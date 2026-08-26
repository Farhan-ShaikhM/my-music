class Song {
  final String id;
  final String title;
  final String? artistId;
  final String? albumId;
  final int? trackNumber;
  final int? discNumber;
  final int? durationMs;
  final String? genre;
  final String? artworkReference;
  final String? cloudAudioReference;
  final String? cloudLyricsReference;
  final String? localAudioPath;
  final String? audioFingerprint;
  final String? localArtworkPath;
  final String? localLyricsPath;
  final String? downloadState;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Song({
    required this.id,
    required this.title,
    this.artistId,
    this.albumId,
    this.trackNumber,
    this.discNumber,
    this.durationMs,
    this.genre,
    this.artworkReference,
    this.cloudAudioReference,
    this.cloudLyricsReference,
    this.localAudioPath,
    this.localArtworkPath,
    this.localLyricsPath,
    this.downloadState,
    required this.createdAt,
    required this.updatedAt,
    this.audioFingerprint,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist_id': artistId,
      'album_id': albumId,
      'track_number': trackNumber,
      'disc_number': discNumber,
      'duration_ms': durationMs,
      'genre': genre,
      'artwork_reference': artworkReference,
      'cloud_audio_reference': cloudAudioReference,
      'cloud_lyrics_reference': cloudLyricsReference,
      'local_audio_path': localAudioPath,
      'audio_fingerprint': audioFingerprint,
      'local_artwork_path': localArtworkPath,
      'local_lyrics_path': localLyricsPath,
      'download_state': downloadState,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String,
      artistId: map['artist_id'] as String?,
      albumId: map['album_id'] as String?,
      trackNumber: map['track_number'] as int?,
      discNumber: map['disc_number'] as int?,
      durationMs: map['duration_ms'] as int?,
      genre: map['genre'] as String?,
      artworkReference: map['artwork_reference'] as String?,
      cloudAudioReference: map['cloud_audio_reference'] as String?,
      cloudLyricsReference: map['cloud_lyrics_reference'] as String?,
      localAudioPath: map['local_audio_path'] as String?,
      audioFingerprint: map['audio_fingerprint'] as String?,
      localArtworkPath: map['local_artwork_path'] as String?,
      localLyricsPath: map['local_lyrics_path'] as String?,
      downloadState: map['download_state'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}