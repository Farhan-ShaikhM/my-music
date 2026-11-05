import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

/// Square artwork with rounded corners. Without artwork it shows a colourful
/// gradient tile with a music note, picked from [seedId] so each song keeps
/// its own colours.
class ArtworkImage extends StatelessWidget {
  final String? artworkPath;
  final String? seedId;
  final double size;
  final double borderRadius;

  const ArtworkImage({
    super.key,
    this.artworkPath,
    this.seedId,
    this.size = 56,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final path = artworkPath;

    if (path == null || path.isEmpty) {
      return _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Decode at display size; full-size covers for 300 rows use a lot
        // of memory otherwise.
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    final colors = SongPalette.tileFor(seedId ?? '');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.5,
        color: Colors.white.withValues(alpha: 0.92),
      ),
    );
  }
}
