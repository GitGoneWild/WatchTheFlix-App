import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/modules/xtreamcodes/sync/xtream_sync_service.dart';

void main() {
  group('SyncProgress', () {
    test('should create with default values', () {
      const progress = SyncProgress();

      expect(progress.state, equals(SyncState.idle));
      expect(progress.currentOperation, isNull);
      expect(progress.progress, equals(0.0));
      expect(progress.errorMessage, isNull);
      expect(progress.stats, isNull);
    });

    test('should copyWith correctly', () {
      const progress = SyncProgress();

      final updated = progress.copyWith(
        state: SyncState.syncing,
        currentOperation: 'Syncing channels...',
        progress: 0.5,
      );

      expect(updated.state, equals(SyncState.syncing));
      expect(updated.currentOperation, equals('Syncing channels...'));
      expect(updated.progress, equals(0.5));
      expect(updated.errorMessage, isNull);
    });

    test('should preserve unchanged values in copyWith', () {
      const original = SyncProgress(
        state: SyncState.syncing,
        currentOperation: 'Initial operation',
        progress: 0.25,
      );

      final updated = original.copyWith(progress: 0.5);

      expect(updated.state, equals(SyncState.syncing));
      expect(updated.currentOperation, equals('Initial operation'));
      expect(updated.progress, equals(0.5));
    });
  });

  group('SyncStats', () {
    test('should calculate totalItems correctly', () {
      const stats = SyncStats(
        channelsImported: 100,
        categoriesImported: 10,
        moviesImported: 500,
        seriesImported: 50,
        epgProgramsImported: 1000,
      );

      expect(stats.totalItems, equals(1660));
    });

    test('should report hasErrors correctly', () {
      const statsNoErrors = SyncStats();
      expect(statsNoErrors.hasErrors, isFalse);

      const statsWithErrors = SyncStats(errors: ['Error 1', 'Error 2']);
      expect(statsWithErrors.hasErrors, isTrue);
    });

    test('should have default zero values', () {
      const stats = SyncStats();

      expect(stats.channelsImported, equals(0));
      expect(stats.categoriesImported, equals(0));
      expect(stats.moviesImported, equals(0));
      expect(stats.seriesImported, equals(0));
      expect(stats.epgProgramsImported, equals(0));
      expect(stats.duration, equals(Duration.zero));
      expect(stats.errors, isEmpty);
    });
  });

  group('SyncConfig', () {
    test('should have correct default values', () {
      const config = SyncConfig();

      expect(config.channelTtl, equals(const Duration(hours: 1)));
      expect(config.movieTtl, equals(const Duration(hours: 4)));
      expect(config.seriesTtl, equals(const Duration(hours: 4)));
      expect(config.epgTtl, equals(const Duration(hours: 6)));
      expect(config.syncEpgOnInitial, isTrue);
      expect(config.syncMoviesOnInitial, isTrue);
      expect(config.syncSeriesOnInitial, isTrue);
    });

    test('should allow custom configuration', () {
      const config = SyncConfig(
        channelTtl: Duration(minutes: 30),
        movieTtl: Duration(hours: 2),
        seriesTtl: Duration(hours: 2),
        epgTtl: Duration(hours: 3),
        syncEpgOnInitial: false,
        syncMoviesOnInitial: false,
        syncSeriesOnInitial: true,
      );

      expect(config.channelTtl, equals(const Duration(minutes: 30)));
      expect(config.movieTtl, equals(const Duration(hours: 2)));
      expect(config.seriesTtl, equals(const Duration(hours: 2)));
      expect(config.epgTtl, equals(const Duration(hours: 3)));
      expect(config.syncEpgOnInitial, isFalse);
      expect(config.syncMoviesOnInitial, isFalse);
      expect(config.syncSeriesOnInitial, isTrue);
    });
  });

  group('SyncState', () {
    test('should have all expected states', () {
      expect(SyncState.values, contains(SyncState.idle));
      expect(SyncState.values, contains(SyncState.syncing));
      expect(SyncState.values, contains(SyncState.completed));
      expect(SyncState.values, contains(SyncState.failed));
    });
  });
}
