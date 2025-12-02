import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:watchtheflix/domain/entities/playlist_source.dart';
import 'package:watchtheflix/domain/usecases/get_playlists.dart';
import 'package:watchtheflix/domain/usecases/add_playlist.dart';
import 'package:watchtheflix/presentation/blocs/playlist/playlist_bloc.dart';

class MockGetPlaylists extends Mock implements GetPlaylists {}

class MockAddPlaylist extends Mock implements AddPlaylist {}

void main() {
  late MockGetPlaylists mockGetPlaylists;
  late MockAddPlaylist mockAddPlaylist;

  setUp(() {
    mockGetPlaylists = MockGetPlaylists();
    mockAddPlaylist = MockAddPlaylist();
  });

  group('PlaylistBloc', () {
    final testPlaylists = [
      PlaylistSource(
        id: '1',
        name: 'Test Playlist',
        url: 'http://example.com/playlist.m3u',
        type: PlaylistSourceType.m3uUrl,
        addedAt: DateTime.now(),
      ),
    ];

    blocTest<PlaylistBloc, PlaylistState>(
      'emits [PlaylistLoadingState, PlaylistLoadedState] when LoadPlaylistsEvent is added',
      setUp: () {
        when(() => mockGetPlaylists()).thenAnswer((_) async => testPlaylists);
      },
      build: () => PlaylistBloc(
        getPlaylists: mockGetPlaylists,
        addPlaylist: mockAddPlaylist,
      ),
      act: (bloc) => bloc.add(const LoadPlaylistsEvent()),
      expect: () => [
        const PlaylistLoadingState(),
        isA<PlaylistLoadedState>().having(
          (state) => state.playlists.length,
          'playlists length',
          1,
        ),
      ],
    );

    blocTest<PlaylistBloc, PlaylistState>(
      'emits [PlaylistErrorState] when loading fails',
      setUp: () {
        when(() => mockGetPlaylists()).thenThrow(Exception('Failed to load'));
      },
      build: () => PlaylistBloc(
        getPlaylists: mockGetPlaylists,
        addPlaylist: mockAddPlaylist,
      ),
      act: (bloc) => bloc.add(const LoadPlaylistsEvent()),
      expect: () => [
        const PlaylistLoadingState(),
        isA<PlaylistErrorState>(),
      ],
    );
  });
}
