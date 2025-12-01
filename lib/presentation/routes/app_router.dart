import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/channel.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/search_screen.dart';
import '../screens/playback/player_screen.dart';

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
