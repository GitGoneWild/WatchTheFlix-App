import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local/local_storage.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../data/repositories/channel_repository_impl.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../domain/repositories/channel_repository.dart';
import '../../domain/usecases/get_playlists.dart';
import '../../domain/usecases/add_playlist.dart';
import '../../domain/usecases/get_channels.dart';
import '../../domain/usecases/get_categories.dart';
import '../../features/m3u/m3u_parser.dart';
import '../../features/xtream/xtream_api_client.dart';
import '../../features/xtream/xtream_service.dart';
import '../../modules/core/config/app_config.dart';
import '../../modules/xtreamcodes/xtreamcodes.dart';
import '../../modules/xtreamcodes/epg/xmltv_parser.dart';
import '../../modules/xtreamcodes/repositories/repositories.dart';
import '../../modules/xtreamcodes/storage/xtream_local_storage.dart';
import '../../presentation/blocs/playlist/playlist_bloc.dart';
import '../../presentation/blocs/channel/channel_bloc.dart';
import '../../presentation/blocs/player/player_bloc.dart';
import '../../presentation/blocs/navigation/navigation_bloc.dart';
import '../../presentation/blocs/favorites/favorites_bloc.dart';
import '../../presentation/blocs/settings/settings_bloc.dart';
import '../../presentation/blocs/xtream_onboarding/xtream_onboarding_bloc.dart';

final getIt = GetIt.instance;

/// Initialize dependencies
Future<void> initDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Core
  getIt.registerLazySingleton<LocalStorage>(
    () => LocalStorageImpl(sharedPreferences: getIt()),
  );

  getIt.registerLazySingleton<ApiClient>(
    () => ApiClientImpl(),
  );

  // Register AppConfig singleton
  getIt.registerSingleton<AppConfig>(AppConfig());

  // Register shared Dio instance for Xtream operations
  getIt.registerLazySingleton<Dio>(
    () {
      final config = getIt<AppConfig>();
      return Dio(BaseOptions(
        connectTimeout: config.defaultTimeout,
        receiveTimeout: config.extendedTimeout,
        headers: {
          'Accept': '*/*',
          'User-Agent': 'WatchTheFlix/1.0',
        },
      ));
    },
    instanceName: 'xtreamDio',
  );

  // Features
  getIt.registerLazySingleton<M3UParser>(
    () => M3UParserImpl(),
  );

  // Legacy Xtream services (for backward compatibility)
  getIt.registerLazySingleton<XtreamApiClient>(
    () => XtreamApiClientImpl(apiClient: getIt()),
  );

  getIt.registerLazySingleton<XtreamService>(
    () => XtreamService(
      apiClient: getIt(),
      localStorage: getIt(),
    ),
  );

  // ============ Xtream Codes Module (Clean Architecture) ============
  
  // Xtream Local Storage for persistence
  getIt.registerLazySingleton<XtreamLocalStorage>(
    () => XtreamLocalStorage(),
  );

  // XMLTV Parser for EPG
  getIt.registerLazySingleton<XmltvParser>(
    () => XmltvParser(),
  );

  // Xtream Repositories
  getIt.registerLazySingleton<XtreamAuthRepository>(
    () => XtreamAuthRepositoryImpl(
      dio: getIt<Dio>(instanceName: 'xtreamDio'),
    ),
  );

  getIt.registerLazySingleton<XtreamAccountRepository>(
    () => XtreamAccountRepositoryImpl(
      dio: getIt<Dio>(instanceName: 'xtreamDio'),
    ),
  );

  // EPG Repository - XMLTV only implementation
  getIt.registerLazySingleton<EpgRepository>(
    () => EpgRepositoryImpl(
      dio: getIt<Dio>(instanceName: 'xtreamDio'),
      xmltvParser: getIt<XmltvParser>(),
      localStorage: getIt<XtreamLocalStorage>(),
      config: getIt<AppConfig>(),
    ),
  );

  getIt.registerLazySingleton<LiveTvRepository>(
    () => LiveTvRepositoryImpl(
      dio: getIt<Dio>(instanceName: 'xtreamDio'),
      epgRepository: getIt<EpgRepository>(),
    ),
  );

  getIt.registerLazySingleton<MoviesRepository>(
    () => MoviesRepositoryImpl(
      dio: getIt<Dio>(instanceName: 'xtreamDio'),
    ),
  );

  getIt.registerLazySingleton<SeriesRepository>(
    () => SeriesRepositoryImpl(
      dio: getIt<Dio>(instanceName: 'xtreamDio'),
    ),
  );

  // Xtream Services
  getIt.registerLazySingleton<XtreamAuthService>(
    () => XtreamAuthService(repository: getIt<XtreamAuthRepository>()),
  );

  getIt.registerLazySingleton<XtreamAccountService>(
    () => XtreamAccountService(repository: getIt<XtreamAccountRepository>()),
  );

  getIt.registerLazySingleton<EpgService>(
    () => EpgService(repository: getIt<EpgRepository>()),
  );

  getIt.registerLazySingleton<LiveTvService>(
    () => LiveTvService(repository: getIt<LiveTvRepository>()),
  );

  getIt.registerLazySingleton<MoviesService>(
    () => MoviesService(repository: getIt<MoviesRepository>()),
  );

  getIt.registerLazySingleton<SeriesService>(
    () => SeriesService(repository: getIt<SeriesRepository>()),
  );

  // New modular Xtream Codes client (facade for all Xtream services)
  getIt.registerLazySingleton<XtreamCodesClient>(
    () => XtreamCodesClient(
      dio: getIt<Dio>(instanceName: 'xtreamDio'),
      localStorage: getIt<XtreamLocalStorage>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepositoryImpl(
      localStorage: getIt(),
      apiClient: getIt(),
      m3uParser: getIt(),
    ),
  );

  getIt.registerLazySingleton<ChannelRepository>(
    () => ChannelRepositoryImpl(
      playlistRepository: getIt(),
      xtreamApiClient: getIt(),
      xtreamService: getIt(),
      localStorage: getIt(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton(() => GetPlaylists(getIt()));
  getIt.registerLazySingleton(() => AddPlaylist(getIt()));
  getIt.registerLazySingleton(() => GetChannels(getIt()));
  getIt.registerLazySingleton(() => GetCategories(getIt()));

  // BLoCs
  getIt.registerFactory(
    () => PlaylistBloc(
      getPlaylists: getIt(),
      addPlaylist: getIt(),
    ),
  );

  getIt.registerFactory(
    () => ChannelBloc(
      getChannels: getIt(),
      getCategories: getIt(),
    ),
  );

  getIt.registerFactory(
    () => PlayerBloc(),
  );

  getIt.registerFactory(
    () => NavigationBloc(),
  );

  getIt.registerFactory(
    () => FavoritesBloc(
      repository: getIt(),
    ),
  );

  getIt.registerFactory(
    () => SettingsBloc(
      localStorage: getIt(),
    ),
  );

  getIt.registerFactory(
    () => XtreamOnboardingBloc(
      apiClient: getIt(),
      xtreamService: getIt(),
    ),
  );
}

/// Initialize Xtream local storage (call after Hive is initialized)
Future<void> initXtreamStorage() async {
  final localStorage = getIt<XtreamLocalStorage>();
  if (!localStorage.isInitialized) {
    await localStorage.initialize();
  }
}
