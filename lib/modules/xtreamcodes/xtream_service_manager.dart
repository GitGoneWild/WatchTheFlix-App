// Xtream Service Manager
// Central service for managing Xtream repositories and state.

import '../core/logging/app_logger.dart';
import '../core/storage/storage_service.dart';
import 'auth/xtream_auth_service.dart';
import 'auth/xtream_credentials.dart';
import 'epg/xmltv_parser.dart';
import 'repositories/xtream_repository_factory.dart';

/// Xtream service manager
class XtreamServiceManager {
  XtreamServiceManager({
    required IXtreamAuthService authService,
    required IStorageService storage,
    required IXmltvParser xmltvParser,
  })  : _authService = authService,
        _storage = storage,
        _xmltvParser = xmltvParser;

  final IXtreamAuthService _authService;
  final IStorageService _storage;
  final IXmltvParser _xmltvParser;

  XtreamRepositoryFactory? _repositoryFactory;

  /// Check if Xtream service is initialized
  bool get isInitialized => _repositoryFactory != null;

  /// Get the repository factory (throws if not initialized)
  XtreamRepositoryFactory get repositoryFactory {
    if (_repositoryFactory == null) {
      throw StateError('Xtream service not initialized. Call initialize() first.');
    }
    return _repositoryFactory!;
  }

  /// Initialize Xtream service with credentials
  Future<void> initialize(XtreamCredentials credentials) async {
    try {
      moduleLogger.info('Initializing Xtream service', tag: 'XtreamService');

      // Dispose existing factory if any
      if (_repositoryFactory != null) {
        _repositoryFactory!.dispose();
      }

      // Create new factory
      _repositoryFactory = XtreamRepositoryFactory(
        credentials: credentials,
        storage: _storage,
        xmltvParser: _xmltvParser,
      );

      moduleLogger.info('Xtream service initialized', tag: 'XtreamService');
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to initialize Xtream service',
        tag: 'XtreamService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Try to restore from saved credentials
  Future<bool> tryRestore() async {
    try {
      moduleLogger.info('Attempting to restore Xtream service', tag: 'XtreamService');

      final result = await _authService.loadCredentials();
      if (result.isFailure) {
        moduleLogger.info('No saved credentials found', tag: 'XtreamService');
        return false;
      }

      await initialize(result.data);
      moduleLogger.info('Xtream service restored successfully', tag: 'XtreamService');
      return true;
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to restore Xtream service',
        tag: 'XtreamService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Clear Xtream service and credentials
  Future<void> clear() async {
    try {
      moduleLogger.info('Clearing Xtream service', tag: 'XtreamService');

      if (_repositoryFactory != null) {
        _repositoryFactory!.dispose();
        _repositoryFactory = null;
      }

      await _authService.clearCredentials();
      moduleLogger.info('Xtream service cleared', tag: 'XtreamService');
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to clear Xtream service',
        tag: 'XtreamService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
