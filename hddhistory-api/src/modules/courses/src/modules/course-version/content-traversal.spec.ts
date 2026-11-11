import { collectKeypointIds, collectLessonIds } from './content-traversal';

/**
 * What "the content of this course" means when the schema has no ownership
 * tree: `keypoint.schema.ts` has no `courseId` at all, and a lesson can be
 * referenced by the roadmap without carrying the right `courseId`. Tagging has
 * to collect the union, or a freshly created lesson silently misses the tag.
 * See `plans/260907-course-content-versions/README.md` §4.
 */
describe('collectLessonIds', () => {
  it('takes lessons found by courseId', () => {
    expect(
      collectLessonIds({
        courseLessons: [{ _id: 'l1' }, { _id: 'l2' }],
        roadmap: null,
      }),
    ).toEqual(['l1', 'l2']);
  });

  /** A roadmap node points at a lesson through five different columns. */
  it('takes every lesson a roadmap node references', () => {
    const ids = collectLessonIds({
      courseLessons: [],
      roadmap: {
        levels: [
          {
            nodes: [
              {
                lessonIds: ['l3', 'l4'],
                openingVideoId: 'l5',
                roleplayId: 'l6',
                outputId: 'l7',
                closingVideoId: 'l8',
              },
            ],
          },
        ],
      },
    });

    expect(ids.sort()).toEqual(['l3', 'l4', 'l5', 'l6', 'l7', 'l8']);
  });

  /**
   * The reason this is a union: a lesson created but not yet placed on the
   * roadmap is real content the editor expects the tag to carry.
   */
  it('unions both sources and de-duplicates', () => {
    expect(
      collectLessonIds({
        courseLessons: [{ _id: 'l1' }, { _id: 'l2' }],
        roadmap: { levels: [{ nodes: [{ lessonIds: ['l2', 'l9'] }] }] },
      }),
    ).toEqual(['l1', 'l2', 'l9']);
  });

  it('drops blank and missing references', () => {
    expect(
      collectLessonIds({
        courseLessons: [{ _id: 'l1' }],
        roadmap: {
          levels: [{ nodes: [{ lessonIds: ['', null as any], outputId: '' }] }],
        },
      }),
    ).toEqual(['l1']);
  });
});

describe('collectKeypointIds', () => {
  it('takes the keypoints of every lesson, in order', () => {
    expect(
      collectKeypointIds({
        lessons: [{ _id: 'l1', keypoints: ['k1', 'k2'] }, { _id: 'l2', keypoints: ['k3'] }],
        roadmap: null,
      }),
    ).toEqual(['k1', 'k2', 'k3']);
  });

  /** `levels[].keypointIds` is computed by the roadmap editor, not by lessons. */
  it('also takes keypoints listed directly on a roadmap level', () => {
    expect(
      collectKeypointIds({
        lessons: [{ _id: 'l1', keypoints: ['k1'] }],
        roadmap: { levels: [{ keypointIds: ['k1', 'k4'] }] },
      }),
    ).toEqual(['k1', 'k4']);
  });

  it('drops blanks and de-duplicates', () => {
    expect(
      collectKeypointIds({
        lessons: [{ _id: 'l1', keypoints: ['k1', '', 'k1'] }],
        roadmap: { levels: [{ keypointIds: [null as any] }] },
      }),
    ).toEqual(['k1']);
  });
});
