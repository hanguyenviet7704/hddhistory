import { GradeResultType } from "../enum/user-progress.enum";
import { BaseQuery } from "./common.interface";

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
