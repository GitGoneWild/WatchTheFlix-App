# Onboarding Flow and Xtream Integration Improvements

## Overview
This document describes the changes made to improve onboarding persistence, Xtream Codes storage, and EPG-channel linking in the WatchTheFlix app.

## Changes Made

### 1. Onboarding Persistence

**Problem:** The onboarding screen was showing on every app startup instead of only on first launch.

**Solution:**
- Added `onboardingCompleted` storage key to track completion status
- Modified `WatchTheFlixApp` to check onboarding status during initialization
- Updated `OnboardingScreen` to save completion status when user proceeds
- App now routes to home screen if onboarding is already completed

**Files Modified:**
- `lib/modules/core/storage/storage_service.dart` - Added storage key
- `lib/app.dart` - Added initialization logic to check onboarding status
- `lib/presentation/screens/onboarding/onboarding_screen.dart` - Save completion status

### 2. Xtream Codes Local Storage & Session Restoration

**Problem:** Xtream Codes credentials were saved but not properly restored on app restart, causing Live TV, Movies, and Series screens to fail to build.

**Solution:**
- Created `XtreamServiceManager` to manage Xtream repositories lifecycle
- Created `XtreamRepositoryFactory` to instantiate repositories after authentication
- Updated `XtreamAuthBloc` to initialize service manager on successful authentication
- Registered `XtreamAuthBloc` as singleton for consistent state across app
- Added automatic credential restoration on app startup

**New Files:**
- `lib/modules/xtreamcodes/xtream_service_manager.dart` - Central service manager
- `lib/modules/xtreamcodes/repositories/xtream_repository_factory.dart` - Repository factory

**Files Modified:**
- `lib/core/config/dependency_injection.dart` - Register service manager
- `lib/presentation/blocs/xtream_auth/xtream_auth_bloc.dart` - Initialize service manager
- `lib/presentation/blocs/xtream_connection/xtream_connection_bloc.dart` - Use service manager

### 3. EPG-Channel Linking

**Problem:** EPG data was not linked to channels, so the program guide wasn't displayed with Live TV entries.

**Solution:**
- Updated `XtreamLiveRepository` to accept optional `IXtreamEpgRepository`
- Added `_enrichChannelsWithEpg()` method to fetch and link EPG data to channels
- EPG repository is created via factory after authentication
- EPG refresh is triggered during connection setup (non-blocking)
- Channels are enriched with current/next program info when retrieved

**Files Modified:**
- `lib/modules/xtreamcodes/repositories/xtream_live_repository.dart` - EPG integration
- `lib/modules/xtreamcodes/repositories/xtream_repository_factory.dart` - EPG repository creation

## Architecture

```
App Startup
├── Check Onboarding Status
│   ├── Not Completed → Show Onboarding
│   └── Completed → Try Restore Xtream Session
│       ├── Success → Initialize XtreamServiceManager
│       └── Failure → Continue to Home
│
Xtream Authentication
├── Login Success
│   ├── Save Credentials
│   └── Initialize XtreamServiceManager
│       ├── Create XtreamRepositoryFactory
│       ├── Create EPG Repository
│       ├── Create Live Repository (with EPG)
│       └── Create VOD Repository
│
Channel Loading
├── Fetch Channels from API/Cache
└── Enrich with EPG Data
    ├── Get EPG Channel ID from metadata
    ├── Fetch Current/Next Program
    └── Attach to Channel Entity
```

## Testing

New tests added:
- `test/modules/onboarding_persistence_test.dart` - Onboarding persistence
- `test/modules/xtream_service_manager_test.dart` - Service manager lifecycle

## Usage

### Onboarding
The onboarding flow now persists completion:
```dart
// Mark onboarding complete
final storage = getIt<IStorageService>();
await storage.setBool(StorageKeys.onboardingCompleted, true);
```

### Accessing Xtream Repositories
After authentication, access repositories via service manager:
```dart
final serviceManager = getIt<XtreamServiceManager>();
if (serviceManager.isInitialized) {
  final liveRepo = serviceManager.repositoryFactory.liveRepository;
  final epgRepo = serviceManager.repositoryFactory.epgRepository;
  // Use repositories...
}
```

### EPG Data in Channels
Channels now include EPG information:
```dart
final channels = await liveRepo.getLiveChannels();
for (final channel in channels) {
  if (channel.epgInfo != null) {
    print('Current: ${channel.epgInfo!.currentProgram}');
    print('Next: ${channel.epgInfo!.nextProgram}');
    print('Progress: ${channel.epgInfo!.progress}');
  }
}
```

## Notes

- EPG refresh happens in background during connection setup
- EPG data is cached and automatically refreshed when stale
- Repository lifecycle is tied to authentication state
- All changes follow Clean Architecture and existing code patterns
