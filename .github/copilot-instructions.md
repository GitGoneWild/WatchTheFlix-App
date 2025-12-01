# WatchTheFlix Copilot Instructions

This is a Flutter-based IPTV streaming application called WatchTheFlix. It supports live TV, movies, series, M3U playlists, Xtream Codes API, smart search, cross-platform deployment (Android, iOS, Web, Windows, macOS, Linux), dark theme, favorites, EPG, Picture-in-Picture, VPN awareness, and optional Firebase integration. The app follows Clean Architecture with modular design, BLoC for state management, and GetIt for dependency injection.

## Project Overview
- Core functionality: Streaming live TV, VOD (movies/series), playlist management (M3U/Xtream), EPG display, VPN detection, and optional analytics/notifications.
- Tech stack: Flutter 3.24.3+, Dart 3.2.0+, Dependencies include flutter_bloc, dio, video_player, chewie, cached_network_image, shared_preferences, hive, get_it, equatable.
- Key enums/configs: ContentSourceStrategy (xtreamApiDirect or xtreamM3uImport), vpnDetectionEnabled, firebaseEnabled.

## Code Standards
- Follow Flutter and Dart best practices: Use null safety, async/await for futures, and immutable data where possible.
- Adhere to Clean Architecture: Separate presentation (widgets/BLoCs), domain (entities/use cases), data (repositories/models), and modules (feature-specific).
- Use BLoC pattern: Events and states with equatable for equality checks; clear event/state separation.
- Dependency injection: Register services as lazy singletons via GetIt.
- Naming: CamelCase for classes, snake_case for files/variables; descriptive names (e.g., XtreamAuthService).
- Error handling: Use custom exceptions/failures from core/errors/.
- Theming: Netflix-inspired dark theme with specific colors (primary: 0xFFE50914, background: 0xFF0D0D0D, etc.).
- Testing: Write unit/integration tests with flutter_test; aim for high coverage.
- Avoid: Mutable globals, direct HTTP calls outside dio, unhandled futures.

## Development Flow
- Install dependencies: flutter pub get
- Build: flutter build apk --release (Android), flutter build ios --release (iOS), flutter build web --release (Web), etc.
- Test: flutter test --coverage
- Lint: Use dart analyze and flutter format .
- Run: flutter run (mobile), flutter run -d chrome (web), flutter run -d windows (desktop).
- Configure: Edit lib/modules/core/config/app_config.dart for firebaseEnabled, vpnDetectionEnabled, contentSourceStrategy.
- For Firebase: Set firebaseEnabled = true and provide project ID, API key, app ID in AppConfig.initialize().
- CI/CD: Uses GitHub Actions (flutter_ci.yml) for builds/tests.

## Repository Structure
- lib/core/: Legacy core (config, constants, errors, services, theme, utils).
- lib/data/: Data layer (datasources, models, repositories).
- lib/domain/: Domain layer (entities, repositories, usecases).
- lib/features/: Legacy features (m3u parser, xtream API client).
- lib/modules/: Modular architecture (core: config/logging/models/network/storage; xtreamcodes: auth/account/livetv/movies/series/epg/mappers/repositories; m3u: import/parsing/mapping; vpn: detection/providers; firebase: analytics/messaging/remote_config; ui: components/shared/icons).
- lib/presentation/: Presentation (blocs, routes, screens, widgets).
- lib/app.dart: App configuration.
- lib/main.dart: Entry point.
- test/: All tests.
- docs/: Documentation (architecture.md, xtream.md, etc.).
- assets/: Images, icons.

## Key Guidelines
1. Ensure cross-platform compatibility: Use platform-specific checks where needed (e.g., for desktop vs. mobile).
2. For streaming: Use video_player/chewie for playback; handle EPG with provider data.
3. Security: Store playlists locally (shared_preferences/hive); no external data transmission.
4. Performance: Cache images with cached_network_image; use lazy loading for lists.
5. Updates: Suggest changes to README.md or docs/ for new features.
6. When generating code: Include imports, follow BLoC patterns, and add tests if applicable.