import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/repeat_mode.dart';

class PlayerRepeatNotifier extends Notifier<RepeatMode> {
  @override
  RepeatMode build() {
    return RepeatMode.off;
  }

  void cycleMode() {
    switch (state) {
      case RepeatMode.off:
        state = RepeatMode.playlist;
        break;

      case RepeatMode.playlist:
        state = RepeatMode.song;
        break;

      case RepeatMode.song:
        state = RepeatMode.off;
        break;
    }
  }

  void setMode(RepeatMode mode) {
    state = mode;
  }
}

final playerRepeatProvider =
    NotifierProvider<PlayerRepeatNotifier, RepeatMode>(
  PlayerRepeatNotifier.new,
);