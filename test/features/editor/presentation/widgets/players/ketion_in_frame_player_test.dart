import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:ketion/features/editor/presentation/widgets/players/ketion_in_frame_player.dart';

class FakeVideoPlayerController extends VideoPlayerController {
  FakeVideoPlayerController() : super.file(io.File('test/assets/sample.mp4')) {
    value = const VideoPlayerValue(
      duration: Duration(minutes: 2),
      position: Duration(seconds: 42),
      isPlaying: false,
      isInitialized: true,
      size: Size(640, 480),
    );
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
    notifyListeners();
  }

  @override
  Future<void> seekTo(Duration position) async {
    value = value.copyWith(position: position);
    notifyListeners();
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    value = value.copyWith(playbackSpeed: speed);
    notifyListeners();
  }
}

void main() {
  group('KetionInFramePlayer Widget Tests', () {
    testWidgets('renders player container with in-frame layout and controls',
        (tester) async {
      final fakeController = FakeVideoPlayerController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: KetionInFramePlayer(
                  filePath: 'test/assets/sample.mp4',
                  caption: 'Sample Video Caption',
                  controller: fakeController,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the widget mounts with overlay controls inside the frame
      expect(find.byType(KetionInFramePlayer), findsOneWidget);
      expect(find.text('Sample Video Caption'), findsOneWidget);
      expect(find.text('00:42 / 02:00'), findsOneWidget);
      expect(find.text('1×'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsWidgets);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    });

    testWidgets('play and pause toggle playback on controller', (tester) async {
      final fakeController = FakeVideoPlayerController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: KetionInFramePlayer(
                  filePath: 'test/assets/sample.mp4',
                  controller: fakeController,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap play button
      await tester.tap(find.byIcon(Icons.play_arrow).first);
      await tester.pump();

      expect(fakeController.value.isPlaying, isTrue);

      // Tap pause button
      await tester.tap(find.byIcon(Icons.pause).first);
      await tester.pump();

      expect(fakeController.value.isPlaying, isFalse);
    });

    testWidgets(
        'speed selection bottom sheet / popup renders all documented speed multipliers',
        (tester) async {
      final fakeController = FakeVideoPlayerController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: KetionInFramePlayer(
                  filePath: 'test/assets/sample.mp4',
                  controller: fakeController,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap speed selector popup
      await tester.tap(find.text('1×'));
      await tester.pumpAndSettle();

      expect(find.text('0.5×'), findsOneWidget);
      expect(find.text('0.75×'), findsOneWidget);
      expect(find.text('1.0×'), findsOneWidget);
      expect(find.text('1.25×'), findsOneWidget);
      expect(find.text('1.5×'), findsOneWidget);
      expect(find.text('2.0×'), findsOneWidget);

      // Select 1.5x
      await tester.tap(find.text('1.5×'));
      await tester.pumpAndSettle();

      expect(fakeController.value.playbackSpeed, 1.5);
    });
  });
}
