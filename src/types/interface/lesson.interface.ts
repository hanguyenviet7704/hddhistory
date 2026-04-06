import { ITranslation } from "../../utils/translate";
import { LessonStatus, LessonType } from "../enum/lesson.enum";
import { IAvatar } from "./avatar.interface";
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
  video?: ILessonVideo;
  status: LessonStatus;
  keypoints: IKeypoint[];
  estimateCompleTime: ITranslation;
  estimateCompleTimeNumber?: number;
  icon: ITag | null;
  lightIcon: ITag | null;
  AIConfig: string;
  animation: IAvatar | null;
  index: number;
}

export interface ILessonVideo {
  url: string;
  thumbnail?: string;
  summary?: ITranslation;
}

export interface LessonPayload {
  courseId: string;
  learningItemId?: string;
  type: LessonType;
  title: ITranslation;
  description?: ITranslation;
  image: string;
  video?: ILessonVideo;
  status: LessonStatus;
  keypoints: string[];
  estimateCompleTime?: ITranslation;
  estimateCompleTimeNumber?: number;
  icon: string;
  lightIcon: string;
  AIConfig: string;
  animation: string;
  index: number;
}

export interface ILessonBrief {
  _id: string;
  type: LessonType;
  title: ITranslation;
}

export interface ILessonBrief2 {
  _id: string;
  title?: ITranslation;
  type?: LessonType;
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
