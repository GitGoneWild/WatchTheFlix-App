import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/dependency_injection.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/playlist/playlist_bloc.dart';
import 'presentation/blocs/channel/channel_bloc.dart';
import 'presentation/blocs/navigation/navigation_bloc.dart';
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
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: AppRoutes.onboarding,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
