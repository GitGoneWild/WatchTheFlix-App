import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/logger.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/repositories/channel_repository.dart';

// Events
abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

class LoadFavoritesEvent extends FavoritesEvent {
  const LoadFavoritesEvent();
}

class LoadRecentEvent extends FavoritesEvent {
  const LoadRecentEvent();
}

class AddFavoriteEvent extends FavoritesEvent {
  final Channel channel;

  const AddFavoriteEvent(this.channel);

  @override
  List<Object?> get props => [channel];
}

class RemoveFavoriteEvent extends FavoritesEvent {
  final String channelId;

  const RemoveFavoriteEvent(this.channelId);

  @override
  List<Object?> get props => [channelId];
}

class ToggleFavoriteEvent extends FavoritesEvent {
  final Channel channel;

  const ToggleFavoriteEvent(this.channel);

  @override
  List<Object?> get props => [channel];
}

class AddRecentEvent extends FavoritesEvent {
  final Channel channel;

  const AddRecentEvent(this.channel);

  @override
  List<Object?> get props => [channel];
}

// States
abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

class FavoritesInitialState extends FavoritesState {
  const FavoritesInitialState();
}

class FavoritesLoadingState extends FavoritesState {
  const FavoritesLoadingState();
}

class FavoritesLoadedState extends FavoritesState {
  final List<Channel> favorites;
  final List<Channel> recentlyWatched;
  final Set<String> favoriteIds;

  const FavoritesLoadedState({
    required this.favorites,
    required this.recentlyWatched,
    required this.favoriteIds,
  });

  bool isFavorite(String channelId) => favoriteIds.contains(channelId);

  FavoritesLoadedState copyWith({
    List<Channel>? favorites,
    List<Channel>? recentlyWatched,
    Set<String>? favoriteIds,
  }) {
    return FavoritesLoadedState(
      favorites: favorites ?? this.favorites,
      recentlyWatched: recentlyWatched ?? this.recentlyWatched,
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }

  @override
  List<Object?> get props => [favorites, recentlyWatched, favoriteIds];
}

class FavoritesErrorState extends FavoritesState {
  final String message;

  const FavoritesErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final ChannelRepository _repository;

  FavoritesBloc({required ChannelRepository repository})
      : _repository = repository,
        super(const FavoritesInitialState()) {
    on<LoadFavoritesEvent>(_onLoadFavorites);
    on<LoadRecentEvent>(_onLoadRecent);
    on<AddFavoriteEvent>(_onAddFavorite);
    on<RemoveFavoriteEvent>(_onRemoveFavorite);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<AddRecentEvent>(_onAddRecent);
  }

  Future<void> _onLoadFavorites(
    LoadFavoritesEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(const FavoritesLoadingState());
    try {
      final favorites = await _repository.getFavorites();
      final recent = await _repository.getRecentChannels();
      final favoriteIds = favorites.map((c) => c.id).toSet();

      emit(FavoritesLoadedState(
        favorites: favorites,
        recentlyWatched: recent,
        favoriteIds: favoriteIds,
      ));
    } catch (e) {
      AppLogger.error('Failed to load favorites', e);
      emit(FavoritesErrorState(e.toString()));
    }
  }

  Future<void> _onLoadRecent(
    LoadRecentEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      final recent = await _repository.getRecentChannels();
      if (state is FavoritesLoadedState) {
        emit((state as FavoritesLoadedState).copyWith(recentlyWatched: recent));
      } else {
        final favorites = await _repository.getFavorites();
        final favoriteIds = favorites.map((c) => c.id).toSet();
        emit(FavoritesLoadedState(
          favorites: favorites,
          recentlyWatched: recent,
          favoriteIds: favoriteIds,
        ));
      }
    } catch (e) {
      AppLogger.error('Failed to load recent channels', e);
    }
  }

  Future<void> _onAddFavorite(
    AddFavoriteEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _repository.addToFavorites(event.channel);
      if (state is FavoritesLoadedState) {
        final currentState = state as FavoritesLoadedState;
        final newFavorites = [...currentState.favorites, event.channel];
        final newIds = {...currentState.favoriteIds, event.channel.id};
        emit(currentState.copyWith(
          favorites: newFavorites,
          favoriteIds: newIds,
        ));
      }
    } catch (e) {
      AppLogger.error('Failed to add favorite', e);
    }
  }

  Future<void> _onRemoveFavorite(
    RemoveFavoriteEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _repository.removeFromFavorites(event.channelId);
      if (state is FavoritesLoadedState) {
        final currentState = state as FavoritesLoadedState;
        final newFavorites = currentState.favorites
            .where((c) => c.id != event.channelId)
            .toList();
        final newIds = currentState.favoriteIds
            .where((id) => id != event.channelId)
            .toSet();
        emit(currentState.copyWith(
          favorites: newFavorites,
          favoriteIds: newIds,
        ));
      }
    } catch (e) {
      AppLogger.error('Failed to remove favorite', e);
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    if (state is FavoritesLoadedState) {
      final currentState = state as FavoritesLoadedState;
      if (currentState.isFavorite(event.channel.id)) {
        add(RemoveFavoriteEvent(event.channel.id));
      } else {
        add(AddFavoriteEvent(event.channel));
      }
    }
  }

  Future<void> _onAddRecent(
    AddRecentEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _repository.addToRecent(event.channel);
      if (state is FavoritesLoadedState) {
        final currentState = state as FavoritesLoadedState;
        
        // Create a new list with the new channel first, then filter out duplicates
        final newList = <Channel>[event.channel];
        for (final channel in currentState.recentlyWatched) {
          if (channel.id != event.channel.id && newList.length < 20) {
            newList.add(channel);
          }
        }
        
        emit(currentState.copyWith(recentlyWatched: newList));
      }
    } catch (e) {
      AppLogger.error('Failed to add to recent', e);
    }
  }
}
