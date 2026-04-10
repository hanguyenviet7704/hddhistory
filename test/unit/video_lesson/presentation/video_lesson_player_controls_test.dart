import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  testWidgets('allows opening notes while video is playing and controls are visible', (tester) async {
    var notesTapped = false;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, widget) => MaterialApp(
          home: Scaffold(
            body: VideoLessonPlayerControls(
              state: VideoLessonState.initial().copyWith(
                isPlaying: true,
                controlsVisible: true,
                durationSeconds: 120,
              ),
              onClose: () {},
              onPlayPause: () {},
              onSummaryTap: () {},
              onNotesTap: () => notesTapped = true,
              onShareTap: () {},
              onSeekStart: (_) {},
              onSeekChanged: (_) {},
              onSeekEnd: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('video-lesson-notes-button')));
    await tester.pumpAndSettle();

    expect(notesTapped, isTrue);
  });
}
