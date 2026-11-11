import { OnboardingSymptom } from '@utils/enum/course.enum';
import { IPrice, ITranslation } from '@utils/interface/common.interface';

import { VoiceoverProvider } from '../../voiceover/enum/voiceover-provider.enum';
import { CourseStatus } from '../enum/course.enum';

export interface ICourse {
  title: ITranslation;
  description: ITranslation;
  image: string;
  categoryId: string;
  onboardingSymptoms?: OnboardingSymptom[] | null;
  /** Onboarding v3: mã nhãn chi tiết (vấn đề) khoá này giải quyết. */
  onboardingLabelCodes?: string[];
  /** Onboarding v3: mã gói (mong muốn) khoá này phục vụ. */
  onboardingDesireCodes?: string[];
  prices?: IPrice[];
  status: CourseStatus;
  numberOfLesson?: number;
  isNew: boolean;
  /** Scheduled publish time — used for Coming Soon courses. */
  publishAt?: Date | null;
  /** How many days the course shows the "New course" badge after publishAt. */
  newDurationDays?: number | null;
  /**
   * Editorial credit shown on the app's "New today" card. Free text, not a
   * user reference and not translated — a person's name reads the same in
   * every locale.
   */
  author?: string | null;
  /**
   * Reach figure shown next to the author on that same card. Curated per
   * course in admin rather than counted from progress data: it is a
   * social-proof signal the content team sets, so nothing in the app writes to
   * it. Stored raw (6300); the client is what abbreviates it to "6.3k".
   */
  viewCount?: number | null;
  /**
   * Markets this course is published to (ISO-3166 alpha-2, upper-case). Empty
   * -- the default -- means every market. Hides the course from DISCOVERY
   * outside those markets; a reader who already saved it or has progress in it
   * keeps it.
   */
  countries?: string[];
  /**
   * Speech engine for this course's Vietnamese voiceover: `edge` (free, the
   * default) or `vbee` (paid, per character). Opted into per course in admin —
   * see `voiceover/enum/voiceover-provider.enum.ts` for why it is not global.
   */
  voiceoverViProvider?: VoiceoverProvider;
  /**
   * The content tag the app serves for this course (a `course_content_versions`
   * id). Null means the course has never been tagged, and the app reads the
   * working tree exactly as it did before content versions existed -- which is
   * what makes the rollout invisible.
   * See `plans/260907-course-content-versions/README.md`.
   */
  currentVersionId?: string | null;
  /**
   * Cache of the `entityType: 'course'` row of `currentVersionId`. The master
   * copy lives in the tag; this exists only so the app's course list and
   * search stay single-collection: the ten `title.*`/`description.*` indexes
   * are on `courses`, and `CourseRepository.findOption()` regex-searches them
   * directly, so serving a frozen title from another collection would both
   * cost N lookups and let search match the DRAFT title.
   */
  published?: IPublishedCourseFields | null;
}

/** The editorial fields a tag freezes; distribution and pricing stay live. */
export interface IPublishedCourseFields {
  title: ITranslation;
  description: ITranslation;
  image: string;
}

export interface ICourseBrief {
  _id: string;
  title?: ITranslation;
  createdAt?: Date;
}
