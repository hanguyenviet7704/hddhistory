import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('videoLessonShouldAutoExitOnCompletionSuccess', () {
    test('returns true only for the first transition into success', () {
      final previous = VideoLessonState.initial().copyWith(
        completionStatus: VideoLessonCompletionStatus.loading,
      );
      final current = previous.copyWith(
        completionStatus: VideoLessonCompletionStatus.success,
      );

      expect(
        videoLessonShouldAutoExitOnCompletionSuccess(
          previous: previous,
          current: current,
        ),
        isTrue,
      );
    });

    test('returns false when success is emitted again after session cleanup', () {
      final previous = VideoLessonState.initial().copyWith(
        completionStatus: VideoLessonCompletionStatus.success,
        activeOverlay: VideoLessonOverlay.end,
      );
      final current = previous.copyWith(
        activeOverlay: VideoLessonOverlay.none,
        noteDraft: '',
      );

      expect(
        videoLessonShouldAutoExitOnCompletionSuccess(
          previous: previous,
          current: current,
        ),
        isFalse,
      );
    });

    test('returns false for non-success transitions', () {
      final previous = VideoLessonState.initial();
      final current = previous.copyWith(
        completionStatus: VideoLessonCompletionStatus.loading,
      );

      expect(
        videoLessonShouldAutoExitOnCompletionSuccess(
          previous: previous,
          current: current,
        ),
        isFalse,
      );
    });
  });

  group('videoLessonShouldDisableCompletionSubmit', () {
    test('disables only while loading or waiting to exit after success', () {
      expect(
        videoLessonShouldDisableCompletionSubmit(VideoLessonCompletionStatus.idle),
        isFalse,
      );
      expect(
        videoLessonShouldDisableCompletionSubmit(VideoLessonCompletionStatus.failure),
        isFalse,
      );
      expect(
        videoLessonShouldDisableCompletionSubmit(VideoLessonCompletionStatus.loading),
        isTrue,
      );
      expect(
        videoLessonShouldDisableCompletionSubmit(VideoLessonCompletionStatus.success),
        isTrue,
      );
    });
  });
}
