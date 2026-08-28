import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobile/features/player/providers/player_repeat_provider.dart';
import 'package:mobile/features/player/providers/player_shuffle_provider.dart';

import '../../library/models/song.dart';
import '../models/repeat_mode.dart';
import '../services/music_player_service.dart';
import 'player_queue_provider.dart';

final musicPlayerServiceProvider = Provider<MusicPlayerService>((ref) {
  final service = MusicPlayerService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

class CurrentSongNotifier extends Notifier<Song?> {
  @override
  Song? build() {
    ref.listen<AsyncValue<ProcessingState>>(
      playerProcessingStateProvider,
      (previous, next) {
        final processingState = next.value;

        if (processingState != ProcessingState.completed) {
          return;
        }

        _handleSongCompleted();
      },
    );

    return null;
  }

  void setSong(Song? song) {
    state = song;
  }

  Future<void> _handleSongCompleted() async {
    final currentSong = state;

    if (currentSong == null) {
      return;
    }

    final repeatMode = ref.read(playerRepeatProvider);
    final player = ref.read(musicPlayerServiceProvider);

    // Repeat the current song.
    if (repeatMode == RepeatMode.song) {
      await player.seek(Duration.zero);
      await player.resume();
      return;
    }

    final queueNotifier = ref.read(playerQueueProvider.notifier);

    // No longer need to pass 'isShuffle' here
    final nextSong = queueNotifier.nextSong(
      currentSong.id,
      repeatAll: repeatMode == RepeatMode.playlist,
    );

    // If there is a next song, play it. Otherwise, stop.
    if (nextSong != null) {
      await player.playSong(nextSong);
      state = nextSong;
    } else {
      await player.stop();
    }
  }
}

final playerProcessingStateProvider = StreamProvider<ProcessingState>((ref) {
  final player = ref.watch(musicPlayerServiceProvider).audioPlayer;

  return player.processingStateStream;
});


// ==========================================
// NEWLY ADDED PROVIDERS TO FIX YOUR ERRORS
// ==========================================

// 1. The provider that actually exposes your CurrentSongNotifier
final currentSongProvider = NotifierProvider<CurrentSongNotifier, Song?>(() {
  return CurrentSongNotifier();
});

// 2. Provider to check if the audio is currently playing or paused
final playerPlayingProvider = StreamProvider<bool>((ref) {
  final player = ref.watch(musicPlayerServiceProvider).audioPlayer;
  return player.playingStream;
});

// 3. Provider to get the current playback position (for the slider)
final playerPositionProvider = StreamProvider<Duration>((ref) {
  final player = ref.watch(musicPlayerServiceProvider).audioPlayer;
  return player.positionStream;
});

// 4. Provider to get the total duration of the current song
final playerDurationProvider = StreamProvider<Duration?>((ref) {
  final player = ref.watch(musicPlayerServiceProvider).audioPlayer;
  return player.durationStream;
});