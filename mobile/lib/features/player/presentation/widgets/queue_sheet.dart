import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../library/models/song.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../../../library/presentation/widgets/song_options_sheet.dart';
import '../../../library/providers/library_providers.dart';
import '../../models/play_mode.dart';
import '../../providers/player_providers.dart';

Future<void> showQueueSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const FractionallySizedBox(
      heightFactor: 1,
      child: _QueueSheet(),
    ),
  );
}

/// "Cancel" + Queue / History tabs, mode row with count and clear, then the
/// songs with remove (x) and drag handles.
class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Cancel" in red, 16sp, 16dp from the left.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const SizedBox(
            height: 40,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              labelPadding: EdgeInsets.symmetric(horizontal: 38),
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              unselectedLabelStyle:
                  TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 2.5, color: AppColors.textPrimary),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: [Tab(text: 'Queue'), Tab(text: 'History')],
            ),
          ),
          const Expanded(
            child: TabBarView(children: [_QueueTab(), _HistoryTab()]),
          ),
        ],
      ),
    );
  }
}

class _QueueTab extends ConsumerWidget {
  const _QueueTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueProvider).value;
    final player = ref.read(musicPlayerServiceProvider);

    if (queue == null || queue.isEmpty) {
      return const Center(
        child: Text(
          'The queue is empty',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    // Drag to reorder only when not shuffling: then the list order is the
    // play order.
    final canReorder = queue.mode != PlayMode.shuffle;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 4, 6),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: player.cycleMode,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(queue.mode.icon, color: Colors.white, size: 15),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      queue.mode.label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${queue.songs.length} track(s)',
                style: const TextStyle(fontSize: 17, color: Color(0xFFB0B0B5)),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Clear queue',
                iconSize: 24,
                color: AppColors.textPrimary,
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await player.clearQueue();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: queue.songs.length,
            onReorder: (from, to) {
              // ReorderableListView reports the slot *before* removal.
              final target = to > from ? to - 1 : to;
              player.moveInQueue(from, target);
            },
            itemBuilder: (context, i) {
              final song = queue.songs[i];

              return _QueueRow(
                key: ValueKey('${song.id}-$i'),
                song: song,
                index: i,
                isCurrent: i == queue.currentIndex,
                canReorder: canReorder,
                onTap: () => player.jumpTo(i),
                onRemove: () => player.removeFromQueue(i),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QueueRow extends ConsumerWidget {
  final Song song;
  final int index;
  final bool isCurrent;
  final bool canReorder;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _QueueRow({
    super.key,
    required this.song,
    required this.index,
    required this.isCurrent,
    required this.canReorder,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = ref.watch(
      libraryIndexProvider.select((i) => i.value?.subtitle(song) ?? ''),
    );
    final titleColor = isCurrent ? AppColors.accent : AppColors.textPrimary;
    final subColor = isCurrent ? AppColors.accent : AppColors.textSecondary;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 71,
          child: Row(
            children: [
              const SizedBox(width: 16),
              ArtworkImage(
                artworkPath: song.localArtworkPath,
                seedId: song.id,
                size: 56,
                borderRadius: 8,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, height: 1.25, color: titleColor),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.smartphone_outlined, size: 11, color: subColor),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, height: 1.2, color: subColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: onRemove,
                icon: const CircleAvatar(
                  radius: 9,
                  backgroundColor: Color(0xFFDCDCE0),
                  child: Icon(Icons.close_rounded, size: 12, color: Colors.white),
                ),
              ),
              if (canReorder)
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(6, 10, 16, 10),
                    child: Icon(Icons.drag_handle, size: 24, color: Color(0xFFC4C4C8)),
                  ),
                )
              else
                const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSongsProvider);

    return recent.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(
            child: Text(
              'Nothing played yet',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: songs.length,
          itemBuilder: (context, i) {
            final song = songs[i];

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: ArtworkImage(
                artworkPath: song.localArtworkPath,
                seedId: song.id,
                size: 48,
              ),
              title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => playFromList(context, ref, songs, i),
            );
          },
        );
      },
    );
  }
}
