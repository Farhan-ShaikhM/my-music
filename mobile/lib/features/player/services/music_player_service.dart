import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../library/models/song.dart';
import '../models/play_mode.dart';

/// What the queue sheet, mini player and now playing screen show.
class QueueState {
  /// Songs in the order they will play (shuffled order when shuffling).
  final List<Song> songs;

  /// Position of the current song inside [songs], or -1 when nothing loaded.
  final int currentIndex;

  final PlayMode mode;

  const QueueState({
    required this.songs,
    required this.currentIndex,
    required this.mode,
  });

  static const empty = QueueState(
    songs: [],
    currentIndex: -1,
    mode: PlayMode.playlistLoop,
  );

  Song? get current =>
      currentIndex >= 0 && currentIndex < songs.length
          ? songs[currentIndex]
          : null;

  bool get isEmpty => songs.isEmpty;
}

/// Wraps just_audio's own playlist, so auto-advance, looping and shuffle keep
/// working with the screen off and from the notification / headset buttons.
///
/// The previous version kept its own queue and started the next song from a
/// Riverpod listener, which only ran while the app's UI was alive.
class MusicPlayerService {
  final AudioPlayer player = AudioPlayer();

  /// Called once each time a different song starts (for Recent).
  void Function(Song song)? onSongStarted;

  /// Builds the artist line for the notification.
  String Function(Song song)? describeArtist;
  String Function(Song song)? describeAlbum;

  /// Song for each entry of player.sequence, same order.
  final List<Song> _sequence = [];

  PlayMode _mode = PlayMode.playlistLoop;
  String? _lastStartedId;
  QueueState _latest = QueueState.empty;

  final _queueController = StreamController<QueueState>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  MusicPlayerService() {
    _subscriptions.add(
      player.sequenceStateStream.listen((_) => _emitQueue()),
    );
    _subscriptions.add(
      player.currentIndexStream.listen((_) => _notifyStarted()),
    );
    // Start in playlist-loop mode, like the phone's player.
    unawaited(_applyMode(_mode));
  }

  PlayMode get mode => _mode;

  QueueState get queue => _latest;

  Stream<QueueState> get queueStream async* {
    yield _latest;
    yield* _queueController.stream;
  }

  Song? get currentSong => _latest.current;

  // ------------------------------------------------------------ loading

  /// Replaces the queue with [songs] and starts [startIndex].
  Future<void> playSongs(
    List<Song> songs, {
    int startIndex = 0,
    bool shuffle = false,
  }) async {
    final playable = songs
        .where((song) => (song.localAudioPath ?? '').isNotEmpty)
        .toList();

    if (playable.isEmpty) {
      throw Exception('None of these songs has an audio file.');
    }

    var start = 0;

    if (startIndex >= 0 && startIndex < songs.length) {
      final wanted = songs[startIndex].id;
      start = playable.indexWhere((song) => song.id == wanted);
      if (start < 0) start = 0;
    }

    if (shuffle) {
      start = DateTime.now().microsecondsSinceEpoch % playable.length;
    }

    _sequence
      ..clear()
      ..addAll(playable);

    await player.setAudioSources(
      [for (final song in playable) _sourceFor(song)],
      initialIndex: start,
      initialPosition: Duration.zero,
    );

    // Tapping a song while shuffling keeps shuffle on (reshuffled around
    // the tapped song); the Shuffle button turns it on.
    if (shuffle) {
      _mode = PlayMode.shuffle;
    }

    await _applyMode(_mode);
    _emitQueue();

    // play() only completes when playback pauses or stops, so it must not
    // be awaited here (the old code waited, which delayed the UI update
    // until the song was paused).
    unawaited(player.play());
  }

  /// Plays [song] right after the current one.
  Future<void> playNext(Song song) async {
    if (_sequence.isEmpty) {
      await playSongs([song]);
      return;
    }

    final at = (player.currentIndex ?? -1) + 1;
    _sequence.insert(at, song);
    await player.insertAudioSource(at, _sourceFor(song));
  }

  Future<void> addToQueue(Song song) async {
    if (_sequence.isEmpty) {
      await playSongs([song]);
      return;
    }

    _sequence.add(song);
    await player.addAudioSource(_sourceFor(song));
  }

  /// [queueIndex] is a position in [QueueState.songs] (play order).
  Future<void> removeFromQueue(int queueIndex) async {
    final sequenceIndex = _sequenceIndexForQueueIndex(queueIndex);

    if (sequenceIndex == null) {
      return;
    }

    if (_sequence.length == 1) {
      await clearQueue();
      return;
    }

    _sequence.removeAt(sequenceIndex);
    await player.removeAudioSourceAt(sequenceIndex);
  }

  /// Drag-to-reorder in the queue sheet. Only offered when not shuffling,
  /// where play order and sequence order are the same.
  Future<void> moveInQueue(int from, int to) async {
    if (from == to ||
        from < 0 ||
        to < 0 ||
        from >= _sequence.length ||
        to >= _sequence.length) {
      return;
    }

    final song = _sequence.removeAt(from);
    _sequence.insert(to, song);
    await player.moveAudioSource(from, to);
  }

  Future<void> clearQueue() async {
    await player.stop();
    _sequence.clear();
    await player.clearAudioSources();
    _lastStartedId = null;
    _emitQueue();
  }

  /// Used when a song is deleted from the library.
  Future<void> removeSongEverywhere(String songId) async {
    for (var i = _sequence.length - 1; i >= 0; i--) {
      if (_sequence[i].id != songId) continue;

      if (_sequence.length == 1) {
        await clearQueue();
        return;
      }

      _sequence.removeAt(i);
      await player.removeAudioSourceAt(i);
    }
  }

  /// Refreshes song details (e.g. new lyrics) without touching playback.
  void updateSongInQueue(Song song) {
    var changed = false;

    for (var i = 0; i < _sequence.length; i++) {
      if (_sequence[i].id == song.id) {
        _sequence[i] = song;
        changed = true;
      }
    }

    if (changed) _emitQueue();
  }

  // ----------------------------------------------------------- controls

  Future<void> togglePlayPause() async {
    if (player.playing) {
      await player.pause();
      return;
    }

    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero, index: player.currentIndex);
    }

    unawaited(player.play());
  }

  Future<void> seek(Duration position) => player.seek(position);

  /// Plays the song at [queueIndex] in the queue sheet.
  Future<void> jumpTo(int queueIndex) async {
    final sequenceIndex = _sequenceIndexForQueueIndex(queueIndex);

    if (sequenceIndex == null) return;

    await player.seek(Duration.zero, index: sequenceIndex);
    unawaited(player.play());
  }

  /// Next always moves on, even in Single Loop (just_audio's seekToNext
  /// stays on the same song in that mode).
  Future<void> next() => _step(1);

  /// Restarts the song if more than 3 seconds in, otherwise goes back.
  Future<void> previous() async {
    if (player.position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
      return;
    }

    await _step(-1);
  }

  Future<void> _step(int direction) async {
    final order = _playOrder();
    final current = player.currentIndex;

    if (order.isEmpty || current == null) return;

    final position = order.indexOf(current);

    if (position < 0) return;

    // Dart's % is never negative for a positive divisor, so -1 wraps to last.
    final target = order[(position + direction) % order.length];

    await player.seek(Duration.zero, index: target);

    if (!player.playing) {
      unawaited(player.play());
    }
  }

  Future<void> cycleMode() => setMode(_mode.next);

  Future<void> setMode(PlayMode mode) async {
    _mode = mode;
    await _applyMode(mode);
    _emitQueue();
  }

  Future<void> _applyMode(PlayMode mode) async {
    switch (mode) {
      case PlayMode.playlistLoop:
        await player.setShuffleModeEnabled(false);
        await player.setLoopMode(LoopMode.all);
      case PlayMode.singleLoop:
        await player.setShuffleModeEnabled(false);
        await player.setLoopMode(LoopMode.one);
      case PlayMode.shuffle:
        if (_sequence.isNotEmpty) {
          await player.shuffle();
        }
        await player.setShuffleModeEnabled(true);
        await player.setLoopMode(LoopMode.all);
    }
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _queueController.close();
    await player.dispose();
  }

  // ------------------------------------------------------------ helpers

  AudioSource _sourceFor(Song song) {
    final artwork = song.localArtworkPath;

    return AudioSource.file(
      song.localAudioPath!,
      tag: MediaItem(
        id: song.id,
        title: song.title,
        artist: describeArtist?.call(song),
        album: describeAlbum?.call(song),
        duration: song.duration,
        artUri: artwork == null || artwork.isEmpty ? null : Uri.file(artwork),
      ),
    );
  }

  /// Sequence indices in the order they play.
  List<int> _playOrder() {
    final count = _sequence.length;

    if (count == 0) return const [];

    if (player.shuffleModeEnabled) {
      final shuffled = player.shuffleIndices;

      if (shuffled.length == count) {
        return shuffled;
      }
    }

    return List<int>.generate(count, (i) => i);
  }

  int? _sequenceIndexForQueueIndex(int queueIndex) {
    final order = _playOrder();

    if (queueIndex < 0 || queueIndex >= order.length) return null;

    return order[queueIndex];
  }

  void _emitQueue() {
    final order = _playOrder();
    final current = player.currentIndex;

    final songs = [
      for (final i in order)
        if (i < _sequence.length) _sequence[i],
    ];

    _latest = QueueState(
      songs: songs,
      currentIndex: current == null ? -1 : order.indexOf(current),
      mode: _mode,
    );

    if (!_queueController.isClosed) {
      _queueController.add(_latest);
    }
  }

  void _notifyStarted() {
    _emitQueue();

    final song = _latest.current;

    if (song == null || song.id == _lastStartedId) return;

    _lastStartedId = song.id;
    onSongStarted?.call(song);
  }
}
