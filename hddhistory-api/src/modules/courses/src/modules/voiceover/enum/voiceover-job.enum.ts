// A dub run is either the single catalogue-wide job or one course's job. Both
// live in the same collection, one document per scope (`courseId` is '' for the
// global one), so the admin can read every run in flight from one query.
export enum VoiceoverJobScope {
  GLOBAL = 'global',
  COURSE = 'course',
}

// `INTERRUPTED` is never STORED — a job whose process died keeps `RUNNING` in
// the document forever, since nothing is left alive to write a final status.
// The service derives INTERRUPTED from a stale `heartbeatAt` when it reads a
// job back, which is what stops the admin banner claiming a dead run is still
// working. See `VoiceoverJobService.HEARTBEAT_STALE_MS`.
export enum VoiceoverJobStatus {
  RUNNING = 'running',
  DONE = 'done',
  FAILED = 'failed',
  INTERRUPTED = 'interrupted',
}

// Whether the run was asked to re-synthesise everything (`FORCE`) or only what
// is missing/stale/failed (`NEEDED`, relying on generateForKeypoint's own
// per-language hash skip).
export enum VoiceoverJobMode {
  NEEDED = 'needed',
  FORCE = 'force',
}
