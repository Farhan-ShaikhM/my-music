import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/models/song.dart';
import '../../library/providers/library_providers.dart';
import '../services/music_player_service.dart';

final musicPlayerServiceProvider = Provider<MusicPlayerService>((ref) {
  final service = MusicPlayerService();

  service.describeArtist =
      (song) => ref.read(libraryIndexProvider).value?.artistLabel(song) ?? '';
  service.describeAlbum =
      (song) => ref.read(libraryIndexProvider).value?.albumLabel(song) ?? '';

  service.onSongStarted = (song) async {
    try {
      await ref.read(libraryExtrasRepositoryProvider).addToHistory(song.id);
      ref.invalidate(recentSongsProvider);
    } catch (_) {
      // History is a nice-to-have; never interrupt playback for it.
    }
  };

  ref.onDispose(service.dispose);

  return service;
});

final queueProvider = StreamProvider<QueueState>((ref) {
  return ref.watch(musicPlayerServiceProvider).queueStream;
});

/// The playing song, or null when the queue is empty.
final currentSongProvider = Provider<Song?>((ref) {
  return ref.watch(queueProvider).value?.current;
});

final playerPlayingProvider = StreamProvider<bool>((ref) {
  return ref.watch(musicPlayerServiceProvider).player.playingStream;
});

final playerPositionProvider = StreamProvider<Duration>((ref) {
  return ref.watch(musicPlayerServiceProvider).player.positionStream;
});

final playerDurationProvider = StreamProvider<Duration?>((ref) {
  return ref.watch(musicPlayerServiceProvider).player.durationStream;
});

/// 0..1 progress of the current song, for the ring around the mini player
/// button.
final playerProgressProvider = Provider<double>((ref) {
  final position = ref.watch(playerPositionProvider).value ?? Duration.zero;
  final duration = ref.watch(playerDurationProvider).value;

  if (duration == null || duration.inMilliseconds <= 0) {
    return 0;
  }

  return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
});

// ------------------------------------------------------------ sleep timer

class SleepTimerNotifier extends Notifier<DateTime?> {
  Timer? _timer;

  @override
  DateTime? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void start(Duration duration) {
    _timer?.cancel();
    _timer = Timer(duration, () async {
      await ref.read(musicPlayerServiceProvider).player.pause();
      state = null;
    });
    state = DateTime.now().add(duration);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }
}

final sleepTimerProvider = NotifierProvider<SleepTimerNotifier, DateTime?>(
  SleepTimerNotifier.new,
);
