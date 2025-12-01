import '../entities/playlist_source.dart';
import '../repositories/playlist_repository.dart';

/// Get all playlists use case
class GetPlaylists {
  final PlaylistRepository _repository;

  GetPlaylists(this._repository);

  /// Execute the use case
  Future<List<PlaylistSource>> call() async {
    return _repository.getPlaylists();
  }
}
