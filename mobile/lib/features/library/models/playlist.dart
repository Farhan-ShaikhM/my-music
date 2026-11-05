class Playlist {
  final String id;
  final String name;
  final int songCount;
  final DateTime createdAt;

  const Playlist({
    required this.id,
    required this.name,
    required this.songCount,
    required this.createdAt,
  });

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'] as String,
      name: map['name'] as String,
      songCount: (map['song_count'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
