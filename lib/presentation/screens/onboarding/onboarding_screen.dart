import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/dependency_injection.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/playlist_source.dart';
import '../../../modules/core/logging/app_logger.dart';
import '../../../modules/core/storage/storage_service.dart';
import '../../blocs/playlist/playlist_bloc.dart';
import '../../routes/app_router.dart';

/// Onboarding screen for first-time setup
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Welcome to WatchTheFlix',
      description:
          'Your ultimate IPTV streaming experience. Watch live TV, movies, and series on any device.',
      icon: Icons.tv,
      gradient: const [AppColors.primary, AppColors.primaryDark],
    ),
    _OnboardingPageData(
      title: 'Connect Your IPTV Provider',
      description:
          'Sign in with your Xtream Codes credentials or import M3U playlists for seamless streaming.',
      icon: Icons.live_tv,
      gradient: const [AppColors.accentPurple, Color(0xFF6B21A8)],
    ),
    _OnboardingPageData(
      title: 'Enjoy Anywhere',
      description:
          'Stream on mobile, tablet, desktop, or web. Your content, your way.',
      icon: Icons.devices,
      gradient: const [AppColors.secondary, AppColors.secondaryDark],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _showConnectionOptions();
    }
  }

  void _showConnectionOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ConnectionOptionsSheet(
        onComplete: _markOnboardingComplete,
      ),
    );
  }

  Future<void> _markOnboardingComplete() async {
    try {
      final storage = getIt<IStorageService>();
      final result =
          await storage.setBool(StorageKeys.onboardingCompleted, true);
      if (result.isFailure) {
        moduleLogger.warning(
          'Failed to save onboarding completion status',
          tag: 'Onboarding',
          error: result.error,
        );
      }
    } catch (e, stackTrace) {
      moduleLogger.error(
        'Error saving onboarding completion',
        tag: 'Onboarding',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header with skip button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo/App name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'WatchTheFlix',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    // Skip button
                    TextButton(
                      onPressed: _showConnectionOptions,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPageWidget(
                      data: _pages[index],
                      isActive: _currentPage == index,
                    );
                  },
                ),
              ),

              // Page indicators
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.primary
                            : AppColors.textTertiary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Next/Get Started button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onNextPage,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage == _pages.length - 1
                              ? Icons.rocket_launch
                              : Icons.arrow_forward,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data class for onboarding page
class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;
}

/// Widget for each onboarding page
class _OnboardingPageWidget extends StatelessWidget {
  const _OnboardingPageWidget({
    required this.data,
    required this.isActive,
  });

  final _OnboardingPageData data;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.8, end: isActive ? 1.0 : 0.8),
            curve: Curves.easeOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        data.gradient[0].withValues(alpha: 0.2),
                        data.gradient[1].withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: data.gradient[0].withValues(alpha: 0.3),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    data.icon,
                    size: 64,
                    color: data.gradient[0],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),
          // Title
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isActive ? 1.0 : 0.5,
            child: Text(
              data.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          // Description
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isActive ? 1.0 : 0.5,
            child: Text(
              data.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Backwards compatible OnboardingPage widget
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Add playlist screen
class AddPlaylistScreen extends StatefulWidget {
  const AddPlaylistScreen({super.key});

  @override
  State<AddPlaylistScreen> createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends State<AddPlaylistScreen> {
  // M3U form
  final _m3uNameController = TextEditingController();
  final _m3uUrlController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _m3uNameController.dispose();
    _m3uUrlController.dispose();
    super.dispose();
  }

  Future<void> _addM3UPlaylist() async {
    if (_m3uNameController.text.isEmpty || _m3uUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final playlist = PlaylistSource(
      id: IdGenerator.generate(),
      name: _m3uNameController.text,
      url: _m3uUrlController.text,
      type: PlaylistSourceType.m3uUrl,
      addedAt: DateTime.now(),
    );

    context.read<PlaylistBloc>().add(AddPlaylistEvent(playlist));

    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Playlist'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add M3U Playlist',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the URL of your M3U playlist file',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _m3uNameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                hintText: 'My Playlist',
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _m3uUrlController,
              decoration: const InputDecoration(
                labelText: 'Playlist URL',
                hintText: 'http://example.com/playlist.m3u',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _addM3UPlaylist,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Playlist'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Connection options bottom sheet
class ConnectionOptionsSheet extends StatelessWidget {
  const ConnectionOptionsSheet({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.connect_without_contact, 
                  color: AppColors.primary, 
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Choose Connection Method',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Xtream Codes Option (Primary)
            _ConnectionOptionCard(
              icon: Icons.live_tv,
              iconColor: AppColors.primary,
              title: 'Xtream Codes',
              subtitle: 'Connect to your IPTV panel with credentials',
              badge: 'RECOMMENDED',
              onTap: () {
                onComplete();
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, AppRoutes.xtreamLogin);
              },
            ),
            
            const SizedBox(height: 12),

            // M3U Option (Secondary)
            _ConnectionOptionCard(
              icon: Icons.playlist_play,
              iconColor: AppColors.secondary,
              title: 'M3U Playlist',
              subtitle: 'Import a playlist URL or file',
              onTap: () {
                onComplete();
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, AppRoutes.addPlaylist);
              },
            ),

            const SizedBox(height: 16),

            // Skip option
            TextButton(
              onPressed: () {
                onComplete();
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              },
              child: const Text(
                'Skip for now',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Connection option card widget
class _ConnectionOptionCard extends StatelessWidget {
  const _ConnectionOptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: badge != null ? AppColors.primary : AppColors.border,
              width: badge != null ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

