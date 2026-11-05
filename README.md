# My Music

A cross-platform music app for storing and playing your own audio files, with lyrics display and album artwork. Built with a Flutter mobile app and a FastAPI backend.

> **Status:** In development. The Flutter app supports playback and looping; the FastAPI backend is set up as the foundation for file storage and syncing.

<!-- Add screenshots of the player and library screens and uncomment below -->
<!-- <img src="screenshots/player.png" width="250"> <img src="screenshots/library.png" width="250"> -->

## Features

- Scan a music folder on the phone and play the songs in place (no second copy), or import files into app storage
- Library with Tracks, Albums, Playlists, Artists and Folders tabs, plus sorting and search
- Favorites, Recent (play history) and your own playlists
- Full-screen player with a spinning record, colours taken from the cover art, seek bar, Playlist Loop / Single Loop / Shuffle
- Synced lyrics from .lrc files (auto-matched by file name during a scan, or picked by hand); tap a line to jump to it
- Queue sheet: play next, add to queue, reorder by dragging, remove, clear; History tab
- Background playback with notification and lock-screen controls
- Sleep timer, duplicate-song cleanup

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter, Dart |
| Backend | Python, FastAPI |
| Audio playback | just_audio + just_audio_background |
| State / storage | Riverpod, sqflite |

## Project Structure

```
mobile/          Flutter app (Android, iOS, web, desktop targets)
backend/app/     FastAPI backend
```

## Getting Started

### Prerequisites
- Flutter SDK [version – fill in, e.g. 3.x]
- Python 3.10 or later
- Android Studio or an Android/iOS device or emulator

### Run the mobile app
```bash
git clone https://github.com/Farhan-ShaikhM/my-music.git
cd my-music/mobile
flutter pub get
flutter run
```

### Run the backend
```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```
The API runs at http://localhost:8000, with interactive docs at http://localhost:8000/docs.

## Roadmap

- Upload and store music files through the backend
- Sync library between mobile and web
- Fetch lyrics and album art automatically
- User accounts and authentication
- Web version of the player

## Contributors

- Farhan Shaikh – [GitHub](https://github.com/Farhan-ShaikhM)
- Taha – [GitHub](https://github.com/Taha2804)