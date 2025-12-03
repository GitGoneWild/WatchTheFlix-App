# Player & Import Workflows

This document describes the modern workflows for IPTV import and video playback in WatchTheFlix.

## Smart Xtream Import

### Overview
The Xtream Codes import process has been optimized for large-scale IPTV content (40k+ channels, 100k+ movies, etc.) with parallel loading and background processing.

### Import Flow

1. **Authentication** (Quick)
   - Validates credentials format
   - Tests connection to server
   - Authenticates with Xtream API
   - Saves credentials locally

2. **Content Loading** (Parallel)
   - **Channels**, **Movies**, and **Series** are fetched simultaneously
   - Each content type loads independently
   - Progress is shown in real-time
   - Data is cached as it arrives

3. **EPG Processing** (Background)
   - EPG (Electronic Program Guide) starts loading in the background
   - Does NOT block navigation to home screen
   - Updates continue even while user watches content
   - Graceful failure handling (EPG is optional)

4. **Ready to Watch**
   - User can navigate to home screen once content is loaded
   - No need to wait for EPG completion
   - Content is immediately accessible

### Performance Benefits

| Aspect | Old Approach | New Approach | Improvement |
|--------|--------------|--------------|-------------|
| Channel Loading | Sequential | Parallel | 3x faster |
| Movies Loading | Blocking | Parallel | 3x faster |
| Series Loading | Blocking | Parallel | 3x faster |
| EPG Loading | Blocking | Background | Non-blocking |
| Time to First Content | ~30-60s | ~10-20s | 50-66% faster |

### Error Handling

- **Network Errors**: Automatic retry with exponential backoff
- **Auth Errors**: Clear error messages with guidance
- **Partial Failures**: If one content type fails, others continue
- **EPG Failures**: Gracefully degraded (EPG is optional)

### Fun UX Touch

During content loading (channels, movies, series), a playful "You wouldn't steal a channel..." meme is displayed, referencing the classic anti-piracy campaign. This adds humor to the wait time and makes the import process more enjoyable.

---

## Modern Video Player

### Architecture

The video player is built as a modular, reusable component with three content modes:

```dart
enum PlayerContentType {
  liveTV,   // Live TV streams
  movie,    // On-demand movies
  series,   // TV series episodes
}
```

### Player Configuration

```dart
PlayerConfig(
  contentType: PlayerContentType.liveTV,
  autoPlay: true,
  autoRetry: true,
  maxRetries: 3,
  allowPip: true,
  showControls: true,
  enableGestures: true,
  retryDelay: Duration(seconds: 2),
)
```

### Features by Content Type

#### Live TV
- No seeking (live stream)
- Channel info display
- EPG overlay on demand
- Fast channel switching

#### Movies
- Full seeking support
- Progress bar
- Resume playback
- Time remaining display

#### Series
- Episode navigation
- Continue watching
- Next episode suggestions
- Season/episode info

### Gesture Controls

| Gesture | Action | Notes |
|---------|--------|-------|
| Single Tap | Toggle Controls | Shows/hides control overlay |
| Double Tap (Left) | Seek -10s | VOD only |
| Double Tap (Center) | Play/Pause | All content types |
| Double Tap (Right) | Seek +10s | VOD only |

### Control Behavior

- Controls automatically show on player initialization
- Auto-hide after 5 seconds during playback
- Animated fade in/out transitions
- Always-visible back button when controls are hidden

### Error Handling & Buffering

1. **Automatic Retry**
   - Retries up to 3 times by default
   - Exponential backoff (2s, 4s, 8s)
   - Shows retry count to user

2. **Buffering States**
   - Loading indicator before initialization
   - Buffering indicator during playback
   - Clear error messages on failure

3. **Error Messages**
   - Network errors
   - Stream unavailable
   - Server errors
   - Authentication errors

### Cross-Platform Support

| Platform | Support Level | Notes |
|----------|---------------|-------|
| Android | Full | Native performance |
| iOS | Full | Native performance |
| Web | Full | HTML5 video |
| Windows | Full | FFmpeg backend |
| macOS | Full | Native frameworks |
| Linux | Full | FFmpeg backend |

### Integration Example

```dart
ModernVideoPlayer(
  url: 'http://example.com/stream.m3u8',
  title: 'Channel Name',
  config: PlayerConfig(
    contentType: PlayerContentType.liveTV,
    autoPlay: true,
  ),
  onBack: () => Navigator.pop(context),
  onError: (error) => print('Player error: $error'),
)
```

---

## Help System Integration

### Access Points

1. **Settings Screen**
   - Help & Support menu item
   - Direct navigation to help topics

2. **First Launch**
   - Optional onboarding flow
   - Links to help screens

3. **Error States**
   - Troubleshooting links in error messages

### Help Topics

| Topic | Content |
|-------|---------|
| Adding Xtream Codes | Step-by-step guide with credentials info |
| Adding M3U Playlists | URL and file import instructions |
| Updating Playlists | Refresh and update procedures |
| Refreshing EPG | Manual and automatic EPG updates |
| Managing Favorites | Add, view, remove favorites |
| Player Controls | Gesture guide and feature list |
| Troubleshooting | Common issues and solutions |

### Help Screen Design

- Clean, scannable layout
- Numbered steps for processes
- Visual icons for topics
- Tip boxes for important info
- Problem-solution format for troubleshooting

---

## Performance Considerations

### Memory Management

- Content loaded in batches
- Cached data purged when stale
- Progressive loading for large catalogs
- Lazy initialization of repositories

### Network Optimization

- Parallel requests for independent data
- Connection pooling and reuse
- Timeout handling (30s default)
- Retry with exponential backoff

### Caching Strategy

| Content Type | Cache Duration | Update Strategy |
|--------------|----------------|-----------------|
| Channels | 24 hours | Background refresh |
| Movies | 24 hours | Background refresh |
| Series | 24 hours | Background refresh |
| EPG | 6 hours | Background refresh |

### UI Performance

- Virtualized lists for large datasets (100k+ items)
- Lazy loading of images
- Throttled search queries
- Debounced user inputs

---

## Testing Guidelines

### Import Testing

1. **Small Playlists** (< 1000 items)
   - Should complete in < 5 seconds
   - All content types load

2. **Medium Playlists** (1k - 10k items)
   - Should complete in < 15 seconds
   - Progress updates visible

3. **Large Playlists** (10k - 100k+ items)
   - Should complete in < 60 seconds
   - Parallel loading observable
   - EPG continues in background

### Player Testing

1. **Live TV Streams**
   - Test HLS, RTMP, UDP streams
   - Verify no seeking available
   - Check channel switching

2. **VOD Content**
   - Test MP4, MKV, AVI formats
   - Verify seeking works
   - Check resume functionality

3. **Error Scenarios**
   - Invalid URLs
   - Network disconnection
   - Expired credentials
   - Corrupted streams

### Help System Testing

- Navigate all help topics
- Verify all steps are clear
- Test deep linking from errors
- Check formatting and layout

---

## Future Enhancements

### Planned Features

1. **Adaptive Streaming**
   - Automatic quality adjustment
   - Bandwidth detection
   - Manual quality selection

2. **Advanced Subtitles**
   - Multiple subtitle tracks
   - Custom styling
   - Subtitle search

3. **Multi-Audio**
   - Audio track selection
   - Language preferences
   - Dual audio support

4. **Enhanced PiP**
   - Native PiP on all platforms
   - Resizable PiP window
   - Mini player mode

5. **Chromecast Support**
   - Cast to TV
   - Remote control from phone
   - Queue management

---

## Troubleshooting

### Import Issues

**Problem**: Import takes too long
- **Solution**: Check internet speed (5+ Mbps recommended)
- **Solution**: Try during off-peak hours
- **Solution**: Contact provider for server status

**Problem**: EPG not loading
- **Solution**: Wait for background loading to complete
- **Solution**: Check if provider includes EPG data
- **Solution**: Manually refresh EPG from settings

### Playback Issues

**Problem**: Video won't play
- **Solution**: Check internet connection
- **Solution**: Verify subscription is active
- **Solution**: Try different channel/movie
- **Solution**: Update playlist

**Problem**: Frequent buffering
- **Solution**: Improve internet speed
- **Solution**: Use WiFi instead of mobile data
- **Solution**: Close other bandwidth-heavy apps
- **Solution**: Contact provider about server load

---

## Support

For additional help:
- Check in-app Help & Support
- Review README.md in the repository
- Check GitHub Issues for known problems
- Contact your IPTV provider for service-specific issues
