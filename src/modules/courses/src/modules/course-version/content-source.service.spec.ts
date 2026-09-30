import { NotFoundException } from '@nestjs/common';

import { ContentSource } from './content-source.service';

/**
 * The one place that answers "read this from the working tree or from a tag".
 * `versionId === null` has to behave exactly like the code did before content
 * versions existed, because that is what every untagged course relies on.
 * See `plans/260907-course-content-versions/README.md` section 3.
 */
const COURSE_ID = '68c0000000000000000000c1';
const VERSION_ID = 'v1';
const OTHER_COURSE = '68c0000000000000000000c2';

const liveLesson = { _id: 'l1', courseId: COURSE_ID, title: { en: 'live lesson' } };
const liveKeypoint = { _id: 'k1', title: { en: 'live keypoint' } };
const liveItem = { _id: 'i1', keypointId: 'k1', title: { en: 'live item' } };
const liveRoadmap = { _id: 'r1', courseId: COURSE_ID, levels: [{ id: 1 }] };

const frozen = (doc: Record<string, unknown>) => ({ ...doc });

function makeSource() {
  const rows = [
    { versionId: VERSION_ID, courseId: COURSE_ID, entityType: 'lesson', entityId: 'l1', doc: frozen({ _id: 'l1', title: { en: 'tagged lesson' } }) },
    { versionId: VERSION_ID, courseId: COURSE_ID, entityType: 'keypoint', entityId: 'k1', doc: frozen({ _id: 'k1', title: { en: 'tagged keypoint' } }) },
    { versionId: VERSION_ID, courseId: COURSE_ID, entityType: 'learningItem', entityId: 'i1', doc: frozen({ _id: 'i1', keypointId: 'k1', title: { en: 'tagged item' } }) },
    { versionId: VERSION_ID, courseId: COURSE_ID, entityType: 'roadmap', entityId: 'r1', doc: frozen({ _id: 'r1', levels: [{ id: 9 }] }) },
    { versionId: VERSION_ID, courseId: COURSE_ID, entityType: 'course', entityId: COURSE_ID, doc: frozen({ title: { en: 'tagged course title' }, description: { en: 'tagged desc' }, image: 'tagged.png' }) },
    // Belongs to a course that has no current version.
    { versionId: 'vOld', courseId: OTHER_COURSE, entityType: 'keypoint', entityId: 'k9', doc: frozen({ _id: 'k9' }) },
  ];

  const publishedContentRepository = {
    async findEntity(versionId: string, entityType: string, entityId: string) {
      return rows.find(r => r.versionId === versionId && r.entityType === entityType && r.entityId === entityId)?.doc ?? null;
    },
    async findEntities(versionId: string, entityType: string, entityIds: string[]) {
      return rows.filter(r => r.versionId === versionId && r.entityType === entityType && entityIds.includes(r.entityId)).map(r => r.doc);
    },
    async findAllOfType(versionId: string, entityType: string) {
      return rows.filter(r => r.versionId === versionId && r.entityType === entityType).map(r => r.doc);
    },
    async findCourseIdByEntity(entityType: string, entityId: string) {
      return rows.find(r => r.entityType === entityType && r.entityId === entityId)?.courseId ?? null;
    },
    async findCourseIdsByEntities(entityType: string, entityIds: string[]) {
      const seen = new Map<string, string>();
      for (const r of rows)
        if (r.entityType === entityType && entityIds.includes(r.entityId))
          seen.set(r.entityId, r.courseId);

      return [...seen].map(([entityId, courseId]) => ({ entityId, courseId }));
    },
  };

  const courseVersionRepository = {
    async findOneByTag(courseId: string, tag: string) {
      return tag === 'v1.0.0' && courseId === COURSE_ID
        ? { _id: VERSION_ID, courseId, tag }
        : null;
    },
  };

  const courses: Record<string, any> = {
    [COURSE_ID]: { _id: COURSE_ID, currentVersionId: VERSION_ID },
    // A second course that has never been tagged.
    [OTHER_COURSE]: { _id: OTHER_COURSE, currentVersionId: null },
  };
  const courseRepository = {
    async findById(id: string) { return courses[id] ?? null; },
    async findVersionPointers(ids: string[]) {
      return ids.map(id => courses[id]).filter(Boolean);
    },
  };

  const roadmapRepository = { async findByCourseIds() { return [liveRoadmap]; } };
  const lessonRepository = {
    async findAllForExport() { return [liveLesson]; },
    async findByIds(ids: string[]) { return [liveLesson].filter(l => ids.includes(l._id)); },
    async findFullByIds(ids: string[]) { return [liveLesson].filter(l => ids.includes(l._id)); },
    async findBriefByCourse() { return [liveLesson]; },
  };
  const keypointRepository = {
    async findKeypointsByIds(ids: string[]) { return [liveKeypoint].filter(k => ids.includes(k._id)); },
    async findBriefByIds(ids: string[]) { return [liveKeypoint].filter(k => ids.includes(k._id)); },
  };
  const learningItemRepository = {
    async findAllByKeypointIds(ids: string[]) { return [liveItem].filter(i => ids.includes(i.keypointId)); },
    async findByIds(ids: string[]) { return [liveItem].filter(i => ids.includes(i._id)); },
  };

  // Mặc định không có đợt A/B nào — các test cũ phải giữ nguyên hành vi.
  const experiments = { async factsFor() { return null; } };

  return new ContentSource(
    publishedContentRepository as any,
    courseVersionRepository as any,
    courseRepository as any,
    roadmapRepository as any,
    lessonRepository as any,
    keypointRepository as any,
    learningItemRepository as any,
    experiments as any,
    // The tag branch fills `audio` from the clip store; these tests are about
    // WHICH bank answers, so a resolver that adds nothing keeps them on that.
    { attach: async (keypoints: any[]) => keypoints } as any,
  );
}

describe('ContentSource with versionId null', () => {
  it('reads lessons from the working tree', async () => {
    const lessons = await makeSource().getLessonsByCourse(COURSE_ID, null);

    expect(lessons).toEqual([liveLesson]);
  });

  it('reads keypoints from the working tree', async () => {
    expect(await makeSource().getKeypointsByIds(['k1'], null)).toEqual([liveKeypoint]);
  });

  it('reads learning items from the working tree', async () => {
    expect(await makeSource().getLearningItemsByKeypointIds(['k1'], null)).toEqual([liveItem]);
  });

  it('reads the roadmap from the working tree', async () => {
    expect(await makeSource().getRoadmap(COURSE_ID, null)).toEqual(liveRoadmap);
  });
});

describe('ContentSource with a versionId', () => {
  it('reads lessons from the tag, not the working tree', async () => {
    const lessons = await makeSource().getLessonsByCourse(COURSE_ID, VERSION_ID);

    expect(lessons).toEqual([{ _id: 'l1', title: { en: 'tagged lesson' } }]);
  });

  it('reads a single keypoint from the tag', async () => {
    expect(await makeSource().getKeypoint('k1', VERSION_ID)).toEqual({
      _id: 'k1',
      title: { en: 'tagged keypoint' },
    });
  });

  it('reads one learning item from the tag', async () => {
    expect(await makeSource().getLearningItem('i1', VERSION_ID)).toEqual({
      _id: 'i1',
      keypointId: 'k1',
      title: { en: 'tagged item' },
    });
  });

  it('reads learning items of a keypoint from the tag', async () => {
    expect(await makeSource().getLearningItemsByKeypointIds(['k1'], VERSION_ID)).toEqual([
      { _id: 'i1', keypointId: 'k1', title: { en: 'tagged item' } },
    ]);
  });

  /**
   * A keypoint dropped from the tag must read as absent, not fall through to
   * the working tree -- `saved-card` already relies on a missing keypoint to
   * drop the card quietly.
   */
  it('returns null for an entity the tag does not contain', async () => {
    expect(await makeSource().getKeypoint('k404', VERSION_ID)).toBeNull();
  });
});

describe('resolveVersionId', () => {
  it('gives an app request the course current version', async () => {
    const versionId = await makeSource().resolveVersionId(
      { _id: COURSE_ID, currentVersionId: VERSION_ID } as any,
      {},
    );

    expect(versionId).toBe(VERSION_ID);
  });

  it('gives the admin panel the working tree', async () => {
    const versionId = await makeSource().resolveVersionId(
      { _id: COURSE_ID, currentVersionId: VERSION_ID } as any,
      { 'x-ignore-content-version': '1' },
    );

    expect(versionId).toBeNull();
  });

  it('looks a requested tag up by name', async () => {
    const versionId = await makeSource().resolveVersionId(
      { _id: COURSE_ID, currentVersionId: null } as any,
      { 'x-ignore-content-version': '1' },
      'v1.0.0',
    );

    expect(versionId).toBe(VERSION_ID);
  });

  it('refuses a tag the course does not have', async () => {
    await expect(
      makeSource().resolveVersionId(
        { _id: COURSE_ID, currentVersionId: null } as any,
        { 'x-ignore-content-version': '1' },
        'v9.9.9',
      ),
    ).rejects.toThrow(NotFoundException);
  });
});

describe('resolveCourseOfKeypoint', () => {
  /** The lookup `keypoint.schema.ts` cannot do: it has no `courseId`. */
  it('finds the course a tagged keypoint belongs to', async () => {
    expect(await makeSource().resolveCourseOfKeypoint('k1')).toBe(COURSE_ID);
  });

  /** Never tagged -- the caller reads null as "use the working tree". */
  it('returns null for a keypoint no tag contains', async () => {
    expect(await makeSource().resolveCourseOfKeypoint('k404')).toBeNull();
  });
});

/**
 * Most app reads name a keypoint or a course, not a version. These resolve it
 * so no controller has to thread anything: the eight content services already
 * inject `RequestService` (they are already request-scoped), so they read the
 * panel header straight off `this.requestService.headers`.
 * See `plans/260907-course-content-versions/README.md` section 3.
 */
describe('versionForCourse', () => {
  it('gives an app request the course current version', async () => {
    expect(await makeSource().versionForCourse(COURSE_ID, {})).toBe(VERSION_ID);
  });

  it('gives the working tree for an untagged course', async () => {
    expect(await makeSource().versionForCourse(OTHER_COURSE, {})).toBeNull();
  });

  it('gives the panel the working tree', async () => {
    expect(
      await makeSource().versionForCourse(COURSE_ID, {
        'x-ignore-content-version': '1',
      }),
    ).toBeNull();
  });

  /** A course id that does not exist must not throw on a read path. */
  it('gives the working tree for an unknown course', async () => {
    expect(await makeSource().versionForCourse('68c00000000000000000ffff', {})).toBeNull();
  });
});

/**
 * `learning-item.findOne` and `lesson.findOne` receive only an id, so they
 * cannot know the course before reading -- and reading the working tree first
 * to find out would be wrong, since a draft entity may not exist in the tag at
 * all. One reverse lookup answers it for any entity type.
 */
describe('versionForEntity', () => {
  it('resolves a learning item through the course that tagged it', async () => {
    expect(await makeSource().versionForEntity('learningItem', 'i1', {})).toBe(
      VERSION_ID,
    );
  });

  it('resolves a lesson through the course that tagged it', async () => {
    expect(await makeSource().versionForEntity('lesson', 'l1', {})).toBe(
      VERSION_ID,
    );
  });

  it('gives the working tree for an entity no tag contains', async () => {
    expect(
      await makeSource().versionForEntity('learningItem', 'i404', {}),
    ).toBeNull();
  });
});

/**
 * `?version=` phải đi được TỚI resolver. Trước 2026-09-08 nó không: controller
 * không đọc query và service không truyền tham số thứ ba, nên panel gửi
 * `?version=rac` vẫn nhận 200 thay vì 400 — nhánh resolver có test nhưng không
 * ai gọi nó với `requested`.
 */
describe('versionForEntity truyền ?version= xuống resolver', () => {
  const PANEL = { 'x-ignore-content-version': '1' };

  it('panel xin đúng một tag thì đọc tag đó', async () => {
    expect(
      await makeSource().versionForEntity('lesson', 'l1', PANEL, 'v1.0.0'),
    ).toBe(VERSION_ID);
  });

  it('panel xin ?version=current thì đọc tag đang phát hành', async () => {
    expect(
      await makeSource().versionForEntity('lesson', 'l1', PANEL, 'current'),
    ).toBe(VERSION_ID);
  });

  it('panel xin tag không tồn tại thì báo không tìm thấy', async () => {
    await expect(
      makeSource().versionForEntity('lesson', 'l1', PANEL, 'v9.9.9'),
    ).rejects.toThrow(NotFoundException);
  });

  it('request của app thì bỏ qua ?version=, vẫn đọc tag đang phát hành', async () => {
    expect(
      await makeSource().versionForEntity('lesson', 'l1', {}, 'v9.9.9'),
    ).toBe(VERSION_ID);
  });

  it('versionForKeypoint cũng truyền được', async () => {
    expect(
      await makeSource().versionForKeypoint('k1', PANEL, 'v1.0.0'),
    ).toBe(VERSION_ID);
  });
});

describe('versionForKeypoint', () => {
  /** `keypoint.schema.ts` has no `courseId`, so this goes through the tag index. */
  it('resolves through the course the keypoint was tagged under', async () => {
    expect(await makeSource().versionForKeypoint('k1', {})).toBe(VERSION_ID);
  });

  it('gives the working tree for a keypoint no tag contains', async () => {
    expect(await makeSource().versionForKeypoint('k404', {})).toBeNull();
  });

  it('gives the working tree when the owning course has no current version', async () => {
    expect(await makeSource().versionForKeypoint('k9', {})).toBeNull();
  });

  it('gives the panel the working tree without any lookup', async () => {
    expect(
      await makeSource().versionForKeypoint('k1', {
        'x-ignore-content-version': '1',
      }),
    ).toBeNull();
  });
});

/**
 * Cross-course lists (saved cards, daily warm-up) hold keypoints from many
 * courses at once, each possibly on a different tag. Resolving one at a time
 * would be N round-trips per list render.
 */
describe('versionsForKeypoints', () => {
  it('resolves a mixed batch in one pass', async () => {
    const map = await makeSource().versionsForKeypoints(['k1', 'k9', 'k404'], {});

    expect(map.get('k1')).toBe(VERSION_ID);
    expect(map.get('k9')).toBeNull();
    expect(map.get('k404')).toBeNull();
  });

  it('returns an all-working-tree map for the panel', async () => {
    const map = await makeSource().versionsForKeypoints(['k1'], {
      'x-ignore-content-version': '1',
    });

    expect(map.get('k1')).toBeNull();
  });

  it('handles an empty batch', async () => {
    expect((await makeSource().versionsForKeypoints([], {})).size).toBe(0);
  });
});

/**
 * Cross-course lists -- saved cards, the study journal, my-courses, daily
 * warm-up -- hold entities from many courses, each possibly on a different
 * tag, and some on courses with no tag at all. One pass has to serve all of
 * them, or these lists would show the draft titles an editor is still working
 * on.
 * See `plans/260907-course-content-versions/README.md` section 3.
 */
describe('getKeypointBriefsAcrossVersions', () => {
  it('reads each keypoint from its own bank in one pass', async () => {
    const briefs = await makeSource().getKeypointBriefsAcrossVersions(
      ['k1', 'k9'],
      {},
    );
    const byId = new Map(briefs.map(b => [String(b._id), b]));

    // k1 is on the tag; k9's course has no current version, so the working
    // tree answers for it.
    expect(byId.get('k1')?.title).toEqual({ en: 'tagged keypoint' });
    expect(byId.get('k9')).toBeUndefined();
    expect(byId.get('k1')).toBeDefined();
  });

  it('reads everything from the working tree for the panel', async () => {
    const briefs = await makeSource().getKeypointBriefsAcrossVersions(['k1'], {
      'x-ignore-content-version': '1',
    });

    expect(briefs[0].title).toEqual({ en: 'live keypoint' });
  });

  it('handles an empty list', async () => {
    expect(await makeSource().getKeypointBriefsAcrossVersions([], {})).toEqual([]);
  });

  /** The brief must never carry the transcript, whichever bank answered. */
  it('never returns audio.text from the tag', async () => {
    const briefs = await makeSource().getKeypointBriefsAcrossVersions(['k1'], {});

    expect((briefs[0] as any).audio?.text).toBeUndefined();
  });
});

describe('getLessonBriefsAcrossVersions', () => {
  it('reads each lesson from its own bank in one pass', async () => {
    const briefs = await makeSource().getLessonBriefsAcrossVersions(['l1'], {});

    expect(briefs[0].title).toEqual({ en: 'tagged lesson' });
  });

  it('reads from the working tree for the panel', async () => {
    const briefs = await makeSource().getLessonBriefsAcrossVersions(['l1'], {
      'x-ignore-content-version': '1',
    });

    expect(briefs[0].title).toEqual({ en: 'live lesson' });
  });
});

/**
 * Coach and habit read content as raw material across whichever course and tag
 * it happens to sit on, so they need the same across-versions readers the
 * cross-course lists use.
 * See `plans/260907-course-content-versions/README.md` section 3.
 */
describe('getLearningItemsAcrossVersions', () => {
  it('reads each item from its own bank', async () => {
    const items = await makeSource().getLearningItemsAcrossVersions(['i1'], {});

    expect(items[0].title).toEqual({ en: 'tagged item' });
  });

  it('reads from the working tree for the panel', async () => {
    const items = await makeSource().getLearningItemsAcrossVersions(['i1'], {
      'x-ignore-content-version': '1',
    });

    expect(items[0].title).toEqual({ en: 'live item' });
  });

  it('handles an empty list', async () => {
    expect(await makeSource().getLearningItemsAcrossVersions([], {})).toEqual([]);
  });
});

describe('getLearningItemsByKeypointIdsAcrossVersions', () => {
  it('reads the items of each keypoint from that keypoint own bank', async () => {
    const items = await makeSource().getLearningItemsByKeypointIdsAcrossVersions(
      ['k1'],
      {},
    );

    expect(items[0].title).toEqual({ en: 'tagged item' });
  });

  it('reads from the working tree for the panel', async () => {
    const items = await makeSource().getLearningItemsByKeypointIdsAcrossVersions(
      ['k1'],
      { 'x-ignore-content-version': '1' },
    );

    expect(items[0].title).toEqual({ en: 'live item' });
  });
});

describe('getLessonChipsByCourse', () => {
  it('reads the tag and keeps the chip projection, newest index first', async () => {
    const chips = await makeSource().getLessonChipsByCourse(COURSE_ID, {});

    expect(chips[0].title).toEqual({ en: 'tagged lesson' });
    expect(Object.keys(chips[0]).sort()).toEqual(['_id', 'title']);
  });

  it('reads the working tree for the panel', async () => {
    const chips = await makeSource().getLessonChipsByCourse(COURSE_ID, {
      'x-ignore-content-version': '1',
    });

    expect(chips[0].title).toEqual({ en: 'live lesson' });
  });
});

/**
 * Xem lại một tag CŨ: `Course.published` chỉ là cache của tag đang phát hành,
 * nên field biên tập của tag khác phải đọc từ chính row `course` đã đóng băng.
 */
describe('getCourseFields', () => {
  it('đọc field biên tập đã đóng băng của tag', async () => {
    expect(await makeSource().getCourseFields(COURSE_ID, VERSION_ID)).toEqual({
      title: { en: 'tagged course title' },
      description: { en: 'tagged desc' },
      image: 'tagged.png',
    });
  });

  it('trả null khi tag không chứa khoá đó', async () => {
    expect(
      await makeSource().getCourseFields('68c00000000000000000ffff', VERSION_ID),
    ).toBeNull();
  });
});
