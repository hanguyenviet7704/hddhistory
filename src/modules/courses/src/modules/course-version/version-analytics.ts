/**
 * Phần tính toán thuần của bảng so sánh phiên bản. Không chạm DB, không chạm
 * Nest — nhận số đã gom về và trả ra đúng những gì trang admin vẽ.
 *
 * Xem `plans/260907-course-content-versions/README.md` mục "So sánh phiên bản".
 */

/** Một đoạn thời gian mà một tag được phục vụ. */
export interface VersionWindow {
  from: Date;
  /** `null` = đang phục vụ tới bây giờ. */
  to?: Date | null;
}

export interface TagWindows {
  tag: string;
  versionId: string;
  windows: VersionWindow[];
}

/**
 * Gộp log cửa sổ thành mỗi tag một dải đoạn.
 *
 * Vì roll back cho một tag nhiều đoạn rời nhau, gom theo tag là bắt buộc —
 * lấy đoạn cuối cùng thôi thì mọi số của bản bị roll back rồi quay lại đều chỉ
 * tính nửa sau, và bản đó trông tệ hơn thực tế đúng vào lúc người ta đang cân
 * nhắc có nên quay lại nó hay không.
 */
export const groupWindowsByTag = (
  rows: { tag: string; versionId: string; from: Date; to?: Date | null }[],
): TagWindows[] => {
  const byTag = new Map<string, TagWindows>();

  for (const row of [...rows].sort((a, b) => +a.from - +b.from)) {
    const found = byTag.get(row.tag);
    const window: VersionWindow = { from: row.from, to: row.to ?? null };
    if (found) found.windows.push(window);
    else
      byTag.set(row.tag, {
        tag: row.tag,
        versionId: String(row.versionId),
        windows: [window],
      });
  }

  return [...byTag.values()];
};

/** Tổng số giây một tag đã được phục vụ — dùng để chuẩn hoá số lượt báo lỗi. */
export const liveSeconds = (windows: VersionWindow[], now: Date): number => {
  let total = 0;
  for (const w of windows) {
    total += Math.max(0, (+(w.to ?? now) - +w.from) / 1000);
  }

  return total;
};

// ------------------------------------------------------------------- đồ thị

/** Một bài trong đúng thứ tự học của MỘT phiên bản. */
export interface LessonShape {
  lessonId: string;
  /** Keypoint của bài, đúng thứ tự — "card" trong bảng so sánh là keypoint. */
  keypointIds: string[];
}

/**
 * Thứ tự học của MỘT phiên bản, dựng từ snapshot của chính phiên bản đó.
 *
 * Phải đọc từ snapshot chứ không đọc bản đang sửa: trục X của cả hai đồ thị là
 * "bài thứ mấy trong khoá", mà một bản tái cấu trúc 12 bài xuống 10 bài thì
 * bài số 7 của hai bản là hai bài khác nhau. Dùng chung một thứ tự cho mọi cột
 * là âm thầm so bài này với bài kia.
 *
 * Thứ tự lấy theo roadmap (đó mới là thứ tự người học đi qua); bài có trong
 * khoá nhưng chưa được đặt lên roadmap xếp sau, theo thứ tự snapshot, để không
 * biến mất khỏi bảng.
 */
export const lessonShapesOf = (params: {
  roadmap?: { levels?: { nodes?: { lessonIds?: (string | null)[] }[] }[] } | null;
  lessons: { _id?: unknown; keypoints?: (string | null)[] }[];
}): LessonShape[] => {
  const keypointsOf = new Map<string, string[]>();
  for (const lesson of params.lessons) {
    const id = lesson._id ? String(lesson._id) : '';
    if (!id) continue;
    keypointsOf.set(
      id,
      (lesson.keypoints ?? []).filter(Boolean).map(String),
    );
  }

  const ordered: string[] = [];
  const seen = new Set<string>();
  const push = (id: string) => {
    if (!id || seen.has(id) || !keypointsOf.has(id)) return;
    seen.add(id);
    ordered.push(id);
  };

  for (const level of params.roadmap?.levels ?? []) {
    for (const node of level.nodes ?? []) {
      for (const id of node.lessonIds ?? []) push(id ? String(id) : '');
    }
  }
  for (const id of keypointsOf.keys()) push(id);

  return ordered.map(lessonId => ({
    lessonId,
    keypointIds: keypointsOf.get(lessonId) ?? [],
  }));
};

export interface RetentionPoint {
  lessonIndex: number;
  lessonId: string;
  /** % người đã mở khoá mà đọc hết bài này. */
  pct: number;
}

/**
 * Đường giữ chân toàn khoá: mẫu số CỐ ĐỊNH là người đã mở khoá, không reset ở
 * mỗi bài. "Hoàn thành bài i" = có đọc xong card cuối của bài i.
 *
 * Mẫu số cố định là điểm mấu chốt: nếu mỗi bài lại chia cho riêng người mở bài
 * đó thì đường sẽ gần như phẳng ở mức cao và đúng chỗ rơi — chỗ duy nhất đáng
 * xem — bị chính phép chia xoá đi.
 */
export const retentionCurve = (params: {
  lessons: LessonShape[];
  completersByKeypoint: Record<string, number>;
  courseViewers: number;
}): RetentionPoint[] => {
  const { lessons, completersByKeypoint, courseViewers } = params;

  return lessons.map((lesson, at) => {
    const last = lesson.keypointIds[lesson.keypointIds.length - 1];
    const done = last ? completersByKeypoint[last] ?? 0 : 0;

    return {
      lessonIndex: at + 1,
      lessonId: lesson.lessonId,
      pct: courseViewers ? round1((done / courseViewers) * 100) : 0,
    };
  });
};

export interface DepthPoint {
  lessonIndex: number;
  lessonId: string;
  /** % số card của bài mà người đã mở bài đọc được, tính trung bình. */
  pct: number;
  /** Trọng số: số người đã mở bài này. */
  openers: number;
  cards: number;
}

/**
 * Độ sâu theo từng bài.
 *
 * Công thức là một ĐẲNG THỨC chứ không phải xấp xỉ: trung bình trên mỗi người
 * của (số card đã đọc / tổng card) = (Σ số người đọc từng card) / (số người mở
 * bài × tổng card), vì Σ theo người của "số card đã đọc" và Σ theo card của
 * "số người đọc card đó" đếm cùng một tập cặp (người, card).
 *
 * Nên không cần biết từng người đọc tới đâu — chỉ cần số người trên mỗi card,
 * thứ một `$group` duy nhất đã trả về.
 */
export const depthCurve = (params: {
  lessons: LessonShape[];
  readersByKeypoint: Record<string, number>;
  openersByLesson: Record<string, number>;
}): DepthPoint[] => {
  const { lessons, readersByKeypoint, openersByLesson } = params;

  return lessons.map((lesson, at) => {
    const cards = lesson.keypointIds.length;
    const openers = openersByLesson[lesson.lessonId] ?? 0;
    const readPairs = lesson.keypointIds.reduce(
      (sum, id) => sum + (readersByKeypoint[id] ?? 0),
      0,
    );
    const denominator = openers * cards;

    return {
      lessonIndex: at + 1,
      lessonId: lesson.lessonId,
      pct: denominator ? round1((readPairs / denominator) * 100) : 0,
      openers,
      cards,
    };
  });
};

/**
 * Bài bị bỏ dở: độ sâu tụt dưới ngưỡng. Trang admin tô đậm mấy điểm này, nên
 * ngưỡng phải nằm ở đây chứ không nằm trong component — hai chỗ đặt ngưỡng
 * khác nhau là hai câu trả lời khác nhau cho cùng một câu hỏi.
 */
export const DROP_OFF_DEPTH_PCT = 50;

export const dropOffLessons = (points: DepthPoint[]): number[] =>
  points.filter(p => p.openers > 0 && p.pct < DROP_OFF_DEPTH_PCT).map(p => p.lessonIndex);

// ------------------------------------------------------------------- chênh lệch

/**
 * Mức thấp nhất/cao nhất của một chỉ số trong TOÀN BỘ lịch sử khoá — số hiện
 * ra khi rê chuột vào ô.
 *
 * Tính trên mọi phiên bản có số, không phải chỉ mấy phiên bản đang được tích
 * chọn: câu hỏi là "bản này so với lịch sử khoá thì thế nào", và nếu chỉ so
 * trong mấy cột đang mở thì ô nào cũng có một cột là thấp nhất và một cột là
 * cao nhất, chẳng nói lên điều gì.
 */
export const rangeOf = (values: (number | null)[]): { min: number; max: number } | null => {
  const real = values.filter((v): v is number => v !== null && Number.isFinite(v));
  if (!real.length) return null;

  return { min: Math.min(...real), max: Math.max(...real) };
};

const round1 = (n: number): number => Math.round(n * 10) / 10;
