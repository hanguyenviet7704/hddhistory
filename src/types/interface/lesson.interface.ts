import { ITranslation } from "../../utils/translate";
import { LessonStatus, LessonType } from "../enum/lesson.enum";
import { BaseQuery } from "./common.interface";
import { IKeypoint } from "./keypoint.interface";
import { ITag } from "./tag.interface";

export interface ILesson {
  _id: string;
  courseId: string;
  learningItemId?: string;
  type: LessonType;
  title: ITranslation;
  description: ITranslation;
  image: string;
  status: LessonStatus;
  keypoints: IKeypoint[];
  estimateCompleTime: ITranslation;
  icon: ITag | null;
  index: number;
}

export interface LessonPayload {
  courseId: string;
  learningItemId?: string;
  type: LessonType;
  title: ITranslation;
  description?: ITranslation;
  image: string;
  status: LessonStatus;
  keypoints: string[];
  estimateCompleTime?: ITranslation;
  icon: string;
  index: number;
}

export interface ILessonBrief {
  _id: string;
  type: LessonType;
  title: ITranslation;
}

interface LessonIndex {
  id: string;
  index: number;
}

export interface LessonsIndexPayload {
  courseId: string;
  lessons: LessonIndex[];
}

export class LessonListQuery extends BaseQuery {
  type?: LessonType;
  status?: LessonStatus;
  courseId?: string;

  constructor(init?: Partial<LessonListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());
    if (this.type) params.set("type", this.type);
    if (this.status) params.set("status", this.status);
    if (this.courseId) params.set("courseId", this.courseId);

    return params.toString();
  }
}
