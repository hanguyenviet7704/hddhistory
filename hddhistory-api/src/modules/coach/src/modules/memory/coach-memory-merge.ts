import {
  CoachMemoryStatus,
  CoachMemoryType,
  ICoachMemory,
} from './interface/memory.interface';
import {
  MEMORY_ACTIVE_EVIDENCE,
  MEMORY_MAX_CONFIDENCE,
  MEMORY_NEW_MAX_CONFIDENCE,
  MEMORY_NEW_MIN_CONFIDENCE,
  MEMORY_REINFORCE_STEP,
} from '../../shared/coach.constant';

/** One thing the extraction says it heard — new, or the reinforcement of a known row. */
export interface ExtractedMemory {
  /** The id of an existing memory this reinforces, or null for a new one. */
  id?: string | null;
  type: CoachMemoryType;
  content: string;
  /** The model's own confidence, 0–1. Capped for new rows — see `mergeMemory`. */
  confidence: number;
  /** Only ever set by the extraction to move a pattern along: improving, inactive. */
  status?: CoachMemoryStatus | null;
}

/**
 * "Memory không phải sự thật tuyệt đối" — the arithmetic of doubt.
 *
 * A new memory starts capped (never above `MEMORY_NEW_MAX_CONFIDENCE`), and a
 * new PATTERN starts as `possible`: one evening of not speaking up is not a
 * trait. Each time the same row is heard again its evidence count and
 * confidence step up, and a possible pattern becomes active only at
 * `MEMORY_ACTIVE_EVIDENCE`. The extraction may move a row to `improving` or
 * `inactive` — behaviour changes, and the memory has to be allowed to change
 * with it — but it may never promote one on its own.
 *
 * Pure, so the rules can be pinned in a spec without a database.
 */
export function mergeMemory(
  existing: ICoachMemory | null,
  extracted: ExtractedMemory,
  sessionId: string,
  now: Date = new Date(),
): Partial<ICoachMemory> {
  const content = extracted.content.trim();

  if (!existing) {
    const confidence = clamp(
      extracted.confidence,
      MEMORY_NEW_MIN_CONFIDENCE,
      MEMORY_NEW_MAX_CONFIDENCE,
    );

    return {
      type: extracted.type,
      content,
      confidence,
      evidenceCount: 1,
      firstSeen: now,
      lastSeen: now,
      status:
        extracted.type === CoachMemoryType.PATTERN
          ? CoachMemoryStatus.POSSIBLE
          : CoachMemoryStatus.ACTIVE,
      sourceSessionIds: [sessionId],
    };
  }

  const evidenceCount = existing.evidenceCount + 1;
  const confidence = Math.min(
    MEMORY_MAX_CONFIDENCE,
    Math.max(existing.confidence, extracted.confidence) + MEMORY_REINFORCE_STEP,
  );

  let status = existing.status;
  if (
    extracted.status === CoachMemoryStatus.IMPROVING ||
    extracted.status === CoachMemoryStatus.INACTIVE
  ) {
    status = extracted.status;
  } else if (
    status === CoachMemoryStatus.POSSIBLE &&
    evidenceCount >= MEMORY_ACTIVE_EVIDENCE
  ) {
    status = CoachMemoryStatus.ACTIVE;
  }

  return {
    // Reinforcement may sharpen the wording; the row stays the same row.
    content: content || existing.content,
    confidence,
    evidenceCount,
    lastSeen: now,
    status,
    sourceSessionIds: existing.sourceSessionIds.includes(sessionId)
      ? existing.sourceSessionIds
      : [...existing.sourceSessionIds, sessionId],
  };
}

function clamp(value: number, min: number, max: number): number {
  if (!Number.isFinite(value)) return min;

  return Math.min(max, Math.max(min, value));
}
