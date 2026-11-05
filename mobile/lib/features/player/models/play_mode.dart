import 'package:flutter/material.dart';

/// The three modes the mode button cycles through.
enum PlayMode {
  playlistLoop('Playlist Loop', Icons.repeat_rounded),
  singleLoop('Single Loop', Icons.repeat_one_rounded),
  shuffle('Shuffle', Icons.shuffle_rounded);

  final String label;
  final IconData icon;

  const PlayMode(this.label, this.icon);

  PlayMode get next => PlayMode.values[(index + 1) % PlayMode.values.length];
}
