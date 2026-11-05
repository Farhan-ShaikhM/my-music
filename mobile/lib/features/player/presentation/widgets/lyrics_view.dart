import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/models/song.dart';
import '../../../library/presentation/widgets/song_options_sheet.dart';
import '../../../library/services/library_actions.dart';
import '../../../lyrics/lrc_parser.dart';
import '../../../lyrics/lyrics_providers.dart';
import '../../providers/player_providers.dart';

/// The LYRIC page. Synced (.lrc) lyrics scroll and highlight the current
/// line; tapping a line seeks there. Without lyrics it explains how to add
/// them, like the phone's player.
class LyricsView extends ConsumerWidget {
  final Song song;

  const LyricsView({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyricsAsync = ref.watch(lyricsProvider(song.localLyricsPath));

    return lyricsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => _NoLyrics(song: song),
      data: (lyrics) {
        if (lyrics.isEmpty) return _NoLyrics(song: song);

        if (!lyrics.isSynced) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 140),
            children: [
              for (final line in lyrics.plain)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    line,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
            ],
          );
        }

        return _SyncedLyrics(lyrics: lyrics);
      },
    );
  }
}

class _SyncedLyrics extends ConsumerStatefulWidget {
  final Lyrics lyrics;

  const _SyncedLyrics({required this.lyrics});

  @override
  ConsumerState<_SyncedLyrics> createState() => _SyncedLyricsState();
}

class _SyncedLyricsState extends ConsumerState<_SyncedLyrics> {
  static const _lineHeight = 56.0;

  final _scroll = ScrollController();
  int _lastIndex = -2;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _follow(int index, double viewportHeight) {
    if (index == _lastIndex || !_scroll.hasClients) return;

    _lastIndex = index;

    // Keep the current line in the middle.
    final target = (index.clamp(0, widget.lyrics.synced.length) * _lineHeight)
        .toDouble();

    _scroll.animateTo(
      target.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(playerPositionProvider).value ?? Duration.zero;
    final current = widget.lyrics.indexAt(position);
    final lines = widget.lyrics.synced;

    return LayoutBuilder(
      builder: (context, constraints) {
        final half = constraints.maxHeight / 2 - _lineHeight / 2;

        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _follow(current, constraints.maxHeight),
        );

        return ListView.builder(
          controller: _scroll,
          padding: EdgeInsets.symmetric(vertical: half < 0 ? 0 : half),
          itemExtent: _lineHeight,
          itemCount: lines.length,
          itemBuilder: (context, i) {
            final active = i == current;

            return InkWell(
              onTap: () =>
                  ref.read(musicPlayerServiceProvider).seek(lines[i].time),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: active ? 21 : 17,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                    child: Text(lines[i].text.isEmpty ? '♪' : lines[i].text),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NoLyrics extends ConsumerWidget {
  final Song song;

  const _NoLyrics({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faded = Colors.white.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 5),
          Text('No Lyric Yet', style: TextStyle(color: faded, fontSize: 20)),
          const Spacer(flex: 4),
          GestureDetector(
            onTap: () => _explainAutoMatch(context),
            child: const Text(
              'How to automatically match lyric files to songs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('or', style: TextStyle(color: faded, fontSize: 18)),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontSize: 17),
            ),
            onPressed: () async {
              try {
                final added =
                    await ref.read(libraryActionsProvider).pickLyricsFor(song);
                if (added && context.mounted) {
                  showMessage(context, 'Lyrics added');
                }
              } catch (error) {
                if (context.mounted) showMessage(context, '$error');
              }
            },
            child: const Text('Manually specify lyric file'),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  void _explainAutoMatch(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Matching lyrics automatically'),
        content: const Text(
          'Put a .lrc lyrics file in the same folder as the song, with the '
          'same name (for example "My Song.mp3" and "My Song.lrc"). '
          'Then use Scan a music folder: the lyrics are attached while the '
          'song is added.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
