import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../player/providers/player_providers.dart';
import '../../models/song.dart';
import '../../providers/library_providers.dart';
import 'artwork_image.dart';
import 'song_options_sheet.dart';

/// One track row: artwork, title, "phone icon  Artist - Album", menu.
/// The playing song is shown in the accent colour.
class SongTile extends ConsumerWidget {
  final Song song;
  final VoidCallback onTap;

  /// Extra menu entry, e.g. "Remove from playlist".
  final String? extraActionLabel;
  final VoidCallback? onExtraAction;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.extraActionLabel,
    this.onExtraAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = ref.watch(
      currentSongProvider.select((current) => current?.id == song.id),
    );
    final subtitle = ref.watch(
      libraryIndexProvider.select(
        (index) => index.value?.subtitle(song) ?? '',
      ),
    );

    final titleColor = isCurrent ? AppColors.accent : AppColors.textPrimary;
    final subColor = isCurrent ? AppColors.accent : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Row(
          children: [
            ArtworkImage(
              artworkPath: song.localArtworkPath,
              seedId: song.id,
              size: 56,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.smartphone_outlined, size: 13, color: subColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: subColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onPressed: () => showSongOptionsSheet(
                context,
                song,
                extraActionLabel: extraActionLabel,
                onExtraAction: onExtraAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Red play pill + "Shuffle  N track(s)" + an optional trailing button.
class ShuffleHeader extends StatelessWidget {
  final int count;
  final VoidCallback? onShuffle;
  final Widget? trailing;

  const ShuffleHeader({
    super.key,
    required this.count,
    required this.onShuffle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: count == 0 ? null : onShuffle,
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Shuffle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count track(s)',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
