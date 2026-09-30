import { ITranslation } from '@utils/interface/common.interface';

import { ITag } from '../../tags/interface/tag.interface';
import { LessonStatus, LessonType } from '../enum/lesson.enum';

export interface ILessonVideo {
  url: string;
  thumbnail?: string;
  summary?: ITranslation;
}

export interface ILesson {
  courseId: string;
  learningItemId: string;
  type: LessonType;
  title: ITranslation;
  description: ITranslation;
  image: string;
  video?: ILessonVideo;
  status: LessonStatus;
  keypoints: string[];
  estimateCompleTime: ITranslation;
  estimateCompleTimeNumber?: number;
  icon: string;
  lightIcon: string;
  AIConfig: string;
  animation: string;
  index: number;
}

export interface ILessonBrief {
  type: LessonType;
  title: ITranslation;
  description?: ITranslation;
  video?: ILessonVideo;
  image?: string;
  learningItemId?: string;
  estimateCompleTime: ITranslation;
  estimateCompleTimeNumber?: number;
  icon: ITag;
  lightIcon: ITag;
}

export interface ILessonBrief2 {
  _id: string;
  title?: ITranslation;
  type?: LessonType;
}
