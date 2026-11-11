import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { KeypointAudioClip } from '../schema/keypoint-audio-clip.schema';

@Injectable()
export class KeypointAudioClipRepository extends AbstractRepository<KeypointAudioClip> {
  protected readonly logger = new Logger(KeypointAudioClipRepository.name);

  constructor(
    @InjectModel(KeypointAudioClip.name) model: Model<KeypointAudioClip>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Every clip belonging to a batch of keypoints, oldest first.
   *
   * Oldest first is load-bearing: callers build a map keyed by
   * `(keypointId, lang, kind, textHash)` and let later rows overwrite earlier
   * ones, so a narrator switch — which inserts a second row for the same text —
   * wins without anyone having to filter by voice.
   */
  async findByKeypointIds(keypointIds: string[]): Promise<KeypointAudioClip[]> {
    if (!keypointIds.length) return [];

    return this.model
      .find({ keypointId: { $in: keypointIds } })
      .sort({ createdAt: 1, _id: 1 })
      .lean() as unknown as Promise<KeypointAudioClip[]>;
  }

  /** How many clips the store holds. The backfill's only honest receipt. */
  async countAll(): Promise<number> {
    return this.model.countDocuments({});
  }

  /**
   * Store clips, skipping any whose identity is already there.
   *
   * An upsert per row rather than one `insertMany({ ordered: false })`.
   * `insertMany` looked cheaper and was wrong: a batch that contains two rows
   * with the same identity — one keypoint really can hold the same sentence on
   * two cards — throws, and what it throws is a duplicate-key error whose shape
   * varies enough that the first version read it as "nothing inserted" and
   * reported a backfill of 34,428 clips as `inserted: 0` while writing nothing.
   * An upsert has no error to interpret.
   *
   * Returns how many rows were actually added, so a caller can tell "already
   * done" from "did nothing".
   */
  async insertMissing(clips: Partial<KeypointAudioClip>[]): Promise<number> {
    if (!clips.length) return 0;

    const now = new Date();
    const result = await this.model.bulkWrite(
      clips.map(clip => ({
        updateOne: {
          filter: {
            keypointId: clip.keypointId,
            lang: clip.lang,
            kind: clip.kind,
            textHash: clip.textHash,
            voice: clip.voice ?? '',
          },
          // `$setOnInsert` only: a clip already stored is never rewritten, and
          // that is the append-only promise the whole store rests on.
          update: { $setOnInsert: { ...clip, createdAt: now, updatedAt: now } },
          upsert: true,
        },
      })),
      { ordered: false },
    );

    // Every count the driver gives back, not just the one we expect: a run that
    // writes nothing must be able to say WHY — matched-but-not-upserted means
    // the rows are already there, matched 0 and upserted 0 means the write
    // never landed, and the two used to look identical from outside.
    const upserted = result.upsertedCount ?? 0;
    if (!upserted && clips.length) {
      this.logger.warn(
        `insertMissing wrote nothing for ${clips.length} clips: ` +
          `matched=${result.matchedCount} modified=${result.modifiedCount} ` +
          `upserted=${result.upsertedCount}`,
      );
    }

    return upserted;
  }
}
