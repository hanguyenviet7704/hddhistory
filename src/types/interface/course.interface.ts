import { ITranslation } from "../../utils/translate";
import { OnboardingSymptom } from "../enum/common.enum";
import { CourseLevel, CourseStatus } from "../enum/course.enum";
import { BaseQuery } from "./common.interface";
import { ILessonBrief } from "./lesson.interface";

export interface IPrice {
  currency: string;
  originalPrice: number;
  salePrice?: number;
  isFree?: boolean;
}

export interface ICourse {
  _id: string;
  title: ITranslation;
  description?: ITranslation;
  skillsetId: string;
  image: string;
  status: CourseStatus;
  prices?: IPrice[];
  numberOfLesson?: number;
  onboardingSymptom?: OnboardingSymptom | null;
}

export interface CoursePayload {
  title: ITranslation;
  description: ITranslation;
  skillsetId: string;
  image: string;
  status: CourseStatus;
  prices?: IPrice[];
  numberOfLesson?: number;
  onboardingSymptom?: OnboardingSymptom | null;
}

export interface ICourseBrief {
  _id: string;
  title?: ITranslation;
  createdAt?: Date;
}

export class CourseListQuery extends BaseQuery {
  status?: CourseStatus;
  isAll?: boolean;

  constructor(init?: Partial<CourseListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());
    if (this.status) params.set("status", this.status);
    if (this.isAll) params.set("isAll", this.isAll.toString());

    return params.toString();
  }
}

export interface IRoadmapNode {
  id: string;
  title: ITranslation;
  description?: ITranslation;
  openingVideoId?: string;
  roleplayId: string;
  lessonIds: string[];
  outputId: string;
  closingVideoId?: string;
  openingVideo?: ILessonBrief | null;
  roleplay?: ILessonBrief | null;
  lessons?: ILessonBrief[] | null;
  output?: ILessonBrief | null;
  closingVideo?: ILessonBrief | null;
}

export interface IRoadmapLevel {
  id: number;
  lightBadge: string;
  darkBadge: string;
  titleBadge: ITranslation;
  level: CourseLevel;
  nodes: IRoadmapNode[];
}

export interface IRoadmap {
  courseId: string;
  levels: IRoadmapLevel[];
}

export interface RoadmapNodePayload {
  id: string;
  title: ITranslation;
  description?: ITranslation;
  openingVideoId?: string;
  roleplayId: string;
  lessonIds: string[];
  outputId: string;
  closingVideoId?: string;
}

export interface RoadmapLevelPayload {
  id: number;
  lightBadge: string;
  darkBadge: string;
  titleBadge?: ITranslation;
  level: CourseLevel;
  nodes: RoadmapNodePayload[];
}

export interface RoadmapPayload {
  levels: RoadmapLevelPayload[];
}
