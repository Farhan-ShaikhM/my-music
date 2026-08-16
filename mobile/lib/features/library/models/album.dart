
class Album {
  final String id;
  final String title;
  final String? artistId;
  final String? artworkReference;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Album({
    required this.id,
    required this.title,
    this.artistId,
    this.artworkReference,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist_id': artistId,
      'artwork_reference': artworkReference,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'] as String,
      title: map['title'] as String,
      artistId: map['artist_id'] as String?,
      artworkReference: map['artwork_reference'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

