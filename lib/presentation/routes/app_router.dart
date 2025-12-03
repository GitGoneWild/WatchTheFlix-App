import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/dependency_injection.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/channel.dart';
import '../blocs/xtream_auth/xtream_auth_bloc.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/search_screen.dart';
import '../screens/home/enhanced_search_screen.dart';
import '../screens/home/movies_optimized_screen.dart';
import '../screens/home/watch_history_screen.dart';
import '../screens/live_tv/live_tv_redesigned_screen.dart';
import '../screens/playback/player_screen.dart';
import '../screens/xtream_login/xtream_login_screen.dart';
import '../screens/xtream_progress/xtream_progress_screen.dart';
import '../../modules/xtreamcodes/auth/xtream_credentials.dart';

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

      case AppRoutes.xtreamLogin:
        return _buildRoute(
          BlocProvider(
            create: (_) => getIt<XtreamAuthBloc>(),
            child: const XtreamLoginScreen(),
          ),
          settings,
        );

      case AppRoutes.xtreamProgress:
        final credentials = settings.arguments as XtreamCredentials?;
        if (credentials != null) {
          return _buildRoute(
            XtreamProgressScreen(credentials: credentials),
            settings,
          );
        }
        return _buildRoute(const OnboardingScreen(), settings);

      case AppRoutes.home:
        return _buildRoute(const HomeScreen(), settings);

      case AppRoutes.search:
        // Use the enhanced search screen for better UX
        return _buildRoute(const EnhancedSearchScreen(), settings);

      case AppRoutes.watchHistory:
        return _buildRoute(const WatchHistoryScreen(), settings);

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
