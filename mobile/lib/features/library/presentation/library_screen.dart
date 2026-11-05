import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../player/presentation/widgets/mini_player.dart';
import '../models/library_index.dart';
import '../models/import_song_draft.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/library_data_providers.dart';
import '../providers/library_providers.dart';
import '../screens/import_song_review_screen.dart';
import '../services/duplicate_song_exception.dart';
import '../services/folder_scan_service.dart';
import '../services/library_actions.dart';
import 'search_screen.dart';
import 'song_list_screen.dart';
import 'widgets/artwork_image.dart';
import 'widgets/song_options_sheet.dart';
import 'widgets/song_tile.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 5, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                _quickCards(),
                _tabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: const [
                      _TracksTab(),
                      _GroupsTab(kind: _GroupKind.albums),
                      _PlaylistsTab(),
                      _GroupsTab(kind: _GroupKind.artists),
                      _GroupsTab(kind: _GroupKind.folders),
                    ],
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- header

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      child: Row(
        children: [
          const Text(
            'Library',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Search',
            iconSize: 28,
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Add music',
            icon: const Icon(Icons.add_rounded, size: 28),
            onSelected: _onMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'scan', child: Text('Scan a music folder')),
              PopupMenuItem(value: 'files', child: Text('Import files')),
              PopupMenuItem(
                value: 'review',
                child: Text('Import one song (edit details)'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'dupes',
                child: Text('Remove duplicate songs'),
              ),
              PopupMenuItem(value: 'clear', child: Text('Clear Recent')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickCards() {
    return SizedBox(
      height: 112,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          _QuickCard(
            icon: Icons.favorite_rounded,
            color: const Color(0xFFFF4D67),
            label: 'Favorites',
            onTap: () => _open(
              SongListScreen(
                title: 'Favorites',
                emptyMessage: 'Tap the heart on a song to add it here.',
                watchSongs: (ref) => ref.watch(favoriteSongsProvider),
              ),
            ),
          ),
          _QuickCard(
            icon: Icons.schedule_rounded,
            color: const Color(0xFFFF9F43),
            label: 'Recent',
            onTap: () => _open(
              SongListScreen(
                title: 'Recent',
                emptyMessage: 'Songs you play show up here.',
                watchSongs: (ref) => ref.watch(recentSongsProvider),
              ),
            ),
          ),
          _QuickCard(
            icon: Icons.folder_open_rounded,
            color: const Color(0xFF8B6CFF),
            label: 'Scan',
            onTap: _scanFolder,
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return TabBar(
      controller: _tabs,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      labelColor: AppColors.textPrimary,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 18),
      indicatorColor: AppColors.textPrimary,
      indicatorSize: TabBarIndicatorSize.label,
      indicatorWeight: 3,
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(text: 'Tracks'),
        Tab(text: 'Albums'),
        Tab(text: 'Playlists'),
        Tab(text: 'Artists'),
        Tab(text: 'Folders'),
      ],
    );
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // ------------------------------------------------------------- import

  Future<void> _onMenu(String value) async {
    switch (value) {
      case 'scan':
        await _scanFolder();
      case 'files':
        await _importFiles();
      case 'review':
        await _importWithReview();
      case 'dupes':
        await _removeDuplicates();
      case 'clear':
        await ref.read(libraryExtrasRepositoryProvider).clearHistory();
        ref.invalidate(recentSongsProvider);
        if (mounted) showMessage(context, 'Recent cleared');
    }
  }

  Future<void> _scanFolder() async {
    final scanner = FolderScanService(
      importService: ref.read(musicImportServiceProvider),
    );

    final allowed = await scanner.requestAudioPermission();

    if (!allowed) {
      if (mounted) {
        showMessage(context, 'Allow "Music and audio" access to scan songs.');
      }
      return;
    }

    final folder = await scanner.pickFolder();

    if (folder == null || !mounted) return;

    final files = await scanner.findAudioFiles(folder);

    if (!mounted) return;

    if (files.isEmpty) {
      showMessage(context, 'No audio files found in that folder.');
      return;
    }

    final result = await showDialog<ScanProgress>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProgressDialog(stream: scanner.importFiles(files)),
    );

    await ref.read(libraryActionsProvider).refresh();

    if (result != null && mounted) {
      showMessage(
        context,
        'Added ${result.added}, already in library ${result.skipped}'
        '${result.failed > 0 ? ', failed ${result.failed}' : ''}',
      );
    }
  }

  Future<void> _importFiles() async {
    final importService = ref.read(musicImportServiceProvider);
    final paths = await importService.pickSongsForBulkImport();

    if (paths.isEmpty || !mounted) return;

    var added = 0;
    var skipped = 0;
    var failed = 0;

    final result = await showDialog<ScanProgress>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProgressDialog(
        stream: () async* {
          for (var i = 0; i < paths.length; i++) {
            try {
              await importService.importSong(paths[i]);
              added++;
            } on DuplicateSongException {
              skipped++;
            } catch (_) {
              failed++;
            }
            yield ScanProgress(
              done: i + 1,
              total: paths.length,
              added: added,
              skipped: skipped,
              failed: failed,
            );
          }
        }(),
      ),
    );

    await _clearPickerCache();
    await ref.read(libraryActionsProvider).refresh();

    if (result != null && mounted) {
      showMessage(
        context,
        'Imported ${result.added}, duplicates ${result.skipped}'
        '${result.failed > 0 ? ', failed ${result.failed}' : ''}',
      );
    }
  }

  Future<void> _importWithReview() async {
    final importService = ref.read(musicImportServiceProvider);

    try {
      final draft = await importService.pickSongForImport();

      if (draft == null || !mounted) return;

      final reviewed = await Navigator.push<ImportSongDraft>(
        context,
        MaterialPageRoute(builder: (_) => ImportSongReviewScreen(draft: draft)),
      );

      await _clearPickerCache();

      if (reviewed == null) return;

      await ref.read(libraryActionsProvider).refresh();
    } catch (error) {
      if (mounted) showMessage(context, 'Failed to prepare song: $error');
    }
  }

  Future<void> _removeDuplicates() async {
    final count =
        await ref.read(duplicateSongCleanupServiceProvider).removeExactDuplicates();
    await ref.read(libraryActionsProvider).refresh();

    if (mounted) {
      showMessage(
        context,
        count == 0 ? 'No duplicates found' : 'Removed $count duplicate(s)',
      );
    }
  }

  /// file_picker copies picked files into the app cache on Android. Once
  /// they are imported the copies are only wasting space.
  Future<void> _clearPickerCache() async {
    try {
      await FilePicker.platform.clearTemporaryFiles();
    } catch (_) {
      // Not supported on every platform.
    }
  }
}

// =============================================================== widgets

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            width: 104,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 40),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressDialog extends StatefulWidget {
  final Stream<ScanProgress> stream;

  const _ProgressDialog({required this.stream});

  @override
  State<_ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  ScanProgress? _progress;
  StreamSubscription<ScanProgress>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.stream.listen(
      (progress) {
        if (mounted) setState(() => _progress = progress);
      },
      onDone: () {
        if (mounted) Navigator.pop(context, _progress);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    final total = progress?.total ?? 0;
    final done = progress?.done ?? 0;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Adding music'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: total == 0 ? null : done / total,
              color: AppColors.accent,
            ),
            const SizedBox(height: 12),
            Text(total == 0 ? 'Starting...' : '$done of $total'),
          ],
        ),
      ),
    );
  }
}

// ================================================================== tabs

class _TracksTab extends ConsumerWidget {
  const _TracksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(sortedSongsProvider);
    final sort = ref.watch(songSortProvider);

    return songsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Failed to load library:\n$error', textAlign: TextAlign.center),
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return const _EmptyLibrary();
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 110),
          itemCount: songs.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return ShuffleHeader(
                count: songs.length,
                onShuffle: () => playFromList(context, ref, songs, 0, shuffle: true),
                trailing: PopupMenuButton<SongSort>(
                  tooltip: 'Sort',
                  icon: const Icon(Icons.sort_rounded, size: 28),
                  initialValue: sort,
                  onSelected: ref.read(songSortProvider.notifier).set,
                  itemBuilder: (_) => [
                    for (final option in SongSort.values)
                      CheckedPopupMenuItem(
                        value: option,
                        checked: option == sort,
                        child: Text(option.label),
                      ),
                  ],
                ),
              );
            }

            final song = songs[index - 1];

            return SongTile(
              song: song,
              onTap: () => playFromList(context, ref, songs, index - 1),
            );
          },
        );
      },
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No music yet.\nTap Scan to add the songs on your phone, '
          'or + to import files.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ),
    );
  }
}

enum _GroupKind { albums, artists, folders }

class _GroupsTab extends ConsumerWidget {
  final _GroupKind kind;

  const _GroupsTab({required this.kind});

  static List<SongGroup> _groupsOf(LibraryIndex index, _GroupKind kind) {
    switch (kind) {
      case _GroupKind.albums:
        return index.albumGroups();
      case _GroupKind.artists:
        return index.artistGroups();
      case _GroupKind.folders:
        return index.folderGroups();
    }
  }

  String get _noun => switch (kind) {
        _GroupKind.albums => 'album(s)',
        _GroupKind.artists => 'artist(s)',
        _GroupKind.folders => 'folder(s)',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indexAsync = ref.watch(libraryIndexProvider);

    return indexAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (index) {
        final groups = _groupsOf(index, kind);

        if (groups.isEmpty) return const _EmptyLibrary();

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 110),
          itemCount: groups.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${groups.length} $_noun',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                  ],
                ),
              );
            }

            final group = groups[i - 1];

            return _GroupTile(
              group: group,
              showDisc: kind == _GroupKind.albums,
              icon: kind == _GroupKind.folders ? Icons.folder_rounded : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SongListScreen(
                    title: group.name,
                    watchSongs: (ref) => ref
                        .watch(libraryIndexProvider)
                        .whenData((index) {
                      for (final g in _groupsOf(index, kind)) {
                        if (g.id == group.id) return g.songs;
                      }
                      return const <Song>[];
                    }),
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

/// Album/artist/folder row. Albums show a record peeking out from behind
/// the cover.
class _GroupTile extends StatelessWidget {
  final SongGroup group;
  final bool showDisc;
  final IconData? icon;
  final VoidCallback onTap;

  const _GroupTile({
    required this.group,
    required this.showDisc,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Widget art = icon != null
        ? Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFFFB020), size: 32),
          )
        : ArtworkImage(
            artworkPath: group.artworkPath,
            seedId: group.id,
            size: 56,
          );

    if (showDisc) {
      art = SizedBox(
        width: 70,
        height: 56,
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 2,
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF262626),
                ),
              ),
            ),
            art,
          ],
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            art,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${group.songs.length} track(s)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    final actions = ref.read(libraryActionsProvider);

    return playlistsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (playlists) {
        return ListView(
          padding: const EdgeInsets.only(bottom: 110, top: 8),
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.accent, size: 30),
              ),
              title: const Text(
                'New playlist',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              ),
              onTap: () async {
                final name = await askForText(context, title: 'New playlist');
                if (name != null) await actions.createPlaylist(name);
              },
            ),
            for (final playlist in playlists) _playlistTile(context, ref, playlist),
          ],
        );
      },
    );
  }

  Widget _playlistTile(BuildContext context, WidgetRef ref, Playlist playlist) {
    final actions = ref.read(libraryActionsProvider);

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      leading: ArtworkImage(seedId: playlist.id, size: 56),
      title: Text(
        playlist.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      ),
      subtitle: Text('${playlist.songCount} track(s)'),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
        onSelected: (value) async {
          if (value == 'rename') {
            final name = await askForText(
              context,
              title: 'Rename playlist',
              initial: playlist.name,
            );
            if (name != null) await actions.renamePlaylist(playlist.id, name);
          } else if (value == 'delete') {
            await actions.deletePlaylist(playlist.id);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'rename', child: Text('Rename')),
          PopupMenuItem(value: 'delete', child: Text('Delete playlist')),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SongListScreen(
            title: playlist.name,
            emptyMessage: 'Add songs from their ⋮ menu.',
            watchSongs: (ref) => ref.watch(playlistSongsProvider(playlist.id)),
            extraActionLabel: 'Remove from this playlist',
            onExtraAction: (song) => actions.removeFromPlaylist(playlist.id, song),
          ),
        ),
      ),
    );
  }
}
