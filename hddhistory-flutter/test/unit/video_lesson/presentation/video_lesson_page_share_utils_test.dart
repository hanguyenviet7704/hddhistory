import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('videoLessonShouldPreloadShareThumbnail', () {
    test('preloads when the lesson becomes ready with a thumbnail', () {
      final shouldPreload = videoLessonShouldPreloadShareThumbnail(
        previous: VideoLessonState.initial(),
        current: VideoLessonState.initial().copyWith(
          loadStatus: VideoLessonLoadStatus.success,
          lesson: const LessonEntity(
            video: LessonVideoEntity(thumbnail: ' https://cdn.meup.app/thumb.png '),
          ),
        ),
      );

      expect(shouldPreload, isTrue);
    });

    test('does not preload when the ready lesson has no thumbnail', () {
      final shouldPreload = videoLessonShouldPreloadShareThumbnail(
        previous: VideoLessonState.initial(),
        current: VideoLessonState.initial().copyWith(
          loadStatus: VideoLessonLoadStatus.success,
        ),
      );

      expect(shouldPreload, isFalse);
    });

    test('preloads again when the ready thumbnail changes', () {
      final previousState = VideoLessonState.initial().copyWith(
        loadStatus: VideoLessonLoadStatus.success,
        lesson: const LessonEntity(
          video: LessonVideoEntity(thumbnail: 'https://cdn.meup.app/one.png'),
        ),
      );

      final shouldPreload = videoLessonShouldPreloadShareThumbnail(
        previous: previousState,
        current: previousState.copyWith(
          lesson: const LessonEntity(
            video: LessonVideoEntity(thumbnail: 'https://cdn.meup.app/two.png'),
          ),
        ),
      );

      expect(shouldPreload, isTrue);
    });
  });
}
