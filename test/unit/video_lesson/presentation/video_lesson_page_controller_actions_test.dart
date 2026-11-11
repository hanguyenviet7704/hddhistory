import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('videoLessonResolveInitialAutoplayAction', () {
    test('returns play on first ready load without zero-second question', () {
      final action = videoLessonResolveInitialAutoplayAction(
        hasTriggeredInitialAutoplay: false,
        state: VideoLessonState.initial().copyWith(
          loadStatus: VideoLessonLoadStatus.success,
          learningItem: const LearningItemEntity(),
        ),
      );

      expect(action, VideoLessonInitialAutoplayAction.play);
    });

    test('opens the zero-second question instead of playing immediately', () {
      final action = videoLessonResolveInitialAutoplayAction(
        hasTriggeredInitialAutoplay: false,
        state: VideoLessonState.initial().copyWith(
          loadStatus: VideoLessonLoadStatus.success,
          learningItem: LearningItemEntity(
            videoQuestions: [
              VideoQuestionEntity(
                atSecond: 0,
                exercise: const QuestionEntity(id: 100),
              ),
            ],
          ),
        ),
      );

      expect(
        action,
        VideoLessonInitialAutoplayAction.openZeroSecondQuestion,
      );
    });

    test('does nothing after the initial autoplay has already been consumed', () {
      final action = videoLessonResolveInitialAutoplayAction(
        hasTriggeredInitialAutoplay: true,
        state: VideoLessonState.initial().copyWith(
          loadStatus: VideoLessonLoadStatus.success,
        ),
      );

      expect(action, VideoLessonInitialAutoplayAction.none);
    });
  });
}
