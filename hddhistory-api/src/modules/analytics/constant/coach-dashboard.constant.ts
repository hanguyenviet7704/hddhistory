// Event names and label tables behind the Coach statistics page.
//
// Same contract as `dashboard.constant.ts`: these are the fired strings from
// the Flutter app's `TrackingKey` (`lib/core/constants/manual/tracking_key.dart`
// → the `//* AI Coach events` block), not the Dart constant names. A rename in
// the app is a one-line change here. Anything the collection has never seen
// simply reports zero — a Coach that stops firing an event must not 500 the
// page.

/** Every Coach event shares this prefix. */
export const COACH_EVENT_PREFIX = 'coach_';

// ------------------------------------------------------------------ doors

export const COACH_BUBBLE_VIEW = 'coach_bubble_view';
export const COACH_BUBBLE_CLICK = 'coach_bubble_click';
export const COACH_INVITE_VIEW = 'coach_invite_scr_view';
export const COACH_INVITE_ACCEPT = 'coach_invite_accept';
export const COACH_INVITE_LATER = 'coach_invite_later';
export const COACH_SCR_VIEW = 'coach_scr_view';
export const COACH_OPEN_SILENT = 'coach_open_silent';
export const COACH_OPEN_FAILED = 'coach_open_failed';

// --------------------------------------------------------------- session

export const COACH_SCR_EXIT = 'coach_scr_exit';
export const COACH_TURN_SEND = 'coach_turn_send';
export const COACH_TURN_FAILED = 'coach_turn_failed';
export const COACH_SESSION_EXPIRED = 'coach_session_expired';
export const COACH_EXIT_PLEA_VIEW = 'coach_exit_plea_view';
export const COACH_EXIT_STAY = 'coach_exit_stay';
export const COACH_EXIT_LEAVE = 'coach_exit_leave';

// -------------------------------------------------------------- surfaces

export const COACH_COURSE_CARD_VIEW = 'coach_course_card_view';
export const COACH_RATING_VIEW = 'coach_rating_view';
export const COACH_SAFETY_VIEW = 'coach_safety_view';
export const COACH_SCENE_SCORE_VIEW = 'coach_scene_score_view';
export const COACH_QUIZ_RUN = 'coach_quiz_run';
export const COACH_MIC_START = 'coach_mic_start';
export const COACH_MIC_DONE = 'coach_mic_done';

// ------------------------------------------------------------ param paths

/** `params` is a free-form bag, so every read of it is spelled out here. */
export const PARAM_ENTRY = 'params.entry';
export const PARAM_STEP = 'params.step';
export const PARAM_KIND = 'params.kind';
export const PARAM_IS_ENDED = 'params.is_ended';
export const PARAM_IS_REOPEN = 'params.is_reopen';
export const PARAM_IS_RESUMED = 'params.is_resumed';
export const PARAM_REASON_KEY = 'params.reason_key';
export const PARAM_TURN_COUNT = 'params.turn_count';
export const PARAM_DURATION_SEC = 'params.duration_sec';
export const PARAM_THUMB = 'params.thumb';
export const PARAM_CHIP_LIST = 'params.chip_list';
export const PARAM_GRANTED = 'params.granted';
export const PARAM_HAS_TEXT = 'params.has_text';
export const PARAM_QUIZ_COUNT = 'params.quiz_count';
export const PARAM_QUIZ_PASSED = 'params.quiz_passed';
export const PARAM_ERROR_TYPE = 'params.error_type';

// ------------------------------------------------------------ funnel: door

/**
 * The bubble door, in the order somebody passes it.
 *
 * `coach_scr_view` is the session that actually OPENED — the app fires it when
 * the server hands back the first turn, not when the bubble is pressed, so the
 * gap between click and view is real failure rather than a render delay.
 */
export const COACH_BUBBLE_FUNNEL = [
  { key: 'bubbleView', label: 'Thấy bong bóng', event: COACH_BUBBLE_VIEW },
  { key: 'bubbleClick', label: 'Bấm bong bóng', event: COACH_BUBBLE_CLICK },
  { key: 'sessionOpen', label: 'Mở được phiên', event: COACH_SCR_VIEW },
] as const;

/** The other door: the invitation shown at the end of a keypoint. */
export const COACH_INVITE_FUNNEL = [
  { key: 'inviteView', label: 'Thấy màn mời', event: COACH_INVITE_VIEW },
  { key: 'inviteAccept', label: 'Nhận lời mời', event: COACH_INVITE_ACCEPT },
] as const;

/** Counted beside the funnel, never inside it — these are ways in that failed. */
export const COACH_DOOR_MISSES = [
  {
    key: 'inviteLater',
    label: 'Chọn "để sau"',
    event: COACH_INVITE_LATER,
    hint: 'Thấy màn mời nhưng hoãn lại',
  },
  {
    key: 'openSilent',
    label: 'Cửa im lặng',
    event: COACH_OPEN_SILENT,
    hint: 'Bấm vào nhưng server không có gì để nói',
  },
  {
    key: 'openFailed',
    label: 'Mở lỗi',
    event: COACH_OPEN_FAILED,
    hint: 'Bấm vào và request hỏng',
  },
] as const;

// --------------------------------------------------------- funnel: surfaces

export const COACH_SURFACES = [
  {
    key: 'courseCard',
    label: 'Card khoá học',
    event: COACH_COURSE_CARD_VIEW,
  },
  { key: 'rating', label: 'Hỏi đánh giá', event: COACH_RATING_VIEW },
  { key: 'safety', label: 'Màn an toàn', event: COACH_SAFETY_VIEW },
  {
    key: 'sceneScore',
    label: 'Điểm tình huống',
    event: COACH_SCENE_SCORE_VIEW,
  },
  { key: 'quiz', label: 'Quiz trong phiên', event: COACH_QUIZ_RUN },
  { key: 'micStart', label: 'Bấm mic', event: COACH_MIC_START },
  { key: 'micDone', label: 'Mic xong', event: COACH_MIC_DONE },
] as const;

// ----------------------------------------------------------------- labels

/** The doors, by their `entry` param. */
export const COACH_ENTRY_LABELS: Record<string, string> = {
  home: 'Home',
  lesson: 'Cuối bài học',
  habit: 'Nav Habit (đã bỏ)',
};

/**
 * The `kind` of a turn — what the reader actually did.
 *
 * Taken from the allow-list in the app's `_answerParams`; a `kind` added later
 * falls through to its raw id rather than being hidden.
 */
export const COACH_TURN_KIND_LABELS: Record<string, string> = {
  mood: 'Chọn tâm trạng',
  intent: 'Trả lời cam kết',
  text: 'Gõ chữ',
  quizAnswer: 'Trả lời quiz',
  plan: 'Nhận/từ chối kế hoạch',
  schedule: 'Đặt nhắc hẹn',
  rating: 'Đánh giá 👍👎',
  course: 'Thao tác card khoá',
  keepGoing: 'Đi tiếp',
  retry: 'Làm lại tình huống',
  met: 'Có dịp / chưa có dịp',
};

/**
 * Step ids the sheet can be parked at when somebody leaves.
 *
 * Deliberately partial: `CoachStep` carries 47 values, a dozen of them retired,
 * and a map that must list all of them rots the first time a beat is renamed.
 * Anything missing renders as its raw id, which is still readable.
 */
export const COACH_STEP_LABELS: Record<string, string> = {
  mood: 'Hỏi tâm trạng',
  pickNew: 'Chọn habit mới',
  intent: 'Hỏi cam kết',
  intentTell: 'Kể về cam kết',
  checkin: 'Điểm danh',
  checkinAsk: 'Hỏi điểm danh',
  checkinTell: 'Kể lúc điểm danh',
  checkinOffer: 'Mời sau điểm danh',
  story: 'Kể chuyện hôm nay',
  storyTalk: 'Nói tiếp câu chuyện',
  depth: 'Chọn độ sâu',
  free: 'Trò chuyện tự do',
  barrier: 'Hỏi rào cản',
  shrinkAsk: 'Mời thu nhỏ',
  shrink: 'Thu nhỏ cam kết',
  contextAsk: 'Hỏi bối cảnh',
  contextEdit: 'Sửa bối cảnh',
  scenePick: 'Chọn tình huống',
  sceneFeeling: 'Hỏi cảm giác',
  tellOnce: 'Trả lời tình huống',
  tellOnceA: 'Trả lời tình huống (chặng 1)',
  tellOnceB: 'Trả lời tình huống (chặng 2)',
  sceneStage2: 'Tình huống chặng 2',
  sceneFix: 'Sửa câu trả lời',
  sceneRetry: 'Làm lại tình huống',
  retryScene: 'Làm lại tình huống',
  twoCols: 'Bản nháp hai cột',
  redraft: 'Tự viết lại nháp',
  quizInChat: 'Quiz trong phiên',
  quizHandoff: 'Chuyển sang quiz',
  talkAsk: 'Mời nói',
  talkSummary: 'Tổng kết buổi nói',
  hub: 'Bảng chọn việc',
  leave: 'Lời níu khi đóng',
};

/**
 * Why a door opened onto silence. Ids come from the app's `reason_key`; an
 * unknown one renders raw for the same reason as the steps above.
 */
export const COACH_SILENT_REASON_LABELS: Record<string, string> = {
  '': 'Không nêu lý do',
  no_habit: 'Chưa có habit nào',
  no_plan: 'Không có cam kết đang mở',
  cooldown: 'Còn trong thời gian nghỉ',
  disabled: 'Coach đang tắt',
};

/**
 * The rating toast's answer.
 *
 * `''` is the reader closing the toast without pressing either thumb — the app
 * sends no `thumb` at all then, so the row must exist or those sessions would
 * silently vanish out of the denominator.
 */
export const COACH_THUMB_LABELS: Record<string, string> = {
  up: '👍 Hữu ích',
  down: '👎 Chưa được',
  '': 'Bỏ qua, không chấm',
};

/** The five closed chip ids behind a 👎, set by the app. */
export const COACH_RATING_CHIP_LABELS: Record<string, string> = {
  missed_the_point: 'Không đúng ý',
  too_generic: 'Chung chung',
  too_long: 'Dài dòng',
  voice_mismatch: 'Sai giọng',
  imposed_thinking: 'Áp đặt suy nghĩ',
};

/** How many rows a "top" breakdown returns before it is a wall of noise. */
export const COACH_BREAKDOWN_LIMIT = 12;

/**
 * The exit-step breakdown gets its own, wider cap.
 *
 * `CoachStep` holds 47 values and the interesting ones are often the rare ones
 * — a beat two people ever reached and both abandoned is a finding, and the
 * default twelve would bury it under the busy steps.
 */
export const COACH_STEP_BREAKDOWN_LIMIT = 30;

/** Percentiles reported for turn count and session length. */
export const COACH_MEDIAN = 0.5;
export const COACH_P90 = 0.9;
