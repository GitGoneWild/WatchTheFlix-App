import '../entities/category.dart';
import '../repositories/channel_repository.dart';

/// Get categories use case
class GetCategories {
  GetCategories(this._repository);
  final ChannelRepository _repository;

  /// Execute the use case
  Future<List<Category>> call() async {
    return _repository.getLiveCategories();
  }
}
