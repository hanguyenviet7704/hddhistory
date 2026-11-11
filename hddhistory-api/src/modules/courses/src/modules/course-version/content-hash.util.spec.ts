import { contentHash } from './content-hash.util';

/**
 * The hash is what tells an editor "you have N changes not in any tag yet"
 * (`plans/260907-course-content-versions/README.md` §4). It has to be a hash
 * and not `updatedAt`, because the reorder and question-folder write paths go
 * through `bulkWrite`, which `AbstractRepository` does not stamp — those edits
 * would otherwise report as "no changes".
 */
describe('contentHash', () => {
  const keypoint = {
    _id: '68b0000000000000000000a1',
    title: { en: 'Say no kindly', vi: 'Nói không tử tế' },
    index: 2,
    createdAt: new Date('2026-08-01T00:00:00Z'),
    updatedAt: new Date('2026-08-01T00:00:00Z'),
  };

  it('is stable for the same document', () => {
    expect(contentHash(keypoint)).toBe(contentHash(keypoint));
    expect(contentHash(keypoint)).toMatch(/^[0-9a-f]{64}$/);
  });

  /**
   * Every write through `updateOne` restamps `updatedAt`/`updatedBy` even when
   * the editor changed nothing, so counting those as changes would show phantom
   * pending edits on a course nobody touched.
   */
  it('ignores updatedAt and updatedBy', () => {
    const restamped = {
      ...keypoint,
      updatedAt: new Date('2026-09-07T10:33:00Z'),
      updatedBy: { _id: 'u1', email: 'editor@eupgroup.net' },
    };

    expect(contentHash(restamped)).toBe(contentHash(keypoint));
  });

  it('does not depend on key insertion order', () => {
    const reordered = {
      updatedAt: keypoint.updatedAt,
      index: keypoint.index,
      title: { vi: keypoint.title.vi, en: keypoint.title.en },
      createdAt: keypoint.createdAt,
      _id: keypoint._id,
    };

    expect(contentHash(reordered)).toBe(contentHash(keypoint));
  });

  it('changes when content changes', () => {
    const edited = { ...keypoint, title: { ...keypoint.title, vi: 'Nói không' } };

    expect(contentHash(edited)).not.toBe(contentHash(keypoint));
  });

  /**
   * Array order carries meaning here: `lesson.keypoints[]` is the study order
   * and `learningItem.questions[]` the question order, so a pure reorder is a
   * real content change that must require a new tag.
   */
  it('changes when array order changes', () => {
    const a = { _id: 'l1', keypoints: ['k1', 'k2', 'k3'] };
    const b = { _id: 'l1', keypoints: ['k1', 'k3', 'k2'] };

    expect(contentHash(a)).not.toBe(contentHash(b));
  });

  /** Mongo hands back ObjectId/Date objects; a lean doc holds primitives. */
  it('treats an ObjectId-like value and its string form as equal', () => {
    const asObject = { _id: { toString: () => 'abc123' }, index: 1 };
    const asString = { _id: 'abc123', index: 1 };

    expect(contentHash(asObject)).toBe(contentHash(asString));
  });
});
