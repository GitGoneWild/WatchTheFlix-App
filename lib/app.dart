import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/dependency_injection.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'modules/core/storage/storage_service.dart';
import 'presentation/blocs/channel/channel_bloc.dart';
import 'presentation/blocs/favorites/favorites_bloc.dart';
import 'presentation/blocs/navigation/navigation_bloc.dart';
import 'presentation/blocs/playlist/playlist_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart' as settings;
import 'presentation/blocs/xtream_auth/xtream_auth_bloc.dart';
import 'presentation/blocs/xtream_auth/xtream_auth_event.dart';
import 'presentation/routes/app_router.dart';

/// Main application widget
class WatchTheFlixApp extends StatefulWidget {
  const WatchTheFlixApp({super.key});

  @override
  State<WatchTheFlixApp> createState() => _WatchTheFlixAppState();
}

class _WatchTheFlixAppState extends State<WatchTheFlixApp> {
  String? _initialRoute;
  bool _isOnboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    final storage = getIt<IStorageService>();

    // Check if onboarding is completed
    final isOnboardingCompleted = await _checkOnboardingCompleted(storage);

    setState(() {
      _initialRoute =
          isOnboardingCompleted ? AppRoutes.home : AppRoutes.onboarding;
      _isOnboardingCompleted = isOnboardingCompleted;
    });
  }

  /// Check if onboarding has been completed
  Future<bool> _checkOnboardingCompleted(IStorageService storage) async {
    final onboardingResult =
        await storage.getBool(StorageKeys.onboardingCompleted);
    return onboardingResult.isSuccess && (onboardingResult.data ?? false);
  }

  @override
  Widget build(BuildContext context) {
    // Show splash while determining initial route
    if (_initialRoute == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

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
          create: (_) =>
              getIt<FavoritesBloc>()..add(const LoadFavoritesEvent()),
        ),
        BlocProvider<settings.SettingsBloc>(
          create: (_) => getIt<settings.SettingsBloc>()
            ..add(const settings.LoadSettingsEvent()),
        ),
        BlocProvider<XtreamAuthBloc>(
          create: (_) {
            final bloc = getIt<XtreamAuthBloc>();
            // Restore credentials after BLoC is in the widget tree
            if (_isOnboardingCompleted) {
              bloc.add(const XtreamAuthLoadCredentials());
            }
            return bloc;
          },
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
            initialRoute: _initialRoute,
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
