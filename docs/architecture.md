# Architecture Overview

This document provides a detailed explanation of the WatchTheFlix application architecture.

## Module Structure

The application is organized into cohesive, testable modules under `lib/modules/`:

```
lib/modules/
├── core/           # Shared infrastructure
├── m3u/            # M3U playlist handling
├── vpn/            # VPN detection
├── firebase/       # Optional Firebase integration
└── ui/             # Shared UI components
```

## Core Module

The `core` module provides shared infrastructure used by all feature modules:

### Config (`core/config/`)
- **AppConfig**: Central configuration management
  - Firebase enable/disable
  - Content source strategy
  - VPN detection toggle
  - Cache durations
  - Network timeouts
- **Environment**: Environment-specific settings (dev/staging/prod)

### Logging (`core/logging/`)
- **ModuleLogger**: Centralized logging service
  - Configurable log levels
  - Console output in development
  - Listener system for external integrations (e.g., crash reporting)

### Models (`core/models/`)
- **ApiResult<T>**: Generic result wrapper for success/failure handling
- **Base Models**: Shared domain models (DomainChannel, VodItem, DomainSeries, etc.)
- **Repository Interfaces**: Contracts for data access (IChannelRepository, IVodRepository, etc.)

### Network (`core/network/`)
- **NetworkClient**: HTTP client abstraction
- **NetworkResult**: Response wrapper with error handling
- **Retry utilities**: Exponential backoff retry logic

### Storage (`core/storage/`)
- **IStorageService**: Storage abstraction interface
- **StorageKeys**: Centralized key definitions

## Feature Modules

### M3U Module (`m3u/`)

M3U playlist import and parsing:

```
m3u/
├── import/         # File & URL import service
├── parsing/        # M3U parser
└── mapping/        # M3U to domain mappers
```

### VPN Module (`vpn/`)

VPN detection and status:

```
vpn/
├── detection/      # VPN detector
└── providers/      # Provider interfaces
```

### Firebase Module (`firebase/`)

Optional Firebase integration:

```
firebase/
├── analytics/      # Analytics service
├── messaging/      # Push notifications
├── remote_config/  # Remote configuration
└── firebase_initializer.dart
```

All Firebase services implement interfaces (e.g., `IAnalyticsService`) with no-op implementations available when Firebase is disabled.

### UI Module (`ui/`)

Shared UI components:

```
ui/
├── components/     # AccountOverviewCard, VpnStatusTile
├── shared/         # StatusBadge, LoadingOverlay, etc.
└── icons/          # AppIcons definitions
```

## Data Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   UI Layer  │────▶│   Service   │────▶│ Repository  │
│   (Widgets) │     │   Layer     │     │   Layer     │
└─────────────┘     └─────────────┘     └─────────────┘
                           │                    │
                           ▼                    ▼
                    ┌─────────────┐     ┌─────────────┐
                    │   Mappers   │     │  API/Cache  │
                    └─────────────┘     └─────────────┘
```

1. **UI Layer**: Widgets and BLoCs interact with services
2. **Service Layer**: Business logic, caching decisions
3. **Repository Layer**: Data access abstraction
4. **Mappers**: Convert raw API responses to domain models
5. **API/Cache**: Network calls and local storage

## Dependency Rules

- **Feature modules** depend only on `core`
- **Feature modules** do NOT depend on each other
- **UI code** is NOT allowed in service/repository files
- **Mappers** centralize all type conversions

## Content Source Strategy

## Testing

Each module should have corresponding tests in `test/modules/`:

```
test/
└── modules/
    ├── core/
    ├── m3u/
    ├── vpn/
    └── firebase/
```

Focus on:
- Unit tests for mappers (parsing logic)
- Unit tests for services (business logic)
- Integration tests for repository implementations
