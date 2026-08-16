// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../models/song.dart';
// import 'library_providers.dart';

// final librarySongsProvider =
//     AsyncNotifierProvider<LibrarySongsNotifier, List<Song>>(
//   LibrarySongsNotifier.new,
// );

// class LibrarySongsNotifier extends AsyncNotifier<List<Song>> {
//   @override
//   Future<List<Song>> build() async {
//     final repository = ref.watch(songRepositoryProvider);

//     return repository.getSongs();
//   }

//   Future<void> refreshSongs() async {
//     state = const AsyncLoading();

//     state = await AsyncValue.guard(() async {
//       final repository = ref.read(songRepositoryProvider);

//       return repository.getSongs();
//     });
//   }
// }