import { Injectable } from '@nestjs/common';

import { clipRefKey, clipTextHash } from '../voiceover/audio-clip.util';
import { buildNarrationSegments } from '../voiceover/narration-text.util';
import { KeypointAudioClipRepository } from '../voiceover/repository/keypoint-audio-clip.repository';
import { VOICEOVER_LANGS } from '../voiceover/tts.service';
import { PublishedContentRepository } from './repository/published-content.repository';

type Doc = Record<string, any>;

/**
 * Per-language verdict for one keypoint of one tag.
 *
 * Deliberately the same vocabulary the working-tree coverage grid already uses
 * (`VoiceoverCellStatus`), minus `failed`: a failure belongs to a dub RUN, and
 * runs happen against the working tree. A tag only ever answers "is there a
 * recording for the words I hold".
 */
export type AudioCoverageStatus = 'done' | 'stale' | 'missing' | 'none';

export interface KeypointAudioCoverage {
  keypointId: string;
  title: Record<string, string>;
  statuses: Record<string, AudioCoverageStatus>;
  /** Cards with words but no recording, per language. Drives "thiếu N ô". */
  missing: Record<string, number>;
}

export interface CourseAudioCoverage {
  courseId: string;
  versionId: string;
  langs: string[];
  summary: Record<AudioCoverageStatus, number>;
  /** True when every cell is `done` or `none` — what the publish gate reads. */
  complete: boolean;
  /**
   * The clip store is empty EVERYWHERE, not just for this course.
   *
   * That means the backfill has not run in this environment, which is not the
   * same as "this course has no audio" — and the gate must tell them apart.
   * Reading an un-backfilled environment as "no audio" would lock every publish
   * behind a condition nobody can satisfy; reading a never-dubbed course as
   * "cannot tell" would wave through exactly what the gate exists to stop.
   */
  storeEmpty: boolean;
  keypoints: KeypointAudioCoverage[];
}

/**
 * "Does this tag have its audio?", answered from the tag's own text.
 *
 * Judged on CARDS, not on the whole-keypoint file: cards are what the app
 * plays. A language is `done` when every card that has words has a recording,
 * `stale` when only some do (the usual shape after an edit — most cards
 * unchanged, one rewritten), `missing` when none do, and `none` when the
 * keypoint has nothing to read in that language, which counts as covered.
 *
 * See `plans/260916-audio-theo-tag/README.md` section 4.
 */
@Injectable()
export class AudioCoverageService {
  constructor(
    private readonly publishedContentRepository: PublishedContentRepository,
    private readonly clipRepository: KeypointAudioClipRepository,
  ) {}

  async forVersion(
    courseId: string,
    versionId: string,
  ): Promise<CourseAudioCoverage> {
    const [keypoints, learningItems] = await Promise.all([
      this.publishedContentRepository.findAllOfType(versionId, 'keypoint'),
      this.publishedContentRepository.findAllOfType(versionId, 'learningItem'),
    ]);

    const itemsByKeypoint = new Map<string, Doc[]>();
    for (const item of learningItems) {
      const key = String(item.keypointId ?? '');
      if (!key) continue;
      const bucket = itemsByKeypoint.get(key);
      if (bucket) bucket.push(item);
      else itemsByKeypoint.set(key, [item]);
    }

    const ids = keypoints.map(keypoint => String(keypoint._id));
    const clips = await this.clipRepository.findByKeypointIds(ids);
    // Only when this course has nothing is the wider question worth a query:
    // an empty store everywhere is a missing backfill, an empty store here is
    // a course that was never dubbed.
    const storeEmpty =
      clips.length === 0 && (await this.clipRepository.countAll()) === 0;
    const have = new Set(
      clips.map(clip =>
        clipRefKey({
          keypointId: clip.keypointId,
          lang: clip.lang,
          kind: clip.kind,
          textHash: clip.textHash,
        }),
      ),
    );

    const summary: Record<AudioCoverageStatus, number> = {
      done: 0,
      stale: 0,
      missing: 0,
      none: 0,
    };
    const rows: KeypointAudioCoverage[] = [];

    for (const keypoint of keypoints) {
      const keypointId = String(keypoint._id);
      const items = (itemsByKeypoint.get(keypointId) ?? [])
        .slice()
        .sort((a, b) => (a.index ?? 0) - (b.index ?? 0));

      const statuses: Record<string, AudioCoverageStatus> = {};
      const missing: Record<string, number> = {};

      for (const lang of VOICEOVER_LANGS) {
        const cards = buildNarrationSegments(items, lang).filter(Boolean);
        if (!cards.length) {
          statuses[lang] = 'none';
          summary.none += 1;
          continue;
        }

        const absent = cards.filter(
          text =>
            !have.has(
              clipRefKey({
                keypointId,
                lang,
                kind: 'card',
                textHash: clipTextHash(text),
              }),
            ),
        ).length;

        const status: AudioCoverageStatus =
          absent === 0 ? 'done' : absent === cards.length ? 'missing' : 'stale';
        statuses[lang] = status;
        summary[status] += 1;
        if (absent) missing[lang] = absent;
      }

      rows.push({
        keypointId,
        title: (keypoint.title as Record<string, string>) ?? {},
        statuses,
        missing,
      });
    }

    return {
      courseId,
      versionId,
      langs: VOICEOVER_LANGS,
      summary,
      // An empty store is "we cannot tell yet", and the gate reads this field —
      // so it has to mean "do not block", not "block everything".
      complete: storeEmpty || (summary.stale === 0 && summary.missing === 0),
      storeEmpty,
      keypoints: rows,
    };
  }
}
