import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../player/providers/player_providers.dart';
import '../../models/song.dart';
import '../../providers/library_providers.dart';
import '../../services/library_actions.dart';
import 'artwork_image.dart';

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Plays [songs] starting at [index] and reports failures as a snackbar.
Future<void> playFromList(
  BuildContext context,
  WidgetRef ref,
  List<Song> songs,
  int index, {
  bool shuffle = false,
}) async {
  try {
    await ref
        .read(musicPlayerServiceProvider)
        .playSongs(songs, startIndex: index, shuffle: shuffle);
  } catch (error) {
    if (context.mounted) showMessage(context, 'Could not play: $error');
  }
}

Future<void> showSongOptionsSheet(
  BuildContext context,
  Song song, {
  String? extraActionLabel,
  VoidCallback? onExtraAction,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _SongOptions(
      song: song,
      extraActionLabel: extraActionLabel,
      onExtraAction: onExtraAction,
    ),
  );
}

class _SongOptions extends ConsumerWidget {
  final Song song;
  final String? extraActionLabel;
  final VoidCallback? onExtraAction;

  const _SongOptions({
    required this.song,
    this.extraActionLabel,
    this.onExtraAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(song.id));
    final subtitle = ref.watch(
      libraryIndexProvider.select((i) => i.value?.subtitle(song) ?? ''),
    );
    final player = ref.read(musicPlayerServiceProvider);
    final actions = ref.read(libraryActionsProvider);
    // Read up front: most actions close the sheet first, and a widget's ref
    // can't be used after it is gone.
    final favorites = ref.read(favoritesProvider.notifier);

    // The sheet's context dies when it closes; use the page's messenger.
    final messenger = ScaffoldMessenger.of(context);
    void toast(String text) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: ArtworkImage(
              artworkPath: song.localArtworkPath,
              seedId: song.id,
              size: 48,
            ),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const Divider(height: 1),
          _action(context, Icons.playlist_play_rounded, 'Play next', () async {
            await player.playNext(song);
            toast('Will play next');
          }),
          _action(context, Icons.queue_music_rounded, 'Add to queue', () async {
            await player.addToQueue(song);
            toast('Added to queue');
          }),
          _action(
            context,
            Icons.playlist_add_rounded,
            'Add to playlist',
            () => showAddToPlaylistDialog(context, ref, song, toast),
            closeFirst: false,
          ),
          _action(
            context,
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
            () => favorites.toggle(song.id),
          ),
          _action(context, Icons.lyrics_outlined, 'Choose lyric file', () async {
            try {
              final picked = await actions.pickLyricsFor(song);
              if (picked) toast('Lyrics added');
            } catch (error) {
              toast('$error');
            }
          }),
          if (extraActionLabel != null && onExtraAction != null)
            _action(
              context,
              Icons.remove_circle_outline,
              extraActionLabel!,
              () async => onExtraAction!(),
            ),
          _action(
            context,
            Icons.delete_outline_rounded,
            'Delete from library',
            () => _confirmDelete(context, ref, toast),
            closeFirst: false,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String label,
    Future<void> Function() onTap, {
    bool closeFirst = true,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textPrimary),
      title: Text(label, style: TextStyle(color: color)),
      onTap: () async {
        if (closeFirst) Navigator.pop(context);
        await onTap();
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    void Function(String) toast,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete song?'),
        content: Text(
          song.isLinked
              ? 'Remove "${song.title}" from the library? '
                  'The file stays on your phone.'
              : 'Remove "${song.title}" from the library?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Read before closing: the sheet's ref is gone once it pops.
    final actions = ref.read(libraryActionsProvider);

    if (context.mounted) Navigator.pop(context);

    try {
      await actions.deleteSong(song);
      toast('"${song.title}" deleted');
    } catch (error) {
      toast('Failed to delete: $error');
    }
  }
}

/// Lets the user pick a playlist (or create one) for [song].
Future<void> showAddToPlaylistDialog(
  BuildContext context,
  WidgetRef ref,
  Song song,
  void Function(String) toast,
) async {
  final actions = ref.read(libraryActionsProvider);
  final playlists = await ref.read(playlistsProvider.future);

  if (!context.mounted) return;

  final choice = await showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('Add to playlist'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, '_new'),
          child: const Row(
            children: [
              Icon(Icons.add_rounded, color: AppColors.accent),
              SizedBox(width: 12),
              Text('New playlist'),
            ],
          ),
        ),
        for (final playlist in playlists)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, playlist.id),
            child: Text('${playlist.name}  (${playlist.songCount})'),
          ),
      ],
    ),
  );

  if (choice == null || !context.mounted) return;

  var playlistId = choice;

  if (choice == '_new') {
    final name = await askForText(context, title: 'New playlist');
    if (name == null) return;
    playlistId = await actions.createPlaylist(name);
  }

  final added = await actions.addToPlaylist(playlistId, song);
  toast(added ? 'Added to playlist' : 'Already in this playlist');

  if (context.mounted && Navigator.canPop(context)) {
    Navigator.pop(context); // close the options sheet
  }
}

/// Simple text prompt; returns null when cancelled or empty.
Future<String?> askForText(
  BuildContext context, {
  required String title,
  String initial = '',
}) async {
  final controller = TextEditingController(text: initial);

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Name'),
        onSubmitted: (value) => Navigator.pop(dialogContext, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  // Not disposed here: the dialog is still animating out and uses it.
  final trimmed = result?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
