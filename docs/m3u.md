# M3U Parsing

This document explains the M3U parsing capabilities in WatchTheFlix.

## Overview

The M3U module (`lib/modules/m3u/`) provides functionality for importing, parsing, and mapping M3U/M3U8 playlists.

## Module Structure

```
m3u/
├── import/
│   └── m3u_import_service.dart   # File & URL import
├── parsing/
│   └── m3u_parser.dart           # M3U parser
└── mapping/
    └── m3u_to_domain_mappers.dart # M3U to domain conversion
```

## Supported Tags

The parser recognizes these M3U tags:

| Tag | Description |
|-----|-------------|
| `#EXTM3U` | Playlist header |
| `#EXTINF` | Entry info (name, duration, attributes) |
| `#EXTGRP` | Group override |
| `#EXTVLCOPT` | VLC-specific options (recognized but not parsed) |

## Attributes

The parser extracts these attributes from `#EXTINF` lines:

| Attribute | Description |
|-----------|-------------|
| `tvg-id` | Channel ID for EPG matching |
| `tvg-name` | Alternative channel name |
| `tvg-logo` | Channel logo URL |
| `logo` | Alternative logo attribute |
| `group-title` | Category/group name |
| `channel-id` | Alternative channel ID |

## Usage

### Parsing Content

```dart
final parser = M3uParser();

// Validate content
if (parser.isValid(content)) {
  // Parse entries
  final entries = parser.parse(content);
  
  for (final entry in entries) {
    print('Name: ${entry.name}');
    print('URL: ${entry.url}');
    print('Group: ${entry.groupTitle}');
    print('Logo: ${entry.tvgLogo}');
    print('Type: ${entry.contentType}');
  }
}
```

### Importing from File/URL

```dart
final importService = M3uImportService(
  parser: M3uParser(),
  repository: importRepository,
);

// Import from URL
final result = await importService.importFromUrl('http://example.com/playlist.m3u');

// Import from file
final result = await importService.importFromFile('/path/to/playlist.m3u');

// Import from raw content
final result = importService.importFromContent(content, source: 'manual');

if (result.isSuccess) {
  print('Imported ${result.data.totalParsed} entries');
}
```

### Mapping to Domain Models

```dart
final entries = parser.parse(content);

// Map to channels
final channels = M3uToDomainMappers.mapToChannels(entries);

// Map only live channels
final liveChannels = M3uToDomainMappers.mapLiveChannels(entries);

// Map movies
final movies = M3uToDomainMappers.mapMovies(entries);

// Extract categories
final categories = M3uToDomainMappers.extractCategories(entries);
```

## Content Type Detection

The parser automatically detects content type based on:

1. **Group title keywords**:
   - `movie`, `film` → `movie`
   - `series`, `show` → `series`
   - Everything else → `live`

2. **URL patterns**:
   - `/movie/` → `movie`
   - `/series/` → `series`
   - Everything else → `live`

## M3uEntry Model

```dart
class M3uEntry {
  final String name;
  final String url;
  final String? tvgId;
  final String? tvgName;
  final String? tvgLogo;
  final String? groupTitle;
  final int duration;
  final Map<String, String> attributes;
  
  String get contentType; // 'live', 'movie', or 'series'
}
```

## Example M3U Content

```
#EXTM3U
#EXTINF:-1 tvg-id="espn" tvg-logo="http://logo.com/espn.png" group-title="Sports",ESPN
http://stream.example.com/live/espn.m3u8

#EXTINF:-1 tvg-id="cnn" tvg-logo="http://logo.com/cnn.png" group-title="News",CNN
http://stream.example.com/live/cnn.m3u8

#EXTINF:-1 group-title="Movies",Inception
http://stream.example.com/movie/inception.mp4
```

## Limitations

- **No EPG parsing**: The parser extracts `tvg-id` but does not parse XMLTV EPG data
- **Basic duration**: Duration from `#EXTINF` is extracted but not validated
- **No authentication**: URL credentials must be embedded in the URL
- **UTF-8 assumed**: Content is assumed to be UTF-8 encoded

## Error Handling

Invalid M3U content will:
- Return `false` from `isValid()`
- Return an empty list from `parse()`
- Return `ApiResult.failure()` from import services

Invalid URLs within valid M3U are skipped with a warning logged.

## Extending the Parser

To add support for additional attributes:

1. Update the regex in `_parseExtInf()`
2. Add field to `M3uEntry`
3. Update mapping in `M3uToDomainMappers`

```dart
// Example: Adding custom attribute
final customValue = parsed['custom-attribute'];
```
