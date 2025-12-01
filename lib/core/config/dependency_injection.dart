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
import '../../presentation/blocs/playlist/playlist_bloc.dart';
import '../../presentation/blocs/channel/channel_bloc.dart';
import '../../presentation/blocs/player/player_bloc.dart';
import '../../presentation/blocs/navigation/navigation_bloc.dart';

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

  // Features
  getIt.registerLazySingleton<M3UParser>(
    () => M3UParserImpl(),
  );

  getIt.registerLazySingleton<XtreamApiClient>(
    () => XtreamApiClientImpl(apiClient: getIt()),
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
}
