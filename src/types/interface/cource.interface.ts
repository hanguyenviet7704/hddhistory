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
  level: CourseLevel;
  prices?: IPrice[];
}

export interface CoursePayload {
  title: string;
  description: string;
  skillsetId: string;
  image: string;
  status: CourseStatus;
  level: CourseLevel;
  prices?: IPrice[];
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
  entrance: ILessonBrief | null;
  lessons: ILessonBrief[];
  output: ILessonBrief | null;
}

export interface IRoadmap {
  courseId: string;
  node: IRoadmapNode[];
}

export interface RoadmapNodePayload {
  title: string;
  entranceId: string;
  lessonIds: string[];
  outputId: string;
}

export interface RoadmapPayload {
  node: RoadmapNodePayload[];
}
