import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
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
  const LoadChannelsEvent({this.categoryId});
  final String? categoryId;

  @override
  List<Object?> get props => [categoryId];
}

class LoadCategoriesEvent extends ChannelEvent {
  const LoadCategoriesEvent();
}

class SelectCategoryEvent extends ChannelEvent {
  const SelectCategoryEvent(this.category);
  final Category? category;

  @override
  List<Object?> get props => [category];
}

class SearchChannelsEvent extends ChannelEvent {
  const SearchChannelsEvent(this.query);
  final String query;

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
  const ChannelLoadedState({
    required this.channels,
    this.categories = const [],
    this.selectedCategory,
    this.searchQuery,
  });
  final List<Channel> channels;
  final List<Category> categories;
  final Category? selectedCategory;
  final String? searchQuery;

  List<Channel> get filteredChannels {
    var result = channels;
    
    // Filter by category first (including special categories)
    if (selectedCategory != null) {
      if (selectedCategory!.id == AppConstants.favoriteCategoryId || 
          selectedCategory!.id == AppConstants.recentCategoryId) {
        // Special categories are handled in the UI layer
        // Don't filter here as we don't have access to favorites/recent data
        result = channels;
      } else {
        // Regular category filtering
        result = result
            .where((c) => c.categoryId == selectedCategory!.id)
            .toList();
      }
    }
    
    // Then apply search filter
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final lowerQuery = searchQuery!.toLowerCase();
      result = result
          .where((c) => c.name.toLowerCase().contains(lowerQuery))
          .toList();
    }
    
    return result;
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
  List<Object?> get props =>
      [channels, categories, selectedCategory, searchQuery];
}

class ChannelErrorState extends ChannelState {
  const ChannelErrorState(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

// BLoC
class ChannelBloc extends Bloc<ChannelEvent, ChannelState> {
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
  final GetChannels _getChannels;
  final GetCategories _getCategories;

  Future<void> _onLoadChannels(
    LoadChannelsEvent event,
    Emitter<ChannelState> emit,
  ) async {
    emit(const ChannelLoadingState());
    try {
      final channels = await _getChannels(categoryId: event.categoryId);
      final categories = await _getCategories();
      emit(
        ChannelLoadedState(
          channels: channels,
          categories: categories,
        ),
      );
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
      emit(
        currentState.copyWith(
          selectedCategory: event.category,
          clearCategory: event.category == null,
        ),
      );
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
