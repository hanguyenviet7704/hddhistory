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
  onboardingSymptoms?: OnboardingSymptom[];
  /** Onboarding v3: mã nhãn chi tiết (vấn đề) — xem onboarding-taxonomy. */
  onboardingLabelCodes?: string[];
  /** Onboarding v3: mã gói (mong muốn). */
  onboardingDesireCodes?: string[];
  /** Scheduled publish time (ISO 8601) — used for Coming Soon courses. */
  publishAt?: string | null;
  /** Days the "New course" badge stays after the course publishes. */
  newDurationDays?: number | null;
  /** Manual override: force the "New course" badge regardless of publish date. */
  isNew?: boolean;
  /** Author credit on the app's "New today" card. Not translated. */
  author?: string | null;
  /** Curated reach figure on that card — raw number; the app shows "6.3k". */
  viewCount?: number | null;
  /**
   * Thị trường course được publish tới (ISO-3166 alpha-2, chữ hoa). Rỗng —
   * mặc định — là publish mọi nơi. Chỉ ẩn course khỏi các màn KHÁM PHÁ ngoài
   * các thị trường này; ai đã lưu hoặc đang học dở thì vẫn giữ.
   */
  countries?: string[];
}

export type CoursePayload = Omit<ICourse, "_id">;

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
