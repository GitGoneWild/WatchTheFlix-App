import '../entities/playlist_source.dart';
import '../repositories/playlist_repository.dart';

/// Get all playlists use case
class GetPlaylists {
  GetPlaylists(this._repository);
  final PlaylistRepository _repository;

  /// Execute the use case
  Future<List<PlaylistSource>> call() {
    return _repository.getPlaylists();
  }
}
