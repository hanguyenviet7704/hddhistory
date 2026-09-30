import { ITranslation } from '@utils/interface/common.interface';

import { ILessonBrief } from '../../lesson/interface/lesson.interface';
import { CourseLevel } from '../enum/course.enum';

export interface IRoadmapNode {
  id: string;
  title: ITranslation;
  description?: ITranslation;
  openingVideoId?: string;
  roleplayId?: string;
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
  level: CourseLevel;
  lightBadge: string;
  darkBadge: string;
  titleBadge: ITranslation;
  keypointIds: string[];
  nodes: IRoadmapNode[];
}

export interface IRoadmap {
  courseId: string;
  levels: IRoadmapLevel[];
}
