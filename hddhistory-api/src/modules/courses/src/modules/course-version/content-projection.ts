type Doc = Record<string, any>;

/** Copy only the listed keys that the source actually has. */
const pick = (doc: Doc, keys: string[]): Doc => {
  const out: Doc = {};
  for (const key of keys) if (key in doc) out[key] = doc[key];

  return out;
};

/**
 * A tag freezes whole documents, but the working-tree read paths answer with
 * projections. These re-apply the same projections to a frozen document so a
 * tagged course returns byte-for-byte the same shape as an untagged one.
 * See `plans/260907-course-content-versions/README.md` section 3.
 */

/**
 * Mirrors `KeypointRepository.findBriefByIds`. The important part is `audio`:
 * only `url` survives. The full `audio.text` is a five-language TTS transcript
 * (~8KB per keypoint) that used to be ~95% of each lesson's bytes on the
 * roadmap, and no client reads it there.
 */
export const keypointBrief = (doc: Doc): Doc => {
  const brief = pick(doc, [
    '_id',
    'title',
    'description',
    'estimateCompleTime',
    'estimateCompleTimeNumber',
    'image',
  ]);
  if (doc.audio) brief.audio = pick(doc.audio, ['url']);

  return brief;
};

/**
 * Mirrors `LearningItemRepository.findAllBrief`. Drops `documents` and
 * `questions` — the bodies are the whole reason a list does not send them.
 */
export const learningItemBrief = (doc: Doc): Doc =>
  pick(doc, [
    '_id',
    'title',
    'index',
    'type',
    'keypointId',
    'image',
    'isSub',
  ]);

/** Mirrors `LessonRepository.findByIds` — note `'video.thumbnail': 1`. */
export const lessonBrief = (doc: Doc): Doc => {
  const brief = pick(doc, [
    '_id',
    'title',
    'type',
    'estimateCompleTime',
    'estimateCompleTimeNumber',
    'keypoints',
    'icon',
    'lightIcon',
    'learningItemId',
    'description',
    'image',
  ]);
  if (doc.video) brief.video = pick(doc.video, ['thumbnail']);

  return brief;
};

/**
 * Show the app the editorial fields the current tag froze, never the draft the
 * editor is still working on. `Course.published` is a cache of the tag's
 * `course` row, kept on the course document so the app's list and search stay
 * on one collection.
 *
 * `overlay: false` is the admin panel, which must see the draft.
 */
/**
 * Document Mongoose → object thường, TRƯỚC khi trải.
 *
 * Trải một document đã hydrate (`{ ...doc }`) không cho ra field của nó: nó
 * chép mấy thuộc tính nội bộ `$__`, `$isNew`, `_doc`, và dữ liệu thật biến mất
 * xuống một tầng. Panel đọc `course.status` ra `undefined` rồi trắng cả trang,
 * không toast, không log — 2026-09-18.
 *
 * Lỗi nấp được lâu vì hai đường đọc không giống nhau: danh sách đi qua
 * `paginateQuery` có `.lean()` nên trải vô hại, còn chi tiết đi qua `findOne`
 * trả document nguyên hydrate. Vá ở đây chứ không ở chỗ gọi: hàm này hứa trả
 * một bản chiếu phẳng, nên nó không được phụ thuộc vào việc người gọi đã lean
 * hay chưa.
 */
export const toPlainDoc = <T>(doc: T): T => {
  const maybe = doc as unknown as { toObject?: () => T };

  return typeof maybe?.toObject === 'function' ? maybe.toObject() : doc;
};

export const applyPublishedFields = <T extends Doc>(
  course: T,
  overlay = true,
): T => {
  if (!overlay || !course?.published) return course;

  const plain = toPlainDoc(course);

  return { ...plain, ...plain.published } as T;
};

/**
 * Mirrors `LearningItemRepository.findWarmUpEligibleExercisesByKeypointIds`
 * for the tag path: exercise items only, ordered by `index`, and within each
 * only the questions an admin flagged `isDailyWarmUp`.
 */
export const warmUpQuestionsOf = (items: Doc[]): Doc[] =>
  items
    .filter(item => item.type === 'EXERCISE')
    .slice()
    .sort((a, b) => Number(a.index ?? 0) - Number(b.index ?? 0))
    .flatMap(item =>
      ((item.questions ?? []) as Doc[]).filter(
        question => question.isDailyWarmUp,
      ),
    );

/**
 * Mirrors `LearningItemRepository.findNarratableByKeypoint(s)`: theory and
 * exercise items only, in display order.
 */
export const narratableItemsOf = (items: Doc[]): Doc[] =>
  items
    .filter(item => item.type === 'THEORY' || item.type === 'EXERCISE')
    .slice()
    .sort((a, b) => Number(a.index ?? 0) - Number(b.index ?? 0));

/**
 * Mirrors `LearningItemRepository.findExercisesByKeypoints`, including its
 * `'questions.0': { $exists: true }` guard — an exercise with no question must
 * not be dealt into a practice deck.
 */
export const exercisesWithQuestionsOf = (items: Doc[]): Doc[] =>
  items
    .filter(
      item =>
        item.type === 'EXERCISE' &&
        Array.isArray(item.questions) &&
        item.questions.length > 0,
    )
    .slice()
    .sort(
      (a, b) =>
        String(a.keypointId ?? '').localeCompare(String(b.keypointId ?? '')) ||
        Number(a.index ?? 0) - Number(b.index ?? 0),
    );

/** Mirrors `LessonRepository.findBriefByCourse`'s select list. */
export const courseLessonChip = (doc: Doc): Doc =>
  pick(doc, ['_id', 'title', 'index', 'keypoints', 'courseId']);
