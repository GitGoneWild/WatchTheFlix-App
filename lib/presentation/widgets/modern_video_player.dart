// Modern Video Player
// A comprehensive, modular video player with advanced features for IPTV streaming.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';

/// Content type for the player
enum PlayerContentType {
  liveTV,
  movie,
  series,
}

/// Player configuration
class PlayerConfig {
  const PlayerConfig({
    this.contentType = PlayerContentType.liveTV,
    this.autoPlay = true,
    this.autoRetry = true,
    this.maxRetries = 3,
    this.allowPip = true,
    this.showControls = true,
    this.enableGestures = true,
    this.retryDelay = const Duration(seconds: 2),
  });

  final PlayerContentType contentType;
  final bool autoPlay;
  final bool autoRetry;
  final int maxRetries;
  final bool allowPip;
  final bool showControls;
  final bool enableGestures;
  final Duration retryDelay;

  PlayerConfig copyWith({
    PlayerContentType? contentType,
    bool? autoPlay,
    bool? autoRetry,
    int? maxRetries,
    bool? allowPip,
    bool? showControls,
    bool? enableGestures,
    Duration? retryDelay,
  }) {
    return PlayerConfig(
      contentType: contentType ?? this.contentType,
      autoPlay: autoPlay ?? this.autoPlay,
      autoRetry: autoRetry ?? this.autoRetry,
      maxRetries: maxRetries ?? this.maxRetries,
      allowPip: allowPip ?? this.allowPip,
      showControls: showControls ?? this.showControls,
      enableGestures: enableGestures ?? this.enableGestures,
      retryDelay: retryDelay ?? this.retryDelay,
    );
  }
}

/// Callback for player events
typedef PlayerCallback = void Function();
typedef PlayerErrorCallback = void Function(String error);

/// Modern video player widget with comprehensive controls
class ModernVideoPlayer extends StatefulWidget {
  const ModernVideoPlayer({
    super.key,
    required this.url,
    this.title,
    this.config = const PlayerConfig(),
    this.onBack,
    this.onError,
    this.onPlayPause,
    this.onSeek,
    this.metadata,
  });

  final String url;
  final String? title;
  final PlayerConfig config;
  final PlayerCallback? onBack;
  final PlayerErrorCallback? onError;
  final PlayerCallback? onPlayPause;
  final ValueChanged<Duration>? onSeek;
  final Map<String, dynamic>? metadata;

  // Constants for gesture-based seeking
  static const int _maxSeekSeconds = 60;
  static const double _seekSensitivity = 60.0; // seconds per screen width

  @override
  State<ModernVideoPlayer> createState() => _ModernVideoPlayerState();
}

class _ModernVideoPlayerState extends State<ModernVideoPlayer>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isBuffering = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _showControls = true;
  bool _isFullscreen = false;
  int _retryCount = 0;
  Timer? _hideControlsTimer;
  Timer? _progressUpdateTimer;
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;

  @override
  void initState() {
    super.initState();
    _controlsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controlsAnimation = CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    );
    _initializePlayer();
  }

  @override
  void didUpdateWidget(ModernVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _retryCount = 0;
      _disposePlayer();
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        httpHeaders: {
          'User-Agent': 'WatchTheFlix/1.0',
          'Accept': '*/*',
        },
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      _controller.addListener(_onPlayerUpdate);

      await _controller.initialize();

      if (widget.config.autoPlay && mounted) {
        await _controller.play();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
        _startProgressUpdates();
        if (widget.config.showControls) {
          _showControlsWithTimer();
        }
      }
    } catch (e) {
      _handleError('Failed to initialize player: ${e.toString()}');
    }
  }

  void _handleError(String error) {
    if (!mounted) return;

    setState(() {
      _hasError = true;
      _errorMessage = error;
    });

    widget.onError?.call(error);

    if (widget.config.autoRetry && _retryCount < widget.config.maxRetries) {
      _retryCount++;
      Future.delayed(widget.config.retryDelay, () {
        if (mounted) {
          _initializePlayer();
        }
      });
    }
  }

  void _onPlayerUpdate() {
    if (!mounted) return;

    final isBuffering = _controller.value.isBuffering;
    if (isBuffering != _isBuffering) {
      setState(() {
        _isBuffering = isBuffering;
      });
    }

    if (_controller.value.hasError) {
      _handleError(_controller.value.errorDescription ?? 'Unknown error');
    }
  }

  void _startProgressUpdates() {
    _progressUpdateTimer?.cancel();
    _progressUpdateTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) {
        if (mounted && _isInitialized) {
          setState(() {}); // Update progress bar
        }
      },
    );
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;

    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    widget.onPlayPause?.call();
    setState(() {});
  }

  Future<void> _toggleFullscreen() async {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    try {
      if (_isFullscreen) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      }
    } catch (e) {
      // Ignore system UI errors on unsupported platforms
    }
  }

  void _seekRelative(Duration offset) {
    if (!_isInitialized) return;

    final currentPosition = _controller.value.position;
    final duration = _controller.value.duration;
    
    // Skip seeking if duration is not available (e.g., live streams)
    if (duration.inMilliseconds <= 0) {
      return;
    }

    final newPosition = currentPosition + offset;
    final clampedPosition = newPosition.clamp(
      Duration.zero,
      duration,
    );
    _controller.seekTo(clampedPosition);
    widget.onSeek?.call(clampedPosition);
    _showControlsWithTimer();
  }

  void _seekTo(Duration position) {
    if (!_isInitialized) return;

    _controller.seekTo(position);
    widget.onSeek?.call(position);
  }

  void _showControlsWithTimer() {
    setState(() {
      _showControls = true;
    });
    _controlsAnimationController.forward();

    _hideControlsTimer?.cancel();
    if (_isInitialized && _controller.value.isPlaying) {
      _hideControlsTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _controller.value.isPlaying) {
          setState(() {
            _showControls = false;
          });
          _controlsAnimationController.reverse();
        }
      });
    }
  }

  void _toggleControls() {
    if (_showControls) {
      setState(() {
        _showControls = false;
      });
      _controlsAnimationController.reverse();
      _hideControlsTimer?.cancel();
    } else {
      _showControlsWithTimer();
    }
  }

  // Handle gesture-based seeking
  void _handleHorizontalDrag(double dx, double screenWidth) {
    if (!_isInitialized || !widget.config.enableGestures) return;

    // Calculate seek amount based on drag distance
    // Full screen width = +/- configured max seek seconds
    final seekSeconds = (dx / screenWidth) * ModernVideoPlayer._seekSensitivity;
    _seekRelative(Duration(seconds: seekSeconds.round()));
  }

  // Handle gesture-based volume (not implemented in base video_player)
  void _handleVerticalDrag(double dy, double screenHeight) {
    if (!_isInitialized || !widget.config.enableGestures) return;
    // Volume control would go here if supported by the player
    // For now, just show controls
    _showControlsWithTimer();
  }

  void _disposePlayer() {
    _hideControlsTimer?.cancel();
    _progressUpdateTimer?.cancel();
    _controller.removeListener(_onPlayerUpdate);
    _controller.dispose();
  }

  @override
  void dispose() {
    _disposePlayer();
    _controlsAnimationController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.config.showControls ? _toggleControls : null,
      onDoubleTapDown: widget.config.enableGestures
          ? (details) {
              final screenWidth = MediaQuery.of(context).size.width;
              final tapPosition = details.localPosition.dx;

              if (tapPosition < screenWidth / 3) {
                _seekRelative(const Duration(seconds: -10));
              } else if (tapPosition > screenWidth * 2 / 3) {
                _seekRelative(const Duration(seconds: 10));
              } else {
                _togglePlayPause();
              }
            }
          : null,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video
            if (_isInitialized && !_hasError)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),

            // Loading indicator
            if ((!_isInitialized || _isBuffering) && !_hasError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                    if (_isBuffering) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Buffering...',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Error view
            if (_hasError) _buildErrorView(),

            // Controls overlay
            if (_showControls && _isInitialized && !_hasError)
              FadeTransition(
                opacity: _controlsAnimation,
                child: _buildControls(),
              ),

            // Always visible back button when controls are hidden
            if (!_showControls || !_isInitialized || _hasError)
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 24),
            const Text(
              'Playback Error',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Failed to load video',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_retryCount >= widget.config.maxRetries) ...[
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _retryCount = 0;
                  });
                  _initializePlayer();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ] else ...[
              Text(
                'Retrying... (${_retryCount}/${widget.config.maxRetries})',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top bar
          _buildTopBar(),

          // Center controls
          _buildCenterControls(),

          // Bottom bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.config.contentType == PlayerContentType.liveTV)
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Only show seek buttons for VOD content
        if (widget.config.contentType != PlayerContentType.liveTV) ...[
          _buildControlButton(
            icon: Icons.replay_10,
            onPressed: () => _seekRelative(const Duration(seconds: -10)),
            size: 36,
          ),
          const SizedBox(width: 24),
        ],
        _buildControlButton(
          icon: _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          onPressed: _togglePlayPause,
          size: 64,
        ),
        if (widget.config.contentType != PlayerContentType.liveTV) ...[
          const SizedBox(width: 24),
          _buildControlButton(
            icon: Icons.forward_10,
            onPressed: () => _seekRelative(const Duration(seconds: 10)),
            size: 36,
          ),
        ],
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 48,
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: size),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildBottomBar() {
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    final isLive = widget.config.contentType == PlayerContentType.liveTV;
    final hasDuration = duration.inMilliseconds > 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress bar (only for VOD content with valid duration)
            if (!isLive && hasDuration) ...[
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withOpacity(0.3),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                ),
                child: Slider(
                  value: position.inMilliseconds.toDouble().clamp(
                        0.0,
                        duration.inMilliseconds.toDouble(),
                      ),
                  min: 0,
                  max: duration.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    _seekTo(Duration(milliseconds: value.toInt()));
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Time display
                Text(
                  isLive
                      ? 'LIVE'
                      : '${position.format()} / ${duration.format()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    // PiP button (if supported)
                    if (widget.config.allowPip && !isLive)
                      IconButton(
                        icon: const Icon(
                          Icons.picture_in_picture_alt,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // PiP implementation would go here
                          // This requires platform-specific implementation
                        },
                      ),
                    // Fullscreen button
                    IconButton(
                      icon: Icon(
                        _isFullscreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        color: Colors.white,
                      ),
                      onPressed: _toggleFullscreen,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
