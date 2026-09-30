import { NotFoundException } from '@nestjs/common';

import {
  CourseVersionAnalyticsService,
  VERSION_METRICS,
} from './course-version-analytics.service';

const COURSE_ID = '68c0000000000000000000c1';
const d = (iso: string) => new Date(iso);

/**
 * Hai bản của một khoá:
 *  - v1.0.0 phát hành 01/09 → 05/09, 2 bài × 2 card.
 *  - v1.0.1 phát hành 05/09 → nay, 2 bài nhưng bài 2 gộp còn 1 card.
 *  - v1.0.2 đã đóng băng nhưng CHƯA phát hành (không có cửa sổ nào).
 */
function makeService(opts: { noEvents?: boolean } = {}) {
  const versions = [
    { _id: 'v1', courseId: COURSE_ID, tag: 'v1.0.0', note: 'bản đầu', createdAt: d('2026-09-01T00:00:00Z') },
    { _id: 'v2', courseId: COURSE_ID, tag: 'v1.0.1', note: 'gộp bài 2', createdAt: d('2026-09-05T00:00:00Z') },
    { _id: 'v3', courseId: COURSE_ID, tag: 'v1.0.2', note: 'chưa phát hành', createdAt: d('2026-09-08T00:00:00Z') },
  ];

  const activations = [
    { courseId: COURSE_ID, versionId: 'v1', tag: 'v1.0.0', from: d('2026-09-01T00:00:00Z'), to: d('2026-09-05T00:00:00Z') },
    { courseId: COURSE_ID, versionId: 'v2', tag: 'v1.0.1', from: d('2026-09-05T00:00:00Z'), to: null },
  ];

  const snapshots: Record<string, { roadmap: any; lessons: any[] }> = {
    v1: {
      roadmap: { levels: [{ nodes: [{ lessonIds: ['l1', 'l2'] }] }] },
      lessons: [
        { _id: 'l1', keypoints: ['k1', 'k2'] },
        { _id: 'l2', keypoints: ['k3', 'k4'] },
      ],
    },
    v2: {
      roadmap: { levels: [{ nodes: [{ lessonIds: ['l1', 'l2'] }] }] },
      lessons: [
        { _id: 'l1', keypoints: ['k1', 'k2'] },
        { _id: 'l2', keypoints: ['k3'] },
      ],
    },
    v3: {
      roadmap: { levels: [{ nodes: [{ lessonIds: ['l1'] }] }] },
      lessons: [{ _id: 'l1', keypoints: ['k1'] }],
    },
  };

  /** Mọi lần đi hỏi user_events, để chứng minh bản chưa phát hành không hỏi. */
  const eventCalls: { method: string; windows: unknown[] }[] = [];

  const courseVersionRepository = {
    async findByCourse() {
      return versions;
    },
    async findTaggedCourseIds() {
      return [COURSE_ID];
    },
  };

  const activationRepository = {
    async findByCourse() {
      return activations;
    },
  };

  const publishedContentRepository = {
    async findAllOfType(versionId: string, entityType: string) {
      const snap = snapshots[versionId];
      if (!snap) return [];

      return entityType === 'roadmap' ? [snap.roadmap] : snap.lessons;
    },
  };

  const byKeypoint = (versionId: string) =>
    versionId === 'v1'
      ? { k1: 100, k2: 80, k3: 60, k4: 40 }
      : { k1: 100, k2: 90, k3: 70 };

  const userEventRepository = {
    async countUsersInWindows(p: any) {
      eventCalls.push({ method: 'countUsersInWindows', windows: p.windows });

      return opts.noEvents ? 0 : 100;
    },
    async countUsersByParamInWindows(p: any) {
      eventCalls.push({ method: 'countUsersByParamInWindows', windows: p.windows });
      if (opts.noEvents) return {};
      const isFirst = +p.windows[0].from === +d('2026-09-01T00:00:00Z');
      if (p.paramKey === 'lesson_id') return { l1: 100, l2: 80 };

      return byKeypoint(isFirst ? 'v1' : 'v2');
    },
    async countEventsInWindows(p: any) {
      eventCalls.push({ method: 'countEventsInWindows', windows: p.windows });

      return opts.noEvents ? 0 : 7;
    },
    async averageSpanSeconds(p: any) {
      eventCalls.push({ method: 'averageSpanSeconds', windows: p.windows });
      if (opts.noEvents) return null;

      return p.groupParam === 'keypoint_id' ? 42 : 300;
    },
  };

  const userFeedbackRepository = {
    async averageContentRatingInWindows() {
      return opts.noEvents
        ? { average: null, responses: 0 }
        : { average: 4.3, responses: 25 };
    },
  };

  const courseRepository = {
    async findById(id: string) {
      return id === COURSE_ID
        ? { _id: COURSE_ID, title: { vi: 'Nền tảng Khoa học Hành vi', en: 'Behavioural' }, currentVersionId: 'v2' }
        : null;
    },
    async findAllBriefTitles() {
      return [
        { _id: COURSE_ID, title: { vi: 'Nền tảng Khoa học Hành vi' } },
        { _id: 'other', title: { vi: 'Khoá chưa đánh tag' } },
      ];
    },
  };

  const service = new CourseVersionAnalyticsService(
    courseVersionRepository as any,
    activationRepository as any,
    publishedContentRepository as any,
    userEventRepository as any,
    userFeedbackRepository as any,
    courseRepository as any,
  );

  return { service, eventCalls };
}

describe('CourseVersionAnalyticsService.comparableCourses', () => {
  it('chỉ trả khoá đã có tag', async () => {
    const { service } = makeService();

    await expect(service.comparableCourses()).resolves.toEqual([
      { id: COURSE_ID, title: 'Nền tảng Khoa học Hành vi' },
    ]);
  });
});

describe('CourseVersionAnalyticsService.compare', () => {
  it('không thấy khoá thì 404, không trả bảng rỗng', async () => {
    const { service } = makeService();

    await expect(service.compare('nope', 'dev')).rejects.toThrow(
      NotFoundException,
    );
  });

  it('xếp các bản cũ nhất trước và đánh dấu đúng bản đang phát hành', async () => {
    const { service } = makeService();

    const out = await service.compare(COURSE_ID, 'dev');

    expect(out.versions.map(v => v.tag)).toEqual([
      'v1.0.0',
      'v1.0.1',
      'v1.0.2',
    ]);
    expect(out.currentTag).toBe('v1.0.1');
    expect(out.versions.map(v => v.live)).toEqual([false, true, false]);
    expect(out.courseTitle).toBe('Nền tảng Khoa học Hành vi');
    expect(out.metrics).toBe(VERSION_METRICS);
  });

  it('KHÔNG đi hỏi event cho bản đóng băng mà chưa phát hành', async () => {
    const { service, eventCalls } = makeService();

    const out = await service.compare(COURSE_ID, 'dev');
    const frozen = out.versions.find(v => v.tag === 'v1.0.2')!;

    // Cửa sổ rỗng: mọi chỉ số hành vi là null, không phải 0 — 0 đọc ra là
    // "đo rồi, không ai học", còn null là "chưa phát hành nên chưa có gì đo".
    expect(frozen.windows).toEqual([]);
    expect(frozen.publishedAt).toBeNull();
    expect(frozen.metrics).toMatchObject({
      pub: null,
      cardSec: null,
      done: null,
      courseDone: null,
      csat: null,
      bugs: null,
    });
    expect(frozen.retention).toEqual([]);
    // Nhưng hình dạng nội dung vẫn đọc được từ snapshot.
    expect(frozen.lessons).toBe(1);
    expect(frozen.cards).toBe(1);

    // Và không một truy vấn nào chạy với danh sách cửa sổ rỗng.
    expect(eventCalls.length).toBeGreaterThan(0);
    expect(eventCalls.every(call => (call.windows as unknown[]).length > 0)).toBe(true);
  });

  it('dựng đường giữ chân theo card cuối của từng bài, mẫu số cố định', async () => {
    const { service } = makeService();

    const out = await service.compare(COURSE_ID, 'dev');
    const first = out.versions[0];

    // v1.0.0: card cuối bài 1 là k2 (80/100), bài 2 là k4 (40/100).
    expect(first.retention).toEqual([
      { lessonIndex: 1, lessonId: 'l1', pct: 80 },
      { lessonIndex: 2, lessonId: 'l2', pct: 40 },
    ]);
    expect(first.metrics.courseDone).toBe(40);
  });

  it('tỉ lệ hoàn thành bài cộng tử/mẫu rồi mới chia, không lấy TB của tỉ lệ', async () => {
    const { service } = makeService();

    const out = await service.compare(COURSE_ID, 'dev');

    // v1.0.0: (80 + 40) / (100 + 80) = 66.7%.
    expect(out.versions[0].metrics.done).toBe(66.7);
  });

  it('đổi giây sang phút cho chỉ số thời gian một bài', async () => {
    const { service } = makeService();

    const out = await service.compare(COURSE_ID, 'dev');

    expect(out.versions[0].metrics.cardSec).toBe(42);
    expect(out.versions[0].metrics.lessonMin).toBe(5);
  });

  it('tính khoảng thấp nhất/cao nhất trên toàn bộ lịch sử khoá', async () => {
    const { service } = makeService();

    const out = await service.compare(COURSE_ID, 'dev');

    // v1.0.0 = 40%, v1.0.1 = 70% (k3 là card cuối của bài 2 sau khi gộp).
    expect(out.ranges.courseDone).toEqual({ min: 40, max: 70 });
    // Bản chưa phát hành là null nên không được kéo min xuống 0.
    expect(out.ranges.csat).toEqual({ min: 4.3, max: 4.3 });
  });

  it('chưa có event nào thì ra null chứ không ra NaN', async () => {
    const { service } = makeService({ noEvents: true });

    const out = await service.compare(COURSE_ID, 'dev');
    const first = out.versions[0];

    expect(first.metrics.done).toBeNull();
    expect(first.metrics.courseDone).toBe(0);
    expect(first.metrics.csat).toBeNull();
    expect(Number.isNaN(first.metrics.courseDone)).toBe(false);
  });

  it('mỗi bản đọc hình dạng bài của CHÍNH NÓ, không dùng chung một thứ tự', async () => {
    const { service } = makeService();

    const out = await service.compare(COURSE_ID, 'dev');

    expect(out.versions[0].cards).toBe(4);
    // v1.0.1 gộp bài 2 còn 1 card.
    expect(out.versions[1].cards).toBe(3);
  });
});
