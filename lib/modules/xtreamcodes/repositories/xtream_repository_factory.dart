// Xtream Repository Factory
// Factory for creating Xtream repositories with authenticated API client.

import '../../core/storage/storage_service.dart';
import '../account/xtream_api_client.dart';
import '../auth/xtream_credentials.dart';
import '../epg/xmltv_parser.dart';
import '../epg/xtream_epg_repository.dart';
import 'xtream_live_repository.dart';
import 'xtream_vod_repository.dart';

/// Factory for creating Xtream repositories
class XtreamRepositoryFactory {
  XtreamRepositoryFactory({
    required XtreamCredentials credentials,
    required IStorageService storage,
    required IXmltvParser xmltvParser,
  })  : _credentials = credentials,
        _storage = storage,
        _xmltvParser = xmltvParser {
    _apiClient = XtreamApiClient(credentials: credentials);
  }

  final XtreamCredentials _credentials;
  final IStorageService _storage;
  final IXmltvParser _xmltvParser;
  late final XtreamApiClient _apiClient;

  // Lazy-initialized repositories
  IXtreamEpgRepository? _epgRepository;
  IXtreamLiveRepository? _liveRepository;
  IXtreamVodRepository? _vodRepository;

  /// Get or create EPG repository
  IXtreamEpgRepository get epgRepository {
    _epgRepository ??= XtreamEpgRepository(
      apiClient: _apiClient,
      xmltvParser: _xmltvParser,
      storage: _storage,
    );
    return _epgRepository!;
  }

  /// Get or create Live TV repository
  IXtreamLiveRepository get liveRepository {
    _liveRepository ??= XtreamLiveRepository(
      apiClient: _apiClient,
      storage: _storage,
      epgRepository: epgRepository,
    );
    return _liveRepository!;
  }

  /// Get or create VOD repository
  IXtreamVodRepository get vodRepository {
    _vodRepository ??= XtreamVodRepository(
      apiClient: _apiClient,
      storage: _storage,
    );
    return _vodRepository!;
  }

  /// Get the API client
  XtreamApiClient get apiClient => _apiClient;

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
    _epgRepository = null;
    _liveRepository = null;
    _vodRepository = null;
  }
}
