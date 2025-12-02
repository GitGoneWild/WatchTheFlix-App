// EPG Module
// Unified EPG system with support for multiple data sources.
//
// This module provides:
// - [EpgSourceConfig] - Configuration for EPG data sources
// - [EpgSourceType] - Enumeration of supported source types
// - [UrlEpgProvider] - Provider for fetching EPG from URLs
// - [UnifiedEpgRepository] - Source-agnostic EPG repository
// - [UnifiedEpgService] - High-level service for EPG operations
// - [EpgLocalStorage] - Local persistence for EPG data
//
// The module integrates with:
// - Xtream Codes EPG via [EpgRepositoryImpl]
// - URL-based XMLTV EPG sources
// - Local storage for caching
//
// Example usage:
// ```dart
// final service = UnifiedEpgService();
//
// // Configure URL source
// service.configureUrl('https://example.com/epg.xml');
//
// // Or configure Xtream Codes source
// service.configureXtream(profileId, credentials);
//
// // Fetch EPG
// final result = await service.fetchEpg();
// ```

export 'epg_local_storage.dart';
export 'epg_source.dart';
export 'unified_epg_repository.dart';
export 'unified_epg_service.dart';
export 'url_epg_provider.dart';
