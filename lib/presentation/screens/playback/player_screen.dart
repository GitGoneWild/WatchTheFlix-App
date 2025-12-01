import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/channel.dart';
import '../../blocs/player/player_bloc.dart';
import '../../widgets/video_player_widget.dart';

/// Player screen for video playback
class PlayerScreen extends StatelessWidget {
  final Channel channel;

  const PlayerScreen({
    super.key,
    required this.channel,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayerBloc()..add(InitializePlayerEvent(channel)),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: VideoPlayerWidget(
          url: channel.streamUrl,
          title: channel.name,
          allowPip: true,
          autoRetry: true,
          autoPlay: true,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
