// Where the user's material came from. PDF arrives as an R2 object key (the app
// uploads through the existing POST /cloudflares/upload before calling us, so a
// 50MB textbook never has to fit in a JSON body); YouTube arrives as a plain URL.
export enum ImportSourceType {
  PDF = 'pdf',
  YOUTUBE = 'youtube',
}

// `INTERRUPTED` is never STORED. A job whose process died keeps `PROCESSING` in
// the document forever -- nothing is left alive to write a final status -- so the
// service derives it from a stale `heartbeatAt` on read. Same reasoning (and the
// same 2-minute window) as VoiceoverJobStatus.INTERRUPTED; see
// LearningImportRunnerService.HEARTBEAT_STALE_MS.
export enum ImportJobStatus {
  QUEUED = 'queued',
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  FAILED = 'failed',
  INTERRUPTED = 'interrupted',
}

// The step a running job is on. Surfaced to the app so the waiting screen can say
// "Đang đọc tài liệu…" instead of showing a bar that moves for no reason -- this
// is a multi-minute job and an honest step name is the only progress signal we
// can actually give.
export enum ImportJobStage {
  FETCHING = 'fetching',
  GENERATING = 'generating',
  VALIDATING = 'validating',
  SAVING = 'saving',
  // The last stage, and the only one that is allowed to give up: see
  // LearningImportRunnerService.dubBeforeCompleting.
  DUBBING = 'dubbing',
}

/**
 * Every way this can fail, as a code the client turns into its own sentence.
 *
 * Deliberately granular: "Đã có lỗi xảy ra" tells a user nothing and generates a
 * support ticket, while "video này không có phụ đề" tells them exactly what to do
 * next. The split between user-fixable (wrong file, no captions) and ours
 * (AI_FAILED, AI_TIMEOUT) also decides whether the attempt burns a quota slot --
 * see `LEARNING_IMPORT_QUOTA_CHARGING_ERRORS`.
 */
export enum ImportErrorCode {
  // The material is the problem -- the user can fix it by picking another file.
  PDF_UNREADABLE = 'PDF_UNREADABLE',
  PDF_TOO_LARGE = 'PDF_TOO_LARGE',
  YOUTUBE_NO_TRANSCRIPT = 'YOUTUBE_NO_TRANSCRIPT',
  YOUTUBE_UNAVAILABLE = 'YOUTUBE_UNAVAILABLE',
  YOUTUBE_TOO_LONG = 'YOUTUBE_TOO_LONG',
  YOUTUBE_TOO_SHORT = 'YOUTUBE_TOO_SHORT',
  CONTENT_TOO_SHORT = 'CONTENT_TOO_SHORT',

  // We are the problem.
  AI_TIMEOUT = 'AI_TIMEOUT',
  AI_FAILED = 'AI_FAILED',
  AI_NOT_CONFIGURED = 'AI_NOT_CONFIGURED',
  SOURCE_FETCH_FAILED = 'SOURCE_FETCH_FAILED',
  INTERNAL = 'INTERNAL',
}

// Blocks raised before a job document exists, so they never reach the error codes
// above -- the controller rejects the request outright.
export enum ImportRejectionCode {
  // The admin switched the feature off. Distinct from AI_NOT_CONFIGURED, which
  // is a fault: this one is somebody's decision, and the app says so differently.
  FEATURE_DISABLED = 'FEATURE_DISABLED',
  NOT_PREMIUM = 'NOT_PREMIUM',
  QUOTA_EXCEEDED = 'QUOTA_EXCEEDED',
  JOB_ALREADY_RUNNING = 'JOB_ALREADY_RUNNING',
}

// Block kinds inside a generated section. Only two, on purpose: v1 generates
// prose only, and every kind added here is a kind the Flutter reader has to grow
// a branch for.
export enum LessonBlockType {
  HEADING = 'heading',
  PARAGRAPH = 'paragraph',
}

/**
 * Whether a generated lesson has narration yet.
 *
 * Dubbing runs as its OWN phase after the lesson is already saved and the import
 * job is already `completed`, so this is a second, independent signal: the job
 * says "the lesson is readable", this says "the lesson is listenable".
 *
 * `FAILED` is a normal outcome, not an incident. The TTS provider is Microsoft
 * Edge's undocumented Read-Aloud endpoint with no SLA, so the UI must treat a
 * lesson without audio as a valid state rather than an error to alarm about.
 */
export enum UserLessonAudioStatus {
  NONE = 'none',
  PROCESSING = 'processing',
  READY = 'ready',
  FAILED = 'failed',
}

/**
 * Whether the lesson BODY is all there yet.
 *
 * Generation is two-phase (see plans/260813-progressive-import): the import job
 * completes once the FIRST keypoint is written and dubbed, and the rest of the
 * outline is generated behind the reader's back. `PARTIAL` is that window. The
 * completion sweep owns moving it to `COMPLETE`, and nothing else writes it.
 *
 * Old lessons carry no field at all and must read as COMPLETE — they were
 * generated whole — hence the schema default.
 */
export enum UserLessonContentStatus {
  PARTIAL = 'partial',
  COMPLETE = 'complete',
}
