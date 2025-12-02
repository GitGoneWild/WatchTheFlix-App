import '../entities/channel.dart';
import '../repositories/channel_repository.dart';

/// Get channels use case
class GetChannels {
  GetChannels(this._repository);
  final ChannelRepository _repository;

  /// Execute the use case
  Future<List<Channel>> call({String? categoryId}) async {
    return _repository.getLiveChannels(categoryId: categoryId);
  }
}
