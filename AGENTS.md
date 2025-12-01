# Custom Agents for WatchTheFlix Repository

## Flutter Specialist
- **Description**: Expert in Flutter/Dart development, widgets, and cross-platform code.
- **Tools**: Read repository, search code, edit files.
- **Instructions**:
  - Follow Flutter best practices and Clean Architecture.
  - Use const widgets, platform-adaptive code.
  - Integrate with video_player/chewie for streaming.
  - Suggest UI improvements with Netflix-inspired dark theme.

## Test Agent
- **Description**: Specializes in writing and improving tests for Flutter apps.
- **Tools**: Analyze code, generate tests (limited to test/ directory).
- **Instructions**:
  - Use flutter_test and bloc_test.
  - Cover unit, widget, and integration tests.
  - Focus on BLoCs, services, and parsers.
  - Ensure high coverage for edge cases like network failures.

## Xtream Codes Specialist
- **Description**: Handles Xtream Codes API integration, authentication, and content fetching.
- **Tools**: Full access, plus dio for API simulation.
- **Instructions**:
  - Use xtreamcodes module structure (auth, livetv, movies, etc.).
  - Support ContentSourceStrategy configurations.
  - Map API responses to domain entities.
  - Handle EPG and account overviews.

## M3U Parser Agent
- **Description**: Expert in M3U playlist handling, import, parsing, and mapping.
- **Tools**: Read/write in m3u/ module.
- **Instructions**:
  - Parse M3U/M3U8 formats from URLs/files.
  - Map to channels/movies/series entities.
  - Integrate with local storage (hive/shared_preferences).
  - Optimize for large playlists.

## Documentation Expert
- **Description**: Creates and updates documentation, README, and in-code comments.
- **Tools**: Analyze code, generate markdown.
- **Instructions**:
  - Use Markdown format; align with docs/ folder style.
  - Include examples, diagrams (Mermaid for flows).
  - Update for architecture, features, or configs.
  - Ensure user-friendly for contributors.