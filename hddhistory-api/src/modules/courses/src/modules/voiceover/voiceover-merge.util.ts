import { createHash } from 'crypto';

import { IMergedAudioCue } from '../keypoint/interface/keypoint.interface';
import { LearningItemType } from '../learning-item/enum/learning-item.enum';

/**
 * A theory document's place in `VoiceoverService.buildSegments`' numbering,
 * plus the card identity the app will look it up by. This walk MUST stay in
 * lockstep with buildSegments (exercise → one segment per question, every
 * other item → one segment per document); it lives here so the numbering has
 * exactly one home on the backend and none in the app.
 */
export interface TheoryCueSlot {
  segmentIndex: number;
  learningItemId: string;
  documentIndex: number;
}

export function computeTheoryCueSlots(items: any[]): TheoryCueSlot[] {
  const slots: TheoryCueSlot[] = [];
  let segmentIndex = 0;
  for (const item of items) {
    if (item.type === LearningItemType.EXERCISE) {
      segmentIndex += (item.questions ?? []).length;
      continue;
    }
    const documents = item.documents ?? [];
    for (
      let documentIndex = 0;
      documentIndex < documents.length;
      documentIndex++
    ) {
      if (item.type === LearningItemType.THEORY) {
        slots.push({
          segmentIndex,
          learningItemId: String(item._id ?? item.id ?? ''),
          documentIndex,
        });
      }
      segmentIndex++;
    }
  }
  return slots;
}

export function buildCues(
  slots: TheoryCueSlot[],
  durationsMs: Map<number, number>,
): { cues: IMergedAudioCue[]; durationMs: number } {
  const cues: IMergedAudioCue[] = [];
  let cursor = 0;
  for (const slot of slots) {
    const durMs = durationsMs.get(slot.segmentIndex) ?? 0;
    cues.push({
      learningItemId: slot.learningItemId,
      documentIndex: slot.documentIndex,
      startMs: cursor,
      durMs,
    });
    cursor += durMs;
  }
  return { cues, durationMs: cursor };
}

/**
 * Content identity of a merged file. Includes the VOICE because a narrator
 * change re-synthesises clips under the SAME deterministic R2 keys — urls
 * alone cannot reveal that the audio behind them changed.
 */
export function computeMergeHash(
  voice: string,
  slots: TheoryCueSlot[],
  segmentHashes: string[],
): string {
  const parts = [
    voice ?? '',
    ...slots.map(
      (s) => `${s.segmentIndex}:${segmentHashes[s.segmentIndex] ?? ''}`,
    ),
  ];
  return createHash('sha256').update(parts.join('|')).digest('hex');
}

/**
 * Cache directive stored on every voiceover object. Safe to keep forever
 * because the urls we hand out are versioned by content hash
 * ([[appendVersion]]) — a re-dub writes the same R2 key but is served under a
 * new url, so nothing can be answered from a stale cache entry.
 */
export const VOICEOVER_CACHE_CONTROL = 'public, max-age=31536000, immutable';

/**
 * Tag a voiceover url with the content hash behind it, so re-dubbed audio
 * arrives under a url no cache has seen. R2 keys are deterministic
 * (`voiceover/<keypoint>/<lang>/…`), which is what made the old un-versioned,
 * un-cacheable urls the only safe option.
 *
 * Returns [url] untouched when either side is missing, and replaces an
 * existing version rather than stacking a second one (re-merges are routine).
 */
export function appendVersion(url: string, hash: string): string {
  if (!url || !hash) return url;
  const version = hash.slice(0, 12);
  const [base] = url.split('?');
  return `${base}?v=${version}`;
}
