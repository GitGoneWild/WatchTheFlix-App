import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';

/// Video player widget with controls
class VideoPlayerWidget extends StatefulWidget {
  final String url;
  final String? title;
  final bool allowPip;
  final bool autoRetry;
  final bool autoPlay;
  final VoidCallback? onBack;

  const VideoPlayerWidget({
    super.key,
    required this.url,
    this.title,
    this.allowPip = true,
    this.autoRetry = true,
    this.autoPlay = true,
    this.onBack,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isBuffering = false;
  bool _hasError = false;
  bool _showControls = true;
  bool _isFullscreen = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        httpHeaders: const {
          'User-Agent': 'WatchTheFlix/1.0',
        },
      );

      _controller.addListener(_onPlayerUpdate);

      await _controller.initialize();

      if (widget.autoPlay) {
        await _controller.play();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
        if (widget.autoRetry && _retryCount < _maxRetries) {
          _retryCount++;
          Future.delayed(const Duration(seconds: 2), _initializePlayer);
        }
      }
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
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
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
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    } catch (_) {
      // Ignore system UI errors on unsupported platforms
    }
  }

  void _seekRelative(Duration offset) {
    final newPosition = _controller.value.position + offset;
    _controller.seekTo(newPosition);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _controller.value.isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerUpdate);
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      onDoubleTapDown: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        final tapPosition = details.localPosition.dx;

        if (tapPosition < screenWidth / 3) {
          _seekRelative(const Duration(seconds: -10));
        } else if (tapPosition > screenWidth * 2 / 3) {
          _seekRelative(const Duration(seconds: 10));
        }
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video
            if (_isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),

            // Loading indicator
            if (!_isInitialized || _isBuffering)
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),

            // Error message
            if (_hasError && _retryCount >= _maxRetries)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load video',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _retryCount = 0;
                          _hasError = false;
                        });
                        _initializePlayer();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

            // Controls overlay
            if (_showControls && _isInitialized) _buildControls(),
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: widget.onBack ?? () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white, size: 36),
                onPressed: () => _seekRelative(const Duration(seconds: -10)),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 64,
                ),
                onPressed: _togglePlayPause,
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
                onPressed: () => _seekRelative(const Duration(seconds: 10)),
              ),
            ],
          ),

          // Bottom bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Progress bar
                  VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: AppColors.primary,
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_controller.value.position.format()} / ${_controller.value.duration.format()}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Row(
                        children: [
                          if (widget.allowPip)
                            IconButton(
                              icon: const Icon(
                                Icons.picture_in_picture_alt,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                // PiP implementation would go here
                              },
                            ),
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
          ),
        ],
      ),
    );
  }
}
