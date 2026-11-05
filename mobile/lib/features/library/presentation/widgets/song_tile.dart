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

    // Sizes measured from the reference screenshots (360dp wide screen):
    // 56dp art, 71dp row, 16sp title, 14sp subtitle.
    return InkWell(
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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w400,
                      color: titleColor,
                    ),
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
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.2,
                            color: subColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 48,
              child: IconButton(
                tooltip: 'More',
                iconSize: 22,
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFFB0B0B5),
                ),
                onPressed: () => showSongOptionsSheet(
                  context,
                  song,
                  extraActionLabel: extraActionLabel,
                  onExtraAction: onExtraAction,
                ),
              ),
            ),
            const SizedBox(width: 4),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                GestureDetector(
                  onTap: count == 0 ? null : onShuffle,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Shuffle',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count track(s)',
                        style: const TextStyle(
                          fontSize: 17,
                          color: Color(0xFFB0B0B5),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, thickness: 0.6, color: AppColors.divider),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
