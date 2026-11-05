import 'package:path/path.dart' as p;

import 'album.dart';
import 'artist.dart';
import 'song.dart';

enum SongSort {
  title('Title'),
  dateAdded('Date added'),
  artist('Artist'),
  duration('Duration');

  final String label;

  const SongSort(this.label);
}

/// A named group of songs (an album, an artist or a folder).
class SongGroup {
  final String id;
  final String name;
  final String? artworkPath;
  final List<Song> songs;

  const SongGroup({
    required this.id,
    required this.name,
    required this.songs,
    this.artworkPath,
  });
}

/// The whole library loaded once, with lookup maps. Every list in the UI
/// reads from this, so 300+ rows don't each run their own database queries.
class LibraryIndex {
  static const unknownArtist = 'Unknown Artist';
  static const unknownAlbum = 'Unknown Album';

  final List<Song> songs;
  final Map<String, Song> songsById;
  final Map<String, Artist> artistsById;
  final Map<String, Album> albumsById;
  final Map<String, List<String>> artistIdsBySong;

  LibraryIndex({
    required this.songs,
    required List<Artist> artists,
    required List<Album> albums,
    required this.artistIdsBySong,
  })  : songsById = {for (final song in songs) song.id: song},
        artistsById = {for (final artist in artists) artist.id: artist},
        albumsById = {for (final album in albums) album.id: album};

  List<Artist> artistsFor(Song song) {
    final ids = artistIdsBySong[song.id] ??
        (song.artistId == null ? const <String>[] : [song.artistId!]);

    return [
      for (final id in ids)
        if (artistsById[id] != null) artistsById[id]!,
    ];
  }

  String artistLabel(Song song) {
    final artists = artistsFor(song);

    if (artists.isEmpty) {
      return unknownArtist;
    }

    return artists.map((artist) => artist.name).join(', ');
  }

  String albumLabel(Song song) {
    return albumsById[song.albumId]?.title ?? unknownAlbum;
  }

  /// "Artist - Album", as shown under each track.
  String subtitle(Song song) => '${artistLabel(song)} - ${albumLabel(song)}';

  /// Looks ids up in order, skipping any song that no longer exists.
  List<Song> songsFromIds(Iterable<String> ids) {
    return [
      for (final id in ids)
        if (songsById[id] != null) songsById[id]!,
    ];
  }

  List<Song> sorted(SongSort sort) {
    final list = List<Song>.from(songs);

    switch (sort) {
      case SongSort.title:
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case SongSort.dateAdded:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SongSort.artist:
        list.sort(
          (a, b) => artistLabel(a)
              .toLowerCase()
              .compareTo(artistLabel(b).toLowerCase()),
        );
      case SongSort.duration:
        list.sort((a, b) => (a.durationMs ?? 0).compareTo(b.durationMs ?? 0));
    }

    return list;
  }

  List<SongGroup> albumGroups() {
    final groups = <String, List<Song>>{};

    for (final song in songs) {
      final key =
          albumsById.containsKey(song.albumId) ? song.albumId! : '_unknown';
      groups.putIfAbsent(key, () => []).add(song);
    }

    final result = [
      for (final entry in groups.entries)
        SongGroup(
          id: entry.key,
          name: albumsById[entry.key]?.title ?? unknownAlbum,
          songs: _byTrackNumber(entry.value),
          artworkPath: _firstArtwork(entry.value),
        ),
    ];

    result.sort(_biggestFirst);
    return result;
  }

  List<SongGroup> artistGroups() {
    final groups = <String, List<Song>>{};

    for (final song in songs) {
      final artists = artistsFor(song);

      if (artists.isEmpty) {
        groups.putIfAbsent('_unknown', () => []).add(song);
        continue;
      }

      for (final artist in artists) {
        groups.putIfAbsent(artist.id, () => []).add(song);
      }
    }

    final result = [
      for (final entry in groups.entries)
        SongGroup(
          id: entry.key,
          name: artistsById[entry.key]?.name ?? unknownArtist,
          songs: entry.value,
          artworkPath: _firstArtwork(entry.value),
        ),
    ];

    result.sort(_biggestFirst);
    return result;
  }

  /// Folder scans keep the original folder; picker imports are grouped as
  /// "Imported" because Android only hands the app a temporary copy.
  List<SongGroup> folderGroups() {
    final groups = <String, List<Song>>{};

    for (final song in songs) {
      final source = song.sourcePath;
      final key = source == null || source.isEmpty
          ? '_imported'
          : p.dirname(source);
      groups.putIfAbsent(key, () => []).add(song);
    }

    final result = [
      for (final entry in groups.entries)
        SongGroup(
          id: entry.key,
          name: entry.key == '_imported' ? 'Imported' : p.basename(entry.key),
          songs: entry.value,
          artworkPath: _firstArtwork(entry.value),
        ),
    ];

    result.sort(_biggestFirst);
    return result;
  }

  List<Song> search(String query) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      return const [];
    }

    return songs.where((song) {
      return song.title.toLowerCase().contains(q) ||
          artistLabel(song).toLowerCase().contains(q) ||
          albumLabel(song).toLowerCase().contains(q);
    }).toList();
  }

  static int _biggestFirst(SongGroup a, SongGroup b) {
    final bySize = b.songs.length.compareTo(a.songs.length);

    if (bySize != 0) {
      return bySize;
    }

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  static List<Song> _byTrackNumber(List<Song> songs) {
    return List<Song>.from(songs)
      ..sort((a, b) {
        final disc = (a.discNumber ?? 0).compareTo(b.discNumber ?? 0);

        if (disc != 0) {
          return disc;
        }

        final track = (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0);

        if (track != 0) {
          return track;
        }

        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
  }

  static String? _firstArtwork(List<Song> songs) {
    for (final song in songs) {
      final path = song.localArtworkPath;

      if (path != null && path.isNotEmpty) {
        return path;
      }
    }

    return null;
  }
}
