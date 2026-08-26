import 'dart:io';

import 'package:flutter/material.dart';

class SongArtwork extends StatelessWidget {
  final String? artworkPath;
  final double size;
  final BorderRadius borderRadius;

  const SongArtwork({
    super.key,
    required this.artworkPath,
    this.size = 56,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(8),
    ),
  });

  @override
  Widget build(BuildContext context) {
    final path = artworkPath;

    if (path == null || path.isEmpty) {
      return _placeholder();
    }

    final file = File(path);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _placeholder();
        },
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: Colors.grey.shade200,
      ),
      child: const Icon(
        Icons.music_note,
      ),
    );
  }
}