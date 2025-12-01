import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/dependency_injection.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/playlist_source.dart';
import '../../features/xtream/xtream_api_client.dart';
import '../../features/xtream/xtream_service.dart';
import '../blocs/xtream_onboarding/xtream_onboarding_bloc.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/xtream_onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/search_screen.dart';
import '../screens/playback/player_screen.dart';

/// Arguments for Xtream onboarding route
class XtreamOnboardingArguments {
  final XtreamCredentials credentials;
  final String playlistName;
  final PlaylistSource playlist;

  const XtreamOnboardingArguments({
    required this.credentials,
    required this.playlistName,
    required this.playlist,
  });
}

/// App router configuration
class AppRouter {
  /// Generate routes for the application
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
      case AppRoutes.onboarding:
        return _buildRoute(const OnboardingScreen(), settings);

      case AppRoutes.addPlaylist:
        return _buildRoute(const AddPlaylistScreen(), settings);

      case AppRoutes.xtreamOnboarding:
        final args = settings.arguments as XtreamOnboardingArguments?;
        if (args != null) {
          return _buildRoute(
            _buildXtreamOnboardingScreen(args),
            settings,
          );
        }
        return _buildRoute(const AddPlaylistScreen(), settings);

      case AppRoutes.home:
        return _buildRoute(const HomeScreen(), settings);

      case AppRoutes.search:
        return _buildRoute(const SearchScreen(), settings);

      case AppRoutes.player:
        final channel = settings.arguments as Channel?;
        if (channel != null) {
          return _buildRoute(
            PlayerScreen(channel: channel),
            settings,
          );
        }
        return _buildRoute(const HomeScreen(), settings);

      default:
        return _buildRoute(const OnboardingScreen(), settings);
    }
  }

  static Widget _buildXtreamOnboardingScreen(XtreamOnboardingArguments args) {
    return BlocProvider(
      create: (_) => XtreamOnboardingBloc(
        apiClient: getIt<XtreamApiClient>(),
        xtreamService: getIt<XtreamService>(),
      )..add(StartOnboardingEvent(
          credentials: args.credentials,
          playlistName: args.playlistName,
        )),
      child: const XtreamOnboardingScreen(),
    );
  }

  static MaterialPageRoute<T> _buildRoute<T>(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<T>(
      settings: settings,
      builder: (_) => page,
    );
  }
}
