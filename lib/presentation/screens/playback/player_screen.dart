import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/dependency_injection.dart';
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

/// Player screen state managing video playback, EPG display, and channel navigation
class _PlayerScreenState extends State<PlayerScreen> {
  late Channel _currentChannel;
  bool _showEpgOverlay = false;
  late PlayerBloc _playerBloc;

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
    _playerBloc = getIt<PlayerBloc>()..add(InitializePlayerEvent(_currentChannel));
  }

  @override
  void dispose() {
    _playerBloc.close();
    super.dispose();
  }

  /// Validates if a URL is safe to load (HTTPS only and not a local network address)
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    
    // Only allow HTTPS URLs (case-insensitive)
    if (uri.scheme.toLowerCase() != 'https') return false;
    
    final host = uri.host.toLowerCase();
    
    // Block localhost by name
    if (host == 'localhost') return false;
    
    // Try to parse as IP address
    final address = InternetAddress.tryParse(host);
    if (address != null) {
      // Check if it's a loopback address (127.0.0.1, ::1)
      if (address.isLoopback) return false;
      
      // Check if it's a link-local address (169.254.0.0/16, fe80::/10)
      if (address.isLinkLocal) return false;
      
      // For IPv4, check private ranges
      if (address.type == InternetAddressType.IPv4) {
        final bytes = address.rawAddress;
        
        // 10.0.0.0/8
        if (bytes[0] == 10) return false;
        
        // 172.16.0.0/12
        if (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) return false;
        
        // 192.168.0.0/16
        if (bytes[0] == 192 && bytes[1] == 168) return false;
      }
      
      // For IPv6, check unique local addresses (fc00::/7)
      if (address.type == InternetAddressType.IPv6) {
        final bytes = address.rawAddress;
        // fc00::/7 means first byte is 0xfc or 0xfd (252-253)
        if (bytes[0] >= 252 && bytes[0] <= 253) return false;
      }
    }
    
    return true;
  }

  /// Switch to a different channel and reinitialize player
  /// The PlayerBloc handles reinitialization through InitializePlayerEvent
  void _switchChannel(Channel newChannel) {
    setState(() {
      _currentChannel = newChannel;
    });
    // PlayerBloc is designed to handle reinitialization
    _playerBloc.add(InitializePlayerEvent(newChannel));
  }

  /// Navigate to the next channel in the channel list
  /// Only works when ChannelBloc is available and in loaded state
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

  /// Navigate to the previous channel in the channel list
  /// Only works when ChannelBloc is available and in loaded state
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
    return BlocProvider.value(
      value: _playerBloc,
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

  /// Builds a navigation button for channel switching (left/right)
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

  /// Builds the EPG overlay showing current and next program information
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
                    if (_currentChannel.logoUrl != null && 
                        _isValidImageUrl(_currentChannel.logoUrl))
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

  /// Formats a DateTime to HH:MM format
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Calculates program progress as a value between 0.0 and 1.0
  /// Returns 0.0 if program hasn't started, 1.0 if completed
  double _calculateProgress(DateTime start, DateTime end) {
    final now = DateTime.now();
    if (now.isBefore(start)) return 0.0;
    if (now.isAfter(end)) return 1.0; // Program completed
    
    final total = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
