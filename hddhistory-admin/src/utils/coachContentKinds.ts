import {
  CoachContentKind,
  CoachContentRow,
} from "../types/interface/coach.interface";

/**
 * Sáu loại, xếp theo thứ tự "gần đời thật nhất trước".
 *
 * Câu kể đứng đầu vì nó là loại duy nhất chứng minh habit đã xảy ra ngoài đời;
 * câu trả lời tình huống đứng cuối vì đó là tập trong app, không tính.
 *
 * Ở đây chứ không nằm trong trang danh sách, vì cả ba chỗ — feed, bảng theo
 * user, dòng thời gian của một user — phải gọi cùng một loại bằng cùng một tên
 * và cùng một màu.
 */
export const KIND_META: Record<
  CoachContentKind,
  { label: string; hint: string; color: string }
> = {
  evidence: {
    label: "Câu kể",
    hint: "Lần làm thật ngoài đời — bằng chứng duy nhất",
    color: "bg-emerald-50 text-emerald-800 border-emerald-200",
  },
  problem_statement: {
    label: "Vấn đề thật",
    hint: "User tự gọi tên vấn đề của mình, sau bản nháp hai cột",
    color: "bg-bronze-50 text-bronze-800 border-bronze-200",
  },
  barrier: {
    label: "Rào cản",
    hint: "Cái gì làm họ dừng lại — dòng dạy cho nhắc hẹn biết nó quá to",
    color: "bg-amber-50 text-amber-900 border-amber-200",
  },
  quick_note: {
    label: "Ghi nhanh",
    hint: "Nhánh nông: ghi lại rồi thôi, không mở ra gì",
    color: "bg-slate-100 text-slate-700 border-slate-200",
  },
  dip: {
    label: "Dịp",
    hint: "Cụm chữ về đời thật mà nhắc hẹn neo vào — chỉ còn trong 48h",
    color: "bg-sky-50 text-sky-800 border-sky-200",
  },
  situation_answer: {
    label: "Trả lời tình huống",
    hint: "Tập trong app — KHÔNG tính là đã làm thật",
    color: "bg-violet-50 text-violet-800 border-violet-200",
  },
};

export const KIND_ORDER = Object.keys(KIND_META) as CoachContentKind[];

/** Ngữ cảnh phụ của một dòng, gộp thành một dòng chữ nhỏ. */
export const formatMeta = (row: CoachContentRow): string =>
  formatMetaBits(row.meta);

export const formatMetaBits = (
  meta: Record<string, unknown> | undefined,
): string => {
  const parts: string[] = [];
  meta = meta ?? {};

  if (typeof meta.round === "number") parts.push(`chặng ${meta.round}`);
  if (typeof meta.variant === "string" && meta.variant) {
    parts.push(meta.variant === "third_person" ? "ngôi thứ ba" : meta.variant);
  }
  // Tỉ lệ dòng bị kéo là chỉ số đo trực tiếp "AI có đang áp đặt không" —
  // gần bằng 0 nghĩa là đang áp đặt, nên nó phải đọc được ngay trên dòng.
  if (
    typeof meta.draftKeptCount === "number" &&
    typeof meta.draftProposedCount === "number" &&
    meta.draftProposedCount > 0
  ) {
    parts.push(`kéo ${meta.draftKeptCount}/${meta.draftProposedCount} dòng`);
  }

  return parts.join(" · ");
};

/** Câu hỏi tình huống mà dòng này đang trả lời, nếu có. */
export const situationPrompt = (row: CoachContentRow): string | null => {
  const prompt = (row.meta ?? {}).situationPrompt;
  return typeof prompt === "string" && prompt.trim() ? prompt : null;
};

/** `YYYY-MM-DD` cho hôm nay và N ngày trước, theo giờ máy người xem. */
export const dateInput = (daysAgo = 0) => {
  const date = new Date();
  date.setDate(date.getDate() - daysAgo);
  return date.toISOString().slice(0, 10);
};

/**
 * Câu hỏi cố định Coach hỏi ngay trước mỗi loại, để dựng lại phía Coach cho
 * những phiên đã hết hạn lưu.
 *
 * Chép nguyên văn từ `hddhistory-flutter/assets/i18n/vi/coach.yaml` — API chỉ giữ
 * KEY của mấy câu này, câu chữ do client render. Đây là tái dựng chứ không
 * phải bản ghi: nó đúng ở chỗ "bước này Coach luôn hỏi câu này", không đúng ở
 * chỗ "hôm đó Coach đã nói đúng từng chữ này" — nên chỗ nào dùng nó cũng phải
 * đánh dấu. Sửa YAML thì sửa cả đây.
 */
export const KIND_QUESTION: Record<CoachContentKind, string> = {
  // promptIntentTell
  evidence: "Kể mình nghe một câu: lúc đó bạn nói hay làm gì?",
  // promptTwoCols
  problem_statement:
    "Mình gom lại thành nháp hai cột — toàn bằng lời bạn. Kéo dòng nào là vấn đề thật của bạn sang phải, rồi viết lại một câu.",
  // promptBarrier
  barrier:
    "Có dịp mà chưa làm là chuyện thường, mình không tính là thất bại. Lúc đó điều gì làm bạn dừng lại?",
  // promptJot
  quick_note: "Được. Ghi một dòng cho hôm nay thôi, mình không hỏi gì thêm.",
  // promptSceneWhen
  dip: "Lúc đó là lúc nào?",
  // Cảnh do biên tập viên viết nên không có câu cố định — nếu tới đây nghĩa là
  // cảnh đã bị xoá khỏi kho và câu hỏi thật sự không còn.
  situation_answer: "(cảnh đã bị xoá khỏi kho tình huống)",
};

/** Cửa vào phiên, cho header của khối hội thoại. */
export const ENTRY_LABEL: Record<string, string> = {
  home: "Màn hình chính",
  lesson: "Cuối bài học",
  habit: "Màn habit",
};
