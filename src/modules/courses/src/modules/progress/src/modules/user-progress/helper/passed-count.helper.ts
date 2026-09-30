import { LessonType } from '../../../../../lesson/enum/lesson.enum';
import { LessonResult } from '../schema/user-progress.schema';

/**
 * How many roadmap items of a course the user has passed.
 *
 * The unit MUST match `course.numberOfLesson`, which counts keypoint-bearing
 * lessons by their KEYPOINT count and video/roleplay/output lessons as one unit
 * each — the same unit the roadmap draws. So 1 of 5 keypoint-items reads as 20%
 * and lines up with the roadmap's "1/5".
 *
 * Shared by `my-course` (Home / Library "In progress") and `saved-courses`, so
 * a saved course and the same course in the history strip can never disagree
 * about its percentage.
 */
export function countPassedItems(lessonsResult?: LessonResult[]): number {
  return (lessonsResult ?? []).reduce((sum, result) => {
    const isKeypointLesson =
      result.lessonType === LessonType.LESSON ||
      (result.keypointsResult?.length ?? 0) > 0;

    if (isKeypointLesson) {
      return (
        sum + (result.keypointsResult ?? []).filter(kp => kp.passed).length
      );
    }

    return sum + (result.passed ? 1 : 0);
  }, 0);
}
