import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app/app_theme.dart';
import 'features/library/presentation/library_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Notification + lock-screen controls, and playback that keeps going with
  // the screen off. Must run before the first AudioPlayer is created.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.mobile.playback',
    androidNotificationChannelName: 'Music playback',
    androidNotificationOngoing: true,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(
    const ProviderScope(
      child: MyMusicApp(),
    ),
  );
}

class MyMusicApp extends StatelessWidget {
  const MyMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Music',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const LibraryScreen(),
    );
  }
}
