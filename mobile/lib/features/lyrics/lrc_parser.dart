class LyricLine {
  final Duration time;
  final String text;

  const LyricLine(this.time, this.text);
}

class Lyrics {
  /// Time-stamped lines, sorted. Empty for plain-text lyrics.
  final List<LyricLine> synced;

  /// Lines of a file without timestamps.
  final List<String> plain;

  const Lyrics({this.synced = const [], this.plain = const []});

  bool get isSynced => synced.isNotEmpty;

  bool get isEmpty => synced.isEmpty && plain.isEmpty;

  /// Index of the line being sung at [position], or -1 before the first line.
  int indexAt(Duration position) {
    if (synced.isEmpty) {
      return -1;
    }

    var low = 0;
    var high = synced.length - 1;
    var result = -1;

    while (low <= high) {
      final mid = (low + high) >> 1;

      if (synced[mid].time <= position) {
        result = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return result;
  }
}

/// Parses .lrc files: "[mm:ss.xx]text", several stamps per line allowed,
/// plus an optional "[offset:+/-ms]" tag. Files with no timestamps are
/// returned as plain lines.
class LrcParser {
  static final _stamp = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
  static final _offset = RegExp(r'^\[offset:\s*([+-]?\d+)\s*\]', caseSensitive: false);
  static final _metaTag = RegExp(r'^\[[a-zA-Z]+:.*\]$');

  static Lyrics parse(String content) {
    final synced = <LyricLine>[];
    final plain = <String>[];
    var offsetMs = 0;

    for (final rawLine in content.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();

      if (line.isEmpty) {
        continue;
      }

      final offsetMatch = _offset.firstMatch(line);

      if (offsetMatch != null) {
        offsetMs = int.tryParse(offsetMatch.group(1)!) ?? 0;
        continue;
      }

      final stamps = _stamp.allMatches(line).toList();

      if (stamps.isEmpty) {
        // [ar:...], [ti:...] and similar tags are not lyrics.
        if (!_metaTag.hasMatch(line)) {
          plain.add(line);
        }
        continue;
      }

      final text = line.substring(stamps.last.end).trim();

      for (final stamp in stamps) {
        final minutes = int.parse(stamp.group(1)!);
        final seconds = int.parse(stamp.group(2)!);
        final fraction = stamp.group(3);
        var millis = 0;

        if (fraction != null) {
          // ".5" = 500ms, ".50" = 500ms, ".500" = 500ms
          millis = int.parse(fraction.padRight(3, '0'));
        }

        synced.add(
          LyricLine(
            Duration(minutes: minutes, seconds: seconds, milliseconds: millis),
            text,
          ),
        );
      }
    }

    if (synced.isEmpty) {
      return Lyrics(plain: plain);
    }

    // A positive offset in LRC means lyrics should appear earlier.
    final shifted = [
      for (final line in synced)
        LyricLine(
          _nonNegative(line.time - Duration(milliseconds: offsetMs)),
          line.text,
        ),
    ]..sort((a, b) => a.time.compareTo(b.time));

    return Lyrics(synced: shifted);
  }

  static Duration _nonNegative(Duration d) => d.isNegative ? Duration.zero : d;
}
