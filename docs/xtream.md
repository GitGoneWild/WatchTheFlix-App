# Xtream Codes Integration

This document explains how the Xtream Codes API integration works in WatchTheFlix.

## Overview

The Xtream Codes module (`lib/modules/xtreamcodes/`) provides complete integration with Xtream Codes API servers.

## Module Structure

```
xtreamcodes/
├── auth/
│   └── xtream_auth_service.dart    # Login & session management
├── account/
│   ├── xtream_account_models.dart  # Typed account models
│   └── xtream_account_service.dart # Account info service
├── livetv/
│   └── livetv_service.dart         # Live TV channels & categories
├── movies/
│   └── movies_service.dart         # VOD movies
├── series/
│   └── series_service.dart         # TV series
├── epg/
│   └── epg_service.dart            # Electronic Program Guide
├── mappers/
│   └── xtream_to_domain_mappers.dart # API to domain conversion
└── repositories/
    └── xtream_repository_base.dart   # Shared repository utilities
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
| `get_series_categories` | Series categories |
| `get_series` | Series list |
| `get_series_info` | Series details with episodes |
| `get_short_epg` | Current/next EPG for a channel |
| `get_simple_data_table` | Full EPG data |

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

// Authenticate
final authService = XtreamAuthService(repository: repository);
final result = await authService.login(credentials);

if (result.isSuccess && result.data.isAuthenticated) {
  // Login successful
  final accountInfo = result.data.accountInfo;
}
```

## Fetching Content

### Live TV
```dart
final liveTvService = LiveTvService(repository: repository);

// Get categories
final categories = await liveTvService.getCategories(credentials);

// Get channels
final channels = await liveTvService.getChannels(credentials);

// Get channels with EPG
final channelsWithEpg = await liveTvService.getChannelsWithEpg(credentials);
```

### Movies
```dart
final moviesService = MoviesService(repository: repository);

final categories = await moviesService.getCategories(credentials);
final movies = await moviesService.getMovies(credentials);
final movieDetails = await moviesService.getMovieDetails(credentials, movieId);
```

### Series
```dart
final seriesService = SeriesService(repository: repository);

final categories = await seriesService.getCategories(credentials);
final series = await seriesService.getSeries(credentials);
final seriesDetails = await seriesService.getSeriesDetails(credentials, seriesId);
```

## Stream URLs

Generate playback URLs:

```dart
// Live stream
final liveUrl = liveTvService.getStreamUrl(
  credentials,
  streamId,
  format: 'm3u8',  // or 'ts', 'rtmp'
);

// Movie stream
final movieUrl = moviesService.getStreamUrl(
  credentials,
  streamId,
  extension: 'mp4',
);

// Series episode stream
final episodeUrl = seriesService.getStreamUrl(
  credentials,
  streamId,
  extension: 'mkv',
);
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
  buildStreamUrl,
);
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
final result = await service.getChannels(credentials);

result.fold(
  onSuccess: (channels) => // Handle success,
  onFailure: (error) => // Handle error,
);
```

## Adding New Endpoints

To add a new Xtream API endpoint:

1. Add the endpoint action to `XtreamRepositoryBase.buildUrl()`
2. Create a method in the appropriate service
3. Add mapping in `XtreamToDomainMappers`
4. Add corresponding domain model if needed

Example:
```dart
// In repository
Future<ApiResult<List<SomeModel>>> fetchNewData(
  XtreamCredentialsModel credentials,
) async {
  final url = buildUrl(credentials, 'new_action');
  // ... fetch and map
}
```
