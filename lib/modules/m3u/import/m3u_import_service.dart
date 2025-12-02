// M3uImportService
// Service for importing M3U playlists from files and URLs.

import '../../core/models/api_result.dart';
import '../../core/logging/app_logger.dart';
import '../parsing/m3u_parser.dart';

/// M3U import result
class M3uImportResult {
  const M3uImportResult({
    required this.entries,
    required this.totalParsed,
    this.errors = 0,
    this.source,
  });
  final List<M3uEntry> entries;
  final int totalParsed;
  final int errors;
  final String? source;
}

/// M3U import service interface
abstract class IM3uImportService {
  /// Import M3U from file path
  Future<ApiResult<M3uImportResult>> importFromFile(String path);

  /// Import M3U from URL
  Future<ApiResult<M3uImportResult>> importFromUrl(String url);

  /// Import M3U from raw content
  ApiResult<M3uImportResult> importFromContent(String content,
      {String? source});

  /// Validate M3U content
  bool validate(String content);
}

/// M3U import service implementation
class M3uImportService implements IM3uImportService {
  M3uImportService({
    required IM3uParser parser,
    required M3uImportRepository repository,
  })  : _parser = parser,
        _repository = repository;
  final IM3uParser _parser;
  final M3uImportRepository _repository;

  @override
  Future<ApiResult<M3uImportResult>> importFromFile(String path) async {
    try {
      moduleLogger.info('Importing M3U from file: $path', tag: 'M3uImport');

      final contentResult = await _repository.readFile(path);
      if (contentResult.isFailure) {
        return ApiResult.failure(contentResult.error);
      }

      return importFromContent(contentResult.data, source: path);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to import M3U from file',
        tag: 'M3uImport',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  Future<ApiResult<M3uImportResult>> importFromUrl(String url) async {
    try {
      moduleLogger.info('Importing M3U from URL: $url', tag: 'M3uImport');

      final contentResult = await _repository.fetchFromUrl(url);
      if (contentResult.isFailure) {
        return ApiResult.failure(contentResult.error);
      }

      return importFromContent(contentResult.data, source: url);
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to import M3U from URL',
        tag: 'M3uImport',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  ApiResult<M3uImportResult> importFromContent(String content,
      {String? source}) {
    try {
      if (!_parser.isValid(content)) {
        return ApiResult.failure(
          const ApiError(
            type: ApiErrorType.validation,
            message: 'Invalid M3U content',
          ),
        );
      }

      final entries = _parser.parse(content);

      moduleLogger.info(
        'Imported ${entries.length} entries from M3U',
        tag: 'M3uImport',
      );

      return ApiResult.success(
        M3uImportResult(
          entries: entries,
          totalParsed: entries.length,
          source: source,
        ),
      );
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Failed to parse M3U content',
        tag: 'M3uImport',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiResult.failure(ApiError.fromException(e));
    }
  }

  @override
  bool validate(String content) {
    return _parser.isValid(content);
  }
}

/// M3U import repository interface
abstract class M3uImportRepository {
  /// Read content from file
  Future<ApiResult<String>> readFile(String path);

  /// Fetch content from URL
  Future<ApiResult<String>> fetchFromUrl(String url);
}
