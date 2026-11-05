import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/lyrics/lrc_parser.dart';

// The full app needs the audio and database plugins, so these tests cover
// the pure-Dart parts instead.
void main() {
  group('LrcParser', () {
    test('parses timestamps and sorts lines', () {
      final lyrics = LrcParser.parse('''
[ti:Demo]
[00:12.50]second
[00:01.00]first
[01:02.123]third
''');

      expect(lyrics.isSynced, isTrue);
      expect(lyrics.synced.map((l) => l.text), ['first', 'second', 'third']);
      expect(lyrics.synced[1].time, const Duration(seconds: 12, milliseconds: 500));
      expect(
        lyrics.synced[2].time,
        const Duration(minutes: 1, seconds: 2, milliseconds: 123),
      );
    });

    test('one line with several timestamps repeats', () {
      final lyrics = LrcParser.parse('[00:05.00][00:30.00]chorus');

      expect(lyrics.synced.length, 2);
      expect(lyrics.synced.every((l) => l.text == 'chorus'), isTrue);
    });

    test('offset shifts lines earlier', () {
      final lyrics = LrcParser.parse('[offset:+500]\n[00:02.00]a');

      expect(lyrics.synced.single.time, const Duration(milliseconds: 1500));
    });

    test('plain text without timestamps', () {
      final lyrics = LrcParser.parse('line one\nline two');

      expect(lyrics.isSynced, isFalse);
      expect(lyrics.plain, ['line one', 'line two']);
    });

    test('indexAt finds the current line', () {
      final lyrics = LrcParser.parse('[00:01.00]a\n[00:05.00]b\n[00:09.00]c');

      expect(lyrics.indexAt(Duration.zero), -1);
      expect(lyrics.indexAt(const Duration(seconds: 1)), 0);
      expect(lyrics.indexAt(const Duration(seconds: 7)), 1);
      expect(lyrics.indexAt(const Duration(minutes: 3)), 2);
    });
  });
}
