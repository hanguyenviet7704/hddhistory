import { createHash } from 'crypto';

import {
  ILessonKeypoint,
  ILessonSection,
  IUserLessonAudioCue,
} from '../interface/learning-import.interface';

/**
 * One narration script per section, in section order.
 *
 * Heading first, then the paragraphs, joined by blank lines so the synthesiser
 * pauses between them the way a reader would. HTML is stripped here rather than
 * at generation time because the model is asked for plain prose and only
 * occasionally slips a tag in -- stripping on the way to the ear costs nothing
 * and means a stray `<b>` is never read aloud as "less than b greater than".
 *
 * Returns one entry per section ALWAYS, including empty strings for sections
 * with nothing sayable. The caller depends on index alignment: script `i` is
 * section `i` is card `i` is cue `i`.
 */
export function buildSectionNarrationScripts(
  sections: ILessonSection[],
): string[] {
  return (sections ?? []).map((section) => {
    const parts = [
      section?.title ?? '',
      ...(section?.blocks ?? []).map((block) => block?.text ?? ''),
    ];

    return parts
      .map((part) => stripHtml(part))
      .filter((part) => part.length > 0)
      .join('\n\n')
      .trim();
  });
}

export function stripHtml(value: string): string {
  return String(value || '')
    .replace(/<[^>]*>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Every keypoint's scripts, flattened, with the boundaries kept.
 *
 * One pass rather than a nested loop at the call site: synthesis wants a flat
 * list it can run a worker pool over, and the merge wants to know where one
 * keypoint's clips stop and the next one's start. Returning both from one place
 * is what stops those two views from drifting apart.
 *
 * The TAKEAWAY is one more script at the end of each keypoint's group, at card
 * index `sections.length`. It is not a section, so it used to be dubbed nowhere
 * at all -- the recap card that closes a keypoint sat silent while every card
 * before it read aloud, and narration simply stopped one card early. The
 * catalogue's own keypoints do read their takeaway (there it is a trailing
 * theory item and the reader hands its clips to the recap card), so this is the
 * generated lesson catching up with the shape the reader already expects, not a
 * new idea.
 */
export function buildKeypointNarrationScripts(
  keypoints: ILessonKeypoint[],
): { scripts: string[]; groups: { start: number; count: number }[] } {
  const scripts: string[] = [];
  const groups: { start: number; count: number }[] = [];

  (keypoints ?? []).forEach(keypoint => {
    const own = buildSectionNarrationScripts(keypoint?.sections ?? []);
    const takeaway = stripHtml(keypoint?.takeaway ?? '');
    // Appended only when there is something to say. An empty entry would still
    // occupy a cue and hand the reader a zero-length clip for its recap card,
    // which is a promise of narration the file cannot keep.
    const all = takeaway.length > 0 ? [...own, takeaway] : own;

    groups.push({ start: scripts.length, count: all.length });
    scripts.push(...all);
  });

  return { scripts, groups };
}

/**
 * Lay one keypoint's card durations end to end into cues.
 *
 * A sibling of the catalogue's `buildCues` rather than a call to it: that one
 * emits `{ learningItemId, documentIndex }` because a catalogue keypoint's audio
 * is addressed by the learning item it came from. Here the server has no
 * learning items -- the app synthesises that identity when it maps a keypoint
 * into the reader -- so the cue carries the card index and nothing else.
 *
 * Cards that produced no audio still get a cue, with `durMs: 0`. Skipping them
 * would slide every later index by one and point the reader at the wrong card --
 * exactly the class of bug the catalogue's identity-keyed cue map was introduced
 * to kill.
 *
 * The LAST cue of a keypoint is the takeaway's whenever the keypoint has one
 * (see [buildKeypointNarrationScripts]), so its `cardIndex` is `sections.length`
 * — one past the last card. The app maps that index onto the recap card rather
 * than looking for a card that is not there.
 */
export function buildSectionCues(
  durationsMs: number[],
): { cues: IUserLessonAudioCue[]; durationMs: number } {
  const cues: IUserLessonAudioCue[] = [];
  let cursor = 0;

  durationsMs.forEach((durMs, cardIndex) => {
    cues.push({ cardIndex, startMs: cursor, durMs });
    cursor += durMs;
  });

  return { cues, durationMs: cursor };
}

/**
 * Content identity of a lesson's narration.
 *
 * Includes the voice: a narrator change re-synthesises audio under the SAME
 * deterministic R2 key, so the url alone cannot reveal that what is behind it
 * changed. The hash rides in the url via `appendVersion`.
 */
export function computeNarrationHash(
  voice: string,
  scripts: string[],
): string {
  return createHash('sha256')
    .update([voice ?? '', ...scripts].join('|'))
    .digest('hex');
}
