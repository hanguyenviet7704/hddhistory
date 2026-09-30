import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';

import { CourseVersionService } from './course-version.service';

/**
 * The tag lifecycle the owner asked for: edit freely, publish by tagging, roll
 * back by pointing `currentVersionId` at an older tag. These fakes keep the two
 * invariants the real indexes enforce -- unique `(courseId, tag)` and unique
 * `(versionId, entityType, entityId)` -- so the tests exercise the real
 * contract without a database.
 * See `plans/260907-course-content-versions/README.md`.
 */
const COURSE_ID = '68c0000000000000000000c1';

const liveCourse = () => ({
  _id: COURSE_ID,
  title: { en: 'Draft title', vi: 'Tiêu đề nháp' },
  description: { en: 'Draft desc', vi: 'Mô tả nháp' },
  image: 'https://cdn.test/draft.png',
  status: 'PUBLISHED',
  prices: [{ currency: 'VND', amount: 199000 }],
  currentVersionId: null as string | null,
  published: null as unknown,
});

function makeService(
  opts: { failRowInsert?: boolean; duplicateOnCreate?: boolean } = {},
) {
  const courses: Record<string, any> = { [COURSE_ID]: liveCourse() };
  const versions: any[] = [];
  const rows: any[] = [];
  let autoId = 0;

  const courseVersionRepository = {
    async create(data: any, user?: any) {
      // Cái mà unique (courseId, tag) thật sự ném ra là E11000, không phải
      // ConflictException — `duplicateOnCreate` mô phỏng tick cron kia vừa
      // chèn xong trong khi findByCourse của tick này còn thấy rỗng.
      if (
        opts.duplicateOnCreate ||
        versions.some(v => v.courseId === data.courseId && v.tag === data.tag)
      )
        throw new Error('E11000 duplicate key error collection');
      const row = {
        ...data,
        _id: `v${++autoId}`,
        createdAt: new Date('2026-09-07T10:00:00Z'),
        createdBy: user ?? null,
      };
      versions.push(row);

      return row;
    },
    async findByCourse(courseId: string) {
      return versions.filter(v => v.courseId === courseId);
    },
    async findOneByTag(courseId: string, tag: string) {
      return versions.find(v => v.courseId === courseId && v.tag === tag) ?? null;
    },
    async findTaggedCourseIds() {
      return [...new Set(versions.map(v => v.courseId))];
    },
    async deleteOne(filter: any) {
      const at = versions.findIndex(v => String(v._id) === String(filter._id));
      if (at >= 0) versions.splice(at, 1);
    },
  };

  const publishedContentRepository = {
    async insertRows(versionId: string, courseId: string, newRows: any[]) {
      if (opts.failRowInsert) throw new Error('insert failed');
      for (const row of newRows) {
        const clash = rows.some(
          r =>
            r.versionId === versionId &&
            r.entityType === row.entityType &&
            r.entityId === row.entityId,
        );
        if (clash) throw new Error('E11000 duplicate key');
        rows.push({ ...row, versionId, courseId });
      }

      return newRows.length;
    },
    async findEntity(versionId: string, entityType: string, entityId: string) {
      return (
        rows.find(
          r =>
            r.versionId === versionId &&
            r.entityType === entityType &&
            r.entityId === entityId,
        )?.doc ?? null
      );
    },
    async findHashes(versionId: string) {
      return rows
        .filter(r => r.versionId === versionId)
        .map(({ entityType, entityId, docHash }) => ({
          entityType,
          entityId,
          docHash,
        }));
    },
    async deleteByVersion(versionId: string) {
      let removed = 0;
      for (let i = rows.length - 1; i >= 0; i--) {
        if (rows[i].versionId === versionId) {
          rows.splice(i, 1);
          removed++;
        }
      }

      return removed;
    },
  };

  const courseRepository = {
    async findById(id: string) {
      return courses[id] ?? null;
    },
    async updateOne(filter: any, data: any) {
      Object.assign(courses[String(filter._id)], data);
    },
    async findAllIds() {
      return Object.keys(courses);
    },
  };

  const roadmapRepository = {
    async findByCourseIds() {
      return [{ _id: 'r1', courseId: COURSE_ID, levels: [] }];
    },
  };

  const lessonRepository = {
    async findAllForExport() {
      return [{ _id: 'l1', courseId: COURSE_ID, keypoints: ['k1'] }];
    },
    async findFullByIds(ids: string[]) {
      return [{ _id: 'l1', courseId: COURSE_ID, keypoints: ['k1'] }].filter(l =>
        ids.includes(String(l._id)),
      );
    },
  };

  const keypointRepository = {
    async findKeypointsByIds(ids: string[]) {
      return [{ _id: 'k1', title: { en: 'Kp' }, index: 1 }].filter(k =>
        ids.includes(String(k._id)),
      );
    },
  };

  const learningItemRepository = {
    async findAllByKeypointIds() {
      return [{ _id: 'i1', keypointId: 'k1', type: 'EXERCISE' }];
    },
  };

  // Sổ cửa sổ thời gian. Giữ đúng bất biến của index thật: mỗi khoá nhiều nhất
  // một đoạn `to: null`.
  const activations: any[] = [];
  const activationRepository = {
    async closeOpenWindows(courseId: string, at: Date) {
      let closed = 0;
      for (const row of activations) {
        if (row.courseId === courseId && row.to === null) {
          row.to = at;
          closed++;
        }
      }

      return closed;
    },
    async openWindow(params: any) {
      activations.push({ ...params, to: null });
    },
    async findOpenWindow(courseId: string) {
      return (
        activations.find(r => r.courseId === courseId && r.to === null) ?? null
      );
    },
    async findByCourse(courseId: string) {
      return activations.filter(r => r.courseId === courseId);
    },
  };

  const audioCoverage = {
    forVersion: jest.fn().mockResolvedValue({
      complete: true,
      summary: { done: 1, stale: 0, missing: 0, none: 0 },
      keypoints: [],
    }),
  };

  const service = new CourseVersionService(
    courseVersionRepository as any,
    publishedContentRepository as any,
    courseRepository as any,
    roadmapRepository as any,
    lessonRepository as any,
    keypointRepository as any,
    learningItemRepository as any,
    activationRepository as any,
    // Covered audio by default: these tests are about tagging, and the publish
    // gate has its own. `complete: false` here is what a gate test overrides.
    audioCoverage as any,
    { start: jest.fn(), snapshot: jest.fn() } as any,
  );

  return { service, courses, versions, rows, activations, audioCoverage };
}

describe('createTag', () => {
  it('rejects a tag that is not vX.Y.Z', async () => {
    const { service } = makeService();

    await expect(
      service.createTag(COURSE_ID, { tag: 'latest' }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects a tag the course already has', async () => {
    const { service } = makeService();
    await service.createTag(COURSE_ID, { tag: 'v1.0.0' });

    await expect(
      service.createTag(COURSE_ID, { tag: 'v1.0.0' }),
    ).rejects.toThrow(ConflictException);
  });

  it('refuses to tag a course that does not exist', async () => {
    const { service } = makeService();

    await expect(
      service.createTag('68c0000000000000000000ff', { tag: 'v1.0.0' }),
    ).rejects.toThrow(NotFoundException);
  });

  it('freezes the whole content tree into the tag', async () => {
    const { service, rows } = makeService();
    const view = await service.createTag(COURSE_ID, { tag: 'v1.0.0' });

    expect(view.entityCounts).toEqual({
      lessons: 1,
      keypoints: 1,
      learningItems: 1,
    });
    expect(rows.map(r => r.entityType).sort()).toEqual([
      'course',
      'keypoint',
      'learningItem',
      'lesson',
      'roadmap',
    ]);
  });

  /** Tagging alone must not change what users are served. */
  it('leaves the course pointer alone without setCurrent', async () => {
    const { service, courses } = makeService();
    await service.createTag(COURSE_ID, { tag: 'v1.0.0' });

    expect(courses[COURSE_ID].currentVersionId).toBeNull();
    expect(courses[COURSE_ID].published).toBeNull();
  });

  it('points the course at the new tag with setCurrent', async () => {
    const { service, courses, versions } = makeService();
    await service.createTag(COURSE_ID, { tag: 'v1.0.0', setCurrent: true });

    expect(courses[COURSE_ID].currentVersionId).toBe(String(versions[0]._id));
    expect(courses[COURSE_ID].published).toEqual({
      title: { en: 'Draft title', vi: 'Tiêu đề nháp' },
      description: { en: 'Draft desc', vi: 'Mô tả nháp' },
      image: 'https://cdn.test/draft.png',
    });
  });

  /**
   * There is no transaction here (dev Mongo is not guaranteed to be a replica
   * set), so a failed row insert must not leave a tag that resolves to no
   * content -- the app would serve an empty course.
   */
  it('removes the tag again if freezing the rows fails', async () => {
    const { service, versions } = makeService({ failRowInsert: true });

    await expect(
      service.createTag(COURSE_ID, { tag: 'v1.0.0' }),
    ).rejects.toThrow();
    expect(versions).toHaveLength(0);
  });
});

describe('createTag actor', () => {
  const EDITOR = { _id: 'admin1', email: 'editor@eupgroup.net' };

  /**
   * The acting user is passed in rather than injected. Injecting
   * `RequestService` would make this service request-scoped, and
   * `course-publish.scheduler.ts` has to call `createTag` when it publishes a
   * course that has no tag yet -- a request-scoped dependency would silently
   * kill that @Cron, exactly as documented on `SegmentModule`.
   */
  it('records who tagged', async () => {
    const { service, versions } = makeService();
    await service.createTag(COURSE_ID, { tag: 'v1.0.0' }, EDITOR as any);

    expect(versions[0].createdBy).toEqual(EDITOR);
  });

  it('allows an unattended tag with no actor', async () => {
    const { service, versions } = makeService();
    await service.createTag(COURSE_ID, { tag: 'v1.0.0' });

    expect(versions[0].createdBy).toBeNull();
  });
});

describe('setCurrent', () => {
  /**
   * The reason the course row is stored inside the tag at all: rolling back
   * has to restore the title of THAT tag, and `Course.published` only ever
   * holds one. Restoring from the live course would silently keep the draft
   * title on a rollback.
   */
  it('restores the published fields from the tag, not from the live course', async () => {
    const { service, courses, versions } = makeService();
    await service.createTag(COURSE_ID, { tag: 'v1.0.0', setCurrent: true });

    // The editor keeps working after tagging.
    courses[COURSE_ID].title = { en: 'Edited later', vi: 'Sửa sau' };
    await service.createTag(COURSE_ID, { tag: 'v1.0.1', setCurrent: true });
    expect(courses[COURSE_ID].published.title.en).toBe('Edited later');

    await service.setCurrent(COURSE_ID, 'v1.0.0');

    expect(courses[COURSE_ID].currentVersionId).toBe(String(versions[0]._id));
    expect(courses[COURSE_ID].published.title.en).toBe('Draft title');
  });

  it('refuses a tag the course does not have', async () => {
    const { service } = makeService();

    await expect(service.setCurrent(COURSE_ID, 'v9.9.9')).rejects.toThrow(
      NotFoundException,
    );
  });

  it('refuses to publish a tag that is short of audio', async () => {
    const { service, audioCoverage, courses } = makeService();
    await service.createTag(COURSE_ID, { tag: 'v1.0.0' });
    const before = courses[COURSE_ID].currentVersionId;

    audioCoverage.forVersion.mockResolvedValue({
      complete: false,
      summary: { done: 3, stale: 1, missing: 2, none: 0 },
      keypoints: [
        { keypointId: 'k1', title: { vi: 'Hiểu về mâu thuẫn' }, missing: { vi: 2 } },
      ],
    });

    await expect(service.setCurrent(COURSE_ID, 'v1.0.0')).rejects.toThrow(
      /chưa đủ audio/,
    );
    // And nothing moved — a refused publish must not half-apply.
    expect(courses[COURSE_ID].currentVersionId).toBe(before);
  });

  /**
   * This endpoint is also the rollback. A gate that blocks the way back is
   * worse than the hole it closes — anything already served is a state users
   * have lived with.
   */
  it('lets a tag that has already been served come back', async () => {
    const { service, audioCoverage, courses, versions } = makeService();
    await service.createTag(COURSE_ID, { tag: 'v1.0.0', setCurrent: true });
    await service.createTag(COURSE_ID, { tag: 'v1.0.1', setCurrent: true });

    audioCoverage.forVersion.mockResolvedValue({
      complete: false,
      summary: { done: 0, stale: 0, missing: 5, none: 0 },
      keypoints: [],
    });

    await service.setCurrent(COURSE_ID, 'v1.0.0');

    expect(courses[COURSE_ID].currentVersionId).toBe(String(versions[0]._id));
  });
});

describe('deleteTag', () => {
  it('refuses to delete the tag the course is serving', async () => {
    const { service } = makeService();
    await service.createTag(COURSE_ID, { tag: 'v1.0.0', setCurrent: true });

    await expect(service.deleteTag(COURSE_ID, 'v1.0.0')).rejects.toThrow(
      ConflictException,
    );
  });

  it('drops the frozen rows along with the tag', async () => {
    const { service, rows, versions } = makeService();
    await service.createTag(COURSE_ID, { tag: 'v1.0.0' });

    await service.deleteTag(COURSE_ID, 'v1.0.0');

    expect(versions).toHaveLength(0);
    expect(rows).toHaveLength(0);
  });
});

describe('listVersions', () => {
  it('suggests the next patch tag', async () => {
    const { service } = makeService();
    expect((await service.listVersions(COURSE_ID)).nextTag).toBe('v1.0.0');

    await service.createTag(COURSE_ID, { tag: 'v1.0.0' });
    expect((await service.listVersions(COURSE_ID)).nextTag).toBe('v1.0.1');
  });

  it('reports no pending changes right after tagging', async () => {
    const { service } = makeService();
    await service.createTag(COURSE_ID, { tag: 'v1.0.0', setCurrent: true });

    expect((await service.listVersions(COURSE_ID)).pending.total).toBe(0);
  });

  /**
   * The banner that stops an editor from publishing half-finished copy while
   * re-tagging for something else.
   */
  it('reports an edit made after the tag as a pending change', async () => {
    const { service, courses } = makeService();
    await service.createTag(COURSE_ID, { tag: 'v1.0.0', setCurrent: true });

    courses[COURSE_ID].title = { en: 'Edited', vi: 'Đã sửa' };
    const { pending } = await service.listVersions(COURSE_ID);

    expect(pending.total).toBe(1);
    expect(pending.changed).toEqual([
      { entityType: 'course', entityId: COURSE_ID },
    ]);
  });

  it('marks the current tag', async () => {
    const { service } = makeService();
    await service.createTag(COURSE_ID, { tag: 'v1.0.0', setCurrent: true });
    await service.createTag(COURSE_ID, { tag: 'v1.0.1' });

    const { versions } = await service.listVersions(COURSE_ID);

    expect(versions.find(v => v.tag === 'v1.0.0')?.isCurrent).toBe(true);
    expect(versions.find(v => v.tag === 'v1.0.1')?.isCurrent).toBe(false);
  });
});

describe('autoTag', () => {
  /**
   * The Google Sheet workflow: edit the sheet, sync, and have it live. Without
   * this the content team would sync a sheet and see nothing change, because a
   * tagged course only serves what a tag holds.
   * See `plans/260907-course-content-versions/README.md` section on Excel.
   */
  it('publishes the next patch tag', async () => {
    const { service, courses, versions } = makeService();
    await service.createTag(COURSE_ID, { tag: 'v1.0.0', setCurrent: true });

    const view = await service.autoTag(COURSE_ID);

    expect(view.tag).toBe('v1.0.1');
    expect(view.isCurrent).toBe(true);
    expect(courses[COURSE_ID].currentVersionId).toBe(String(versions[1]._id));
  });

  it('starts at v1.0.0 for a course that has never been tagged', async () => {
    const { service } = makeService();

    expect((await service.autoTag(COURSE_ID)).tag).toBe('v1.0.0');
  });
});

/**
 * Chốt an toàn của mục 6: không được tồn tại khoá đang live mà không có tag.
 * Gọi từ `course-publish.scheduler.ts` (cron mỗi phút, `updateMany` idempotent)
 * nên bản thân nó phải idempotent — tên tag cố định `v1.0.0` và nuốt xung đột,
 * chứ không patch-bump, kẻo hai tick chồng nhau đẻ ra v1.0.0 + v1.0.1.
 */
describe('ensureInitialTag', () => {
  it('tags an untagged course v1.0.0 and publishes it', async () => {
    const { service, courses, versions } = makeService();

    const view = await service.ensureInitialTag(COURSE_ID);

    expect(view?.tag).toBe('v1.0.0');
    expect(courses[COURSE_ID].currentVersionId).toBe(String(versions[0]._id));
  });

  it('does nothing to a course that already has a tag', async () => {
    const { service, versions } = makeService();
    await service.createTag(COURSE_ID, { tag: 'v2.0.0', setCurrent: true });

    expect(await service.ensureInitialTag(COURSE_ID)).toBeNull();
    expect(versions).toHaveLength(1);
  });

  /** Hai tick cron chồng nhau: tick sau phải im lặng bỏ qua, không nổ. */
  it('swallows a raced duplicate instead of throwing', async () => {
    const { service } = makeService({ duplicateOnCreate: true });

    await expect(service.ensureInitialTag(COURSE_ID)).resolves.toBeNull();
  });

  /** Nhưng lỗi thật thì vẫn phải nổ, không được nuốt. */
  it('still throws when freezing the content fails', async () => {
    const { service } = makeService({ failRowInsert: true });

    await expect(service.ensureInitialTag(COURSE_ID)).rejects.toThrow();
  });
});

describe('backfill', () => {
  /** Rollout: every existing course gets v1.0.0 so nothing looks different. */
  it('tags every untagged course and points it at v1.0.0', async () => {
    const { service, courses, versions } = makeService();

    const result = await service.backfill();

    expect(result.tagged).toEqual([COURSE_ID]);
    expect(versions[0].tag).toBe('v1.0.0');
    expect(courses[COURSE_ID].currentVersionId).toBe(String(versions[0]._id));
  });

  it('skips a course that already has a tag', async () => {
    const { service } = makeService();
    await service.createTag(COURSE_ID, { tag: 'v1.0.0', setCurrent: true });

    const result = await service.backfill();

    expect(result.tagged).toEqual([]);
    expect(result.skipped).toEqual([COURSE_ID]);
  });
});

/**
 * Sổ cửa sổ thời gian là thứ duy nhất cho phép bảng so sánh gán một event học
 * tập về đúng tag người đó đã đọc, nên nó phải đúng ở CẢ đường roll back —
 * chỗ dễ sai nhất, vì một tag quay lại live lần thứ hai và phải có đoạn thứ
 * hai chứ không phải sửa đoạn cũ.
 */
describe('CourseVersionService — sổ cửa sổ phiên bản', () => {
  it('mở một đoạn khi đánh tag đầu tiên', async () => {
    const { service, activations } = makeService();

    await service.createTag(COURSE_ID, { tag: 'v1.0.0', setCurrent: true } as any);

    expect(activations).toHaveLength(1);
    expect(activations[0]).toMatchObject({
      courseId: COURSE_ID,
      tag: 'v1.0.0',
      to: null,
    });
    expect(activations[0].from).toBeInstanceOf(Date);
  });

  it('đóng đoạn cũ và mở đoạn mới khi đánh tag tiếp', async () => {
    const { service, activations } = makeService();

    await service.createTag(COURSE_ID, { tag: 'v1.0.0', setCurrent: true } as any);
    await service.createTag(COURSE_ID, { tag: 'v1.0.1', setCurrent: true } as any);

    expect(activations.map(a => a.tag)).toEqual(['v1.0.0', 'v1.0.1']);
    expect(activations[0].to).toBeInstanceOf(Date);
    expect(activations[1].to).toBeNull();
    // Không hở và không chồng: đoạn trước đóng đúng lúc đoạn sau mở.
    expect(+activations[0].to).toBe(+activations[1].from);
  });

  it('roll back cho tag cũ một đoạn THỨ HAI, không sửa đoạn thứ nhất', async () => {
    const { service, activations } = makeService();

    await service.createTag(COURSE_ID, { tag: 'v1.0.0', setCurrent: true } as any);
    await service.createTag(COURSE_ID, { tag: 'v1.0.1', setCurrent: true } as any);
    await service.setCurrent(COURSE_ID, 'v1.0.0');

    expect(activations.map(a => a.tag)).toEqual([
      'v1.0.0',
      'v1.0.1',
      'v1.0.0',
    ]);
    expect(activations[0].to).toBeInstanceOf(Date);
    expect(activations[1].to).toBeInstanceOf(Date);
    expect(activations[2].to).toBeNull();
    // Đoạn đầu của v1.0.0 giữ nguyên khoảng của nó — nếu bị nối vào đoạn mới
    // thì mọi event của v1.0.1 sẽ bị đếm sang v1.0.0.
    expect(+activations[0].to).toBe(+activations[1].from);
  });

  it('trỏ lại đúng tag đang live thì không thêm đoạn nào', async () => {
    const { service, activations } = makeService();

    await service.createTag(COURSE_ID, { tag: 'v1.0.0', setCurrent: true } as any);
    await service.setCurrent(COURSE_ID, 'v1.0.0');

    expect(activations).toHaveLength(1);
    expect(activations[0].to).toBeNull();
  });
});

describe('CourseVersionService — tag đóng băng nhưng chưa phát hành', () => {
  it('không mở cửa sổ nào: chưa ai đọc tag đó', async () => {
    const { service, activations } = makeService();

    await service.createTag(COURSE_ID, { tag: 'v1.0.0' } as any);

    expect(activations).toHaveLength(0);
  });
});
