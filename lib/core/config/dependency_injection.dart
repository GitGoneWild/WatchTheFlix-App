import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local/local_storage.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/repositories/channel_repository_impl.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../domain/repositories/channel_repository.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../domain/usecases/add_playlist.dart';
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/get_channels.dart';
import '../../domain/usecases/get_playlists.dart';
import '../../features/m3u/m3u_parser.dart';
import '../../modules/core/config/app_config.dart';
import '../../presentation/blocs/channel/channel_bloc.dart';
import '../../presentation/blocs/favorites/favorites_bloc.dart';
import '../../presentation/blocs/navigation/navigation_bloc.dart';
import '../../presentation/blocs/player/player_bloc.dart';
import '../../presentation/blocs/playlist/playlist_bloc.dart';
import '../../presentation/blocs/settings/settings_bloc.dart';

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

  // Features
  getIt.registerLazySingleton<M3UParser>(
    () => M3UParserImpl(),
  );

  // Repositories
  getIt.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepositoryImpl(
      localStorage: getIt<LocalStorage>(),
      apiClient: getIt<ApiClient>(),
      m3uParser: getIt<M3UParser>(),
    ),
  );

  getIt.registerLazySingleton<ChannelRepository>(
    () => ChannelRepositoryImpl(
      playlistRepository: getIt<PlaylistRepository>(),
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
}
