import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/channel.dart';
import '../../blocs/channel/channel_bloc.dart';
import '../../blocs/player/player_bloc.dart';
import '../../widgets/video_player_widget.dart';

/// Player screen for video playback with EPG and channel navigation
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.channel,
  });
  final Channel channel;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late Channel _currentChannel;
  bool _showEpgOverlay = false;

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
  }

  void _switchChannel(Channel newChannel) {
    setState(() {
      _currentChannel = newChannel;
    });
    context.read<PlayerBloc>().add(InitializePlayerEvent(newChannel));
  }

  void _navigateToNextChannel() {
    try {
      final channelBloc = context.read<ChannelBloc>();
      if (channelBloc.state is ChannelLoadedState) {
        final state = channelBloc.state as ChannelLoadedState;
        final channels = state.filteredChannels;
        final currentIndex = channels.indexWhere((c) => c.id == _currentChannel.id);
        if (currentIndex != -1 && currentIndex < channels.length - 1) {
          _switchChannel(channels[currentIndex + 1]);
        }
      }
    } catch (e) {
      // ChannelBloc not available in context
      // This can happen when navigating directly to player
    }
  }

  void _navigateToPreviousChannel() {
    try {
      final channelBloc = context.read<ChannelBloc>();
      if (channelBloc.state is ChannelLoadedState) {
        final state = channelBloc.state as ChannelLoadedState;
        final channels = state.filteredChannels;
        final currentIndex = channels.indexWhere((c) => c.id == _currentChannel.id);
        if (currentIndex > 0) {
          _switchChannel(channels[currentIndex - 1]);
        }
      }
    } catch (e) {
      // ChannelBloc not available in context
      // This can happen when navigating directly to player
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayerBloc()..add(InitializePlayerEvent(_currentChannel)),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Video player
            VideoPlayerWidget(
              url: _currentChannel.streamUrl,
              title: _currentChannel.name,
              onBack: () => Navigator.pop(context),
            ),

            // EPG overlay (shown when user taps info button)
            if (_showEpgOverlay) _buildEpgOverlay(),

            // Channel navigation controls (overlay on sides)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _buildNavigationButton(
                icon: Icons.chevron_left,
                onTap: _navigateToPreviousChannel,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _buildNavigationButton(
                icon: Icons.chevron_right,
                onTap: _navigateToNextChannel,
              ),
            ),

            // Info button to toggle EPG overlay
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: IconButton(
                  icon: Icon(
                    _showEpgOverlay ? Icons.info : Icons.info_outline,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _showEpgOverlay = !_showEpgOverlay;
                    });
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        color: Colors.transparent,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.7),
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEpgOverlay() {
    final epgInfo = _currentChannel.epgInfo;
    
    return Positioned(
      left: 16,
      right: 16,
      bottom: 100,
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showEpgOverlay = false;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel info
                Row(
                  children: [
                    if (_currentChannel.logoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _currentChannel.logoUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.live_tv,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.live_tv,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentChannel.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_currentChannel.groupTitle != null)
                            Text(
                              _currentChannel.groupTitle!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (epgInfo != null) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),

                  // Now Playing
                  if (epgInfo.currentProgram != null) ...[
                    const Row(
                      children: [
                        Icon(
                          Icons.play_circle_filled,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Now Playing',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      epgInfo.currentProgram!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (epgInfo.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        epgInfo.description!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (epgInfo.startTime != null && epgInfo.endTime != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatTime(epgInfo.startTime!)} - ${_formatTime(epgInfo.endTime!)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          // Progress indicator
                          Container(
                            width: 100,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _calculateProgress(
                                epgInfo.startTime!,
                                epgInfo.endTime!,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],

                  // Up Next
                  if (epgInfo.nextProgram != null) ...[
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(
                          Icons.upcoming,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Up Next',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      epgInfo.nextProgram!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'No program guide available',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Tap anywhere to close',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  double _calculateProgress(DateTime start, DateTime end) {
    final now = DateTime.now();
    if (now.isBefore(start) || now.isAfter(end)) return 0.0;
    
    final total = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
