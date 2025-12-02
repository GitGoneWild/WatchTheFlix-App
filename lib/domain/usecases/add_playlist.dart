import '../entities/playlist_source.dart';
import '../repositories/playlist_repository.dart';

/// Add playlist use case
class AddPlaylist {
  AddPlaylist(this._repository);
  final PlaylistRepository _repository;

  /// Execute the use case
  Future<PlaylistSource> call(PlaylistSource playlist) async {
    return _repository.addPlaylist(playlist);
  }
}
