import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/models/song.dart';
import 'music_player_provider.dart';
import 'player_shuffle_provider.dart';

class PlayerQueueNotifier extends Notifier<List<Song>> {
  List<Song> _playbackQueue = [];

  @override
  List<Song> build() {
    // Automatically rebuild the playback queue whenever shuffle is toggled.
    ref.listen(playerShuffleProvider, (previous, isShuffle) {
      final currentSongId = ref.read(currentSongProvider)?.id;
      _updatePlaybackQueue(isShuffle, currentSongId);
    });

    return [];
  }

  void _updatePlaybackQueue(bool isShuffle, String? currentSongId) {
    if (isShuffle) {
      _createShuffleQueue(currentSongId);
    } else {
      _playbackQueue = List<Song>.from(state);
    }
  }

  void setQueue(List<Song> songs) {
    state = List<Song>.from(songs);
    final isShuffle = ref.read(playerShuffleProvider);
    _updatePlaybackQueue(isShuffle, null);
  }

  void clearQueue() {
    state = [];
    _playbackQueue = [];
  }

  void addSong(Song song) {
    state = [...state, song];
    final isShuffle = ref.read(playerShuffleProvider);
    
    if (isShuffle) {
      _playbackQueue.add(song);
    } else {
      _playbackQueue = List<Song>.from(state);
    }
  }

  void removeSong(String songId) {
    state = state.where((song) => song.id != songId).toList();
    _playbackQueue = _playbackQueue.where((song) => song.id != songId).toList();
  }

  int indexOf(String songId) {
    return state.indexWhere((song) => song.id == songId);
  }

  void _createShuffleQueue(String? currentSongId) {
    final songs = List<Song>.from(state);

    if (songs.isEmpty) {
      _playbackQueue = [];
      return;
    }

    songs.shuffle(Random());

    // Keep the currently playing song at the beginning.
    if (currentSongId != null) {
      final currentIndex = songs.indexWhere(
        (song) => song.id == currentSongId,
      );

      if (currentIndex != -1) {
        final currentSong = songs.removeAt(currentIndex);
        songs.insert(0, currentSong);
      }
    }

    _playbackQueue = songs;
  }

  // Notice: isShuffle argument is completely removed
  Song? nextSong(String currentSongId, {bool repeatAll = false}) {
    if (state.isEmpty) return null;

    final index = _playbackQueue.indexWhere((song) => song.id == currentSongId);

    if (index == -1) return null;

    if (index < _playbackQueue.length - 1) {
      return _playbackQueue[index + 1];
    }

    if (repeatAll) {
      return _playbackQueue.first;
    }

    return null;
  }

  // Notice: isShuffle argument is completely removed
  Song? previousSong(String currentSongId, {bool repeatAll = false}) {
    if (state.isEmpty) return null;

    final index = _playbackQueue.indexWhere((song) => song.id == currentSongId);

    if (index == -1) return null;

    if (index > 0) {
      return _playbackQueue[index - 1];
    }

    if (repeatAll) {
      return _playbackQueue.last;
    }

    return null;
  }
}

final playerQueueProvider =
    NotifierProvider<PlayerQueueNotifier, List<Song>>(
  PlayerQueueNotifier.new,
);