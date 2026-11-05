import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lrc_parser.dart';

/// Lyrics for a lyrics file path (null path = no lyrics).
final lyricsProvider =
    FutureProvider.family<Lyrics, String?>((ref, lyricsPath) async {
  if (lyricsPath == null || lyricsPath.isEmpty) {
    return const Lyrics();
  }

  final file = File(lyricsPath);

  if (!await file.exists()) {
    return const Lyrics();
  }

  final bytes = await file.readAsBytes();
  final content = utf8.decode(bytes, allowMalformed: true);

  return LrcParser.parse(content);
});
