import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/logger.dart';
import '../../../domain/entities/playlist_source.dart';
import '../../../domain/usecases/get_playlists.dart';
import '../../../domain/usecases/add_playlist.dart';

// Events
abstract class PlaylistEvent extends Equatable {
  const PlaylistEvent();

  @override
  List<Object?> get props => [];
}

class LoadPlaylistsEvent extends PlaylistEvent {
  const LoadPlaylistsEvent();
}

class AddPlaylistEvent extends PlaylistEvent {
  const AddPlaylistEvent(this.playlist);
  final PlaylistSource playlist;

  @override
  List<Object?> get props => [playlist];
}

class SelectPlaylistEvent extends PlaylistEvent {
  const SelectPlaylistEvent(this.playlistId);
  final String playlistId;

  @override
  List<Object?> get props => [playlistId];
}

class DeletePlaylistEvent extends PlaylistEvent {
  const DeletePlaylistEvent(this.playlistId);
  final String playlistId;

  @override
  List<Object?> get props => [playlistId];
}

class RefreshPlaylistEvent extends PlaylistEvent {
  const RefreshPlaylistEvent(this.playlistId);
  final String playlistId;

  @override
  List<Object?> get props => [playlistId];
}

// States
abstract class PlaylistState extends Equatable {
  const PlaylistState();

  @override
  List<Object?> get props => [];
}

class PlaylistInitialState extends PlaylistState {
  const PlaylistInitialState();
}

class PlaylistLoadingState extends PlaylistState {
  const PlaylistLoadingState();
}

class PlaylistLoadedState extends PlaylistState {
  const PlaylistLoadedState({
    required this.playlists,
    this.activePlaylist,
  });
  final List<PlaylistSource> playlists;
  final PlaylistSource? activePlaylist;

  @override
  List<Object?> get props => [playlists, activePlaylist];
}

class PlaylistErrorState extends PlaylistState {
  const PlaylistErrorState(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

// BLoC
class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  PlaylistBloc({
    required GetPlaylists getPlaylists,
    required AddPlaylist addPlaylist,
  })  : _getPlaylists = getPlaylists,
        _addPlaylist = addPlaylist,
        super(const PlaylistInitialState()) {
    on<LoadPlaylistsEvent>(_onLoadPlaylists);
    on<AddPlaylistEvent>(_onAddPlaylist);
    on<SelectPlaylistEvent>(_onSelectPlaylist);
    on<DeletePlaylistEvent>(_onDeletePlaylist);
    on<RefreshPlaylistEvent>(_onRefreshPlaylist);
  }
  final GetPlaylists _getPlaylists;
  final AddPlaylist _addPlaylist;

  Future<void> _onLoadPlaylists(
    LoadPlaylistsEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    emit(const PlaylistLoadingState());
    try {
      final playlists = await _getPlaylists();
      final activePlaylist = playlists.where((p) => p.isActive).firstOrNull ??
          playlists.firstOrNull;
      emit(
        PlaylistLoadedState(
          playlists: playlists,
          activePlaylist: activePlaylist,
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to load playlists', e);
      emit(PlaylistErrorState(e.toString()));
    }
  }

  Future<void> _onAddPlaylist(
    AddPlaylistEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    try {
      await _addPlaylist(event.playlist);
      add(const LoadPlaylistsEvent());
    } catch (e) {
      AppLogger.error('Failed to add playlist', e);
      emit(PlaylistErrorState(e.toString()));
    }
  }

  Future<void> _onSelectPlaylist(
    SelectPlaylistEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    if (state is PlaylistLoadedState) {
      final currentState = state as PlaylistLoadedState;
      final selected = currentState.playlists
          .where((p) => p.id == event.playlistId)
          .firstOrNull;
      emit(
        PlaylistLoadedState(
          playlists: currentState.playlists,
          activePlaylist: selected,
        ),
      );
    }
  }

  Future<void> _onDeletePlaylist(
    DeletePlaylistEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    add(const LoadPlaylistsEvent());
  }

  Future<void> _onRefreshPlaylist(
    RefreshPlaylistEvent event,
    Emitter<PlaylistState> emit,
  ) async {
    add(const LoadPlaylistsEvent());
  }
}
