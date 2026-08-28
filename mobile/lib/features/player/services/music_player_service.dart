import 'package:just_audio/just_audio.dart';

import '../../library/models/song.dart';

class MusicPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayer get audioPlayer => _audioPlayer;

  Future<void> playSong(Song song) async {
  final audioPath = song.localAudioPath;

  if (audioPath == null || audioPath.isEmpty) {
    throw Exception('Song has no local audio file.');
  }

  await _audioPlayer.setFilePath(audioPath);
  await _audioPlayer.play();
}

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> seek(Duration position) async {
  await _audioPlayer.seek(position);
}

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }

  
}