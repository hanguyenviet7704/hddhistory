import {
  applyPublishedFields,
  toPlainDoc,
  courseLessonChip,
  exercisesWithQuestionsOf,
  narratableItemsOf,
  warmUpQuestionsOf,
  keypointBrief,
  learningItemBrief,
  lessonBrief,
} from './content-projection';

/**
 * A tag stores whole documents, but the working-tree read paths return
 * PROJECTIONS. If the tagged path returned the full documents instead, a
 * tagged course would silently answer with a different, much bigger payload
 * than an untagged one -- and the roadmap is the app's main screen.
 * See `plans/260907-course-content-versions/README.md` section 3.
 */
describe('keypointBrief', () => {
  const frozen = {
    _id: 'k1',
    title: { en: 'Say no' },
    description: { en: 'desc' },
    estimateCompleTime: { en: '3 min' },
    estimateCompleTimeNumber: 3,
    image: 'https://cdn.test/k1.png',
    index: 4,
    tag: ['t1'],
    audio: {
      url: { en: 'https://cdn.test/k1.mp3' },
      text: { en: 'a very long transcript'.repeat(200) },
    },
    learningItems: [{ _id: 'i1' }],
  };

  /**
   * `audio.text` is a five-language TTS transcript, ~8KB per keypoint, and it
   * used to be ~95% of every lesson's bytes on the roadmap. Dropping it here
   * is why `findBriefByIds` exists at all.
   */
  it('keeps only the audio url, never the transcript', () => {
    const brief = keypointBrief(frozen) as any;

    expect(brief.audio).toEqual({ url: { en: 'https://cdn.test/k1.mp3' } });
    expect(brief.audio.text).toBeUndefined();
  });

  it('keeps exactly the fields the working-tree projection keeps', () => {
    expect(Object.keys(keypointBrief(frozen)).sort()).toEqual([
      '_id',
      'audio',
      'description',
      'estimateCompleTime',
      'estimateCompleTimeNumber',
      'image',
      'title',
    ]);
  });

  it('omits audio entirely when the keypoint has none', () => {
    const brief = keypointBrief({ _id: 'k2', title: { en: 'x' } }) as any;

    expect('audio' in brief).toBe(false);
  });
});

/** Mirrors `LearningItemRepository.findAllBrief`'s select list. */
describe('learningItemBrief', () => {
  const frozen = {
    _id: 'i1',
    keypointId: 'k1',
    title: { en: 'Theory' },
    index: 3,
    type: 'THEORY',
    image: 'img',
    isSub: false,
    documents: [{ content: 'a very long body'.repeat(500) }],
    questions: [{ _id: 'q1' }],
  };

  it('keeps exactly the fields the working-tree projection keeps', () => {
    expect(Object.keys(learningItemBrief(frozen)).sort()).toEqual([
      '_id',
      'image',
      'index',
      'isSub',
      'keypointId',
      'title',
      'type',
    ]);
  });

  /** The body is the whole point of not sending it in a list. */
  it('drops the document bodies and questions', () => {
    const brief = learningItemBrief(frozen) as any;

    expect(brief.documents).toBeUndefined();
    expect(brief.questions).toBeUndefined();
  });
});

describe('lessonBrief', () => {
  const frozen = {
    _id: 'l1',
    courseId: 'c1',
    title: { en: 'Lesson' },
    type: 'LESSON',
    estimateCompleTime: { en: '5 min' },
    estimateCompleTimeNumber: 5,
    keypoints: ['k1', 'k2'],
    icon: 'icon',
    lightIcon: 'lightIcon',
    learningItemId: 'i1',
    description: { en: 'd' },
    image: 'img',
    index: 2,
    AIConfig: 'cfg',
    animation: 'anim',
    status: 'PUBLISHED',
    video: { thumbnail: 'thumb', url: 'https://cdn.test/v.mp4' },
  };

  it('keeps exactly the fields the working-tree projection keeps', () => {
    expect(Object.keys(lessonBrief(frozen)).sort()).toEqual([
      '_id',
      'description',
      'estimateCompleTime',
      'estimateCompleTimeNumber',
      'icon',
      'image',
      'keypoints',
      'learningItemId',
      'lightIcon',
      'title',
      'type',
      'video',
    ]);
  });

  /** The projection is `'video.thumbnail': 1` — not the whole video object. */
  it('keeps only the video thumbnail', () => {
    expect((lessonBrief(frozen) as any).video).toEqual({ thumbnail: 'thumb' });
  });

  it('omits video entirely when the lesson has none', () => {
    expect('video' in lessonBrief({ _id: 'l2', title: {} })).toBe(false);
  });
});

/**
 * The app must read the frozen title/description/image, never the draft the
 * editor is still working on. The cache lives on the course document so the
 * list and search stay single-collection.
 */
describe('applyPublishedFields', () => {
  const course = {
    _id: 'c1',
    title: { en: 'Draft title' },
    description: { en: 'Draft desc' },
    image: 'draft.png',
    status: 'PUBLISHED',
    prices: [{ currency: 'VND', amount: 1 }],
    published: {
      title: { en: 'Published title' },
      description: { en: 'Published desc' },
      image: 'published.png',
    },
  };

  it('overlays the published editorial fields', () => {
    const view = applyPublishedFields(course) as any;

    expect(view.title).toEqual({ en: 'Published title' });
    expect(view.description).toEqual({ en: 'Published desc' });
    expect(view.image).toBe('published.png');
  });

  /** Distribution and pricing are deliberately not frozen by a tag. */
  it('leaves distribution and pricing on the live values', () => {
    const view = applyPublishedFields(course) as any;

    expect(view.status).toBe('PUBLISHED');
    expect(view.prices).toEqual([{ currency: 'VND', amount: 1 }]);
  });

  it('returns an untagged course untouched', () => {
    const untagged = { _id: 'c2', title: { en: 'Only draft' }, published: null };

    expect(applyPublishedFields(untagged)).toBe(untagged);
  });

  /** The panel edits the draft, so it must never get the overlay. */
  it('returns the course untouched when told not to overlay', () => {
    expect(applyPublishedFields(course, false)).toBe(course);
  });
});


/**
 * Mirrors `LearningItemRepository.findWarmUpEligibleExercisesByKeypointIds`
 * for the tag path: same filter (EXERCISE items, questions flagged
 * `isDailyWarmUp`), same order (by item `index`). A pure function so the
 * duplicated rule is pinned rather than left to drift.
 */
describe('warmUpQuestionsOf', () => {
  const items = [
    {
      _id: 'i2',
      index: 2,
      type: 'EXERCISE',
      questions: [
        { _id: 'q3', isDailyWarmUp: true },
        { _id: 'q4', isDailyWarmUp: false },
      ],
    },
    {
      _id: 'i1',
      index: 1,
      type: 'EXERCISE',
      questions: [{ _id: 'q1', isDailyWarmUp: true }],
    },
    // A theory item never contributes warm-up questions.
    {
      _id: 'i3',
      index: 0,
      type: 'THEORY',
      questions: [{ _id: 'q0', isDailyWarmUp: true }],
    },
  ];

  it('keeps only flagged questions of exercise items, ordered by index', () => {
    expect(warmUpQuestionsOf(items).map((q: any) => q._id)).toEqual([
      'q1',
      'q3',
    ]);
  });

  it('returns nothing when no question is flagged', () => {
    const none = [
      { _id: 'i1', index: 1, type: 'EXERCISE', questions: [{ _id: 'q1' }] },
    ];

    expect(warmUpQuestionsOf(none)).toEqual([]);
  });

  it('tolerates items with no questions array', () => {
    expect(warmUpQuestionsOf([{ _id: 'i1', index: 1, type: 'EXERCISE' }])).toEqual(
      [],
    );
  });
});


/** Mirrors `LearningItemRepository.findNarratableByKeypoint(s)`. */
describe('narratableItemsOf', () => {
  const items = [
    { _id: 'i3', index: 3, type: 'EXERCISE' },
    { _id: 'i1', index: 1, type: 'THEORY' },
    { _id: 'i2', index: 2, type: 'ROLEPLAY' },
  ];

  it('keeps theory and exercise, ordered by index', () => {
    expect(narratableItemsOf(items).map(i => i._id)).toEqual(['i1', 'i3']);
  });

  it('drops every other type', () => {
    expect(narratableItemsOf([{ _id: 'x', index: 0, type: 'ROLEPLAY' }])).toEqual([]);
  });
});

/** Mirrors `LearningItemRepository.findExercisesByKeypoints`. */
describe('exercisesWithQuestionsOf', () => {
  const items = [
    { _id: 'i2', keypointId: 'k2', index: 1, type: 'EXERCISE', questions: [{ _id: 'q' }] },
    { _id: 'i1', keypointId: 'k1', index: 2, type: 'EXERCISE', questions: [{ _id: 'q' }] },
    { _id: 'i0', keypointId: 'k1', index: 1, type: 'EXERCISE', questions: [{ _id: 'q' }] },
    // `'questions.0': { $exists: true }` -- an exercise with no question is skipped.
    { _id: 'i9', keypointId: 'k1', index: 0, type: 'EXERCISE', questions: [] },
    { _id: 'i8', keypointId: 'k1', index: 0, type: 'THEORY', questions: [{ _id: 'q' }] },
  ];

  it('keeps exercises that have questions, ordered by keypoint then index', () => {
    expect(exercisesWithQuestionsOf(items).map(i => i._id)).toEqual([
      'i0',
      'i1',
      'i2',
    ]);
  });
});

/** Mirrors `LessonRepository.findBriefByCourse` — note the descending index. */
describe('courseLessonChip', () => {
  it('keeps exactly the four fields that projection keeps', () => {
    const chip = courseLessonChip({
      _id: 'l1',
      title: { en: 'L' },
      index: 2,
      keypoints: ['k1'],
      courseId: 'c1',
      description: { en: 'nope' },
      image: 'nope',
    });

    expect(Object.keys(chip).sort()).toEqual([
      '_id',
      'courseId',
      'index',
      'keypoints',
      'title',
    ]);
  });
});


/**
 * 2026-09-18 — trang sửa khoá học trên panel trắng bóc.
 *
 * `GET /courses/:id` trả về `{$__, $isNew, _doc}` thay vì khoá học: `findOne`
 * của repository trả document đã hydrate, và trải nó ra thì chỉ nhận được
 * thuộc tính nội bộ. Danh sách thoát nạn chỉ vì `paginateQuery` có `.lean()` —
 * nên cùng một hàm chiếu, một đường sống một đường chết.
 */
describe('applyPublishedFields · document đã hydrate', () => {
  /** Giả một document Mongoose: field thật nằm trong `_doc`, lộ ra qua `toObject`. */
  const fakeDoc = (fields: Record<string, unknown>) => {
    const doc = {
      $__: { activePaths: {} },
      $isNew: false,
      _doc: fields,
      toObject: () => ({ ...fields }),
    };

    return Object.assign(doc, fields) as never;
  };

  it('trả về field thật, không trả `_doc`/`$__`', () => {
    const out = applyPublishedFields(
      fakeDoc({
        _id: 'c1',
        title: { vi: 'nháp' },
        status: 'PUBLISHED',
        published: { title: { vi: 'đã phát hành' } },
      }),
    ) as Record<string, unknown>;

    expect(out._doc).toBeUndefined();
    expect(out.$__).toBeUndefined();
    expect(out._id).toBe('c1');
    expect(out.status).toBe('PUBLISHED');
    // Phần đã phát hành vẫn đè lên bản nháp — đó là việc của hàm này.
    expect(out.title).toEqual({ vi: 'đã phát hành' });
  });

  it('object thường đi qua y nguyên', () => {
    const out = toPlainDoc({ _id: 'c2', title: 'x' });
    expect(out).toEqual({ _id: 'c2', title: 'x' });
  });
});
