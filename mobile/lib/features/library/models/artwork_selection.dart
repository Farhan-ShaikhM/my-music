import 'dart:typed_data';

class ArtworkSelection {
  final Uint8List bytes;
  final String mimeType;

  const ArtworkSelection({
    required this.bytes,
    required this.mimeType,
  });
}