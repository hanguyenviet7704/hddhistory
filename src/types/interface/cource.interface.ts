import { ITranslation } from "../../utils/translate";
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
}

export interface CoursePayload {
  title: ITranslation;
  description: ITranslation;
  skillsetId: string;
  image: string;
  status: CourseStatus;
  prices?: IPrice[];
  numberOfLesson?: number;
}

export class CourseListQuery extends BaseQuery {
  status?: CourseStatus;

  constructor(init?: Partial<CourseListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());
    if (this.status) params.set("status", this.status);

    return params.toString();
  }
}

export interface IRoadmapNode {
  title: ITranslation;
  entranceId: string;
  lessonIds: string[];
  outputId: string;
  entrance?: ILessonBrief | null;
  lessons?: ILessonBrief[] | null;
  output?: ILessonBrief | null;
}

export interface IRoadmapLevel {
  id: number;
  level: CourseLevel;
  nodes: IRoadmapNode[];
}

export interface IRoadmap {
  courseId: string;
  levels: IRoadmapLevel[];
}

export interface RoadmapNodePayload {
  title: ITranslation;
  entranceId: string;
  lessonIds: string[];
  outputId: string;
}

export interface RoadmapLevelPayload {
  id: number;
  level: CourseLevel;
  nodes: RoadmapNodePayload[];
}

export interface RoadmapPayload {
  levels: RoadmapLevelPayload[];
}
