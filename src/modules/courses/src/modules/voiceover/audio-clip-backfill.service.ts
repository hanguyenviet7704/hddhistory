import { Injectable, Logger } from '@nestjs/common';

import { clipRowsFromKeypointAudio } from './audio-clip.util';
import { KeypointAudioClipRepository } from './repository/keypoint-audio-clip.repository';
import { KeypointAudioClip } from './schema/keypoint-audio-clip.schema';
import { KeypointRepository } from '../keypoint/repository/keypoint.repository';

export interface AudioClipBackfillResult {
  scanned: number;
  found: number;
  inserted: number;
  /**
   * How many clips the store holds afterwards.
   *
   * The receipt that matters: `inserted` counts what THIS run wrote, and a run
   * that writes nothing because everything is already stored looks exactly like
   * a run that writes nothing because the writes are failing. This tells them
   * apart without a database client.
   */
  total: number;
}

/** A page small enough that one batch of keypoints never dominates memory. */
const PAGE = 200;

/**
 * Seeds `keypoint_audio_clips` from the audio already on every keypoint.
 *
 * Exists as an endpoint as well as a script (`scripts/backfill-audio-clips.ts`)
 * because the hosted environments are not reachable from a laptop: the dev API
 * talks to a different Mongo than any local `.env`, so "run the script" is not
 * an instruction anyone can follow there. `POST versions/backfill` set the same
 * precedent for the version rollout.
 *
 * Idempotent — the unique index absorbs re-runs — so it is safe to call again
 * after a dub, and safe to call twice by accident.
 *
 * **It has to run before the version-aware read path is trusted.** Until a
 * keypoint has rows here, `AudioResolver` deliberately falls back to the audio
 * frozen in the tag; that guard is what makes deploying before backfilling
 * merely stale rather than silent.
 */
@Injectable()
export class AudioClipBackfillService {
  private readonly logger = new Logger(AudioClipBackfillService.name);

  constructor(
    private readonly keypointRepository: KeypointRepository,
    private readonly clipRepository: KeypointAudioClipRepository,
  ) {}

  async run(): Promise<AudioClipBackfillResult> {
    const result: AudioClipBackfillResult = {
      scanned: 0,
      found: 0,
      inserted: 0,
      total: 0,
    };

    for (let skip = 0; ; skip += PAGE) {
      const page = await this.keypointRepository.findAudioPage(skip, PAGE);
      if (!page.length) break;

      const rows = page.flatMap((doc: any) =>
        clipRowsFromKeypointAudio(String(doc._id), doc.audio),
      );
      result.scanned += page.length;
      result.found += rows.length;
      if (rows.length) {
        result.inserted += await this.clipRepository.insertMissing(
          rows as Partial<KeypointAudioClip>[],
        );
      }
    }

    result.total = await this.clipRepository.countAll();

    this.logger.log(
      `Audio clip backfill: ${result.scanned} keypoints, ${result.found} clips found, ` +
        `${result.inserted} inserted, ${result.total} in store`,
    );

    return result;
  }
}
