import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerShuffleNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setEnabled(bool enabled) {
    state = enabled;
  }

  void toggle() {
    state = !state;
  }
}

final playerShuffleProvider =
    NotifierProvider<PlayerShuffleNotifier, bool>(
  PlayerShuffleNotifier.new,
);