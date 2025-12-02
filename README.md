# 📺 WatchTheFlix

> Your Ultimate Cross-Platform IPTV Streaming Application

[![Flutter CI/CD](https://github.com/GitGoneWild/WatchTheFlix-App/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/GitGoneWild/WatchTheFlix-App/actions/workflows/flutter_ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.24.3-blue.svg)](https://flutter.dev)

---

## 🎬 Overview

WatchTheFlix is a modern, feature-rich IPTV streaming application built with Flutter. Watch live TV, movies, and series across all your devices with a beautiful Netflix-inspired interface.

### ✨ Key Features

- 📺 **Live TV Streaming** - Watch your favorite channels in real-time
- 🎬 **Movies & Series** - Browse and stream VOD content
- 📋 **M3U Playlist Support** - Import playlists via URL or file
- 🔍 **Smart Search** - Find content across all categories
- 📱 **Cross-Platform** - Android, iOS, Web, Windows, macOS, Linux
- 🌙 **Dark Theme** - Cinematic Netflix-style dark interface
- ⭐ **Favorites** - Save your favorite channels
- 📺 **EPG Support** - Electronic Program Guide integration
- 🖼️ **Picture-in-Picture** - Watch while multitasking
- 🛡️ **VPN Awareness** - VPN detection and status display
- 📊 **Optional Firebase** - Analytics and push notifications (free tier)

---

## 📸 Screenshots

| Home | Live TV | Player |
|------|---------|--------|
| ![Home](docs/screenshots/home.png) | ![Live TV](docs/screenshots/live_tv.png) | ![Player](docs/screenshots/player.png) |

| Movies | Series | Settings |
|--------|--------|----------|
| ![Movies](docs/screenshots/movies.png) | ![Series](docs/screenshots/series.png) | ![Settings](docs/screenshots/settings.png) |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.24.3 or higher
- Dart SDK 3.2.0 or higher
- Android Studio / VS Code with Flutter extensions
- For iOS: Xcode 15+ (macOS only)
- For desktop: Respective platform SDKs

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/GitGoneWild/WatchTheFlix-App.git
   cd WatchTheFlix-App
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For mobile
   flutter run

   # For web
   flutter run -d chrome

   # For desktop
   flutter run -d windows  # or macos, linux
   ```

### Build for Production

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

---

## 📋 Loading Playlists

### M3U Playlist

1. Open the app and navigate to **Settings** → **Manage Playlists**
2. Enter a name for your playlist
3. Paste the M3U URL (e.g., `http://example.com/playlist.m3u`)
4. Tap **Add Playlist**

---

## 🏗️ Project Structure

```
lib/
├── core/                    # Legacy core functionality
│   ├── config/             # Dependency injection
│   ├── constants/          # App constants
│   ├── errors/             # Exception/failure handling
│   ├── services/           # Core services
│   ├── theme/              # App theming
│   └── utils/              # Utilities & extensions
├── data/                    # Data layer
│   ├── datasources/        # Local & remote data sources
│   ├── models/             # Data models (DTOs)
│   └── repositories/       # Repository implementations
├── domain/                  # Domain layer
│   ├── entities/           # Business entities
│   ├── repositories/       # Repository interfaces
│   └── usecases/           # Use cases
├── features/               # Legacy feature modules
│   └── m3u/                # M3U parser
├── modules/                # 🆕 Refactored modular architecture
│   ├── core/               # Shared infrastructure
│   │   ├── config/         # App configuration & environment
│   │   ├── logging/        # Centralized logging
│   │   ├── models/         # Shared domain models & interfaces
│   │   ├── network/        # HTTP client abstractions
│   │   └── storage/        # Storage abstractions
│   ├── m3u/                # M3U playlist handling
│   │   ├── import/         # File/URL import service
│   │   ├── parsing/        # M3U parser
│   │   └── mapping/        # M3U to domain mappers
│   ├── vpn/                # VPN detection
│   │   ├── detection/      # VPN detector
│   │   └── providers/      # VPN provider interfaces
│   ├── firebase/           # Optional Firebase integration
│   │   ├── analytics/      # Analytics service
│   │   ├── messaging/      # Push notifications
│   │   └── remote_config/  # Remote configuration
│   └── ui/                 # Shared UI components
│       ├── components/     # Reusable widgets
│       ├── shared/         # Shared utilities
│       └── icons/          # App icons
├── presentation/           # Presentation layer
│   ├── blocs/              # BLoC state management
│   ├── routes/             # App routing
│   ├── screens/            # Screen widgets
│   └── widgets/            # Reusable widgets
├── app.dart                # App configuration
└── main.dart               # Entry point
```

---

## 🔧 Architecture

WatchTheFlix follows **Clean Architecture** principles with a clear separation of concerns:

- **Presentation Layer**: Flutter widgets, BLoC state management
- **Domain Layer**: Business logic, entities, use cases
- **Data Layer**: Repositories, data sources, models
- **Modules Layer**: Feature-based modular architecture (see below)

### Modular Architecture

The `lib/modules/` directory contains a refactored, modular architecture:

| Module | Description |
|--------|-------------|
| `core` | Shared infrastructure (config, logging, models, network, storage) |
| `m3u` | M3U playlist import, parsing, and mapping |
| `vpn` | VPN detection and provider integration |
| `firebase` | Optional Firebase services (analytics, messaging, remote config) |
| `ui` | Shared UI components and icons |

### State Management

The app uses **BLoC (Business Logic Component)** pattern with:
- `flutter_bloc` for state management
- `equatable` for value equality
- Clear event/state separation

### Dependency Injection

Dependencies are managed using **GetIt** service locator:
- Lazy singleton registration
- Easy testing with mock replacements

---

## ⚙️ Configuration

### Firebase (Optional)

Firebase is optional and the app will build/run without it. To enable:

1. Set `firebaseEnabled = true` in `lib/modules/core/config/app_config.dart`
2. Add your Firebase configuration files
3. Provide project ID, API key, and app ID

```dart
await AppConfig().initialize(
  firebaseEnabled: true,
  firebaseProjectId: 'your-project-id',
  firebaseApiKey: 'your-api-key',
  firebaseAppId: 'your-app-id',
);
```

### VPN Detection

VPN awareness is enabled by default. Configure in `AppConfig`:

```dart
AppConfig().vpnDetectionEnabled = true;  // or false to disable
```

---

## 📚 Documentation

Detailed documentation is available in the `docs/` folder:

- [Architecture Overview](docs/architecture.md) - Module structure and data flow
- [M3U Parsing](docs/m3u.md) - Parser capabilities and limitations
- [Firebase Setup](docs/firebase.md) - Configuration guide
- [VPN Detection](docs/vpn.md) - How detection works

---

## 🎨 Theming

WatchTheFlix features a Netflix-inspired dark theme:

```dart
// Primary brand color
Color primary = Color(0xFFE50914);

// Background colors
Color background = Color(0xFF0D0D0D);
Color surface = Color(0xFF1E1E1E);

// Text colors
Color textPrimary = Color(0xFFFFFFFF);
Color textSecondary = Color(0xFFB3B3B3);
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/m3u/m3u_parser_test.dart
```

---

## 🚀 CI/CD

The project uses GitHub Actions for continuous integration and deployment. Workflows are configured to run on self-hosted runners (except for Dependabot PRs).

### Workflows

| Workflow | Purpose | Runner |
|----------|---------|--------|
| `flutter_ci.yml` | Build, test, and analyze code | Self-hosted |
| `dependabot_ci.yml` | Validate dependency updates | GitHub-hosted |

### Build Targets

The CI pipeline builds artifacts for all supported platforms:
- **Android** - APK release build
- **iOS** - Release build (no code signing)
- **Web** - Release web build
- **Windows** - Windows release
- **macOS** - macOS release
- **Linux** - Linux release

### Self-Hosted Runner Setup

To set up self-hosted runners for this repository:

1. Navigate to **Settings** → **Actions** → **Runners**
2. Click **New self-hosted runner**
3. Follow the instructions for your platform
4. Ensure runners have labels:
   - Linux runners: default `self-hosted`
   - macOS runners: `self-hosted, macOS`
   - Windows runners: `self-hosted, Windows`

### Coverage

Test coverage reports are uploaded to [Codecov](https://codecov.io) for tracking.

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State management |
| `dio` | HTTP client |
| `video_player` | Video playback |
| `chewie` | Video player controls |
| `cached_network_image` | Image caching |
| `shared_preferences` | Local storage |
| `hive` | NoSQL database |
| `get_it` | Dependency injection |
| `equatable` | Value equality |

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## ❓ FAQ

**Q: What playlist formats are supported?**
A: M3U and M3U8 formats are fully supported.

**Q: Is there a limit on the number of playlists?**
A: No, you can add as many playlists as you need.

**Q: Does the app support EPG?**
A: Yes, EPG data is displayed when provided by your playlist.

**Q: Can I use the app on Smart TVs?**
A: The app works on Android TV. For other smart TVs, use the web version.

**Q: Is my playlist data secure?**
A: All data is stored locally on your device. No data is sent to external servers.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) - Beautiful native apps
- [BLoC Library](https://bloclibrary.dev) - State management
- [Material Design](https://material.io) - Design system

---

<p align="center">
  Made with ❤️ using Flutter
</p>
