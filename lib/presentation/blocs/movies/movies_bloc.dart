import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/logger.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/movie.dart';
import '../../../domain/repositories/channel_repository.dart';

// Events
abstract class MoviesEvent extends Equatable {
  const MoviesEvent();

  @override
  List<Object?> get props => [];
}

class LoadMoviesEvent extends MoviesEvent {
  const LoadMoviesEvent({this.categoryId});
  final String? categoryId;

  @override
  List<Object?> get props => [categoryId];
}

class LoadMovieCategoriesEvent extends MoviesEvent {
  const LoadMovieCategoriesEvent();
}

class SelectMovieCategoryEvent extends MoviesEvent {
  const SelectMovieCategoryEvent(this.category);
  final Category? category;

  @override
  List<Object?> get props => [category];
}

class SearchMoviesEvent extends MoviesEvent {
  const SearchMoviesEvent(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

class ClearMovieSearchEvent extends MoviesEvent {
  const ClearMovieSearchEvent();
}

// States
abstract class MoviesState extends Equatable {
  const MoviesState();

  @override
  List<Object?> get props => [];
}

class MoviesInitialState extends MoviesState {
  const MoviesInitialState();
}

class MoviesLoadingState extends MoviesState {
  const MoviesLoadingState();
}

class MoviesLoadedState extends MoviesState {
  const MoviesLoadedState({
    required this.movies,
    this.categories = const [],
    this.selectedCategory,
    this.searchQuery,
  });
  final List<Movie> movies;
  final List<Category> categories;
  final Category? selectedCategory;
  final String? searchQuery;

  List<Movie> get filteredMovies {
    var result = movies;
    
    // Filter by category
    if (selectedCategory != null) {
      result = result
          .where((m) => m.categoryId == selectedCategory!.id)
          .toList();
    }
    
    // Filter by search query
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final lowerQuery = searchQuery!.toLowerCase();
      result = result
          .where((m) => m.name.toLowerCase().contains(lowerQuery))
          .toList();
    }
    
    return result;
  }

  MoviesLoadedState copyWith({
    List<Movie>? movies,
    List<Category>? categories,
    Category? selectedCategory,
    String? searchQuery,
    bool clearCategory = false,
    bool clearSearch = false,
  }) {
    return MoviesLoadedState(
      movies: movies ?? this.movies,
      categories: categories ?? this.categories,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }

  @override
  List<Object?> get props => [movies, categories, selectedCategory, searchQuery];
}

class MoviesErrorState extends MoviesState {
  const MoviesErrorState(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

// BLoC
class MoviesBloc extends Bloc<MoviesEvent, MoviesState> {
  MoviesBloc({
    required ChannelRepository repository,
  })  : _repository = repository,
        super(const MoviesInitialState()) {
    on<LoadMoviesEvent>(_onLoadMovies);
    on<LoadMovieCategoriesEvent>(_onLoadCategories);
    on<SelectMovieCategoryEvent>(_onSelectCategory);
    on<SearchMoviesEvent>(_onSearchMovies);
    on<ClearMovieSearchEvent>(_onClearSearch);
  }
  
  final ChannelRepository _repository;

  Future<void> _onLoadMovies(
    LoadMoviesEvent event,
    Emitter<MoviesState> emit,
  ) async {
    emit(const MoviesLoadingState());
    try {
      final movies = await _repository.getMovies(categoryId: event.categoryId);
      final categories = await _repository.getMovieCategories();
      emit(
        MoviesLoadedState(
          movies: movies,
          categories: categories,
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to load movies', e);
      emit(MoviesErrorState(e.toString()));
    }
  }

  Future<void> _onLoadCategories(
    LoadMovieCategoriesEvent event,
    Emitter<MoviesState> emit,
  ) async {
    try {
      final categories = await _repository.getMovieCategories();
      if (state is MoviesLoadedState) {
        emit((state as MoviesLoadedState).copyWith(categories: categories));
      }
    } catch (e) {
      AppLogger.error('Failed to load movie categories', e);
    }
  }

  Future<void> _onSelectCategory(
    SelectMovieCategoryEvent event,
    Emitter<MoviesState> emit,
  ) async {
    if (state is MoviesLoadedState) {
      final currentState = state as MoviesLoadedState;
      emit(
        currentState.copyWith(
          selectedCategory: event.category,
          clearCategory: event.category == null,
        ),
      );
    }
  }

  void _onSearchMovies(
    SearchMoviesEvent event,
    Emitter<MoviesState> emit,
  ) {
    if (state is MoviesLoadedState) {
      emit((state as MoviesLoadedState).copyWith(searchQuery: event.query));
    }
  }

  void _onClearSearch(
    ClearMovieSearchEvent event,
    Emitter<MoviesState> emit,
  ) {
    if (state is MoviesLoadedState) {
      emit((state as MoviesLoadedState).copyWith(clearSearch: true));
    }
  }
}
