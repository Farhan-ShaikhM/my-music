class Genre {
  final String id;
  final String name;

  const Genre({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Genre.fromMap(Map<String, dynamic> map) {
    return Genre(
      id: map['id'] as String,
      name: map['name'] as String,
    );
  }
}