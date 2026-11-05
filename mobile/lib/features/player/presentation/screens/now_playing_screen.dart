import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../library/models/song.dart';
import '../../../library/presentation/widgets/song_options_sheet.dart';
import '../../../library/providers/library_providers.dart';
import '../../../library/services/library_actions.dart';
import '../../models/play_mode.dart';
import '../../providers/player_providers.dart';
import '../widgets/lyrics_view.dart';
import '../widgets/mini_player.dart';
import '../widgets/queue_sheet.dart';
import '../widgets/vinyl_disc.dart';

/// Background colours taken from the cover art, if the song has one.
final _artworkGradientProvider =
    FutureProvider.family<List<Color>?, String>((ref, artworkPath) async {
  final file = File(artworkPath);

  if (!await file.exists()) return null;

  final scheme = await ColorScheme.fromImageProvider(
    provider: ResizeImage(FileImage(file), width: 96, height: 96),
  );

  Color tone(Color color, double lightness) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness(lightness)
        .withSaturation((hsl.saturation * 0.85).clamp(0.0, 1.0))
        .toColor();
  }

  return [tone(scheme.primary, 0.42), tone(scheme.tertiary, 0.30)];
});

/// Full-screen player with COVER and LYRIC pages, like the phone's player.
class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  List<Color> _gradientFor(Song song) {
    final artwork = song.localArtworkPath;

    if (artwork != null && artwork.isNotEmpty) {
      final fromArt = ref.watch(_artworkGradientProvider(artwork)).value;
      if (fromArt != null) return fromArt;
    }

    return SongPalette.backgroundFor(song.id);
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(currentSongProvider);

    if (song == null) {
      // The queue was cleared while this screen was open.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      });
      return const Scaffold(backgroundColor: Colors.black);
    }

    final colors = _gradientFor(song);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                page: _page,
                onSelect: _goTo,
                song: song,
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (page) => setState(() => _page = page),
                  children: [
                    _CoverPage(song: song),
                    Column(
                      children: [
                        Expanded(child: LyricsView(song: song)),
                        const MiniPlayer(onDark: true),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final int page;
  final ValueChanged<int> onSelect;
  final Song song;

  const _TopBar({
    required this.page,
    required this.onSelect,
    required this.song,
  });

  /// 56dp bar: chevron, a 150x29dp COVER/LYRIC switch, more button.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Close',
            iconSize: 30,
            color: Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Container(
            width: 150,
            height: 29,
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(child: _pill('COVER', 0)),
                Expanded(child: _pill('LYRIC', 1)),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'More',
            iconSize: 24,
            color: Colors.white,
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreMenu(context, ref, song),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _pill(String label, int index) {
    final selected = page == index;

    return GestureDetector(
      onTap: () => onSelect(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: selected ? 1 : 0.55),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _showMoreMenu(
    BuildContext context,
    WidgetRef ref,
    Song song,
  ) async {
    final sleepEnd = ref.read(sleepTimerProvider);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Add to playlist'),
              onTap: () {
                final messenger = ScaffoldMessenger.of(context);
                showAddToPlaylistDialog(sheetContext, ref, song, (text) {
                  messenger.showSnackBar(SnackBar(content: Text(text)));
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.lyrics_outlined),
              title: const Text('Choose lyric file'),
              onTap: () async {
                Navigator.pop(sheetContext);
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
            ),
            ListTile(
              leading: const Icon(Icons.bedtime_outlined),
              title: Text(
                sleepEnd == null
                    ? 'Sleep timer'
                    : 'Sleep timer (stops at ${TimeOfDay.fromDateTime(sleepEnd).format(context)})',
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _showSleepTimer(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Song info'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showInfo(context, ref, song);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepTimer(BuildContext context, WidgetRef ref) {
    final timer = ref.read(sleepTimerProvider.notifier);
    const options = [15, 30, 45, 60, 90];

    showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Stop playing after'),
        children: [
          for (final minutes in options)
            SimpleDialogOption(
              onPressed: () {
                timer.start(Duration(minutes: minutes));
                Navigator.pop(dialogContext);
              },
              child: Text('$minutes minutes'),
            ),
          SimpleDialogOption(
            onPressed: () {
              timer.cancel();
              Navigator.pop(dialogContext);
            },
            child: const Text('Turn off', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context, WidgetRef ref, Song song) {
    final index = ref.read(libraryIndexProvider).value;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(song.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Artist: ${index?.artistLabel(song) ?? '-'}'),
            Text('Album: ${index?.albumLabel(song) ?? '-'}'),
            Text('Length: ${formatDuration(song.duration)}'),
            if (song.genre != null) Text('Genre: ${song.genre}'),
            const SizedBox(height: 8),
            Text(
              song.sourcePath ?? song.localAudioPath ?? '',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
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

/// COVER page. Measured on a 360dp-wide screen: 311dp card with 20dp
/// corners, 211dp record, 27sp bold title, 16sp artist, 3dp seek track
/// with a 16dp thumb, five controls on equal 72dp slots.
class _CoverPage extends ConsumerWidget {
  final Song song;

  const _CoverPage({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(playerPlayingProvider).value ?? false;
    final artist = ref.watch(
      libraryIndexProvider.select((i) => i.value?.artistLabel(song) ?? ''),
    );
    final isFavorite = ref.watch(isFavoriteProvider(song.id));

    return LayoutBuilder(
      builder: (context, constraints) {
        // The card is as wide as the screen minus 24dp each side, but
        // shrinks on short screens so everything still fits.
        final cardSize = (constraints.maxWidth - 48)
            .clamp(0.0, constraints.maxHeight - 290)
            .toDouble();

        return Column(
          children: [
            const SizedBox(height: 22),
            Container(
              width: cardSize,
              height: cardSize,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: VinylDisc(
                spinning: playing,
                artworkPath: song.localArtworkPath,
                size: cardSize * 0.68,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    tooltip: 'Add to playlist',
                    iconSize: 26,
                    color: Colors.white,
                    icon: const Icon(Icons.download_outlined),
                    onPressed: () {
                      final messenger = ScaffoldMessenger.of(context);
                      showAddToPlaylistDialog(context, ref, song, (text) {
                        messenger.showSnackBar(SnackBar(content: Text(text)));
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: isFavorite ? 'Remove from Favorites' : 'Favorite',
                    iconSize: 28,
                    color: isFavorite ? const Color(0xFFFF4F6A) : Colors.white,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                    ),
                    onPressed: () =>
                        ref.read(favoritesProvider.notifier).toggle(song.id),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 52),
            const _SeekBar(),
            const SizedBox(height: 8),
            const _Controls(),
            const Spacer(),
          ],
        );
      },
    );
  }
}

class _SeekBar extends ConsumerStatefulWidget {
  const _SeekBar();

  @override
  ConsumerState<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<_SeekBar> {
  /// While dragging, show the drag position instead of the live one.
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(playerPositionProvider).value ?? Duration.zero;
    final duration = ref.watch(playerDurationProvider).value ?? Duration.zero;
    final total = duration.inMilliseconds;

    final live =
        total > 0 ? (position.inMilliseconds / total).clamp(0.0, 1.0) : 0.0;
    final value = _dragValue ?? live;
    final shown = _dragValue == null
        ? position
        : Duration(milliseconds: (total * _dragValue!).round());

    final faded = Colors.white.withValues(alpha: 0.55);
    const timeStyle = TextStyle(fontSize: 13);

    return Column(
      children: [
        SizedBox(
          height: 24,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.12),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8,
                elevation: 0,
                pressedElevation: 0,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              // Explicit shapes replace Material 3's gapped track.
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Slider(
                value: value,
                onChanged:
                    total <= 0 ? null : (v) => setState(() => _dragValue = v),
                onChangeEnd: total <= 0
                    ? null
                    : (v) async {
                        await ref
                            .read(musicPlayerServiceProvider)
                            .seek(Duration(milliseconds: (total * v).round()));
                        if (mounted) setState(() => _dragValue = null);
                      },
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatDuration(shown),
                  style: timeStyle.copyWith(color: faded)),
              Text(formatDuration(duration),
                  style: timeStyle.copyWith(color: faded)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(musicPlayerServiceProvider);
    final playing = ref.watch(playerPlayingProvider).value ?? false;
    final mode = ref.watch(
      queueProvider.select((q) => q.value?.mode ?? PlayMode.playlistLoop),
    );

    Widget slot(Widget child) => Expanded(child: Center(child: child));

    return SizedBox(
      height: 64,
      child: Row(
        children: [
          slot(IconButton(
            tooltip: mode.label,
            iconSize: 24,
            color: Colors.white,
            icon: Icon(mode.icon),
            onPressed: () async {
              await player.cycleMode();
              if (context.mounted) showMessage(context, mode.next.label);
            },
          )),
          slot(IconButton(
            tooltip: 'Previous',
            iconSize: 30,
            color: Colors.white,
            icon: const Icon(Icons.skip_previous_rounded),
            onPressed: player.previous,
          )),
          slot(GestureDetector(
            onTap: player.togglePlayPause,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.6),
              ),
              child: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          )),
          slot(IconButton(
            tooltip: 'Next',
            iconSize: 30,
            color: Colors.white,
            icon: const Icon(Icons.skip_next_rounded),
            onPressed: player.next,
          )),
          slot(IconButton(
            tooltip: 'Queue',
            iconSize: 24,
            color: Colors.white,
            icon: const Icon(Icons.queue_music_rounded),
            onPressed: () => showQueueSheet(context),
          )),
        ],
      ),
    );
  }
}
