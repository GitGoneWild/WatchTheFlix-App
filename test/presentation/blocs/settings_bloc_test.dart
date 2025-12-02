import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:watchtheflix/data/datasources/local/local_storage.dart';
import 'package:watchtheflix/presentation/blocs/settings/settings_bloc.dart';

class MockLocalStorage extends Mock implements LocalStorage {}

void main() {
  group('SettingsBloc', () {
    late MockLocalStorage mockLocalStorage;
    late SettingsBloc settingsBloc;

    setUp(() {
      mockLocalStorage = MockLocalStorage();
      settingsBloc = SettingsBloc(localStorage: mockLocalStorage);
    });

    tearDown(() {
      settingsBloc.close();
    });

    test('initial state is SettingsInitialState', () {
      expect(settingsBloc.state, isA<SettingsInitialState>());
    });

    blocTest<SettingsBloc, SettingsState>(
      'emits [SettingsLoadingState, SettingsLoadedState] when LoadSettingsEvent is added with no saved settings',
      build: () {
        when(() => mockLocalStorage.getSettings())
            .thenAnswer((_) async => null);
        return settingsBloc;
      },
      act: (bloc) => bloc.add(const LoadSettingsEvent()),
      expect: () => [
        isA<SettingsLoadingState>(),
        isA<SettingsLoadedState>().having(
          (state) => state.settings.themeMode,
          'themeMode',
          ThemeMode.dark,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [SettingsLoadingState, SettingsLoadedState] when LoadSettingsEvent is added with saved settings',
      build: () {
        when(() => mockLocalStorage.getSettings()).thenAnswer(
          (_) async => {
            'themeMode': 'light',
            'videoQuality': '720',
            'autoPlay': false,
            'showEpg': true,
            'refreshIntervalHours': 12,
          },
        );
        return settingsBloc;
      },
      act: (bloc) => bloc.add(const LoadSettingsEvent()),
      expect: () => [
        isA<SettingsLoadingState>(),
        isA<SettingsLoadedState>().having(
          (state) => state.settings.themeMode,
          'themeMode',
          ThemeMode.light,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits SettingsLoadedState with updated theme when UpdateThemeModeEvent is added',
      build: () {
        when(() => mockLocalStorage.saveSettings(any()))
            .thenAnswer((_) async {});
        return settingsBloc;
      },
      seed: () => const SettingsLoadedState(AppSettings()),
      act: (bloc) => bloc.add(const UpdateThemeModeEvent(ThemeMode.light)),
      expect: () => [
        isA<SettingsLoadedState>().having(
          (state) => state.settings.themeMode,
          'themeMode',
          ThemeMode.light,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits SettingsLoadedState with updated refresh interval',
      build: () {
        when(() => mockLocalStorage.saveSettings(any()))
            .thenAnswer((_) async {});
        return settingsBloc;
      },
      seed: () => const SettingsLoadedState(AppSettings()),
      act: (bloc) => bloc.add(const UpdateRefreshIntervalEvent(12)),
      expect: () => [
        isA<SettingsLoadedState>().having(
          (state) => state.settings.refreshIntervalHours,
          'refreshIntervalHours',
          12,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits SettingsLoadedState with isRefreshing true then false during refresh',
      build: () {
        when(() => mockLocalStorage.saveSettings(any()))
            .thenAnswer((_) async {});
        return settingsBloc;
      },
      seed: () => const SettingsLoadedState(AppSettings()),
      act: (bloc) => bloc.add(const RefreshPlaylistDataEvent()),
      wait: const Duration(seconds: 1),
      expect: () => [
        isA<SettingsLoadedState>().having(
          (state) => state.isRefreshing,
          'isRefreshing',
          true,
        ),
        isA<SettingsLoadedState>().having(
          (state) => state.isRefreshing,
          'isRefreshing',
          false,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits default SettingsLoadedState when ResetSettingsEvent is added',
      build: () {
        when(() => mockLocalStorage.saveSettings(any()))
            .thenAnswer((_) async {});
        return settingsBloc;
      },
      seed: () => const SettingsLoadedState(
        AppSettings(
          themeMode: ThemeMode.light,
          videoQuality: VideoQuality.hd,
          autoPlay: false,
          refreshIntervalHours: 12,
        ),
      ),
      act: (bloc) => bloc.add(const ResetSettingsEvent()),
      expect: () => [
        isA<SettingsLoadedState>()
            .having((state) => state.settings.themeMode, 'themeMode',
                ThemeMode.dark)
            .having((state) => state.settings.videoQuality, 'videoQuality',
                VideoQuality.auto)
            .having((state) => state.settings.autoPlay, 'autoPlay', true)
            .having((state) => state.settings.refreshIntervalHours,
                'refreshIntervalHours', 24),
      ],
    );

    group('AppSettings', () {
      test('needsRefresh returns true when lastRefresh is null', () {
        const settings = AppSettings();
        expect(settings.needsRefresh, isTrue);
      });

      test('needsRefresh returns true when past refresh interval', () {
        final settings = AppSettings(
          lastRefresh: DateTime.now().subtract(const Duration(hours: 25)),
        );
        expect(settings.needsRefresh, isTrue);
      });

      test('needsRefresh returns false when within refresh interval', () {
        final settings = AppSettings(
          lastRefresh: DateTime.now().subtract(const Duration(hours: 1)),
        );
        expect(settings.needsRefresh, isFalse);
      });

      test('toJson and fromJson round-trip correctly', () {
        final testDate = DateTime.now().subtract(const Duration(hours: 5));
        final original = AppSettings(
          themeMode: ThemeMode.light,
          videoQuality: VideoQuality.hd,
          autoPlay: false,
          subtitlesEnabled: true,
          showEpg: false,
          refreshIntervalHours: 48,
          lastRefresh: testDate,
        );

        final json = original.toJson();
        final restored = AppSettings.fromJson(json);

        expect(restored.themeMode, equals(original.themeMode));
        expect(restored.videoQuality, equals(original.videoQuality));
        expect(restored.autoPlay, equals(original.autoPlay));
        expect(restored.subtitlesEnabled, equals(original.subtitlesEnabled));
        expect(restored.showEpg, equals(original.showEpg));
        expect(restored.refreshIntervalHours,
            equals(original.refreshIntervalHours));
        // Compare timestamps with tolerance for parsing precision
        expect(
          restored.lastRefresh
              ?.difference(original.lastRefresh!)
              .inSeconds
              .abs(),
          lessThan(2),
        );
      });
    });
  });
}
