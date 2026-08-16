class Artist {
  final String id;
  final String name;
  final String? artworkReference;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Artist({
    required this.id,
    required this.name,
    this.artworkReference,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'artwork_reference': artworkReference,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'] as String,
      name: map['name'] as String,
      artworkReference: map['artwork_reference'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}