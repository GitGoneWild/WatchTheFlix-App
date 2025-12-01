import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/channel.dart';

// Events
abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class InitializePlayerEvent extends PlayerEvent {
  final Channel channel;

  const InitializePlayerEvent(this.channel);

  @override
  List<Object?> get props => [channel];
}

class PlayEvent extends PlayerEvent {
  const PlayEvent();
}

class PauseEvent extends PlayerEvent {
  const PauseEvent();
}

class SeekEvent extends PlayerEvent {
  final Duration position;

  const SeekEvent(this.position);

  @override
  List<Object?> get props => [position];
}

class SetVolumeEvent extends PlayerEvent {
  final double volume;

  const SetVolumeEvent(this.volume);

  @override
  List<Object?> get props => [volume];
}

class ToggleFullscreenEvent extends PlayerEvent {
  const ToggleFullscreenEvent();
}

class TogglePiPEvent extends PlayerEvent {
  const TogglePiPEvent();
}

class ChangeQualityEvent extends PlayerEvent {
  final String quality;

  const ChangeQualityEvent(this.quality);

  @override
  List<Object?> get props => [quality];
}

class PlayerErrorEvent extends PlayerEvent {
  final String message;

  const PlayerErrorEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class DisposePlayerEvent extends PlayerEvent {
  const DisposePlayerEvent();
}

// States
abstract class PlayerState extends Equatable {
  const PlayerState();

  @override
  List<Object?> get props => [];
}

class PlayerInitialState extends PlayerState {
  const PlayerInitialState();
}

class PlayerLoadingState extends PlayerState {
  final Channel channel;

  const PlayerLoadingState(this.channel);

  @override
  List<Object?> get props => [channel];
}

class PlayerPlayingState extends PlayerState {
  final Channel channel;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool isFullscreen;
  final bool isPiP;
  final String? quality;
  final bool isBuffering;

  const PlayerPlayingState({
    required this.channel,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.isFullscreen = false,
    this.isPiP = false,
    this.quality,
    this.isBuffering = false,
  });

  PlayerPlayingState copyWith({
    Channel? channel,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? isFullscreen,
    bool? isPiP,
    String? quality,
    bool? isBuffering,
  }) {
    return PlayerPlayingState(
      channel: channel ?? this.channel,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isPiP: isPiP ?? this.isPiP,
      quality: quality ?? this.quality,
      isBuffering: isBuffering ?? this.isBuffering,
    );
  }

  @override
  List<Object?> get props => [
        channel,
        position,
        duration,
        volume,
        isFullscreen,
        isPiP,
        quality,
        isBuffering,
      ];
}

class PlayerPausedState extends PlayerState {
  final Channel channel;
  final Duration position;
  final Duration duration;

  const PlayerPausedState({
    required this.channel,
    required this.position,
    required this.duration,
  });

  @override
  List<Object?> get props => [channel, position, duration];
}

class PlayerErrorState extends PlayerState {
  final String message;
  final Channel? channel;

  const PlayerErrorState({
    required this.message,
    this.channel,
  });

  @override
  List<Object?> get props => [message, channel];
}

// BLoC
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  PlayerBloc() : super(const PlayerInitialState()) {
    on<InitializePlayerEvent>(_onInitializePlayer);
    on<PlayEvent>(_onPlay);
    on<PauseEvent>(_onPause);
    on<SeekEvent>(_onSeek);
    on<SetVolumeEvent>(_onSetVolume);
    on<ToggleFullscreenEvent>(_onToggleFullscreen);
    on<TogglePiPEvent>(_onTogglePiP);
    on<ChangeQualityEvent>(_onChangeQuality);
    on<PlayerErrorEvent>(_onPlayerError);
    on<DisposePlayerEvent>(_onDisposePlayer);
  }

  void _onInitializePlayer(
    InitializePlayerEvent event,
    Emitter<PlayerState> emit,
  ) {
    emit(PlayerLoadingState(event.channel));
    emit(PlayerPlayingState(channel: event.channel, isBuffering: true));
    emit(PlayerPlayingState(channel: event.channel, isBuffering: false));
  }

  void _onPlay(PlayEvent event, Emitter<PlayerState> emit) {
    if (state is PlayerPausedState) {
      final pausedState = state as PlayerPausedState;
      emit(PlayerPlayingState(
        channel: pausedState.channel,
        position: pausedState.position,
        duration: pausedState.duration,
      ));
    }
  }

  void _onPause(PauseEvent event, Emitter<PlayerState> emit) {
    if (state is PlayerPlayingState) {
      final playingState = state as PlayerPlayingState;
      emit(PlayerPausedState(
        channel: playingState.channel,
        position: playingState.position,
        duration: playingState.duration,
      ));
    }
  }

  void _onSeek(SeekEvent event, Emitter<PlayerState> emit) {
    if (state is PlayerPlayingState) {
      emit((state as PlayerPlayingState).copyWith(position: event.position));
    }
  }

  void _onSetVolume(SetVolumeEvent event, Emitter<PlayerState> emit) {
    if (state is PlayerPlayingState) {
      emit((state as PlayerPlayingState).copyWith(volume: event.volume));
    }
  }

  void _onToggleFullscreen(
    ToggleFullscreenEvent event,
    Emitter<PlayerState> emit,
  ) {
    if (state is PlayerPlayingState) {
      final currentState = state as PlayerPlayingState;
      emit(currentState.copyWith(isFullscreen: !currentState.isFullscreen));
    }
  }

  void _onTogglePiP(TogglePiPEvent event, Emitter<PlayerState> emit) {
    if (state is PlayerPlayingState) {
      final currentState = state as PlayerPlayingState;
      emit(currentState.copyWith(isPiP: !currentState.isPiP));
    }
  }

  void _onChangeQuality(
    ChangeQualityEvent event,
    Emitter<PlayerState> emit,
  ) {
    if (state is PlayerPlayingState) {
      emit((state as PlayerPlayingState).copyWith(quality: event.quality));
    }
  }

  void _onPlayerError(PlayerErrorEvent event, Emitter<PlayerState> emit) {
    final currentChannel =
        state is PlayerPlayingState
            ? (state as PlayerPlayingState).channel
            : state is PlayerLoadingState
                ? (state as PlayerLoadingState).channel
                : null;
    emit(PlayerErrorState(message: event.message, channel: currentChannel));
  }

  void _onDisposePlayer(DisposePlayerEvent event, Emitter<PlayerState> emit) {
    emit(const PlayerInitialState());
  }
}
