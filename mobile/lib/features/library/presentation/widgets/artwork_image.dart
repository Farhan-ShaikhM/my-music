import 'dart:io';

import 'package:flutter/material.dart';

class ArtworkImage extends StatelessWidget {
  final String? artworkPath;
  final double size;
  final double borderRadius;

  const ArtworkImage({
    super.key,
    this.artworkPath,
    this.size = 56,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final hasArtwork =
        artworkPath != null &&
        artworkPath!.isNotEmpty;

    if (!hasArtwork) {
      return _buildPlaceholder(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.file(
        File(artworkPath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(context);
        },
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
      ),
      child: Icon(
        Icons.music_note,
        size: size * 0.45,
      ),
    );
  }
}