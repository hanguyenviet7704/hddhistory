import { ITranslation } from '@utils/interface/common.interface';
import { CourseLevel } from 'src/modules/courses/src/modules/course/enum/course.enum';
import {
  ExerciseType,
  FormDragDropType,
} from 'src/modules/courses/src/modules/learning-item/enum/learning-item.enum';
import { IDragDropOptions } from 'src/modules/courses/src/modules/learning-item/interface/excercises/drag-drop.interface';
import { IExerciseChoiceOption } from 'src/modules/courses/src/modules/learning-item/interface/excercises/multiple-choice.interface';
import { IRecordAnswer } from 'src/modules/courses/src/modules/learning-item/interface/excercises/record.interface';
import { IExerciseSingleChoiceNoCorrectAnswerOption } from 'src/modules/courses/src/modules/learning-item/interface/excercises/single-choice-no-correct-answer.interface';
import { LessonType } from 'src/modules/courses/src/modules/lesson/enum/lesson.enum';

export type ProgressSnapshot = {
  passedLesson: Set<string>;
  passedEffective: Set<string>;
  completed: Set<CourseLevel>;
};

export interface IStopAt {
  lessonId: string;
  keypointId?: string;
}

export interface IStopAtDetail extends IStopAt {
  lessonTitle?: ITranslation;
  lessonType?: LessonType;
  keypointTitle?: ITranslation;
}
export interface IUserProgress {
  userId: string;
  courseId: string;
  lessonsResult: ILessonResult[];
  completedLevels: ICompletedLevel[];
  keypointOptional: string[];
  lastTime?: Date;
  stopAt?: IStopAt;
}

export interface ILessonResult {
  lessonId: string;
  averageScore: number;
  passed: boolean;
  keypointsResult: IKeypointResult[];
  lessonType?: LessonType;
  reviews?: string;
  submittedAt?: Date;
}

export interface IKeypointResult {
  keypointId: string;
  averageScore: number;
  passed: boolean;
  exercisesResult: IExcerciseResult[];
  reviews?: string;
  submittedAt?: Date;
}

export interface IExcerciseResult {
  exerciseId: string;
  type: ExerciseType;
  form: FormDragDropType;
  passed?: boolean;
  score: number;
  multipleAnswer?: (
    | IExerciseChoiceOption
    | IExerciseSingleChoiceNoCorrectAnswerOption
  )[];
  singleAnswer?: IExerciseChoiceOption;
  dragDropAnswer?: IDragDropOptions[];
  recordAnswer?: IRecordAnswer;
}

export interface ICompletedLevel {
  level: CourseLevel;
  completedAt: Date;
  additionalContentRequest?: ICompletedLevelAdditionalContentRequest;
}

export interface ICompletedLevelAdditionalContentRequest {
  requested: boolean;
  requestText?: string;
  submittedAt: Date;
}
export interface IAchievenmentResponse {
  categoryId: string;
  categoryTitle: ITranslation;
  courses: ICourseLevelProgress[];
  // Category-wide keypoint totals across ALL levels of ALL published courses —
  // lets the client show real fractional learning progress (completed/total
  // keypoints) instead of a coarse "fully-completed courses / total courses".
  totalKeypoints: number;
  completedKeypoints: number;
}

export interface ICourseLevelProgress {
  level: CourseLevel;
  lightBadge: string;
  darkBadge: string;
  titleBadge: ITranslation;
  courseId: string;
  courseTitle: ITranslation;
  totalKeypoints: number;
  completedKeypoints: number;
  isCompleted: boolean;
}

// ====== Summary result ======
export interface ICourseProgressSummary {
  id: string;
  title?: ITranslation;
  createdAt?: Date;
  lastTime?: Date;
  completedLevels: ICompletedLevel[];
  stopAt?: IStopAtDetail;
}

export interface ICourseLearningStatistics {
  courseId: string;
  title?: ITranslation;
  startedUserCount: number;
  roleplayPassedCount: number;
  lessonKeypointPassedCount: number;
  completedUserCount: number;
}

export type ILessonResultDetail = Omit<ILessonResult, 'keypointsResult'> & {
  title?: ITranslation;
  keypointsResult: IKeypointResultDetail[];
};

export type IUserProgressDetail = Omit<IUserProgress, 'lessonsResult'> & {
  lessonsResult: ILessonResultDetail[];
};

export interface IExerciseResultSummary {
  exerciseId: string;
  score: number;
  passed?: boolean;
  index: number;
}

export type IKeypointResultDetail = Omit<IKeypointResult, 'exercisesResult'> & {
  title?: ITranslation;
  exercisesResult: IExerciseResultSummary[];
};
