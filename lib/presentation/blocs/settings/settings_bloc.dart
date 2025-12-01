import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/logger.dart';
import '../../../data/datasources/local/local_storage.dart';

/// Video quality options
enum VideoQuality {
  auto('Auto', 'auto'),
  low('Low (360p)', '360'),
  medium('Medium (480p)', '480'),
  high('High (720p)', '720'),
  hd('HD (1080p)', '1080'),
  ultra('Ultra HD (4K)', '2160');

  final String label;
  final String value;

  const VideoQuality(this.label, this.value);
}

/// Theme mode options
enum ThemeMode {
  dark('Dark', 'dark'),
  light('Light', 'light'),
  system('System', 'system');

  final String label;
  final String value;

  const ThemeMode(this.label, this.value);
}

/// App settings model
class AppSettings extends Equatable {
  final ThemeMode themeMode;
  final VideoQuality videoQuality;
  final bool autoPlay;
  final bool subtitlesEnabled;
  final String subtitleLanguage;
  final bool pipEnabled;
  final bool backgroundPlayEnabled;
  final double bufferDuration;
  final bool showEpg;
  final bool autoRetry;
  final int maxRetries;
  final int refreshIntervalHours;
  final DateTime? lastRefresh;

  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.videoQuality = VideoQuality.auto,
    this.autoPlay = true,
    this.subtitlesEnabled = false,
    this.subtitleLanguage = 'en',
    this.pipEnabled = true,
    this.backgroundPlayEnabled = false,
    this.bufferDuration = 10.0,
    this.showEpg = true,
    this.autoRetry = true,
    this.maxRetries = 3,
    this.refreshIntervalHours = 24,
    this.lastRefresh,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    VideoQuality? videoQuality,
    bool? autoPlay,
    bool? subtitlesEnabled,
    String? subtitleLanguage,
    bool? pipEnabled,
    bool? backgroundPlayEnabled,
    double? bufferDuration,
    bool? showEpg,
    bool? autoRetry,
    int? maxRetries,
    int? refreshIntervalHours,
    DateTime? lastRefresh,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      videoQuality: videoQuality ?? this.videoQuality,
      autoPlay: autoPlay ?? this.autoPlay,
      subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
      subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
      pipEnabled: pipEnabled ?? this.pipEnabled,
      backgroundPlayEnabled: backgroundPlayEnabled ?? this.backgroundPlayEnabled,
      bufferDuration: bufferDuration ?? this.bufferDuration,
      showEpg: showEpg ?? this.showEpg,
      autoRetry: autoRetry ?? this.autoRetry,
      maxRetries: maxRetries ?? this.maxRetries,
      refreshIntervalHours: refreshIntervalHours ?? this.refreshIntervalHours,
      lastRefresh: lastRefresh ?? this.lastRefresh,
    );
  }

  /// Check if data needs refresh based on interval
  bool get needsRefresh {
    if (lastRefresh == null) return true;
    final hoursSinceRefresh = DateTime.now().difference(lastRefresh!).inHours;
    return hoursSinceRefresh >= refreshIntervalHours;
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.value,
      'videoQuality': videoQuality.value,
      'autoPlay': autoPlay,
      'subtitlesEnabled': subtitlesEnabled,
      'subtitleLanguage': subtitleLanguage,
      'pipEnabled': pipEnabled,
      'backgroundPlayEnabled': backgroundPlayEnabled,
      'bufferDuration': bufferDuration,
      'showEpg': showEpg,
      'autoRetry': autoRetry,
      'maxRetries': maxRetries,
      'refreshIntervalHours': refreshIntervalHours,
      'lastRefresh': lastRefresh?.toIso8601String(),
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    DateTime? lastRefresh;
    final lastRefreshValue = json['lastRefresh'];
    if (lastRefreshValue != null && lastRefreshValue is String) {
      lastRefresh = DateTime.tryParse(lastRefreshValue);
      // If parsing fails, we simply use null (no last refresh)
    }
    
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.value == json['themeMode'],
        orElse: () => ThemeMode.dark,
      ),
      videoQuality: VideoQuality.values.firstWhere(
        (e) => e.value == json['videoQuality'],
        orElse: () => VideoQuality.auto,
      ),
      autoPlay: json['autoPlay'] ?? true,
      subtitlesEnabled: json['subtitlesEnabled'] ?? false,
      subtitleLanguage: json['subtitleLanguage'] ?? 'en',
      pipEnabled: json['pipEnabled'] ?? true,
      backgroundPlayEnabled: json['backgroundPlayEnabled'] ?? false,
      bufferDuration: (json['bufferDuration'] ?? 10.0).toDouble(),
      showEpg: json['showEpg'] ?? true,
      autoRetry: json['autoRetry'] ?? true,
      maxRetries: json['maxRetries'] ?? 3,
      refreshIntervalHours: json['refreshIntervalHours'] ?? 24,
      lastRefresh: lastRefresh,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        videoQuality,
        autoPlay,
        subtitlesEnabled,
        subtitleLanguage,
        pipEnabled,
        backgroundPlayEnabled,
        bufferDuration,
        showEpg,
        autoRetry,
        maxRetries,
        refreshIntervalHours,
        lastRefresh,
      ];
}

// Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

class UpdateSettingsEvent extends SettingsEvent {
  final AppSettings settings;

  const UpdateSettingsEvent(this.settings);

  @override
  List<Object?> get props => [settings];
}

class UpdateThemeModeEvent extends SettingsEvent {
  final ThemeMode themeMode;

  const UpdateThemeModeEvent(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class UpdateVideoQualityEvent extends SettingsEvent {
  final VideoQuality quality;

  const UpdateVideoQualityEvent(this.quality);

  @override
  List<Object?> get props => [quality];
}

class ToggleAutoPlayEvent extends SettingsEvent {
  const ToggleAutoPlayEvent();
}

class ToggleSubtitlesEvent extends SettingsEvent {
  const ToggleSubtitlesEvent();
}

class UpdateSubtitleLanguageEvent extends SettingsEvent {
  final String language;

  const UpdateSubtitleLanguageEvent(this.language);

  @override
  List<Object?> get props => [language];
}

class TogglePipEvent extends SettingsEvent {
  const TogglePipEvent();
}

class ToggleBackgroundPlayEvent extends SettingsEvent {
  const ToggleBackgroundPlayEvent();
}

class ToggleEpgEvent extends SettingsEvent {
  const ToggleEpgEvent();
}

class ToggleAutoRetryEvent extends SettingsEvent {
  const ToggleAutoRetryEvent();
}

class ResetSettingsEvent extends SettingsEvent {
  const ResetSettingsEvent();
}

class RefreshPlaylistDataEvent extends SettingsEvent {
  const RefreshPlaylistDataEvent();
}

class UpdateRefreshIntervalEvent extends SettingsEvent {
  final int hours;

  const UpdateRefreshIntervalEvent(this.hours);

  @override
  List<Object?> get props => [hours];
}

// States
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitialState extends SettingsState {
  const SettingsInitialState();
}

class SettingsLoadingState extends SettingsState {
  const SettingsLoadingState();
}

class SettingsLoadedState extends SettingsState {
  final AppSettings settings;
  final bool isRefreshing;
  final String? refreshError;

  const SettingsLoadedState(
    this.settings, {
    this.isRefreshing = false,
    this.refreshError,
  });

  SettingsLoadedState copyWith({
    AppSettings? settings,
    bool? isRefreshing,
    String? refreshError,
    bool clearError = false,
  }) {
    return SettingsLoadedState(
      settings ?? this.settings,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshError: clearError ? null : (refreshError ?? this.refreshError),
    );
  }

  @override
  List<Object?> get props => [settings, isRefreshing, refreshError];
}

class SettingsErrorState extends SettingsState {
  final String message;

  const SettingsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final LocalStorage _localStorage;

  SettingsBloc({required LocalStorage localStorage})
      : _localStorage = localStorage,
        super(const SettingsInitialState()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateSettingsEvent>(_onUpdateSettings);
    on<UpdateThemeModeEvent>(_onUpdateThemeMode);
    on<UpdateVideoQualityEvent>(_onUpdateVideoQuality);
    on<ToggleAutoPlayEvent>(_onToggleAutoPlay);
    on<ToggleSubtitlesEvent>(_onToggleSubtitles);
    on<UpdateSubtitleLanguageEvent>(_onUpdateSubtitleLanguage);
    on<TogglePipEvent>(_onTogglePip);
    on<ToggleBackgroundPlayEvent>(_onToggleBackgroundPlay);
    on<ToggleEpgEvent>(_onToggleEpg);
    on<ToggleAutoRetryEvent>(_onToggleAutoRetry);
    on<ResetSettingsEvent>(_onResetSettings);
    on<RefreshPlaylistDataEvent>(_onRefreshPlaylistData);
    on<UpdateRefreshIntervalEvent>(_onUpdateRefreshInterval);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoadingState());
    try {
      final json = await _localStorage.getSettings();
      final settings = json != null ? AppSettings.fromJson(json) : const AppSettings();
      emit(SettingsLoadedState(settings));
    } catch (e) {
      AppLogger.error('Failed to load settings', e);
      emit(SettingsLoadedState(const AppSettings()));
    }
  }

  Future<void> _saveSettings(AppSettings settings) async {
    await _localStorage.saveSettings(settings.toJson());
  }

  Future<void> _onUpdateSettings(
    UpdateSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    await _saveSettings(event.settings);
    emit(SettingsLoadedState(event.settings));
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoadedState) {
      final currentSettings = (state as SettingsLoadedState).settings;
      final newSettings = currentSettings.copyWith(themeMode: event.themeMode);
      await _saveSettings(newSettings);
      emit(SettingsLoadedState(newSettings));
    }
  }

  Future<void> _onUpdateVideoQuality(
    UpdateVideoQualityEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoadedState) {
      final currentSettings = (state as SettingsLoadedState).settings;
      final newSettings = currentSettings.copyWith(videoQuality: event.quality);
      await _saveSettings(newSettings);
      emit(SettingsLoadedState(newSettings));
    }
  }

  Future<void> _onToggleAutoPlay(
    ToggleAutoPlayEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoadedState) {
      final currentSettings = (state as SettingsLoadedState).settings;
      final newSettings = currentSettings.copyWith(autoPlay: !currentSettings.autoPlay);
      await _saveSettings(newSettings);
      emit(SettingsLoadedState(newSettings));
    }
  }

  Future<void> _onToggleSubtitles(
    ToggleSubtitlesEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoadedState) {
      final currentSettings = (state as SettingsLoadedState).settings;
      final newSettings = currentSettings.copyWith(
        subtitlesEnabled: !currentSettings.subtitlesEnabled,
      );
      await _saveSettings(newSettings);
      emit(SettingsLoadedState(newSettings));
    }
  }

  Future<void> _onUpdateSubtitleLanguage(
    UpdateSubtitleLanguageEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoadedState) {
      final currentSettings = (state as SettingsLoadedState).settings;
      final newSettings = currentSettings.copyWith(
        subtitleLanguage: event.language,
      );
      await _saveSettings(newSettings);
      emit(SettingsLoadedState(newSettings));
    }
  }

  Future<void> _onTogglePip(
    TogglePipEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoadedState) {
      final currentSettings = (state as SettingsLoadedState).settings;
      final newSettings = currentSettings.copyWith(
        pipEnabled: !currentSettings.pipEnabled,
      );
      await _saveSettings(newSettings);
      emit(SettingsLoadedState(newSettings));
    }
  }

  Future<void> _onToggleBackgroundPlay(
    ToggleBackgroundPlayEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoadedState) {
      final currentSettings = (state as SettingsLoadedState).settings;
      final newSettings = currentSettings.copyWith(
        backgroundPlayEnabled: !currentSettings.backgroundPlayEnabled,
      );
      await _saveSettings(newSettings);
      emit(SettingsLoadedState(newSettings));
    }
  }

  Future<void> _onToggleEpg(
    ToggleEpgEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoadedState) {
      final currentSettings = (state as SettingsLoadedState).settings;
      final newSettings = currentSettings.copyWith(showEpg: !currentSettings.showEpg);
      await _saveSettings(newSettings);
      emit(SettingsLoadedState(newSettings));
    }
  }

  Future<void> _onToggleAutoRetry(
    ToggleAutoRetryEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoadedState) {
      final currentSettings = (state as SettingsLoadedState).settings;
      final newSettings = currentSettings.copyWith(autoRetry: !currentSettings.autoRetry);
      await _saveSettings(newSettings);
      emit(SettingsLoadedState(newSettings));
    }
  }

  Future<void> _onResetSettings(
    ResetSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    const defaultSettings = AppSettings();
    await _saveSettings(defaultSettings);
    emit(const SettingsLoadedState(defaultSettings));
  }

  Future<void> _onRefreshPlaylistData(
    RefreshPlaylistDataEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoadedState) {
      final currentState = state as SettingsLoadedState;
      // Emit refreshing state
      emit(currentState.copyWith(isRefreshing: true, clearError: true));
      
      try {
        // Note: The actual refresh logic is handled by the PlaylistBloc and ChannelBloc
        // This event just marks that a refresh was requested and updates the last refresh time
        final newSettings = currentState.settings.copyWith(
          lastRefresh: DateTime.now(),
        );
        await _saveSettings(newSettings);
        
        // Wait a moment to simulate refresh (actual refresh is done by other blocs)
        await Future.delayed(const Duration(milliseconds: 500));
        
        emit(SettingsLoadedState(newSettings, isRefreshing: false));
        AppLogger.info('Playlist data refresh completed');
      } catch (e) {
        AppLogger.error('Failed to refresh playlist data', e);
        emit(currentState.copyWith(
          isRefreshing: false,
          refreshError: 'Failed to refresh: $e',
        ));
      }
    }
  }

  Future<void> _onUpdateRefreshInterval(
    UpdateRefreshIntervalEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoadedState) {
      final currentSettings = (state as SettingsLoadedState).settings;
      final newSettings = currentSettings.copyWith(refreshIntervalHours: event.hours);
      await _saveSettings(newSettings);
      emit(SettingsLoadedState(newSettings));
      AppLogger.info('Refresh interval updated to ${event.hours} hours');
    }
  }
}
