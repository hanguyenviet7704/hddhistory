import { ITranslation } from "../../utils/translate";
import { LessonType } from "../enum/lesson.enum";
import {
  GradeResultType,
  UserProgressExportStatus,
} from "../enum/user-progress.enum";
import { BaseQuery } from "./common.interface";

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
}

export interface ILessonResult {
  lessonId: string;
  averageScore: number;
  passed: boolean;
  keypointsResult: IKeypointResult[];
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
  score: number;
  passed: boolean;
  numberOfCorrect: number;
  numberOfIncorrect: number;
  reviews?: string;
  submittedAt?: Date;
}

// ====== Summary result ======
export interface ICourseProgressSummary {
  id: string;
  title?: ITranslation;
  createdAt?: Date;
  lastTime?: Date;
  stopAt?: IStopAtDetail;
}

export type ILessonResultDetail = Omit<ILessonResult, "keypointsResult"> & {
  title?: ITranslation;
  lessonType?: LessonType;
  keypointsResult: IKeypointResultDetail[];
};

export type IUserProgressDetail = Omit<IUserProgress, "lessonsResult"> & {
  lessonsResult: ILessonResultDetail[];
};

export interface IExerciseResultSummary {
  exerciseId: string;
  score: number;
  passed?: boolean;
  index: number;
}

export type IKeypointResultDetail = Omit<IKeypointResult, "exercisesResult"> & {
  title?: ITranslation;
  exercisesResult: IExerciseResultSummary[];
};

export class UserProgressListQuery extends BaseQuery {
  userId?: string;
  courseId: string;
  lessonId?: string;
  keypointId?: string;
  exerciseId?: string;
  grade: GradeResultType;

  constructor(
    init: {
      courseId: string;
      grade: GradeResultType;
    } & Partial<UserProgressListQuery>
  ) {
    super(init);
    this.grade = init.grade;
    this.courseId = init.courseId;
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());
    params.set("courseId", this.courseId);
    params.set("grade", this.grade);
    if (this.userId) params.set("userId", this.userId);
    if (this.lessonId) params.set("lessonId", this.lessonId);
    if (this.keypointId) params.set("keypointId", this.keypointId);
    if (this.exerciseId) params.set("exerciseId", this.exerciseId);
    return params.toString();
  }
}

export class ProgressOfUserQuery extends BaseQuery {
  constructor(
    init: {
      courseId: string;
      grade: GradeResultType;
    } & Partial<UserProgressListQuery>
  ) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());
    return params.toString();
  }
}

export class RemoveUserProgress {
  userId: string;
  courseId: string;
  lessonId?: string;
  keypointId?: string;
  exerciseId?: string;
  grade: GradeResultType;

  constructor(
    init: {
      userId: string;
      courseId: string;
      grade: GradeResultType;
    } & Partial<UserProgressListQuery>
  ) {
    this.userId = init.userId;
    this.courseId = init.courseId;
    this.grade = init.grade;

    // assign optional values if provided
    this.lessonId = init.lessonId;
    this.keypointId = init.keypointId;
    this.exerciseId = init.exerciseId;
  }

  toQueryParams(): string {
    const params = new URLSearchParams();

    params.set("userId", this.userId);
    params.set("courseId", this.courseId);
    params.set("grade", this.grade);

    if (this.lessonId) params.set("lessonId", this.lessonId);
    if (this.keypointId) params.set("keypointId", this.keypointId);
    if (this.exerciseId) params.set("exerciseId", this.exerciseId);

    return params.toString();
  }
}

export interface ExportAllUserProgressResponse {
  status: UserProgressExportStatus;
  fileKey: string;
  fileUrl: string;
  requestedAt: Date;
  startedAt: Date;
  finishedAt: Date;
  cooldownRemainingMs: number;
}
