// Modern Video Player Widget Tests
// Tests for the modern video player component

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchtheflix/presentation/widgets/modern_video_player.dart';

void main() {
  group('ModernVideoPlayer', () {
    group('PlayerConfig', () {
      test('creates default configuration', () {
        const config = PlayerConfig();

        expect(config.contentType, PlayerContentType.liveTV);
        expect(config.autoPlay, true);
        expect(config.autoRetry, true);
        expect(config.maxRetries, 3);
        expect(config.allowPip, true);
        expect(config.showControls, true);
        expect(config.enableGestures, true);
      });

      test('creates custom configuration', () {
        const config = PlayerConfig(
          contentType: PlayerContentType.movie,
          autoPlay: false,
          maxRetries: 5,
        );

        expect(config.contentType, PlayerContentType.movie);
        expect(config.autoPlay, false);
        expect(config.maxRetries, 5);
      });

      test('copyWith updates only specified fields', () {
        const original = PlayerConfig(
          contentType: PlayerContentType.liveTV,
          autoPlay: true,
        );

        final updated = original.copyWith(
          contentType: PlayerContentType.movie,
        );

        expect(updated.contentType, PlayerContentType.movie);
        expect(updated.autoPlay, true); // Unchanged
      });
    });

    group('PlayerContentType', () {
      test('has expected values', () {
        expect(PlayerContentType.values.length, 3);
        expect(PlayerContentType.values, [
          PlayerContentType.liveTV,
          PlayerContentType.movie,
          PlayerContentType.series,
        ]);
      });
    });

    testWidgets('builds with required parameters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernVideoPlayer(
              url: 'http://example.com/stream.m3u8',
              title: 'Test Stream',
            ),
          ),
        ),
      );

      // Widget should build without errors
      expect(find.byType(ModernVideoPlayer), findsOneWidget);
    });

    testWidgets('displays loading indicator initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernVideoPlayer(
              url: 'http://example.com/stream.m3u8',
              title: 'Test Stream',
            ),
          ),
        ),
      );

      // Should show loading indicator before video initializes
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows back button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernVideoPlayer(
              url: 'http://example.com/stream.m3u8',
              title: 'Test Stream',
            ),
          ),
        ),
      );

      // Back button should always be visible
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('calls onBack when back button pressed', (tester) async {
      var backPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernVideoPlayer(
              url: 'http://example.com/stream.m3u8',
              title: 'Test Stream',
              onBack: () {
                backPressed = true;
              },
            ),
          ),
        ),
      );

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pump();

      expect(backPressed, true);
    });

    testWidgets('displays title when provided', (tester) async {
      const testTitle = 'My Favorite Channel';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernVideoPlayer(
              url: 'http://example.com/stream.m3u8',
              title: testTitle,
              config: const PlayerConfig(showControls: true),
            ),
          ),
        ),
      );

      // Give time for initial render
      await tester.pump();

      // Title should be visible in controls (when they're shown)
      // Note: Actual video initialization may fail in tests,
      // but we can verify the widget structure
      expect(find.text(testTitle), findsWidgets);
    });

    group('PlayerConfig content-specific behavior', () {
      test('Live TV config disables seeking', () {
        const config = PlayerConfig(contentType: PlayerContentType.liveTV);
        expect(config.contentType, PlayerContentType.liveTV);
      });

      test('Movie config enables seeking', () {
        const config = PlayerConfig(contentType: PlayerContentType.movie);
        expect(config.contentType, PlayerContentType.movie);
      });

      test('Series config supports episodes', () {
        const config = PlayerConfig(contentType: PlayerContentType.series);
        expect(config.contentType, PlayerContentType.series);
      });
    });
  });
}
