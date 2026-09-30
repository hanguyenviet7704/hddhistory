import { Injectable, NotFoundException } from '@nestjs/common';

import { CONTENT_EXPERIMENT_EVENTS } from './course-content-experiment.constants';
import { CourseContentVersionRepository } from './repository/course-content-version.repository';
import { CourseVersionActivationRepository } from './repository/course-version-activation.repository';
import { PublishedContentRepository } from './repository/published-content.repository';
import {
  DepthPoint,
  RetentionPoint,
  TagWindows,
  VersionWindow,
  depthCurve,
  dropOffLessons,
  groupWindowsByTag,
  lessonShapesOf,
  liveSeconds,
  rangeOf,
  retentionCurve,
} from './version-analytics';
import { UserEventRepository } from '../../../../analytics/repository/user-event.repository';
import { CourseRepository } from '../course/repository/course.repository';
import { UserFeedbackRepository } from '../feedback/user-feedback/repository/user-feedback.repository';

/**
 * Hướng tốt của chỉ số. Định nghĩa nằm ở server để trang admin và mọi thứ đọc
 * API sau này tô màu giống nhau — "báo lỗi tăng" phải là màu đỏ ở mọi chỗ.
 */
export type MetricPolarity = 1 | 0 | -1;

export interface MetricDefinition {
  key: string;
  group: string;
  label: string;
  /** Chú thích nhỏ dưới nhãn, nói rõ mẫu số. */
  hint?: string;
  unit: string;
  dec: number;
  polarity: MetricPolarity;
  type?: 'date';
}

/**
 * Bảy dòng của bảng so sánh. Thứ tự ở đây là thứ tự hiển thị.
 *
 * `hint` không phải trang trí: "tỉ lệ hoàn thành" mà không nói rõ mẫu số là
 * chỗ hai người đọc ra hai con số khác nhau từ cùng một ô.
 */
export const VERSION_METRICS: MetricDefinition[] = [
  {
    key: 'pub',
    group: 'Phát hành',
    label: 'Thời gian xuất bản',
    unit: '',
    dec: 0,
    polarity: 0,
    type: 'date',
  },
  {
    key: 'cardSec',
    group: 'Nhịp đọc',
    label: 'Thời gian đọc TB 1 card',
    hint: 'từ lúc mở card tới lúc hoàn thành, trong cùng một phiên',
    unit: ' giây',
    dec: 0,
    polarity: 0,
  },
  {
    key: 'lessonMin',
    group: 'Nhịp đọc',
    label: 'Thời gian đọc TB 1 bài',
    hint: 'từ card đầu tới card cuối của bài, trong cùng một phiên',
    unit: ' phút',
    dec: 1,
    polarity: 0,
  },
  {
    key: 'done',
    group: 'Kết quả',
    label: 'Tỉ lệ hoàn thành bài học',
    hint: 'trên mỗi bài user đã mở',
    unit: '%',
    dec: 1,
    polarity: 1,
  },
  {
    key: 'courseDone',
    group: 'Kết quả',
    label: 'Tỉ lệ hoàn thành khoá học',
    hint: 'đọc hết bài cuối, trên user bắt đầu khoá',
    unit: '%',
    dec: 1,
    polarity: 1,
  },
  {
    key: 'csat',
    group: 'Kết quả',
    label: 'Đánh giá CSAT',
    hint: 'điểm nội dung, trên phản hồi gửi trong lúc bản này đang phát hành',
    unit: '/5',
    dec: 1,
    polarity: 1,
  },
  {
    key: 'bugs',
    group: 'Kết quả',
    label: 'Số lượng báo lỗi',
    hint: 'lượt bấm báo lỗi trong lúc bản này đang phát hành',
    unit: ' lượt',
    dec: 0,
    polarity: -1,
  },
];

export interface VersionMetrics {
  pub: string | null;
  cardSec: number | null;
  lessonMin: number | null;
  done: number | null;
  courseDone: number | null;
  csat: number | null;
  bugs: number | null;
}

export interface VersionComparisonRow {
  tag: string;
  versionId: string;
  note?: string | null;
  createdAt: Date | null;
  /** Lần đầu bản này được phát hành. `null` = đóng băng nhưng chưa phát hành. */
  publishedAt: Date | null;
  live: boolean;
  windows: VersionWindow[];
  liveDays: number;
  lessons: number;
  cards: number;
  metrics: VersionMetrics;
  /** Cỡ mẫu — số nào cũng phải đọc kèm cái này. */
  sample: {
    courseViewers: number;
    lessonOpeners: number;
    csatResponses: number;
  };
  retention: RetentionPoint[];
  depth: DepthPoint[];
  dropOffLessons: number[];
}

export interface VersionComparison {
  courseId: string;
  courseTitle: string;
  currentTag: string | null;
  generatedAt: Date;
  metrics: MetricDefinition[];
  versions: VersionComparisonRow[];
  /** Thấp nhất / cao nhất của mỗi chỉ số trên TOÀN BỘ lịch sử khoá. */
  ranges: Record<string, { min: number; max: number } | null>;
}

/** Trần thời gian một card / một bài, để app bị đưa xuống nền không định đoạt số. */
const CARD_CAP_SECONDS = 15 * 60;
const LESSON_CAP_SECONDS = 2 * 60 * 60;

@Injectable()
export class CourseVersionAnalyticsService {
  constructor(
    private readonly courseVersionRepository: CourseContentVersionRepository,
    private readonly activationRepository: CourseVersionActivationRepository,
    private readonly publishedContentRepository: PublishedContentRepository,
    private readonly userEventRepository: UserEventRepository,
    private readonly userFeedbackRepository: UserFeedbackRepository,
    private readonly courseRepository: CourseRepository,
  ) {}

  /**
   * Khoá được chọn trong dropdown: chỉ những khoá đã có ít nhất một tag. Khoá
   * chưa đánh tag thì không có gì để so, và để nó trong danh sách chỉ dẫn tới
   * một trang trống trông như hỏng.
   */
  async comparableCourses(): Promise<{ id: string; title: string }[]> {
    const ids = await this.courseVersionRepository.findTaggedCourseIds();
    if (!ids.length) return [];

    // `findAllBriefTitles` phủ MỌI trạng thái. Cố ý: một khoá nháp hoặc sắp
    // mở vẫn có tag và vẫn cần xem lại số của bản trước, còn mấy hàm brief
    // khác lọc sẵn theo PUBLISHED nên sẽ âm thầm làm khoá đó mất khỏi dropdown.
    const tagged = new Set(ids.map(String));
    const courses = await this.courseRepository.findAllBriefTitles();

    return courses
      .filter((course: any) => tagged.has(String(course._id)))
      .map((course: any) => ({
        id: String(course._id),
        title: titleOf(course),
      }))
      .sort((a, b) => a.title.localeCompare(b.title, 'vi'));
  }

  async compare(courseId: string, appEnv: string): Promise<VersionComparison> {
    const course = await this.courseRepository.findById(courseId);
    if (!course) throw new NotFoundException(`không thấy khoá ${courseId}`);

    const now = new Date();
    const [versions, activations] = await Promise.all([
      this.courseVersionRepository.findByCourse(courseId),
      this.activationRepository.findByCourse(courseId),
    ]);

    const windowsByTag = new Map<string, TagWindows>(
      groupWindowsByTag(activations as any).map(w => [w.tag, w]),
    );

    const currentVersionId = (course as any).currentVersionId
      ? String((course as any).currentVersionId)
      : null;

    const rows = await Promise.all(
      versions.map(version =>
        this.rowFor({
          courseId,
          version,
          windows: windowsByTag.get(version.tag)?.windows ?? [],
          appEnv,
          now,
          isCurrent:
            !!currentVersionId && String(version._id) === currentVersionId,
        }),
      ),
    );

    // Cũ nhất trước: bảng so sánh đọc từ trái sang phải theo dòng thời gian.
    rows.sort((a, b) => +(a.createdAt ?? 0) - +(b.createdAt ?? 0));

    const ranges: VersionComparison['ranges'] = {};
    for (const metric of VERSION_METRICS) {
      if (metric.type === 'date') continue;
      ranges[metric.key] = rangeOf(
        rows.map(row => row.metrics[metric.key as keyof VersionMetrics] as number | null),
      );
    }

    return {
      courseId,
      courseTitle: titleOf(course),
      currentTag: rows.find(row => row.live)?.tag ?? null,
      generatedAt: now,
      metrics: VERSION_METRICS,
      versions: rows,
      ranges,
    };
  }

  // ------------------------------------------------------------------ một bản

  private async rowFor(params: {
    courseId: string;
    version: { _id: unknown; tag: string; note?: string | null; createdAt?: Date };
    windows: VersionWindow[];
    appEnv: string;
    now: Date;
    isCurrent: boolean;
  }): Promise<VersionComparisonRow> {
    const { courseId, version, windows, appEnv, now, isCurrent } = params;
    const versionId = String(version._id);

    const [roadmaps, lessonDocs] = await Promise.all([
      this.publishedContentRepository.findAllOfType(versionId, 'roadmap' as any),
      this.publishedContentRepository.findAllOfType(versionId, 'lesson' as any),
    ]);

    const lessons = lessonShapesOf({
      roadmap: (roadmaps[0] as any) ?? null,
      lessons: lessonDocs as any,
    });
    const cards = lessons.reduce((sum, l) => sum + l.keypointIds.length, 0);

    const empty: VersionComparisonRow = {
      tag: version.tag,
      versionId,
      note: version.note ?? null,
      createdAt: version.createdAt ?? null,
      publishedAt: windows[0]?.from ?? null,
      live: isCurrent,
      windows,
      liveDays: Math.round((liveSeconds(windows, now) / 86400) * 10) / 10,
      lessons: lessons.length,
      cards,
      metrics: {
        pub: windows[0]?.from?.toISOString() ?? null,
        cardSec: null,
        lessonMin: null,
        done: null,
        courseDone: null,
        csat: null,
        bugs: null,
      },
      sample: { courseViewers: 0, lessonOpeners: 0, csatResponses: 0 },
      retention: [],
      depth: [],
      dropOffLessons: [],
    };

    // Bản đóng băng mà chưa từng phát hành thì không có người học nào để đếm —
    // và quan trọng hơn: không được đi hỏi DB với danh sách cửa sổ rỗng, vì
    // "không giới hạn thời gian" sẽ gom số của TOÀN BỘ các bản khác vào đây.
    if (!windows.length) return empty;

    const scope = { [COURSE_PARAM]: courseId };
    const [
      courseViewers,
      readersByKeypoint,
      completersByKeypoint,
      openersByLesson,
      bugs,
      cardSec,
      lessonSec,
      csat,
    ] = await Promise.all([
      this.userEventRepository.countUsersInWindows({
        name: CONTENT_EXPERIMENT_EVENTS.courseView,
        appEnv,
        windows,
        whereParams: scope,
        now,
      }),
      this.userEventRepository.countUsersByParamInWindows({
        name: CONTENT_EXPERIMENT_EVENTS.keypointRead,
        paramKey: KEYPOINT_PARAM,
        appEnv,
        windows,
        whereParams: scope,
        now,
      }),
      this.userEventRepository.countUsersByParamInWindows({
        name: CONTENT_EXPERIMENT_EVENTS.complete,
        paramKey: KEYPOINT_PARAM,
        appEnv,
        windows,
        whereParams: scope,
        now,
      }),
      this.userEventRepository.countUsersByParamInWindows({
        name: CONTENT_EXPERIMENT_EVENTS.keypointStart,
        paramKey: LESSON_PARAM,
        appEnv,
        windows,
        whereParams: scope,
        now,
      }),
      this.userEventRepository.countEventsInWindows({
        name: CONTENT_EXPERIMENT_EVENTS.report,
        appEnv,
        windows,
        whereParams: scope,
        now,
      }),
      this.userEventRepository.averageSpanSeconds({
        startEvent: CONTENT_EXPERIMENT_EVENTS.keypointRead,
        endEvent: CONTENT_EXPERIMENT_EVENTS.complete,
        groupParam: KEYPOINT_PARAM,
        appEnv,
        windows,
        whereParams: scope,
        capSeconds: CARD_CAP_SECONDS,
        now,
      }),
      this.userEventRepository.averageSpanSeconds({
        startEvent: CONTENT_EXPERIMENT_EVENTS.keypointStart,
        endEvent: CONTENT_EXPERIMENT_EVENTS.complete,
        groupParam: LESSON_PARAM,
        appEnv,
        windows,
        whereParams: scope,
        capSeconds: LESSON_CAP_SECONDS,
        now,
      }),
      this.userFeedbackRepository.averageContentRatingInWindows({
        courseId,
        windows,
        now,
      }),
    ]);

    const retention = retentionCurve({
      lessons,
      completersByKeypoint,
      courseViewers,
    });
    const depth = depthCurve({ lessons, readersByKeypoint, openersByLesson });

    // Hoàn thành bài học: cộng tử số và mẫu số qua các bài rồi mới chia, chứ
    // không lấy trung bình của các tỉ lệ — trung bình của tỉ lệ cho một bài
    // chỉ 3 người mở cùng trọng số với bài 3000 người mở.
    let doneNum = 0;
    let doneDen = 0;
    for (const lesson of lessons) {
      const last = lesson.keypointIds[lesson.keypointIds.length - 1];
      if (!last) continue;
      doneNum += completersByKeypoint[last] ?? 0;
      doneDen += openersByLesson[lesson.lessonId] ?? 0;
    }

    const lessonOpeners = Object.values(openersByLesson).reduce(
      (sum, n) => sum + n,
      0,
    );

    return {
      ...empty,
      metrics: {
        pub: windows[0]?.from?.toISOString() ?? null,
        cardSec,
        lessonMin: lessonSec === null ? null : Math.round((lessonSec / 60) * 10) / 10,
        done: doneDen ? Math.round((doneNum / doneDen) * 1000) / 10 : null,
        courseDone: retention.length ? retention[retention.length - 1].pct : null,
        csat: csat.average,
        bugs,
      },
      sample: {
        courseViewers,
        lessonOpeners,
        csatResponses: csat.responses,
      },
      retention,
      depth,
      dropOffLessons: dropOffLessons(depth),
    };
  }
}

/** Tên param app đóng dấu lên event — xem `app_tracking_service.dart`. */
const COURSE_PARAM = 'course_id';
const LESSON_PARAM = 'lesson_id';
const KEYPOINT_PARAM = 'keypoint_id';

const titleOf = (course: any): string =>
  course?.title?.vi || course?.title?.en || String(course?._id ?? '');
