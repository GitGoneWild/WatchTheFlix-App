# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Onboarding flow persistence - onboarding now only shows once on first launch
- Automatic Xtream Codes session restoration on app startup
- EPG-channel linking - Live TV channels now display current and next programs
- `XtreamServiceManager` for centralized repository lifecycle management
- `XtreamRepositoryFactory` for authenticated repository creation
- Comprehensive unit tests for onboarding persistence and service manager
- Documentation for onboarding, Xtream storage, and EPG improvements

### Changed
- `XtreamAuthBloc` registered as singleton for consistent state across app
- App initialization now checks onboarding completion status before routing
- `XtreamLiveRepository` now enriches channels with EPG data automatically
- EPG refresh triggered during Xtream connection setup (non-blocking)

### Fixed
- Onboarding screen no longer appears on every app restart
- Xtream Codes credentials properly restored from storage on app launch
- Live TV, Movies, and Series screens now build correctly after app restart
- EPG data correctly linked to channels with matching EPG channel IDs

### Technical Improvements
- Better error handling for EPG refresh operations
- Extracted hardcoded metadata keys to constants
- Improved code readability with helper methods
- Added `.catchError()` for async EPG refresh operations
- Proper repository lifecycle management tied to authentication state

## [Previous Releases]
See GitHub releases for earlier version history.
