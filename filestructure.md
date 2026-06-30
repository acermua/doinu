# Doinu Project Structure

Doinu is a Free and Open Source (FOSS) music application built with Flutter. Below is a detailed breakdown of the project's architecture and file organization.

## 📁 Root Directory

- `lib/`: Contains the core Flutter application code.
- `assets/`: Icons and static images used in the application.
- `android/` & `ios/`: Platform-specific configuration files.
- `pubspec.yaml`: Project dependencies and configuration.
- `analysis_options.yaml`: Linting rules for the project.

## 🏗️ Core Application (`lib/`)

### 🧱 `components/`

Reusable UI widgets and building blocks.

- `generalcards.dart`: Standardized card layouts for songs/albums.
- `shimmers.dart`: Loading state animations.
- `snackbar.dart`: Custom notification overlays.
- `timersheet.dart`: UI for the sleep timer feature.

### 🌐 `l10n/`

Localization and internationalization.

- `translations/`: Dart files containing string mappings for English, Spanish, and Basque.

### 📊 `models/`

Data structures and persistence.

- `database.dart`: Database configuration (likely using drift or similar).
- `datamodel.dart`: Core data models for songs, artists, and playlists.

### 📱 `screens/`

Main application views and feature modules.

- `dashboard.dart`: The main user dashboard.
- `home.dart`: Entry point UI.
- `library.dart`: User's saved music and playlists.
- `search.dart`: Search functionality.
- `features/`: Module-specific screens like `settings.dart`, `profile.dart`, and `about.dart`.
- `views/`: Detailed views for specific entities like `albumviewer.dart` and `artistviewer.dart`.

### ⚙️ `services/`

Business logic and external integrations.

- `audiohandler.dart`: Manages playback via `audio_service` and `just_audio`. Includes volume control, Bluetooth metadata synchronization, internet connectivity watchdog, and progress-bar safeguards.
- `supabase.dart`: Integration with Supabase backend for data syncing.
- `dailyfetcher.dart`: Logic for fetching updated content.
- `localnotification.dart`: Handling system-level audio notifications.
- `sleeptimer.dart`: Logic for the automatic stop feature.

### 🤝 `shared/`

Commonly used states and constants.

- `constants.dart`: Global strings, colors, and static values.
- `player.dart`: Shared state for the music player. Contains Bluetooth device detection logic and the Audio Output Switcher UI.

### 🛠️ `utils/`

Helper functions and configuration.

- `theme.dart`: Centralized AppTheme definition (colors, typography).
- `env.dart`: Environment variable management.
- `format.dart`: Data formatting utilities (e.g., duration to string).

---

## 🚀 Tech Stack

- **Framework**: Flutter
- **State Management**: Flutter Riverpod
- **Audio Session**: Audio Session management for Bluetooth routing and speaker switching.
- **Backend**: Supabase
- **Local Storage**: Hive/Drift (indicated by `.g.dart` files)
- **Navigation**: Material Routing with Page Transitions

```text
doinu
├── README.md
├── analysis_options.yaml
├── android
│   ├── app
│   ├── build.gradle.kts
│   ├── gradle
│   ├── gradle.properties
│   ├── local.properties
│   └── settings.gradle.kts
├── assets
│   └── icons
│       ├── add.png
│       ├── add_to_music.png
│       ├── add_to_queue.png
│       ├── alert.png
│       ├── artist.png
│       ├── atsign.png
│       ├── bell.png
│       ├── case.png
│       ├── clean.png
│       ├── complete_download.png
│       ├── data.png
│       ├── disc.png
│       ├── doinu.png
│       ├── doinudark.png
│       ├── doinulight.png
│       ├── doinuwhite.png
│       ├── download.png
│       ├── down_arrow.png
│       ├── equalizer.png
│       ├── github.png
│       ├── heart.png
│       ├── info.png
│       ├── insta.png
│       ├── last_album.png
│       ├── last_played.png
│       ├── like.png
│       ├── linkedin.png
│       ├── medium.png
│       ├── menu.png
│       ├── player.gif
│       ├── playlist.png
│       ├── queue.png
│       ├── radio.png
│       ├── repeat.png
│       ├── search.png
│       ├── share.png
│       ├── shuffle.png
│       ├── song.png
│       ├── sound.png
│       ├── spotify_share.png
│       ├── tick.png
│       └── timer.png
├── devtools_options.yaml
├── filestructure.md
├── ios
│   ├── Flutter
│   ├── Podfile
│   ├── Podfile.lock
│   ├── Runner
│   ├── Runner.xcodeproj
│   ├── Runner.xcworkspace
│   └── RunnerTests
├── lib
│   ├── components
│   │   ├── generalcards.dart
│   │   ├── shimmers.dart
│   │   ├── showmenu.dart
│   │   ├── snackbar.dart
│   │   └── timersheet.dart
│   ├── l10n
│   │   ├── app_localizations.dart
│   │   └── translations
│   │       ├── en.dart
│   │       ├── es.dart
│   │       ├── eu.dart
│   │       └── translations.dart
│   ├── main.dart
│   ├── models
│   │   ├── database.dart
│   │   ├── database.g.dart
│   │   └── datamodel.dart
│   ├── screens
│   │   ├── dashboard.dart
│   │   ├── features
│   │   │   ├── about.dart
│   │   │   ├── drawer.dart
│   │   │   ├── language_selection.dart
│   │   │   ├── profile.dart
│   │   │   ├── queuesheet.dart
│   │   │   ├── settings.dart
│   │   │   └── soundcapsule.dart
│   │   ├── home.dart
│   │   ├── library.dart
│   │   ├── search.dart
│   │   └── views
│   │       ├── albumviewer.dart
│   │       ├── artistviewer.dart
│   │       ├── playlistviewer.dart
│   │       └── songsviewer.dart
│   ├── services
│   │   ├── audiohandler.dart
│   │   ├── audiohandler.g.dart
│   │   ├── dailyfetcher.dart
│   │   ├── defaultfetcher.dart
│   │   ├── language_provider.dart
│   │   ├── language_provider.g.dart
│   │   ├── localnotification.dart
│   │   ├── offlinemanager.dart
│   │   ├── shufflemanager.dart
│   │   ├── sleeptimer.dart
│   │   ├── sleeptimer.g.dart
│   │   ├── supabase.dart
│   │   ├── supabase.g.dart
│   │   └── systemconfig.dart
│   ├── shared
│   │   ├── constants.dart
│   │   ├── likedsong.dart
│   │   ├── likedsong.g.dart
│   │   ├── player.dart
│   │   └── player.g.dart
│   └── utils
│       ├── env.dart
│       ├── env.g.dart
│       ├── format.dart
│       ├── share_image.dart
│       └── theme.dart
├── pubspec.lock
├── pubspec.yaml
└── test
    └── widget_test.dart
```
