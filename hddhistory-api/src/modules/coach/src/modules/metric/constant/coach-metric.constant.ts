import { CoachMetricKind } from '../enum/coach-metric.enum';

/**
 * Which question a counter answers.
 *
 * `quality` counters watch whether the Coach TALKS well; `funnel` counters
 * watch whether anybody gets anywhere. Mixing them in one list would put "the
 * model asked a banned question" beside "somebody opened a course" as if they
 * were the same kind of news.
 */
export enum CoachMetricGroup {
  QUALITY = 'quality',
  FUNNEL = 'funnel',
}

export interface ICoachMetricMeta {
  label: string;
  group: CoachMetricGroup;
  /** What `refId` splits this counter by, when it carries one. */
  refLabel?: string;
}

/**
 * Labels for the admin panel. Every kind in [CoachMetricKind] appears here —
 * a counter with no entry falls back to its raw id rather than disappearing,
 * but that only happens when somebody adds a kind and forgets this table.
 */
export const COACH_METRIC_META: Record<string, ICoachMetricMeta> = {
  [CoachMetricKind.DRAFT_REJECTED]: {
    label: 'Từ chối cả bản nháp',
    group: CoachMetricGroup.QUALITY,
  },
  [CoachMetricKind.EXPLAIN_AGAIN]: {
    label: 'Xin nói lại cho dễ hiểu',
    group: CoachMetricGroup.QUALITY,
    refLabel: 'Keypoint',
  },
  [CoachMetricKind.DRAFT_UNTOUCHED]: {
    label: 'Nhận nháp, không sửa dòng nào',
    group: CoachMetricGroup.QUALITY,
  },
  [CoachMetricKind.DRAFT_EDITED]: {
    label: 'Nhận nháp và có sửa',
    group: CoachMetricGroup.QUALITY,
  },
  [CoachMetricKind.BANNED_QUESTION]: {
    label: 'Model hỏi câu bị cấm',
    group: CoachMetricGroup.QUALITY,
  },
  [CoachMetricKind.BANNED_QUESTION_FALLBACK]: {
    label: 'Cấm hai lần → phải dùng câu cố định',
    group: CoachMetricGroup.QUALITY,
  },
  [CoachMetricKind.ECHOED_READER]: {
    label: 'Trả lời bằng chính câu người đọc vừa gõ',
    group: CoachMetricGroup.QUALITY,
  },
  [CoachMetricKind.HABIT_CHANGED]: {
    label: 'Đổi habit bằng tay',
    group: CoachMetricGroup.QUALITY,
  },
  [CoachMetricKind.SESSION_OPENED]: {
    label: 'Phiên mở (server đếm)',
    group: CoachMetricGroup.FUNNEL,
    refLabel: 'Cửa vào : bậc',
  },
  [CoachMetricKind.PLAN_ASK_YES]: {
    label: 'Nhận cam kết',
    group: CoachMetricGroup.FUNNEL,
  },
  [CoachMetricKind.PLAN_ASK_NO]: {
    label: 'Từ chối cam kết',
    group: CoachMetricGroup.FUNNEL,
  },
  [CoachMetricKind.INTENT_DONE]: {
    label: 'Điểm danh: đã làm',
    group: CoachMetricGroup.FUNNEL,
  },
  [CoachMetricKind.INTENT_MISSED]: {
    label: 'Điểm danh: có dịp mà chưa làm',
    group: CoachMetricGroup.FUNNEL,
  },
  [CoachMetricKind.INTENT_NONE]: {
    label: 'Điểm danh: không có dịp',
    group: CoachMetricGroup.FUNNEL,
  },
  [CoachMetricKind.SCENE_ANSWERED]: {
    label: 'Trả lời tình huống',
    group: CoachMetricGroup.FUNNEL,
  },
  [CoachMetricKind.COURSE_SHOWN]: {
    label: 'Card khoá học hiện ra',
    group: CoachMetricGroup.FUNNEL,
    refLabel: 'Lý do gợi ý',
  },
  [CoachMetricKind.COURSE_OPENED]: {
    label: 'Mở khoá học từ card',
    group: CoachMetricGroup.FUNNEL,
  },
  [CoachMetricKind.COURSE_SAVED]: {
    label: 'Lưu khoá học từ card',
    group: CoachMetricGroup.FUNNEL,
  },
  [CoachMetricKind.COURSE_SKIPPED]: {
    label: 'Bỏ qua card khoá học',
    group: CoachMetricGroup.FUNNEL,
  },
  [CoachMetricKind.SHRINK_ACCEPTED]: {
    label: 'Nhận cam kết nhỏ hơn',
    group: CoachMetricGroup.FUNNEL,
  },
  [CoachMetricKind.SHRINK_KEPT]: {
    label: 'Giữ nguyên cam kết cũ',
    group: CoachMetricGroup.FUNNEL,
  },
};

/** How many weeks the picker offers before it is a wall of dates. */
export const COACH_METRIC_WEEK_LIMIT = 26;

/** How many `refId` rows one counter shows. */
export const COACH_METRIC_REF_LIMIT = 12;
