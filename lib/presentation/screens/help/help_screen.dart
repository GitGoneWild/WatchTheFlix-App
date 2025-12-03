// Help Screen
// Provides user guidance for IPTV setup and playlist management.

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Help topics available in the app
enum HelpTopic {
  addingXtream,
  addingM3u,
  updatingPlaylists,
  refreshingEpg,
  managingFavorites,
  playerControls,
  troubleshooting,
}

/// Extension methods for HelpTopic
extension HelpTopicExtension on HelpTopic {
  String get title {
    switch (this) {
      case HelpTopic.addingXtream:
        return 'Adding Xtream Codes';
      case HelpTopic.addingM3u:
        return 'Adding M3U Playlists';
      case HelpTopic.updatingPlaylists:
        return 'Updating Playlists';
      case HelpTopic.refreshingEpg:
        return 'Refreshing EPG';
      case HelpTopic.managingFavorites:
        return 'Managing Favorites';
      case HelpTopic.playerControls:
        return 'Player Controls';
      case HelpTopic.troubleshooting:
        return 'Troubleshooting';
    }
  }

  IconData get icon {
    switch (this) {
      case HelpTopic.addingXtream:
        return Icons.cloud_upload;
      case HelpTopic.addingM3u:
        return Icons.playlist_add;
      case HelpTopic.updatingPlaylists:
        return Icons.sync;
      case HelpTopic.refreshingEpg:
        return Icons.schedule;
      case HelpTopic.managingFavorites:
        return Icons.favorite;
      case HelpTopic.playerControls:
        return Icons.play_circle;
      case HelpTopic.troubleshooting:
        return Icons.help_outline;
    }
  }
}

/// Help screen with guides for app features
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome section
          _buildWelcomeSection(),
          const SizedBox(height: 24),

          // Help topics
          _buildTopicCard(
            context,
            topic: HelpTopic.addingXtream,
            onTap: () => _navigateToTopic(context, HelpTopic.addingXtream),
          ),
          const SizedBox(height: 12),
          _buildTopicCard(
            context,
            topic: HelpTopic.addingM3u,
            onTap: () => _navigateToTopic(context, HelpTopic.addingM3u),
          ),
          const SizedBox(height: 12),
          _buildTopicCard(
            context,
            topic: HelpTopic.updatingPlaylists,
            onTap: () => _navigateToTopic(context, HelpTopic.updatingPlaylists),
          ),
          const SizedBox(height: 12),
          _buildTopicCard(
            context,
            topic: HelpTopic.refreshingEpg,
            onTap: () => _navigateToTopic(context, HelpTopic.refreshingEpg),
          ),
          const SizedBox(height: 12),
          _buildTopicCard(
            context,
            topic: HelpTopic.managingFavorites,
            onTap: () => _navigateToTopic(context, HelpTopic.managingFavorites),
          ),
          const SizedBox(height: 12),
          _buildTopicCard(
            context,
            topic: HelpTopic.playerControls,
            onTap: () => _navigateToTopic(context, HelpTopic.playerControls),
          ),
          const SizedBox(height: 12),
          _buildTopicCard(
            context,
            topic: HelpTopic.troubleshooting,
            onTap: () => _navigateToTopic(context, HelpTopic.troubleshooting),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 28),
              SizedBox(width: 12),
              Text(
                'Welcome to Help',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Get help with WatchTheFlix features. Tap any topic below to learn more.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(
    BuildContext context, {
    required HelpTopic topic,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                topic.icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                topic.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTopic(BuildContext context, HelpTopic topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HelpTopicDetailScreen(topic: topic),
      ),
    );
  }
}

/// Detail screen for a specific help topic
class HelpTopicDetailScreen extends StatelessWidget {
  const HelpTopicDetailScreen({super.key, required this.topic});

  final HelpTopic topic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(topic.title),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _buildTopicContent(topic),
      ),
    );
  }

  List<Widget> _buildTopicContent(HelpTopic topic) {
    switch (topic) {
      case HelpTopic.addingXtream:
        return _buildXtreamGuide();
      case HelpTopic.addingM3u:
        return _buildM3uGuide();
      case HelpTopic.updatingPlaylists:
        return _buildUpdateGuide();
      case HelpTopic.refreshingEpg:
        return _buildEpgGuide();
      case HelpTopic.managingFavorites:
        return _buildFavoritesGuide();
      case HelpTopic.playerControls:
        return _buildPlayerGuide();
      case HelpTopic.troubleshooting:
        return _buildTroubleshootingGuide();
    }
  }

  List<Widget> _buildXtreamGuide() {
    return [
      _buildSection(
        title: 'What is Xtream Codes?',
        content:
            'Xtream Codes is an IPTV panel system used by many IPTV service providers. '
            'Your provider will give you a server URL, username, and password.',
      ),
      _buildStepSection(
        title: 'Adding Xtream Codes',
        steps: [
          'Tap Settings from the home screen',
          'Select "Add Playlist" and choose "Xtream Codes"',
          'Enter your Server URL (e.g., http://example.com:8080)',
          'Enter your Username',
          'Enter your Password',
          'Tap "Connect"',
          'Wait for channels, movies, and series to load',
          'Once complete, you\'ll be redirected to the home screen',
        ],
      ),
      _buildTipBox(
        'The app will load content in parallel for faster setup. EPG (TV guide) '
        'updates continue in the background even after you start watching.',
      ),
    ];
  }

  List<Widget> _buildM3uGuide() {
    return [
      _buildSection(
        title: 'What is M3U?',
        content:
            'M3U is a playlist file format commonly used for IPTV. It contains a list of '
            'channels and their stream URLs.',
      ),
      _buildStepSection(
        title: 'Adding M3U Playlist',
        steps: [
          'Tap Settings from the home screen',
          'Select "Add Playlist" and choose "M3U"',
          'Choose import method: URL or File',
          'For URL: Enter the playlist URL and tap "Import"',
          'For File: Browse and select your M3U file',
          'Wait for the playlist to be parsed',
          'Channels will appear in Live TV section',
        ],
      ),
      _buildTipBox(
        'M3U playlists can be updated by importing them again. '
        'The app will replace the old playlist with the new one.',
      ),
    ];
  }

  List<Widget> _buildUpdateGuide() {
    return [
      _buildSection(
        title: 'Keeping Playlists Up-to-Date',
        content:
            'IPTV providers may update channels, add new content, or change stream URLs. '
            'Regular updates ensure you have the latest content.',
      ),
      _buildStepSection(
        title: 'Updating Xtream Codes',
        steps: [
          'Go to Settings',
          'Find your Xtream connection',
          'Tap "Refresh" or "Update"',
          'The app will fetch the latest content',
          'Your credentials are saved, so no need to re-enter',
        ],
      ),
      _buildStepSection(
        title: 'Updating M3U Playlists',
        steps: [
          'Go to Settings',
          'Remove the old M3U playlist',
          'Add the playlist again (URL or File)',
          'Alternatively, import the same URL again to replace',
        ],
      ),
      _buildTipBox(
        'For Xtream Codes, updates are automatic and non-blocking. '
        'You can continue watching while content refreshes.',
      ),
    ];
  }

  List<Widget> _buildEpgGuide() {
    return [
      _buildSection(
        title: 'What is EPG?',
        content:
            'EPG (Electronic Program Guide) shows what\'s currently playing and coming up next '
            'on live TV channels.',
      ),
      _buildStepSection(
        title: 'EPG Features',
        steps: [
          'EPG loads automatically with Xtream Codes',
          'Shows current and next program info',
          'Updates in the background without blocking',
          'Available on the player info overlay',
        ],
      ),
      _buildStepSection(
        title: 'Refreshing EPG Manually',
        steps: [
          'Go to Settings',
          'Find EPG settings',
          'Tap "Refresh EPG"',
          'EPG data will update in the background',
        ],
      ),
      _buildTipBox(
        'EPG data is cached locally for faster access. '
        'It refreshes automatically when you update your playlist.',
      ),
    ];
  }

  List<Widget> _buildFavoritesGuide() {
    return [
      _buildSection(
        title: 'Managing Favorites',
        content:
            'Save your favorite channels for quick access. Favorites sync across app restarts.',
      ),
      _buildStepSection(
        title: 'Adding Favorites',
        steps: [
          'Long-press on any channel card',
          'Or tap the star icon in the channel details',
          'The channel is added to your Favorites list',
        ],
      ),
      _buildStepSection(
        title: 'Viewing Favorites',
        steps: [
          'Go to Live TV section',
          'Select "Favorites" from the category list',
          'All your favorite channels appear here',
        ],
      ),
      _buildStepSection(
        title: 'Removing Favorites',
        steps: [
          'Long-press the channel again',
          'Or tap the filled star icon',
          'Channel is removed from Favorites',
        ],
      ),
    ];
  }

  List<Widget> _buildPlayerGuide() {
    return [
      _buildSection(
        title: 'Modern Player Controls',
        content:
            'WatchTheFlix includes a comprehensive video player with gesture controls and modern features.',
      ),
      _buildStepSection(
        title: 'Basic Controls',
        steps: [
          'Tap once to show/hide controls',
          'Tap Play/Pause to control playback',
          'Use the progress bar to seek (VOD only)',
          'Tap fullscreen button to toggle orientation',
        ],
      ),
      _buildStepSection(
        title: 'Gesture Controls',
        steps: [
          'Double-tap left side to rewind 10 seconds',
          'Double-tap right side to forward 10 seconds',
          'Double-tap center to play/pause',
          'Controls auto-hide after 5 seconds',
        ],
      ),
      _buildStepSection(
        title: 'Live TV Features',
        steps: [
          'Swipe left/right to change channels',
          'Tap info button to see EPG overlay',
          'EPG shows current and next program',
        ],
      ),
      _buildTipBox(
        'The player automatically retries on errors and handles buffering gracefully. '
        'For Live TV, seeking is disabled as it\'s a live stream.',
      ),
    ];
  }

  List<Widget> _buildTroubleshootingGuide() {
    return [
      _buildSection(
        title: 'Common Issues',
        content:
            'Solutions to common problems you might encounter while using WatchTheFlix.',
      ),
      _buildProblemSolution(
        problem: 'Video won\'t play',
        solutions: [
          'Check your internet connection',
          'Verify your IPTV subscription is active',
          'Try a different channel to test',
          'Update your playlist/Xtream connection',
          'Contact your IPTV provider if issue persists',
        ],
      ),
      _buildProblemSolution(
        problem: 'Buffering issues',
        solutions: [
          'Check your internet speed (5+ Mbps recommended)',
          'Try connecting via WiFi instead of mobile data',
          'Close other apps using bandwidth',
          'Try a different stream quality if available',
        ],
      ),
      _buildProblemSolution(
        problem: 'EPG not showing',
        solutions: [
          'Wait for background EPG loading to complete',
          'Check if your provider includes EPG data',
          'Try refreshing EPG from settings',
          'EPG may not be available for all providers',
        ],
      ),
      _buildProblemSolution(
        problem: 'Authentication failed',
        solutions: [
          'Double-check your username and password',
          'Verify the server URL is correct',
          'Ensure your subscription is active',
          'Contact your IPTV provider for support',
        ],
      ),
      _buildTipBox(
        'Most playback issues are related to network connectivity or provider problems. '
        'If you continue to experience issues, contact your IPTV service provider.',
      ),
    ];
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStepSection({required String title, required List<String> steps}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProblemSolution({
    required String problem,
    required List<String> solutions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                problem,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...solutions.map((solution) {
          return Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    solution,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTipBox(String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
