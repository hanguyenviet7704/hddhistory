import { contentHash } from './content-hash.util';
import { buildSnapshot, diffSnapshots } from './content-snapshot';

const course = {
  _id: 'c1',
  title: { en: 'Say no', vi: 'Nói không' },
  description: { en: 'desc', vi: 'mô tả' },
  image: 'https://cdn.test/c1.png',
  status: 'PUBLISHED',
  prices: [{ currency: 'VND', amount: 199000 }],
  countries: ['VN'],
  publishAt: new Date('2026-08-01T00:00:00Z'),
};

describe('buildSnapshot', () => {
  /**
   * Decision 3 of the design: a tag freezes editorial content, not
   * distribution or commerce. If `status`/`publishAt` were frozen,
   * `course-publish.scheduler.ts` would silently stop working, and changing a
   * price would need a content tag.
   * See `plans/260907-course-content-versions/README.md` §1.
   */
  it('freezes only the editorial fields of the course', () => {
    const { rows } = buildSnapshot({ course, roadmap: null, lessons: [], keypoints: [], learningItems: [] });
    const courseRow = rows.find(row => row.entityType === 'course');

    expect(courseRow?.doc).toEqual({
      title: course.title,
      description: course.description,
      image: course.image,
    });
    expect(courseRow?.entityId).toBe('c1');
  });

  it('emits one row per content document', () => {
    const { rows, entityCounts } = buildSnapshot({
      course,
      roadmap: { _id: 'r1', courseId: 'c1', levels: [] },
      lessons: [{ _id: 'l1' }, { _id: 'l2' }],
      keypoints: [{ _id: 'k1' }],
      learningItems: [{ _id: 'i1' }, { _id: 'i2' }, { _id: 'i3' }],
    });

    const byType = (type: string) => rows.filter(row => row.entityType === type);
    expect(byType('course')).toHaveLength(1);
    expect(byType('roadmap')).toHaveLength(1);
    expect(byType('lesson')).toHaveLength(2);
    expect(byType('keypoint')).toHaveLength(1);
    expect(byType('learningItem')).toHaveLength(3);
    expect(entityCounts).toEqual({ lessons: 2, keypoints: 1, learningItems: 3 });
  });

  /** A course whose roadmap was never created must still be taggable. */
  it('omits the roadmap row when the course has no roadmap', () => {
    const { rows } = buildSnapshot({ course, roadmap: null, lessons: [], keypoints: [], learningItems: [] });

    expect(rows.some(row => row.entityType === 'roadmap')).toBe(false);
  });

  it('hashes every row with contentHash', () => {
    const keypoint = { _id: 'k1', title: { en: 'x' }, index: 1 };
    const { rows } = buildSnapshot({ course, roadmap: null, lessons: [], keypoints: [keypoint], learningItems: [] });
    const row = rows.find(r => r.entityType === 'keypoint');

    expect(row?.docHash).toBe(contentHash(keypoint));
  });
});

/**
 * The "N changes not in any tag" banner. Without it, re-tagging to pick up a
 * voiceover regen would quietly publish half-finished copy edits, since a tag
 * always snapshots the whole tree.
 * See `plans/260907-course-content-versions/README.md` §4.
 */
describe('diffSnapshots', () => {
  const published = [
    { entityType: 'keypoint' as const, entityId: 'k1', docHash: 'h1' },
    { entityType: 'keypoint' as const, entityId: 'k2', docHash: 'h2' },
    { entityType: 'lesson' as const, entityId: 'l1', docHash: 'h3' },
  ];

  it('reports nothing when the working tree matches the tag', () => {
    expect(diffSnapshots(published, published)).toEqual({
      added: [],
      changed: [],
      removed: [],
      total: 0,
    });
  });

  it('reports a document that exists only in the working tree as added', () => {
    const live = [...published, { entityType: 'keypoint' as const, entityId: 'k3', docHash: 'h4' }];

    expect(diffSnapshots(live, published).added).toEqual([
      { entityType: 'keypoint', entityId: 'k3' },
    ]);
  });

  it('reports a document missing from the working tree as removed', () => {
    const live = published.filter(row => row.entityId !== 'k2');

    expect(diffSnapshots(live, published).removed).toEqual([
      { entityType: 'keypoint', entityId: 'k2' },
    ]);
  });

  it('reports a different hash as changed', () => {
    const live = published.map(row =>
      row.entityId === 'l1' ? { ...row, docHash: 'edited' } : row,
    );

    expect(diffSnapshots(live, published).changed).toEqual([
      { entityType: 'lesson', entityId: 'l1' },
    ]);
  });

  /** Ids repeat across types, so identity is the pair, never the id alone. */
  it('keys on entityType and entityId together', () => {
    const live = [{ entityType: 'lesson' as const, entityId: 'k1', docHash: 'h1' }];
    const onlyK1 = [published[0]];
    const diff = diffSnapshots(live, onlyK1);

    expect(diff.added).toEqual([{ entityType: 'lesson', entityId: 'k1' }]);
    expect(diff.removed).toEqual([{ entityType: 'keypoint', entityId: 'k1' }]);
  });

  it('totals every kind of change', () => {
    const live = [
      { entityType: 'keypoint' as const, entityId: 'k1', docHash: 'edited' },
      { entityType: 'keypoint' as const, entityId: 'k9', docHash: 'new' },
    ];

    expect(diffSnapshots(live, published).total).toBe(4);
  });
});
