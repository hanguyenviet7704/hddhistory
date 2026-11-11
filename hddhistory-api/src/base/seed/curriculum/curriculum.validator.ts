import {
  CurriculumCourse,
  CurriculumFile,
  CurriculumLesson,
} from './curriculum.types';

export interface SeedRef {
  periodIds: Set<string>;
  entityIds: Set<string>;
}

/** Ngưỡng bắt nội dung bỏ dở, không phải chuẩn văn phong. */
const MIN_KEYPOINT_CHARS = 80;
/**
 * `keypoints` trong file nội dung nay nghĩa là "các thẻ của bài" (mỗi mục thành
 * một thẻ vuốt được). Mục tiêu là 5–6 thẻ/bài; file hiện tại mới có 3–4 nên tạm
 * nhận 3–6. Khi task bổ sung nội dung đã nâng mọi bài lên đủ 5 thẻ thì nâng
 * MIN lên 5.
 */
const MIN_KEYPOINTS_PER_LESSON = 3;
const MAX_KEYPOINTS_PER_LESSON = 6;

/** Phân cách khoá của builder (`thời kỳ::khoá::bài::keypoint`). */
const KEY_SEP = '::';

/**
 * Khoá so sánh: NFC + trim. Builder dựng `_localKey` bằng đúng hàm này, nên
 * hai bên luôn đồng ý thế nào là "cùng một tên".
 */
export function normalizeKey(s: string): string {
  return s.normalize('NFC').trim();
}

/** Không phải object thường (null, số, chuỗi, mảng) thì không đọc được trường nào. */
function notAnObject(x: unknown): boolean {
  return x === null || typeof x !== 'object' || Array.isArray(x);
}

/** Kiểm tra một trường chuỗi bắt buộc; trả về chuỗi đã chuẩn hoá nếu dùng được. */
function requireText(
  obj: Record<string, unknown>,
  field: string,
  at: string,
  errors: string[],
): string | undefined {
  const v = obj[field];
  if (v === undefined) {
    errors.push(`${at}: thiếu ${field}`);
    return undefined;
  }
  if (typeof v !== 'string') {
    errors.push(`${at}: ${field} phải là chuỗi, đang là ${v === null ? 'null' : typeof v}`);
    return undefined;
  }
  if (v.trim() === '') {
    errors.push(`${at}: thiếu ${field}`);
    return undefined;
  }
  return v;
}

function requireTitle(
  obj: Record<string, unknown>,
  at: string,
  errors: string[],
): string | undefined {
  const t = requireText(obj, 'titleVi', at, errors);
  if (t !== undefined && t.includes(KEY_SEP)) {
    errors.push(`${at}: titleVi không được chứa "${KEY_SEP}" (builder dùng nó làm dấu phân cách khoá)`);
  }
  return t;
}

/** Báo trùng kèm cả hai đường dẫn để tác giả tìm ra ngay. */
function noteUnique(
  seen: Map<string, string>,
  key: string | undefined,
  at: string,
  what: string,
  errors: string[],
): void {
  if (key === undefined) return;
  const first = seen.get(key);
  if (first !== undefined) {
    errors.push(`${at}: ${what} "${key}" bị trùng với ${first}`);
  } else {
    seen.set(key, at);
  }
}

interface Ctx {
  seed: SeedRef;
  errors: string[];
  /** mô tả keypoint (đã chuẩn hoá) → đường dẫn lần xuất hiện đầu tiên, toàn file */
  descriptions: Map<string, string>;
}

/**
 * Gom *mọi* lỗi rồi mới trả về, cố ý không dừng ở lỗi đầu. Với ~560 keypoint,
 * sửa từng lỗi một rồi chạy lại là không dùng được. Không được ném exception
 * vì bất kỳ hình dạng dữ liệu nào: ném là mất hết lỗi đã gom.
 */
export function validateCurriculum(file: unknown, seed: SeedRef): string[] {
  const errors: string[] = [];
  const f = file as CurriculumFile;

  if (!f || !Array.isArray(f.categories)) {
    return ['File curriculum phải có mảng `categories`.'];
  }
  if (f.categories.length === 0) {
    return ['`categories` rỗng — file curriculum trống hoặc bị cắt cụt.'];
  }

  const ctx: Ctx = { seed, errors, descriptions: new Map() };
  const periods = new Map<string, string>();

  f.categories.forEach((s, si) => {
    const at = `categories[${si}]`;
    if (notAnObject(s)) {
      errors.push(`${at}: không phải object`);
      return;
    }

    if (typeof s.periodId !== 'string' || !seed.periodIds.has(s.periodId)) {
      errors.push(`${at}: periodId "${s.periodId}" không có trong vn_history_seed.json`);
    } else {
      noteUnique(periods, s.periodId, at, 'periodId', errors);
    }
    if (!Array.isArray(s.courses) || s.courses.length === 0) {
      errors.push(`${at}: thời kỳ không có khoá nào`);
      return;
    }

    const courseTitles = new Map<string, string>();
    s.courses.forEach((c, ci) => {
      const cat = `${at}.courses[${ci}]`;
      if (notAnObject(c)) {
        errors.push(`${cat}: không phải object`);
        return;
      }
      const title = validateCourse(c, cat, ctx);
      noteUnique(courseTitles, title && normalizeKey(title), cat, 'tên khoá', errors);
    });
  });

  return errors;
}

const IMAGE_META_FIELDS = ['imageFile', 'imageLicense', 'imageSource', 'imageAuthor'];

/**
 * Ảnh là tuỳ chọn, nhưng nếu có thì phải là URL https (app chặn http trên iOS/Android)
 * và các trường nguồn/ghi công (imageAuthor, imageLicense, imageFile, imageSource)
 * phải là chuỗi — builder dựng lời ghi công từ chúng.
 */
function validateImageFields(
  k: Record<string, unknown>,
  at: string,
  errors: string[],
): void {
  const img = k.image;
  if (img !== undefined) {
    if (typeof img !== 'string') {
      errors.push(`${at}: image phải là chuỗi, đang là ${img === null ? 'null' : typeof img}`);
    } else if (!/^https:\/\/\S+$/.test(img)) {
      errors.push(`${at}: image phải là URL https://, đang là "${img}"`);
    }
  }
  IMAGE_META_FIELDS.forEach((f) => {
    if (k[f] !== undefined && typeof k[f] !== 'string') {
      errors.push(`${at}: ${f} phải là chuỗi`);
    }
  });
}

function validateCourse(c: CurriculumCourse, at: string, ctx: Ctx): string | undefined {
  const { errors } = ctx;
  const title = requireTitle(c as any, at, errors);
  requireText(c as any, 'descriptionVi', at, errors);

  if (!Array.isArray(c.lessons) || c.lessons.length === 0) {
    errors.push(`${at}: khoá không có bài nào`);
    return title;
  }
  const lessonTitles = new Map<string, string>();
  c.lessons.forEach((l, li) => {
    const lat = `${at}.lessons[${li}]`;
    if (notAnObject(l)) {
      errors.push(`${lat}: không phải object`);
      return;
    }
    const lt = validateLesson(l, lat, ctx);
    noteUnique(lessonTitles, lt && normalizeKey(lt), lat, 'tên bài', errors);
  });
  return title;
}

function validateLesson(l: CurriculumLesson, at: string, ctx: Ctx): string | undefined {
  const { errors, seed } = ctx;
  const title = requireTitle(l as any, at, errors);
  requireText(l as any, 'descriptionVi', at, errors);
  validateImageFields(l as unknown as Record<string, unknown>, at, errors);

  if (!Array.isArray(l.keypoints)) {
    errors.push(`${at}: thiếu mảng keypoints`);
    return title;
  }
  if (
    l.keypoints.length < MIN_KEYPOINTS_PER_LESSON ||
    l.keypoints.length > MAX_KEYPOINTS_PER_LESSON
  ) {
    errors.push(
      `${at}: có ${l.keypoints.length} keypoint, phải trong khoảng ` +
        `${MIN_KEYPOINTS_PER_LESSON}–${MAX_KEYPOINTS_PER_LESSON}`,
    );
  }

  const kpTitles = new Map<string, string>();
  l.keypoints.forEach((k, ki) => {
    const kat = `${at}.keypoints[${ki}]`;
    if (notAnObject(k)) {
      errors.push(`${kat}: không phải object`);
      return;
    }
    const kt = requireTitle(k as any, kat, errors);
    noteUnique(kpTitles, kt && normalizeKey(kt), kat, 'tên keypoint', errors);

    const desc = requireText(k as any, 'descriptionVi', kat, errors);
    if (desc !== undefined) {
      const nd = normalizeKey(desc);
      if (nd.length < MIN_KEYPOINT_CHARS) {
        errors.push(
          `${kat}: nội dung ngắn (${nd.length} ký tự, ` +
            `tối thiểu ${MIN_KEYPOINT_CHARS}) — có vẻ bỏ dở`,
        );
      }
      if (kt !== undefined && nd === normalizeKey(kt)) {
        errors.push(`${kat}: descriptionVi giống hệt titleVi`);
      }
      noteUnique(ctx.descriptions, nd, kat, 'descriptionVi', errors);
    }

    validateImageFields(k as unknown as Record<string, unknown>, kat, errors);

    const ids = (k as { entityIds?: unknown }).entityIds;
    if (ids === undefined) return;
    if (!Array.isArray(ids)) {
      errors.push(`${kat}: entityIds phải là mảng chuỗi, đang là ${ids === null ? 'null' : typeof ids}`);
      return;
    }
    ids.forEach((id) => {
      if (typeof id !== 'string') {
        errors.push(`${kat}: entityIds chứa phần tử không phải chuỗi`);
      } else if (!seed.entityIds.has(id)) {
        errors.push(`${kat}: entityId "${id}" không có trong vn_history_seed.json`);
      }
    });
  });
  return title;
}
