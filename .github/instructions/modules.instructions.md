---
applyTo: "lib/modules/xtreamcodes/**/*.dart, lib/modules/m3u/**/*.dart"
---

## XtreamCodes and M3U Module Guidelines
For files in xtreamcodes/ or m3u/ modules:

1. Use dio for HTTP in xtreamcodes (e.g., auth, livetv endpoints).
2. Mappers: Convert API DTOs to domain entities.
3. For Xtream: Handle API endpoints like /player_api.php; support account overview.
4. For M3U: Parse M3U/M3U8 with import from URL/file; map to channels/movies/series.
5. ContentSourceStrategy: Check AppConfig to decide fetch method (direct API or M3U import).
6. EPG: Integrate parsing/display when available.
7. Error handling: Custom XtreamException or M3uParseFailure.
8. Performance: Cache responses with hive where possible.
9. Security: Sanitize URLs/usernames/passwords.
10. Test services/repositories independently.