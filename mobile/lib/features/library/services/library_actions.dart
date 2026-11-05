import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../player/providers/player_providers.dart';
import '../models/song.dart';
import '../providers/library_data_providers.dart';
import '../providers/library_providers.dart';

/// Library changes that touch several places (database, files, player,
/// cached providers), kept out of the widgets.
class LibraryActions {
  final Ref ref;

  LibraryActions(this.ref);

  Future<void> refresh() async {
    await ref.read(librarySongsProvider.notifier).refreshSongs();
    ref.invalidate(favoriteSongsProvider);
    ref.invalidate(recentSongsProvider);
    ref.invalidate(playlistsProvider);
  }

  /// Removes the song from the library. A copied file is deleted; a linked
  /// file (folder scan) stays on the phone.
  Future<void> deleteSong(Song song) async {
    final files = ref.read(localFileServiceProvider);

    await ref.read(musicPlayerServiceProvider).removeSongEverywhere(song.id);

    await ref.read(libraryExtrasRepositoryProvider).deleteSongReferences(
          song.id,
        );
    await ref.read(songRepositoryProvider).deleteSong(song.id);

    await files.deleteOwnedFile(song.localAudioPath);
    await files.deleteOwnedFile(song.localArtworkPath);
    await files.deleteOwnedFile(song.localLyricsPath);

    ref.invalidate(favoritesProvider);
    await refresh();
  }

  /// Lets the user pick an .lrc/.txt file and attaches a copy to the song.
  /// Returns false if they cancelled.
  Future<bool> pickLyricsFor(Song song) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    final picked = result?.files.single.path;

    if (picked == null) {
      return false;
    }

    final ext = path.extension(picked).toLowerCase();

    if (ext != '.lrc' && ext != '.txt') {
      throw const FormatException('Choose a .lrc or .txt lyrics file.');
    }

    final files = ref.read(localFileServiceProvider);
    final destination = await files.getLyricsFilePath(
      song.id,
      ext.substring(1),
    );

    // Replace any earlier lyrics file for this song.
    await files.deleteOwnedFile(song.localLyricsPath);
    await File(picked).copy(destination);

    await ref
        .read(libraryExtrasRepositoryProvider)
        .updateLyricsPath(song.id, destination);

    await refresh();
    ref.read(musicPlayerServiceProvider).updateSongInQueue(
          song.copyWith(localLyricsPath: destination),
        );

    return true;
  }

  Future<String> createPlaylist(String name) async {
    final id =
        await ref.read(libraryExtrasRepositoryProvider).createPlaylist(name);
    ref.invalidate(playlistsProvider);
    return id;
  }

  Future<bool> addToPlaylist(String playlistId, Song song) async {
    final added = await ref
        .read(libraryExtrasRepositoryProvider)
        .addSongToPlaylist(playlistId, song.id);
    ref.invalidate(playlistsProvider);
    ref.invalidate(playlistSongsProvider(playlistId));
    return added;
  }

  Future<void> removeFromPlaylist(String playlistId, Song song) async {
    await ref
        .read(libraryExtrasRepositoryProvider)
        .removeSongFromPlaylist(playlistId, song.id);
    ref.invalidate(playlistsProvider);
    ref.invalidate(playlistSongsProvider(playlistId));
  }

  Future<void> renamePlaylist(String playlistId, String name) async {
    await ref
        .read(libraryExtrasRepositoryProvider)
        .renamePlaylist(playlistId, name);
    ref.invalidate(playlistsProvider);
  }

  Future<void> deletePlaylist(String playlistId) async {
    await ref.read(libraryExtrasRepositoryProvider).deletePlaylist(playlistId);
    ref.invalidate(playlistsProvider);
  }
}

final libraryActionsProvider = Provider<LibraryActions>(LibraryActions.new);
