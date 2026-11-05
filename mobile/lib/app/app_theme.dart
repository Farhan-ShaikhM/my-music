import 'package:flutter/material.dart';

class AppColors {
  /// Red accent used for the playing song, Shuffle pill and Cancel.
  static const accent = Color(0xFFE5302F);
  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF8E8E93);
  static const card = Color(0xFFF5F5F7);
  static const miniPlayer = Color(0xFFF0F0F3);
  static const divider = Color(0xFFE5E5EA);
}

/// Gradient pairs for songs without artwork. Each song always gets the same
/// pair (chosen from its id), for both the list tile and the player
/// background.
class SongPalette {
  static const List<List<Color>> tiles = [
    [Color(0xFFD86BF0), Color(0xFF7EA6FF)], // purple -> blue
    [Color(0xFFF7C66B), Color(0xFF50F0E6)], // yellow -> cyan
    [Color(0xFFF56FB0), Color(0xFF61E3F0)], // pink -> cyan
    [Color(0xFFFF8A73), Color(0xFFFFA9E0)], // coral -> pink
    [Color(0xFF52D4F2), Color(0xFF9BF27A)], // cyan -> lime
    [Color(0xFFFFB45C), Color(0xFFFFE96B)], // orange -> yellow
    [Color(0xFFFF6B6B), Color(0xFFE07BF0)], // red -> violet
  ];

  /// Darker, calmer versions for the full-screen player.
  static const List<List<Color>> backgrounds = [
    [Color(0xFF9150B8), Color(0xFF3F5E9C)], // purple
    [Color(0xFF4E9AA0), Color(0xFF3E7770)], // teal
    [Color(0xFFB0507F), Color(0xFF3F6C9C)], // rose
    [Color(0xFFB8665A), Color(0xFF7A4B86)], // coral
    [Color(0xFF3F8FA8), Color(0xFF4C8A5A)], // sea
    [Color(0xFFB07A3E), Color(0xFF8A5B3A)], // amber
    [Color(0xFFA8464E), Color(0xFF6A3F8C)], // crimson
  ];

  static int indexFor(String id) {
    var hash = 0;

    for (final unit in id.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }

    return hash % tiles.length;
  }

  static List<Color> tileFor(String id) => tiles[indexFor(id)];

  static List<Color> backgroundFor(String id) => backgrounds[indexFor(id)];
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.accent,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    dividerColor: AppColors.divider,
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

String formatDuration(Duration? duration) {
  if (duration == null) return '00:00';

  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;

  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
