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
                        const SizedBox(height: 12),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close',
            iconSize: 34,
            color: Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _pill('COVER', 0),
                _pill('LYRIC', 1),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'More',
            color: Colors.white,
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showMoreMenu(context, ref, song),
          ),
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
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: selected ? 1 : 0.6),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
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
        final cardSize = (constraints.maxWidth - 48)
            .clamp(0.0, constraints.maxHeight * 0.52)
            .toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Center(
                child: Container(
                  width: cardSize,
                  height: cardSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  alignment: Alignment.center,
                  child: VinylDisc(
                    spinning: playing,
                    artworkPath: song.localArtworkPath,
                    size: cardSize * 0.68,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add to playlist',
                    iconSize: 32,
                    color: Colors.white,
                    icon: const Icon(Icons.playlist_add_rounded),
                    onPressed: () {
                      final messenger = ScaffoldMessenger.of(context);
                      showAddToPlaylistDialog(context, ref, song, (text) {
                        messenger.showSnackBar(SnackBar(content: Text(text)));
                      });
                    },
                  ),
                  IconButton(
                    tooltip: isFavorite ? 'Remove from Favorites' : 'Favorite',
                    iconSize: 32,
                    color: isFavorite ? const Color(0xFFFF4D67) : Colors.white,
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    ),
                    onPressed: () =>
                        ref.read(favoritesProvider.notifier).toggle(song.id),
                  ),
                ],
              ),
              const Spacer(flex: 1),
              const _SeekBar(),
              const Spacer(flex: 1),
              const _Controls(),
              const Spacer(flex: 2),
            ],
          ),
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

    final live = total > 0 ? (position.inMilliseconds / total).clamp(0.0, 1.0) : 0.0;
    final value = _dragValue ?? live;
    final shown = _dragValue == null
        ? position
        : Duration(milliseconds: (total * _dragValue!).round());

    final faded = Colors.white.withValues(alpha: 0.6);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: value,
            onChanged: total <= 0 ? null : (v) => setState(() => _dragValue = v),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatDuration(shown), style: TextStyle(color: faded, fontSize: 15)),
              Text(formatDuration(duration), style: TextStyle(color: faded, fontSize: 15)),
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: mode.label,
          iconSize: 30,
          color: Colors.white,
          icon: Icon(mode.icon),
          onPressed: () async {
            await player.cycleMode();
            if (context.mounted) showMessage(context, mode.next.label);
          },
        ),
        IconButton(
          tooltip: 'Previous',
          iconSize: 44,
          color: Colors.white,
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: player.previous,
        ),
        GestureDetector(
          onTap: player.togglePlayPause,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 46,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next',
          iconSize: 44,
          color: Colors.white,
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: player.next,
        ),
        IconButton(
          tooltip: 'Queue',
          iconSize: 30,
          color: Colors.white,
          icon: const Icon(Icons.queue_music_rounded),
          onPressed: () => showQueueSheet(context),
        ),
      ],
    );
  }
}
