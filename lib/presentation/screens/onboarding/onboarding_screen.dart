import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/playlist_source.dart';
import '../../blocs/playlist/playlist_bloc.dart';

/// Onboarding screen for first-time setup
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      title: 'Welcome to WatchTheFlix',
      description:
          'Your ultimate IPTV streaming experience. Watch live TV, movies, and series on any device.',
      icon: Icons.tv,
    ),
    const OnboardingPage(
      title: 'Add Your Playlists',
      description:
          'Import your M3U playlists or connect with Xtream Codes API for seamless streaming.',
      icon: Icons.playlist_add,
    ),
    const OnboardingPage(
      title: 'Enjoy Anywhere',
      description:
          'Stream on mobile, tablet, desktop, or web. Your content, your way.',
      icon: Icons.devices,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/add-playlist');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/add-playlist');
                },
                child: const Text('Skip'),
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
                itemBuilder: (context, index) => _pages[index],
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(4),
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
                child: ElevatedButton(
                  onPressed: _onNextPage,
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

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
              color: AppColors.primary.withOpacity(0.1),
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

class _AddPlaylistScreenState extends State<AddPlaylistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // M3U form
  final _m3uNameController = TextEditingController();
  final _m3uUrlController = TextEditingController();

  // Xtream form
  final _xtreamNameController = TextEditingController();
  final _xtreamHostController = TextEditingController();
  final _xtreamUsernameController = TextEditingController();
  final _xtreamPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _m3uNameController.dispose();
    _m3uUrlController.dispose();
    _xtreamNameController.dispose();
    _xtreamHostController.dispose();
    _xtreamUsernameController.dispose();
    _xtreamPasswordController.dispose();
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
      isActive: true,
    );

    context.read<PlaylistBloc>().add(AddPlaylistEvent(playlist));

    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _addXtreamPlaylist() async {
    if (_xtreamNameController.text.isEmpty ||
        _xtreamHostController.text.isEmpty ||
        _xtreamUsernameController.text.isEmpty ||
        _xtreamPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final credentials = XtreamCredentials(
      host: _xtreamHostController.text,
      username: _xtreamUsernameController.text,
      password: _xtreamPasswordController.text,
    );

    final playlist = PlaylistSource(
      id: IdGenerator.generate(),
      name: _xtreamNameController.text,
      url: _xtreamHostController.text,
      type: PlaylistSourceType.xtream,
      addedAt: DateTime.now(),
      xtreamCredentials: credentials,
      isActive: true,
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'M3U Playlist'),
            Tab(text: 'Xtream Codes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // M3U Tab
          SingleChildScrollView(
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
                Text(
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

          // Xtream Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Connect to Xtream Codes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your Xtream Codes API credentials',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _xtreamNameController,
                  decoration: const InputDecoration(
                    labelText: 'Connection Name',
                    hintText: 'My IPTV Provider',
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _xtreamHostController,
                  decoration: const InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'http://server.com:port',
                    prefixIcon: Icon(Icons.dns),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _xtreamUsernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _xtreamPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addXtreamPlaylist,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Connect'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
