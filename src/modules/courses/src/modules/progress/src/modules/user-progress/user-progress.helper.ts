import { ExerciseType } from 'src/modules/courses/src/modules/learning-item/enum/learning-item.enum';
import { LessonType } from 'src/modules/courses/src/modules/lesson/enum/lesson.enum';

import { GradeResultType } from './enum/user-progress.enum';
import {
  IExcerciseResult,
  IKeypointResult,
} from './interface/user-progress.interface';
import { UserProgress } from './schema/user-progress.schema';

export const OPTIONAL_PRACTICE_MIN_SCORE = 85;

export function isKeypointPassed(averageScore?: number) {
  return (averageScore ?? 0) >= OPTIONAL_PRACTICE_MIN_SCORE;
}

export function ensureProgressNode(
  progress: UserProgress,
  grade: GradeResultType,
  dto: {
    lessonId: string;
    averageScore?: number;
    passed?: boolean;
    reviews?: string;
    lessonType?: LessonType;
    keypoints?: IKeypointResult[];
    keypointId?: string;
    exercises?: IExcerciseResult[];
  },
) {
  // ---- Lesson ----
  let lesson = progress.lessonsResult.find(l => l.lessonId === dto.lessonId);

  const isGradeLesson = grade === GradeResultType.LESSON;

  if (!lesson) {
    lesson = {
      lessonId: dto.lessonId,
      averageScore: isGradeLesson ? dto.averageScore ?? 0 : 0,
      passed: isGradeLesson ? dto.passed ?? false : false,
      keypointsResult: [],
      lessonType: dto.lessonType,
      reviews: isGradeLesson ? dto.reviews ?? '' : '',
      submittedAt: new Date(),
    };
    progress.lessonsResult.push(lesson);
  } else if (isGradeLesson) {
    // chỉ update lesson khi đây là grade lesson
    if (dto.averageScore !== undefined) {
      lesson.averageScore = dto.averageScore;
    }
    if (dto.passed !== undefined) {
      lesson.passed = dto.passed;
    }
    if (dto.reviews !== undefined) {
      lesson.reviews = dto.reviews;
    }
    if (dto.lessonType !== undefined) {
      lesson.lessonType = dto.lessonType;
    }
    lesson.submittedAt = new Date();
  } else if (dto.lessonType !== undefined) {
    lesson.lessonType = dto.lessonType;
  }

  // ---- Keypoint ----
  if (grade === GradeResultType.KEYPOINT && dto.keypoints?.length) {
    lesson.keypointsResult ||= [];

    for (const item of dto.keypoints) {
      let keypoint = lesson.keypointsResult.find(
        k => k.keypointId === item.keypointId,
      );

      if (keypoint) {
        keypoint.averageScore = item.averageScore;
        keypoint.passed = item.passed;
        keypoint.reviews = item.reviews;
        keypoint.submittedAt = new Date();
      } else {
        keypoint = {
          keypointId: item.keypointId!,
          averageScore: item.averageScore,
          passed: item.passed,
          exercisesResult: [],
          reviews: item.reviews,
          submittedAt: new Date(),
        };
        lesson.keypointsResult.push(keypoint);
      }
    }

    // (OPTIONAL) Nếu muốn: sau khi update keypoint, có thể tính lại averageScore của lesson từ keypoints.
    // lesson.averageScore = calcFromKeypoints(lesson.keypointsResult);
  }

  // ---- Exercise ----
  if (
    grade === GradeResultType.EXERCISE &&
    dto.keypointId &&
    dto.exercises?.length
  ) {
    lesson.keypointsResult ||= [];

    let keypoint = lesson.keypointsResult.find(
      k => k.keypointId === dto.keypointId,
    );

    if (!keypoint) {
      keypoint = {
        keypointId: dto.keypointId,
        averageScore: 0,
        passed: false,
        exercisesResult: [],
        reviews: '',
        submittedAt: new Date(),
      };
      lesson.keypointsResult.push(keypoint);
    }

    keypoint.exercisesResult ||= [];

    for (const exerciseDto of dto.exercises) {
      if (!exerciseDto?.exerciseId) continue;
      if (
        exerciseDto.type === ExerciseType.SINGLE_CHOICE_NO_CORRECT_ANSWER
      ) {
        continue;
      }

      const exercise = keypoint.exercisesResult.find(
        e => e.exerciseId === exerciseDto.exerciseId,
      );

      if (exercise) {
        if (exerciseDto.type !== undefined) {
          exercise.type = exerciseDto.type;
        }
        if (exerciseDto.form !== undefined) {
          exercise.form = exerciseDto.form;
        }
        if (exerciseDto.passed !== undefined) {
          exercise.passed = exerciseDto.passed;
        }
        if (exerciseDto.score !== undefined) {
          exercise.score = exerciseDto.score;
        }
        if (exerciseDto.multipleAnswer !== undefined) {
          exercise.multipleAnswer = exerciseDto.multipleAnswer;
        }
        if (exerciseDto.singleAnswer !== undefined) {
          exercise.singleAnswer = exerciseDto.singleAnswer;
        }
        if (exerciseDto.dragDropAnswer !== undefined) {
          exercise.dragDropAnswer = exerciseDto.dragDropAnswer;
        }
        if (exerciseDto.recordAnswer !== undefined) {
          exercise.recordAnswer = exerciseDto.recordAnswer;
        }
      } else {
        keypoint.exercisesResult.push({
          exerciseId: exerciseDto.exerciseId,
          type: exerciseDto.type,
          form: exerciseDto.form,
          passed: exerciseDto.passed,
          score: exerciseDto.score ?? 0,
          multipleAnswer: exerciseDto.multipleAnswer,
          singleAnswer: exerciseDto.singleAnswer,
          dragDropAnswer: exerciseDto.dragDropAnswer,
          recordAnswer: exerciseDto.recordAnswer,
        } as IExcerciseResult);
      }
    }
  }
}
