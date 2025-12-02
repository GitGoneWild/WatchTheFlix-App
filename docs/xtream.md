# Xtream Codes Integration

This document explains how the Xtream Codes API integration works in WatchTheFlix.

## Overview

The Xtream Codes module (`lib/modules/xtreamcodes/`) provides complete integration with Xtream Codes API servers. The module follows Clean Architecture principles with clear separation between services, repositories, and domain models.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  (BLoCs, Screens, Widgets)                                  │
├─────────────────────────────────────────────────────────────┤
│                   XtreamCodesClient                          │
│  (Unified API for all Xtream operations)                    │
├─────────────────────────────────────────────────────────────┤
│                    Service Layer                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │  Auth    │ │ LiveTV   │ │ Movies   │ │ Series   │ ...   │
│  │ Service  │ │ Service  │ │ Service  │ │ Service  │       │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘       │
├───────┼────────────┼────────────┼────────────┼──────────────┤
│       ▼            ▼            ▼            ▼              │
│                 Repository Layer                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │  Auth    │ │ LiveTV   │ │ Movies   │ │ Series   │       │
│  │Repository│ │Repository│ │Repository│ │Repository│       │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘       │
├───────┼────────────┼────────────┼────────────┼──────────────┤
│       ▼            ▼            ▼            ▼              │
│              XtreamRepositoryBase                            │
│  (URL building, error handling, parsing utilities)          │
├─────────────────────────────────────────────────────────────┤
│                   Network Layer (Dio)                        │
└─────────────────────────────────────────────────────────────┘
```

## Module Structure

```
xtreamcodes/
├── auth/
│   ├── auth.dart                      # Module exports
│   └── xtream_auth_service.dart       # Login & session management
├── account/
│   ├── account.dart                   # Module exports
│   ├── xtream_account_models.dart     # Typed account models
│   └── xtream_account_service.dart    # Account info service
├── livetv/
│   ├── livetv.dart                    # Module exports
│   └── livetv_service.dart            # Live TV channels & categories
├── movies/
│   ├── movies.dart                    # Module exports
│   └── movies_service.dart            # VOD movies
├── series/
│   ├── series.dart                    # Module exports
│   └── series_service.dart            # TV series
├── epg/
│   ├── epg.dart                       # Module exports
│   ├── epg_models.dart                # EPG data models
│   ├── epg_service.dart               # Electronic Program Guide
│   └── xmltv_parser.dart              # XMLTV format parser
├── mappers/
│   ├── mappers.dart                   # Module exports
│   └── xtream_to_domain_mappers.dart  # API to domain conversion
├── repositories/
│   ├── repositories.dart              # Module exports
│   ├── xtream_repository_base.dart    # Shared repository utilities
│   ├── xtream_auth_repository_impl.dart
│   ├── xtream_account_repository_impl.dart
│   ├── livetv_repository_impl.dart
│   ├── movies_repository_impl.dart
│   ├── series_repository_impl.dart
│   └── epg_repository_impl.dart
├── storage/
│   ├── storage.dart                   # Module exports
│   ├── xtream_hive_models.dart        # Hive storage models
│   ├── xtream_hive_models.g.dart      # Generated adapters
│   └── xtream_local_storage.dart      # Local storage service
├── sync/
│   ├── sync.dart                      # Module exports
│   ├── xtream_sync_service.dart       # Sync coordination service
│   └── xtream_data_repository.dart    # Unified data repository
├── xtream_codes_client.dart           # Unified client interface
└── xtreamcodes.dart                   # Main module export
```

## Quick Start

### Using XtreamCodesClient (Recommended)

The easiest way to use the Xtream integration is via `XtreamCodesClient`:

```dart
// Get from DI container
final client = getIt<XtreamCodesClient>();

// Or create directly
final client = XtreamCodesClient();

// Create credentials
final credentials = XtreamCredentialsModel(
  host: 'http://server.com:8080',
  username: 'user',
  password: 'pass',
);

// Authenticate
final loginResult = await client.login(credentials);
if (loginResult.isSuccess && loginResult.data.isAuthenticated) {
  final accountInfo = loginResult.data.accountInfo;
  print('Welcome ${accountInfo!.userInfo.username}');
}

// Fetch content
final channels = await client.getLiveTvChannels(credentials);
final movies = await client.getMovies(credentials);
final series = await client.getSeries(credentials);

// Get stream URLs
final streamUrl = client.getLiveStreamUrl(credentials, streamId);
```

## API Endpoints

The integration supports these Xtream Codes API endpoints:

| Endpoint | Description |
|----------|-------------|
| `player_api.php` | Login & account info |
| `get_live_categories` | Live TV categories |
| `get_live_streams` | Live TV channels |
| `get_vod_categories` | Movie categories |
| `get_vod_streams` | Movies |
| `get_vod_info` | Movie details |
| `get_series_categories` | Series categories |
| `get_series` | Series list |
| `get_series_info` | Series details with episodes |
| `get_short_epg` | Current/next EPG for a channel |

## Account Models

The account module provides strongly typed models:

### XtreamUserInfo
```dart
class XtreamUserInfo {
  final String username;
  final String password;
  final String message;
  final int auth;
  final String status;
  final DateTime? expDate;
  final bool isTrial;
  final int activeConnections;
  final DateTime? createdAt;
  final int maxConnections;
  final List<String> allowedOutputFormats;

  bool get isAuthenticated => auth == 1;
  bool get isActive => status.toLowerCase() == 'active';
  bool get isExpired => expDate != null && DateTime.now().isAfter(expDate!);
  AccountStatus get accountStatus => ...;
}
```

### XtreamServerInfo
```dart
class XtreamServerInfo {
  final String url;
  final String port;
  final String httpsPort;
  final String serverProtocol;
  final String rtmpPort;
  final String timezone;
  final DateTime? timestampNow;
  final String timeNow;
  final bool process;

  String get fullUrl => ...;
  bool get hasHttps => ...;
  bool get hasRtmp => ...;
}
```

### XtreamAccountOverview
Combines `XtreamUserInfo` and `XtreamServerInfo` into a single overview object.

## Authentication Flow

```dart
// Create credentials
final credentials = XtreamCredentialsModel(
  host: 'http://server.com:8080',
  username: 'user',
  password: 'pass',
);

// Authenticate using XtreamCodesClient
final client = XtreamCodesClient();
final result = await client.login(credentials);

result.fold(
  onSuccess: (authResult) {
    if (authResult.isAuthenticated) {
      final accountInfo = authResult.accountInfo!;
      print('Status: ${accountInfo.userInfo.status}');
      print('Expires: ${accountInfo.userInfo.expDate}');
    } else {
      print('Auth failed: ${authResult.error?.message}');
    }
  },
  onFailure: (error) {
    print('Network error: ${error.message}');
  },
);
```

## Fetching Content

### Live TV
```dart
final client = XtreamCodesClient();

// Get categories
final categoriesResult = await client.getLiveTvCategories(credentials);
if (categoriesResult.isSuccess) {
  for (final category in categoriesResult.data) {
    print('${category.name}: ${category.channelCount} channels');
  }
}

// Get channels
final channelsResult = await client.getLiveTvChannels(credentials);

// Get channels for specific category
final filteredResult = await client.getLiveTvChannels(
  credentials,
  categoryId: '5',
);

// Get channels with EPG
final channelsWithEpg = await client.getLiveTvChannelsWithEpg(credentials);
```

### Movies
```dart
final client = XtreamCodesClient();

final categories = await client.getMovieCategories(credentials);
final movies = await client.getMovies(credentials);
final movieDetails = await client.getMovieDetails(credentials, movieId);
```

### Series
```dart
final client = XtreamCodesClient();

final categories = await client.getSeriesCategories(credentials);
final series = await client.getSeries(credentials);
final seriesDetails = await client.getSeriesDetails(credentials, seriesId);

// Access seasons and episodes
for (final season in seriesDetails.data.seasons) {
  print('Season ${season.seasonNumber}');
  for (final episode in season.episodes) {
    print('  - ${episode.name}: ${episode.streamUrl}');
  }
}
```

## Stream URLs

Generate playback URLs:

```dart
final client = XtreamCodesClient();

// Live stream
final liveUrl = client.getLiveStreamUrl(
  credentials,
  streamId,
  format: 'm3u8',  // or 'ts', 'rtmp'
);

// Movie stream
final movieUrl = client.getMovieStreamUrl(
  credentials,
  streamId,
  extension: 'mp4',
);

// Series episode stream
final episodeUrl = client.getSeriesStreamUrl(
  credentials,
  streamId,
  extension: 'mkv',
);
```

## EPG (Electronic Program Guide)

```dart
final client = XtreamCodesClient();

// Get EPG for specific channel
final channelEpg = await client.getChannelEpg(credentials, channelId);
if (channelEpg.isSuccess) {
  for (final entry in channelEpg.data) {
    print('${entry.title}: ${entry.startTime} - ${entry.endTime}');
    if (entry.isCurrentlyAiring) {
      print('  Currently airing! Progress: ${entry.progress * 100}%');
    }
  }
}

// Get current program
final currentProgram = await client.getCurrentProgram(credentials, channelId);

// Get EPG for all channels
final allEpg = await client.getAllEpg(credentials);
```

## Mapping

All API responses are converted to domain models via `XtreamToDomainMappers`:

```dart
// Map channel
final channel = XtreamToDomainMappers.mapChannel(json, streamUrl);

// Map category
final category = XtreamToDomainMappers.mapCategory(json);

// Map movie
final movie = XtreamToDomainMappers.mapMovie(json, streamUrl);

// Map series with episodes
final series = XtreamToDomainMappers.mapSeriesWithEpisodes(
  json,
  (streamId, extension) => buildStreamUrl(streamId, extension),
);

// Map EPG entry
final epgInfo = XtreamToDomainMappers.mapEpgEntry(json);
```

## Error Handling

Authentication errors are typed:

```dart
enum AuthErrorType {
  invalidCredentials,
  serverUnreachable,
  accountExpired,
  accountDisabled,
  networkError,
  unknown,
}
```

All services return `ApiResult<T>` for consistent error handling:

```dart
final result = await client.getLiveTvChannels(credentials);

result.fold(
  onSuccess: (channels) {
    // Handle success
    for (final channel in channels) {
      print(channel.name);
    }
  },
  onFailure: (error) {
    // Handle error
    switch (error.type) {
      case ApiErrorType.network:
        print('Network error: ${error.message}');
        break;
      case ApiErrorType.auth:
        print('Authentication error: ${error.message}');
        break;
      case ApiErrorType.timeout:
        print('Request timed out');
        break;
      default:
        print('Error: ${error.message}');
    }
  },
);
```

## Configuration

### AppConfig Integration

The Xtream module integrates with `AppConfig` for content source strategy:

```dart
// In lib/modules/core/config/app_config.dart
enum ContentSourceStrategy {
  xtreamApiDirect,    // Use Xtream API directly (recommended)
  xtreamM3uImport,    // Import M3U from Xtream server
}

// Check current strategy
final strategy = AppConfig().contentSourceStrategy;
if (strategy == ContentSourceStrategy.xtreamApiDirect) {
  // Use XtreamCodesClient
}
```

### Dependency Injection

The `XtreamCodesClient` is registered as a lazy singleton:

```dart
// In lib/core/config/dependency_injection.dart
getIt.registerLazySingleton<XtreamCodesClient>(
  () => XtreamCodesClient(),
);

// Usage
final client = getIt<XtreamCodesClient>();
```

## Local Storage & Sync

The Xtream module includes a comprehensive local storage system using Hive for offline-tolerant access and efficient data management.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   XtreamDataRepository                       │
│  (Unified access to local + remote data)                    │
├─────────────────────────────────────────────────────────────┤
│     XtreamSyncService          XtreamLocalStorage            │
│  (Sync coordination)       (Hive-based persistence)         │
├─────────────────────────────────────────────────────────────┤
│                    XtreamCodesClient                         │
│  (API access)                                               │
└─────────────────────────────────────────────────────────────┘
```

### Using XtreamDataRepository (Recommended for Apps)

The `XtreamDataRepository` provides a "local first" approach:

```dart
final storage = XtreamLocalStorage();
await storage.initialize();

final client = XtreamCodesClient();
final syncService = XtreamSyncService(
  client: client,
  storage: storage,
);

final repository = XtreamDataRepository(
  client: client,
  storage: storage,
  syncService: syncService,
);

// Initialize
await repository.initialize();

// Check if initial sync is needed
if (repository.needsInitialSync(profileId)) {
  final stats = await repository.syncService.performInitialSync(
    profileId,
    credentials,
  );
  print('Synced ${stats.totalItems} items');
}

// Fetch data (local first, auto-refresh in background)
final channels = await repository.getLiveChannels(profileId, credentials);
final movies = await repository.getMovies(profileId, credentials);
final series = await repository.getSeries(profileId, credentials);
```

### Initial Sync

On first connection to an Xtream server, perform a full sync:

```dart
final syncService = XtreamSyncService(
  client: client,
  storage: storage,
);

// Listen to progress
syncService.progressStream.listen((progress) {
  print('${progress.currentOperation}: ${(progress.progress * 100).toInt()}%');
});

// Perform initial sync
final stats = await syncService.performInitialSync(profileId, credentials);

print('Channels: ${stats.channelsImported}');
print('Categories: ${stats.categoriesImported}');
print('Movies: ${stats.moviesImported}');
print('Series: ${stats.seriesImported}');
print('EPG Programs: ${stats.epgProgramsImported}');
print('Duration: ${stats.duration.inSeconds}s');
```

### Incremental Sync

For subsequent syncs, use TTL-based incremental updates:

```dart
// Check if refresh is needed
if (syncService.needsRefresh(profileId)) {
  await syncService.performIncrementalSync(profileId, credentials);
}

// Force refresh specific content
await syncService.performIncrementalSync(
  profileId,
  credentials,
  forceChannels: true,
  forceMovies: false,
  forceSeries: false,
  forceEpg: true,
);

// Quick refresh for live content
await syncService.refreshLiveContent(profileId, credentials);

// Refresh VOD content
await syncService.refreshVodContent(profileId, credentials);
```

### Sync Configuration

Customize TTL values for different content types:

```dart
const config = SyncConfig(
  channelTtl: Duration(hours: 1),      // Channels refresh every hour
  movieTtl: Duration(hours: 4),        // Movies refresh every 4 hours
  seriesTtl: Duration(hours: 4),       // Series refresh every 4 hours
  epgTtl: Duration(hours: 6),          // EPG refresh every 6 hours
  syncEpgOnInitial: true,              // Include EPG in initial sync
  syncMoviesOnInitial: true,           // Include movies in initial sync
  syncSeriesOnInitial: true,           // Include series in initial sync
);

final syncService = XtreamSyncService(
  client: client,
  storage: storage,
  config: config,
);
```

### Direct Local Storage Access

For advanced use cases, access local storage directly:

```dart
final storage = XtreamLocalStorage();
await storage.initialize();

// Get cached channels
final channels = storage.getChannelsByProfile(profileId);

// Get cached movies by category
final movies = storage.getMovies(profileId, categoryId: 'action');

// Get EPG for a channel
final epg = storage.getEpgForChannel(profileId, channelId);

// Get storage statistics
final stats = storage.getStorageStats(profileId);
print('Channels: ${stats['channels']}');
print('Movies: ${stats['movies']}');
print('EPG Programs: ${stats['epgPrograms']}');

// Clear profile data
await storage.clearProfileData(profileId);
```

### Sync Status Tracking

Monitor sync status for each profile:

```dart
final status = storage.getSyncStatus(profileId);

print('Initial sync complete: ${status?.isInitialSyncComplete}');
print('Last channel sync: ${status?.lastChannelSync}');
print('Last EPG sync: ${status?.lastEpgSync}');
print('Channel count: ${status?.channelCount}');

// Check if specific data needs refresh
final needsChannelRefresh = status?.needsChannelRefresh(Duration(hours: 1)) ?? true;
final needsEpgRefresh = status?.needsEpgRefresh(Duration(hours: 6)) ?? true;
```

## Caching

All repository implementations include built-in caching:

- **Categories/Channels/Movies/Series**: 1 hour cache
- **EPG**: 6 hour cache (EPG data changes more frequently)

To force refresh:

```dart
await client.refreshLiveTv(credentials);
await client.refreshMovies(credentials);
await client.refreshSeries(credentials);
await client.refreshEpg(credentials);

// Or refresh all
await client.refreshAll(credentials);
```

## Testing

Run Xtream module tests:

```bash
flutter test test/modules/xtreamcodes/
```

### Test Files

- `xtream_account_models_test.dart` - Account model parsing
- `xtream_mappers_test.dart` - API to domain mapping
- `xtream_repository_base_test.dart` - Repository utilities
- `xtream_auth_service_test.dart` - Authentication logic
- `epg_service_test.dart` - EPG functionality

## Adding New Endpoints

To add a new Xtream API endpoint:

1. Add the endpoint action in the appropriate repository implementation
2. Create a method in the corresponding service
3. Add mapping in `XtreamToDomainMappers` if needed
4. Expose the method via `XtreamCodesClient`
5. Add unit tests

Example:

```dart
// 1. In repository (e.g., livetv_repository_impl.dart)
Future<ApiResult<SomeData>> fetchNewData(
  XtreamCredentialsModel credentials,
) async {
  final url = buildUrl(credentials, 'new_action');
  final response = await _dio.get<dynamic>(url);
  // ... parse and return
}

// 2. In service (e.g., livetv_service.dart)
Future<ApiResult<SomeData>> getNewData(
  XtreamCredentialsModel credentials,
) {
  return _repository.fetchNewData(credentials);
}

// 3. In XtreamCodesClient
Future<ApiResult<SomeData>> getNewData(
  XtreamCredentialsModel credentials,
) {
  return _liveTvService.getNewData(credentials);
}
```
