# Xtream Codes Integration

This document describes the Xtream Codes IPTV integration in WatchTheFlix.

## Overview

The Xtream Codes integration allows users to connect to their Xtream Codes IPTV panels and access live TV channels, movies (VOD), and series directly from the WatchTheFlix app.

## Key Features

### 1. Authentication
- Secure credential storage using SharedPreferences
- Server URL, username, and password validation
- Automatic credential verification on app startup
- Session management with re-authentication when needed

### 2. Content Access
- **Live TV**: Access to all live channels from the Xtream panel
- **Movies (VOD)**: Browse and watch on-demand movies
- **Series**: Watch TV series with seasons and episodes
- **EPG (Electronic Program Guide)**: View program schedules for live channels

### 3. Smart Caching Strategy
All content is cached locally to minimize API calls and improve performance:

- **Live Channels**: Cached for 24 hours (configurable via `AppConfig.cacheExpiration`)
- **Movies**: Cached for 24 hours
- **Series**: Cached for 24 hours
- **EPG Data**: Cached for 6 hours (configurable via `AppConfig.epgCacheExpiration`)

The caching strategy follows a "cache-first, refresh in background" approach:
1. On first request, data is fetched from the Xtream API
2. Subsequent requests serve cached data immediately
3. Background refresh occurs when cache becomes stale
4. Users can manually trigger a refresh at any time

### 4. EPG (Electronic Program Guide) Strategy

**Single XMLTV Download Approach**

To avoid thousands of per-channel API calls that could lead to IP bans, we implement a smart EPG strategy:

1. **Single Full Download**: Download the complete XMLTV EPG file once per refresh cycle
2. **Smart Parsing**: Parse the XMLTV data using the `xml` package
3. **Time Window Filtering**: Keep only today's and tomorrow's programs to conserve storage
4. **Local Caching**: Store parsed EPG data in SharedPreferences
5. **Efficient Lookup**: Query EPG data by channel ID from local cache
6. **Automatic Refresh**: Refresh EPG when cache is older than 6 hours

**EPG Usage Example**:
```dart
// Get current and next program for a channel
final epgResult = await xtreamEpgRepository.getCurrentAndNextProgram(channelId);

if (epgResult.isSuccess) {
  final programPair = epgResult.data;
  print('Now Playing: ${programPair.current?.title}');
  print('Next: ${programPair.next?.title}');
}
```

## Architecture

The Xtream Codes integration follows Clean Architecture principles:

```
lib/modules/xtreamcodes/
├── account/
│   └── xtream_api_client.dart      # HTTP client for Xtream API
├── auth/
│   ├── xtream_credentials.dart      # Credentials model
│   └── xtream_auth_service.dart     # Auth service for storage
├── epg/
│   ├── epg_models.dart              # EPG domain models
│   ├── xmltv_parser.dart            # XMLTV XML parser
│   └── xtream_epg_repository.dart   # EPG repository with caching
├── mappers/
│   └── xtream_mappers.dart          # API DTOs to domain entities
├── models/
│   └── xtream_api_models.dart       # API response models
└── repositories/
    ├── xtream_live_repository.dart  # Live TV repository
    └── xtream_vod_repository.dart   # VOD/Movies repository
```

## Usage

### 1. Login to Xtream Codes

```dart
// Navigate to Xtream login screen
Navigator.pushNamed(context, '/xtream-login');

// Or use the XtreamAuthBloc directly
context.read<XtreamAuthBloc>().add(
  XtreamAuthLoginRequested(
    serverUrl: 'http://example.com:8080',
    username: 'myusername',
    password: 'mypassword',
  ),
);
```

### 2. Load Live Channels

```dart
// Get Xtream API client from saved credentials
final authService = getIt<IXtreamAuthService>();
final credentialsResult = await authService.loadCredentials();

if (credentialsResult.isSuccess) {
  final credentials = credentialsResult.data;
  final apiClient = XtreamApiClient(credentials: credentials);
  
  // Create repository
  final liveRepository = XtreamLiveRepository(
    apiClient: apiClient,
    storage: getIt<IStorageService>(),
  );
  
  // Get live channels
  final channelsResult = await liveRepository.getLiveChannels();
  
  if (channelsResult.isSuccess) {
    final channels = channelsResult.data;
    // Display channels in UI
  }
}
```

### 3. Access EPG Data

```dart
// Create EPG repository
final epgRepository = XtreamEpgRepository(
  apiClient: apiClient,
  xmltvParser: XmltvParser(),
  storage: getIt<IStorageService>(),
);

// Get EPG for a specific channel and date
final epgResult = await epgRepository.getEpgForChannel(
  channelId,
  day: DateTime.now(),
);

if (epgResult.isSuccess) {
  final programs = epgResult.data;
  // Display EPG in UI
}

// Refresh EPG manually
await epgRepository.refreshEpg(force: true);
```

## Configuration

Configure caching durations in `AppConfig`:

```dart
// In lib/modules/core/config/app_config.dart
AppConfig()
  ..cacheExpiration = const Duration(hours: 24)  // Content cache
  ..epgCacheExpiration = const Duration(hours: 6);  // EPG cache
```

## API Endpoints

The Xtream API client uses the following endpoints:

1. **Authentication**: `GET /player_api.php?username=...&password=...`
2. **Live Categories**: `GET /player_api.php?username=...&password=...&action=get_live_categories`
3. **Live Streams**: `GET /player_api.php?username=...&password=...&action=get_live_streams`
4. **VOD Categories**: `GET /player_api.php?username=...&password=...&action=get_vod_categories`
5. **VOD Streams**: `GET /player_api.php?username=...&password=...&action=get_vod_streams`
6. **Series**: `GET /player_api.php?username=...&password=...&action=get_series`
7. **Series Info**: `GET /player_api.php?username=...&password=...&action=get_series_info&series_id=...`
8. **XMLTV EPG**: `GET /xmltv.php?username=...&password=...`

## Stream URLs

The API client automatically builds stream URLs:

- **Live Stream**: `http://server:port/live/username/password/streamId.ts`
- **VOD Stream**: `http://server:port/movie/username/password/streamId.ext`
- **Series Episode**: `http://server:port/series/username/password/episodeId.ext`

## Error Handling

All operations return `ApiResult<T>` which can be either:

- **Success**: Contains the requested data
- **Failure**: Contains an `ApiError` with type and message

```dart
final result = await liveRepository.getLiveChannels();

if (result.isSuccess) {
  final channels = result.data;
  // Handle success
} else {
  final error = result.error;
  // Handle error: error.type, error.message
}
```

### Common Error Types

- `ApiErrorType.auth`: Authentication failed (invalid credentials)
- `ApiErrorType.network`: Network connection issues
- `ApiErrorType.timeout`: Request timed out
- `ApiErrorType.server`: Server error (5xx responses)
- `ApiErrorType.parse`: Failed to parse API response

## Testing

Example test for Xtream auth service:

```dart
test('should save and load credentials', () async {
  final authService = XtreamAuthService(storage: mockStorage);
  
  final credentials = XtreamCredentials(
    serverUrl: 'http://test.com',
    username: 'user',
    password: 'pass',
  );
  
  await authService.saveCredentials(credentials);
  final result = await authService.loadCredentials();
  
  expect(result.isSuccess, true);
  expect(result.data.username, 'user');
});
```

## Limitations and Best Practices

### API Call Limitations
- **Never** make per-channel EPG API calls - always use the XMLTV endpoint
- Respect cache expiration times to avoid excessive API calls
- Implement exponential backoff for retries on failures

### Storage Considerations
- EPG data is filtered to today + tomorrow only
- Cache metadata includes timestamps for staleness checks
- Old cache data is automatically pruned on refresh

### Performance
- Use lazy loading for large channel/movie lists
- Implement pagination where appropriate in UI
- Cache images using `cached_network_image` package

### Security
- Credentials are stored in SharedPreferences (encrypted on iOS/Android)
- Never log or expose passwords
- Use HTTPS when available for server connections

## Troubleshooting

### Login Fails
- Verify server URL includes protocol (http:// or https://)
- Check if port number is correct
- Ensure username/password are correct
- Check server accessibility (network/firewall)

### EPG Not Loading
- Verify XMLTV endpoint is available on your Xtream server
- Check cache expiration settings
- Try manual refresh with `force: true`
- Verify XMLTV URL format

### Streams Not Playing
- Verify stream URLs are correctly formed
- Check if the container extension is supported by video_player
- Ensure network connectivity
- Check server-side stream availability

## Future Enhancements

Potential improvements for the Xtream integration:

1. **Series Repository**: Complete implementation for series with caching
2. **Catch-up TV**: Support for TV archive/catch-up features
3. **Multi-account Support**: Allow multiple Xtream profiles
4. **Advanced EPG Features**: 
   - Search programs
   - Set reminders
   - Record schedule
5. **Bandwidth Optimization**: Adaptive streaming quality
6. **Offline Mode**: Download content for offline viewing

## References

- Xtream Codes API Documentation: (Contact your IPTV provider)
- XMLTV Format: http://wiki.xmltv.org/index.php/XMLTVFormat
- Flutter BLoC: https://bloclibrary.dev/
- Dio HTTP Client: https://pub.dev/packages/dio
