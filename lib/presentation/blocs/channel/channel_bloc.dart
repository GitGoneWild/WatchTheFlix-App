import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/logger.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/usecases/get_channels.dart';
import '../../../domain/usecases/get_categories.dart';

// Events
abstract class ChannelEvent extends Equatable {
  const ChannelEvent();

  @override
  List<Object?> get props => [];
}

class LoadChannelsEvent extends ChannelEvent {
  final String? categoryId;

  const LoadChannelsEvent({this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

class LoadCategoriesEvent extends ChannelEvent {
  const LoadCategoriesEvent();
}

class SelectCategoryEvent extends ChannelEvent {
  final Category? category;

  const SelectCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class SearchChannelsEvent extends ChannelEvent {
  final String query;

  const SearchChannelsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearSearchEvent extends ChannelEvent {
  const ClearSearchEvent();
}

// States
abstract class ChannelState extends Equatable {
  const ChannelState();

  @override
  List<Object?> get props => [];
}

class ChannelInitialState extends ChannelState {
  const ChannelInitialState();
}

class ChannelLoadingState extends ChannelState {
  const ChannelLoadingState();
}

class ChannelLoadedState extends ChannelState {
  final List<Channel> channels;
  final List<Category> categories;
  final Category? selectedCategory;
  final String? searchQuery;

  const ChannelLoadedState({
    required this.channels,
    this.categories = const [],
    this.selectedCategory,
    this.searchQuery,
  });

  List<Channel> get filteredChannels {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return channels;
    }
    final lowerQuery = searchQuery!.toLowerCase();
    return channels
        .where((c) => c.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  ChannelLoadedState copyWith({
    List<Channel>? channels,
    List<Category>? categories,
    Category? selectedCategory,
    String? searchQuery,
    bool clearCategory = false,
    bool clearSearch = false,
  }) {
    return ChannelLoadedState(
      channels: channels ?? this.channels,
      categories: categories ?? this.categories,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }

  @override
  List<Object?> get props => [channels, categories, selectedCategory, searchQuery];
}

class ChannelErrorState extends ChannelState {
  final String message;

  const ChannelErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ChannelBloc extends Bloc<ChannelEvent, ChannelState> {
  final GetChannels _getChannels;
  final GetCategories _getCategories;

  ChannelBloc({
    required GetChannels getChannels,
    required GetCategories getCategories,
  })  : _getChannels = getChannels,
        _getCategories = getCategories,
        super(const ChannelInitialState()) {
    on<LoadChannelsEvent>(_onLoadChannels);
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<SelectCategoryEvent>(_onSelectCategory);
    on<SearchChannelsEvent>(_onSearchChannels);
    on<ClearSearchEvent>(_onClearSearch);
  }

  Future<void> _onLoadChannels(
    LoadChannelsEvent event,
    Emitter<ChannelState> emit,
  ) async {
    emit(const ChannelLoadingState());
    try {
      final channels = await _getChannels(categoryId: event.categoryId);
      final categories = await _getCategories();
      emit(ChannelLoadedState(
        channels: channels,
        categories: categories,
      ));
    } catch (e) {
      AppLogger.error('Failed to load channels', e);
      emit(ChannelErrorState(e.toString()));
    }
  }

  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<ChannelState> emit,
  ) async {
    try {
      final categories = await _getCategories();
      if (state is ChannelLoadedState) {
        emit((state as ChannelLoadedState).copyWith(categories: categories));
      }
    } catch (e) {
      AppLogger.error('Failed to load categories', e);
    }
  }

  Future<void> _onSelectCategory(
    SelectCategoryEvent event,
    Emitter<ChannelState> emit,
  ) async {
    if (state is ChannelLoadedState) {
      final currentState = state as ChannelLoadedState;
      emit(currentState.copyWith(
        selectedCategory: event.category,
        clearCategory: event.category == null,
      ));
      add(LoadChannelsEvent(categoryId: event.category?.id));
    }
  }

  void _onSearchChannels(
    SearchChannelsEvent event,
    Emitter<ChannelState> emit,
  ) {
    if (state is ChannelLoadedState) {
      emit((state as ChannelLoadedState).copyWith(searchQuery: event.query));
    }
  }

  void _onClearSearch(
    ClearSearchEvent event,
    Emitter<ChannelState> emit,
  ) {
    if (state is ChannelLoadedState) {
      emit((state as ChannelLoadedState).copyWith(clearSearch: true));
    }
  }
}
