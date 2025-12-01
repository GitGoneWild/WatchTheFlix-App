import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/dependency_injection.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/playlist/playlist_bloc.dart';
import 'presentation/blocs/channel/channel_bloc.dart';
import 'presentation/blocs/navigation/navigation_bloc.dart';
import 'presentation/blocs/favorites/favorites_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart' as settings;
import 'presentation/routes/app_router.dart';

/// Main application widget
class WatchTheFlixApp extends StatelessWidget {
  const WatchTheFlixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PlaylistBloc>(
          create: (_) => getIt<PlaylistBloc>()..add(const LoadPlaylistsEvent()),
        ),
        BlocProvider<ChannelBloc>(
          create: (_) => getIt<ChannelBloc>()..add(const LoadChannelsEvent()),
        ),
        BlocProvider<NavigationBloc>(
          create: (_) => getIt<NavigationBloc>(),
        ),
        BlocProvider<FavoritesBloc>(
          create: (_) => getIt<FavoritesBloc>()..add(const LoadFavoritesEvent()),
        ),
        BlocProvider<settings.SettingsBloc>(
          create: (_) => getIt<settings.SettingsBloc>()..add(const settings.LoadSettingsEvent()),
        ),
      ],
      child: BlocBuilder<settings.SettingsBloc, settings.SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _getThemeMode(settingsState),
            initialRoute: AppRoutes.onboarding,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }

  ThemeMode _getThemeMode(settings.SettingsState state) {
    if (state is settings.SettingsLoadedState) {
      switch (state.settings.themeMode) {
        case settings.ThemeMode.dark:
          return ThemeMode.dark;
        case settings.ThemeMode.light:
          return ThemeMode.light;
        case settings.ThemeMode.system:
          return ThemeMode.system;
      }
    }
    return ThemeMode.dark;
  }
}
