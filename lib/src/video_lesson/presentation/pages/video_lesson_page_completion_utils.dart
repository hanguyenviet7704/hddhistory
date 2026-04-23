part of '../../video_lesson.dart';

bool videoLessonShouldAutoExitOnCompletionSuccess({
  required VideoLessonState previous,
  required VideoLessonState current,
}) => previous.completionStatus != VideoLessonCompletionStatus.success && current.completionStatus == VideoLessonCompletionStatus.success;

bool videoLessonShouldDisableCompletionSubmit(VideoLessonCompletionStatus status) {
  return status == VideoLessonCompletionStatus.loading || status == VideoLessonCompletionStatus.success;
}
