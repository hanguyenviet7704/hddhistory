import { CurriculumFile, CurriculumImageMeta, CurriculumKeypoint } from './curriculum.types';
import { normalizeKey } from './curriculum.validator';

export interface PeriodRef {
  id: string;
  name: string;
  start: string;
  end: string;
}

/** Chỉ tiếng Việt — quyết định của spec, các locale khác cố ý bỏ trống. */
interface ViOnly {
  vi: string;
}

export interface CategoryDoc {
  _localKey: string;
  index: number;
  title: ViOnly;
  description: ViOnly;
  status: string;
  image: string;
}

export interface CourseDoc {
  _localKey: string;
  categoryLocalKey: string;
  title: ViOnly;
  description: ViOnly;
  status: string;
  image: string;
  numberOfLesson: number;
}

export interface LessonDoc {
  _localKey: string;
  courseLocalKey: string;
  index: number;
  title: ViOnly;
  description: ViOnly;
  status: string;
  image: string;
}

export interface KeypointDoc {
  _localKey: string;
  lessonLocalKey: string;
  index: number;
  title: ViOnly;
  description: ViOnly;
  image: string;
  /**
   * Keypoint là collection phẳng — schema không có lessonId hay courseId. Nên
   * khớp idempotent theo (title, index) sẽ gộp nhầm hai keypoint cùng tên ở hai
   * bài khác nhau, mà "Hệ quả" hay "Bối cảnh" thì chắc chắn lặp lại trong 560
   * keypoint. `tag` là trường duy nhất có sẵn để mang khoá phân biệt, nên
   * `_localKey` (đã đủ điều kiện: thời kỳ::khoá::bài::keypoint) đi vào đây.
   */
  tag: string[];
}

/**
 * `DocumentDataModel` của app đọc `url` như một translation object chứ không
 * phải chuỗi trần. Khối ảnh mang lời ghi công ngay trong `data.content.vi` (app
 * hiển thị thành dòng nghiêng nhỏ dưới ảnh); không có khối caption riêng.
 */
export type DocumentBlockDoc =
  | { id: number; type: 'title' | 'text'; data: { content: ViOnly } }
  | { id: number; type: 'image'; data: { url: ViOnly; content: ViOnly } };

/**
 * Một theory LearningItem cho mỗi keypoint — đây là mặt đọc của app
 * (Keypoint.description chỉ là phần tóm tắt sau cú chạm). Giá trị `type` và
 * `DocumentType` là chuỗi literal (learning-item.enum.ts) để builder giữ thuần.
 * `roleplay` cố ý không có: theory không dùng, schema để Mixed nên vắng mặt là hợp lệ.
 */
export interface LearningItemDoc {
  _localKey: string;
  keypointLocalKey: string;
  type: 'theory';
  title: ViOnly;
  description: ViOnly;
  image: string;
  tag: string[];
  index: number;
  questions: never[];
  subQuestions: never[];
  isSub: boolean;
  documents: {
    id: number;
    tagId: string;
    document: DocumentBlockDoc[];
  }[];
}

export interface RoadmapNodeDoc {
  /** Xác định, suy ra từ khoá bài — cùng đầu vào luôn ra cùng id node. */
  id: string;
  title: ViOnly;
  description: ViOnly;
  lessonLocalKeys: string[];
  outputId: string;
}

/**
 * Một roadmap cho mỗi khoá, một level, mỗi bài là một node. Id thật của khoá,
 * bài, keypoint chỉ có khi ghi, nên ở đây chỉ mang `_localKey` để seeder đổi
 * sang id (chuỗi) lúc ghi.
 */
export interface RoadmapDoc {
  _localKey: string;
  courseLocalKey: string;
  level: { id: number; level: string; titleBadge: ViOnly; badge: string };
  keypointLocalKeys: string[];
  nodes: RoadmapNodeDoc[];
}

export interface SeedPlan {
  categories: CategoryDoc[];
  courses: CourseDoc[];
  lessons: LessonDoc[];
  keypoints: KeypointDoc[];
  learningItems: LearningItemDoc[];
  roadmaps: RoadmapDoc[];
}

/** Giá trị của CourseLevel.LEVEL1 (course.enum.ts) — builder giữ thuần, không import enum. */
const ROADMAP_LEVEL = 'level 1';

export const DEFAULT_STATIC_BASE_URL = 'http://localhost:4000';

function imageFor(staticBaseUrl: string, periodId: string): string {
  const base = staticBaseUrl.replace(/\/+$/, '');
  return `${base}/static/history/${periodId}.png`;
}

/**
 * Dòng ghi công: `Ảnh: <tác giả> / <giấy phép> — Wikimedia Commons`. Tác giả có
 * thể còn thẻ HTML (Commons hay trả `<a>`), nên bỏ hết trước khi dùng. Không
 * biết tác giả thì chỉ nêu giấy phép.
 */
export function imageCredit(k: CurriculumImageMeta): string {
  const author = (k.imageAuthor ?? '')
    .replace(/<[^>]*>/g, '')
    .replace(/\s+/g, ' ')
    .trim();
  const license = (k.imageLicense ?? '').trim();
  const who = [author, license].filter(Boolean).join(' / ');
  return `Ảnh: ${who ? who + ' — ' : ''}Wikimedia Commons`;
}

/**
 * Các khối của một thẻ: tiêu đề, (ảnh mang lời ghi công nếu có), rồi nội dung.
 * `id` theo vị trí nên thẻ không ảnh giữ nguyên id 1/2 như trước.
 */
function cardBlocks(k: CurriculumKeypoint): DocumentBlockDoc[] {
  const blocks: Omit<DocumentBlockDoc, 'id'>[] = [
    { type: 'title', data: { content: { vi: k.titleVi } } },
  ];
  if (k.image) {
    blocks.push({
      type: 'image',
      data: { url: { vi: k.image }, content: { vi: imageCredit(k) } },
    });
  }
  blocks.push({ type: 'text', data: { content: { vi: k.descriptionVi } } });
  return blocks.map((blk, i) => ({ id: i + 1, ...blk }) as DocumentBlockDoc);
}

/**
 * Thuần: cùng đầu vào (kể cả `staticBaseUrl`, do nơi gọi truyền vào, không đọc env ở đây) cho cùng đầu ra, không đụng Mongo và không sinh ObjectId.
 * Quan hệ cha–con đi qua `_localKey` để Task 8 tự quyết id khi ghi, và để test
 * được mà không cần database.
 *
 * Thứ tự chủ đề bám `periods` chứ không bám thứ tự trong file nội dung: người
 * biên tập thêm thời kỳ theo lô nào cũng được, trục thời gian trong app vẫn đúng.
 */
export function buildSeedPlan(
  file: CurriculumFile,
  periods: PeriodRef[],
  staticBaseUrl: string = DEFAULT_STATIC_BASE_URL,
): SeedPlan {
  const byId = new Map(periods.map((p) => [p.id, p]));
  const order = new Map(periods.map((p, i) => [p.id, i]));

  const plan: SeedPlan = {
    categories: [],
    courses: [],
    lessons: [],
    keypoints: [],
    learningItems: [],
    roadmaps: [],
  };

  const sorted = [...file.categories].sort(
    (a, b) => (order.get(a.periodId) ?? 0) - (order.get(b.periodId) ?? 0),
  );

  sorted.forEach((s) => {
    const period = byId.get(s.periodId);
    if (!period) {
      throw new Error(
        `periodId "${s.periodId}" không có trong vn_history_seed.json`,
      );
    }

    const image = imageFor(staticBaseUrl, period.id);
    plan.categories.push({
      _localKey: period.id,
      index: order.get(period.id),
      title: { vi: period.name },
      description: { vi: `${period.name} (${period.start} – ${period.end})` },
      status: 'published',
      image,
    });

    s.courses.forEach((c) => {
      const courseKey = `${period.id}::${normalizeKey(c.titleVi)}`;
      // Ảnh bìa khoá: mượn ảnh bìa của bài đầu tiên có ảnh thật. Không bài nào
      // có thì mới rơi về ảnh nền thời kỳ — trước đây khoá luôn dùng ảnh nền,
      // nên 32/32 thẻ ở Home trông giống hệt nhau.
      const courseImage = c.lessons.find((l) => l.image)?.image || image;
      plan.courses.push({
        _localKey: courseKey,
        categoryLocalKey: period.id,
        title: { vi: c.titleVi },
        description: { vi: c.descriptionVi },
        status: 'published',
        image: courseImage,
        numberOfLesson: c.lessons.length,
      });

      const roadmap: RoadmapDoc = {
        _localKey: courseKey,
        courseLocalKey: courseKey,
        level: {
          id: 1,
          level: ROADMAP_LEVEL,
          titleBadge: { vi: c.titleVi },
          badge: image,
        },
        keypointLocalKeys: [],
        nodes: [],
      };
      plan.roadmaps.push(roadmap);

      c.lessons.forEach((l, li) => {
        const lessonKey = `${courseKey}::${normalizeKey(l.titleVi)}`;
        // Ảnh bìa riêng của bài nếu đã chọn được, không thì ảnh thời kỳ. Dùng
        // lại cho keypoint và learning item của chính bài: thumbnail trên
        // roadmap đọc `keypoint.image` TRƯỚC `lesson.image`
        // (lesson_keypoint_card.dart:17), nên nếu keypoint giữ ảnh thời kỳ thì
        // ảnh thật của bài không bao giờ hiện ra.
        const lessonImage = l.image || image;
        plan.lessons.push({
          _localKey: lessonKey,
          courseLocalKey: courseKey,
          index: li,
          title: { vi: l.titleVi },
          description: { vi: l.descriptionVi },
          status: 'published',
          image: lessonImage,
        });

        roadmap.nodes.push({
          id: `${lessonKey}::node`,
          title: { vi: l.titleVi },
          description: { vi: l.descriptionVi },
          lessonLocalKeys: [lessonKey],
          outputId: '',
        });

        // Mỗi bài đúng MỘT keypoint (tên bài là thứ người học thấy), và một
        // theory learning item mà `documents[]` là các thẻ vuốt được: mỗi mục
        // trong file nội dung (`keypoints`) thành một thẻ, giữ nguyên thứ tự.
        const keypointKey = lessonKey;
        roadmap.keypointLocalKeys.push(keypointKey);
        plan.keypoints.push({
          _localKey: keypointKey,
          lessonLocalKey: lessonKey,
          index: 0,
          title: { vi: l.titleVi },
          description: { vi: l.descriptionVi },
          image: lessonImage,
          tag: ['vn-history', keypointKey],
        });
        plan.learningItems.push({
          _localKey: keypointKey,
          keypointLocalKey: keypointKey,
          type: 'theory',
          title: { vi: l.titleVi },
          description: { vi: l.descriptionVi },
          image: lessonImage,
          tag: ['vn-history', keypointKey],
          index: 0,
          questions: [],
          subQuestions: [],
          isSub: false,
          documents: l.keypoints.map((k, ki) => ({
            id: ki + 1,
            tagId: '',
            document: cardBlocks(k),
          })),
        });
      });
    });
  });

  return plan;
}
