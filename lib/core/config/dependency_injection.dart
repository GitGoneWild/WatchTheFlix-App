import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local/local_storage.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/repositories/channel_repository_impl.dart';
import '../../data/repositories/composite_channel_repository.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../domain/repositories/channel_repository.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../domain/usecases/add_playlist.dart';
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/get_channels.dart';
import '../../domain/usecases/get_playlists.dart';
import '../../features/m3u/m3u_parser.dart';
import '../../modules/core/config/app_config.dart';
import '../../modules/core/storage/shared_preferences_storage.dart';
import '../../modules/core/storage/storage_service.dart';
import '../../modules/xtreamcodes/auth/xtream_auth_service.dart';
import '../../modules/xtreamcodes/epg/xmltv_parser.dart';
import '../../modules/xtreamcodes/epg/xtream_epg_repository.dart';
import '../../modules/xtreamcodes/repositories/xtream_live_repository.dart';
import '../../modules/xtreamcodes/repositories/xtream_vod_repository.dart';
import '../../modules/xtreamcodes/xtream_service_manager.dart';
import '../../presentation/blocs/channel/channel_bloc.dart';
import '../../presentation/blocs/favorites/favorites_bloc.dart';
import '../../presentation/blocs/movies/movies_bloc.dart';
import '../../presentation/blocs/navigation/navigation_bloc.dart';
import '../../presentation/blocs/player/player_bloc.dart';
import '../../presentation/blocs/playlist/playlist_bloc.dart';
import '../../presentation/blocs/settings/settings_bloc.dart';
import '../../presentation/blocs/xtream_auth/xtream_auth_bloc.dart';
import '../../presentation/blocs/xtream_connection/xtream_connection_bloc.dart';

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

  // Register IStorageService for Xtream modules
  getIt.registerLazySingleton<IStorageService>(
    () => SharedPreferencesStorage(sharedPreferences: getIt()),
  );

  // Features
  getIt.registerLazySingleton<M3UParser>(
    () => M3UParserImpl(),
  );

  // Xtream Codes Module
  getIt.registerLazySingleton<IXtreamAuthService>(
    () => XtreamAuthService(storage: getIt<IStorageService>()),
  );

  getIt.registerLazySingleton<IXmltvParser>(
    () => XmltvParser(),
  );

  getIt.registerLazySingleton<XtreamServiceManager>(
    () => XtreamServiceManager(
      authService: getIt<IXtreamAuthService>(),
      storage: getIt<IStorageService>(),
      xmltvParser: getIt<IXmltvParser>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepositoryImpl(
      localStorage: getIt<LocalStorage>(),
      apiClient: getIt<ApiClient>(),
      m3uParser: getIt<M3UParser>(),
    ),
  );

  // Register M3U-based channel repository as a named singleton
  getIt.registerLazySingleton<ChannelRepositoryImpl>(
    () => ChannelRepositoryImpl(
      playlistRepository: getIt<PlaylistRepository>(),
      localStorage: getIt<LocalStorage>(),
    ),
  );

  // Register the composite channel repository that switches between Xtream and M3U
  getIt.registerLazySingleton<ChannelRepository>(
    () => CompositeChannelRepository(
      serviceManager: getIt<XtreamServiceManager>(),
      m3uRepository: getIt<ChannelRepositoryImpl>(),
      localStorage: getIt<LocalStorage>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton(() => GetPlaylists(getIt<PlaylistRepository>()));
  getIt.registerLazySingleton(() => AddPlaylist(getIt<PlaylistRepository>()));
  getIt.registerLazySingleton(() => GetChannels(getIt<ChannelRepository>()));
  getIt.registerLazySingleton(() => GetCategories(getIt<ChannelRepository>()));

  // BLoCs
  getIt.registerFactory(
    () => PlaylistBloc(
      getPlaylists: getIt<GetPlaylists>(),
      addPlaylist: getIt<AddPlaylist>(),
    ),
  );

  getIt.registerFactory(
    () => ChannelBloc(
      getChannels: getIt<GetChannels>(),
      getCategories: getIt<GetCategories>(),
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
      repository: getIt<ChannelRepository>(),
    ),
  );

  getIt.registerFactory(
    () => SettingsBloc(
      localStorage: getIt<LocalStorage>(),
    ),
  );

  // Movies BLoC
  getIt.registerFactory(
    () => MoviesBloc(
      repository: getIt<ChannelRepository>(),
    ),
  );

  // Xtream Auth BLoC - Register as singleton so we can reuse it
  getIt.registerLazySingleton(
    () => XtreamAuthBloc(
      authService: getIt<IXtreamAuthService>(),
      serviceManager: getIt<XtreamServiceManager>(),
    ),
  );

  // Xtream Connection BLoC
  getIt.registerFactory(
    () => XtreamConnectionBloc(
      authService: getIt<IXtreamAuthService>(),
      serviceManager: getIt<XtreamServiceManager>(),
    ),
  );
}
