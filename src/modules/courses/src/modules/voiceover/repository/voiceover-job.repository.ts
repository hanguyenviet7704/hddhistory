import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { VoiceoverJobScope, VoiceoverJobStatus } from '../enum/voiceover-job.enum';
import { VoiceoverJob } from '../schema/voiceover-job.schema';

// Mongo's duplicate-key error. The claim below turns it into a normal answer
// ("someone else is already running this") rather than a failure.
const DUPLICATE_KEY = 11000;

@Injectable()
export class VoiceoverJobRepository extends AbstractRepository<VoiceoverJob> {
  protected readonly logger = new Logger(VoiceoverJobRepository.name);

  constructor(
    @InjectModel(VoiceoverJob.name) model: Model<VoiceoverJob>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Take the run slot for `scope`/`courseId`, or report that a live run already
   * holds it. Returns the freshly claimed job, or `null` when one is in flight.
   *
   * Atomic on purpose. Reading the job and then writing it (what the in-memory
   * version effectively did) leaves a window where two clicks — or two replicas
   * handling one click each — both see "not running" and both start dubbing the
   * whole catalogue. Here the filter only matches a slot that is free or whose
   * heartbeat has gone quiet, so at most one caller updates; a caller that
   * misses falls through to the upsert, hits the unique { scope, courseId }
   * index, and gets `null`.
   *
   * `staleBefore` is what makes a run whose process died reclaimable: without
   * it, a deploy mid-dub would leave a `RUNNING` document no one can ever
   * replace, and the admin could never start another run.
   */
  async claim(
    scope: VoiceoverJobScope,
    courseId: string,
    seed: Partial<VoiceoverJob>,
    staleBefore: Date,
  ): Promise<VoiceoverJob | null> {
    try {
      return await this.findOneAndUpdate(
        {
          scope,
          courseId,
          $or: [
            { status: { $ne: VoiceoverJobStatus.RUNNING } },
            { heartbeatAt: { $lt: staleBefore } },
          ],
        },
        { $set: seed, $unset: { finishedAt: '' } },
        { upsert: true },
      );
    } catch (err: any) {
      if (err?.code === DUPLICATE_KEY) return null;
      throw err;
    }
  }

  async patch(
    scope: VoiceoverJobScope,
    courseId: string,
    data: Partial<VoiceoverJob>,
  ): Promise<void> {
    await this.model.updateOne({ scope, courseId }, { $set: data });
  }

  async findByScope(
    scope: VoiceoverJobScope,
    courseId: string,
  ): Promise<VoiceoverJob | null> {
    return this.model.findOne({ scope, courseId }).lean<VoiceoverJob>();
  }

  /**
   * Every run in flight, plus the ones that finished since `finishedSince` —
   * the single query behind the admin poll. The recently-finished ones are what
   * let a course row still show its outcome for a while after a per-course dub
   * ends, instead of the badge simply disappearing.
   */
  async findLive(finishedSince: Date): Promise<VoiceoverJob[]> {
    return this.model
      .find({
        $or: [
          { status: VoiceoverJobStatus.RUNNING },
          { finishedAt: { $gte: finishedSince } },
        ],
      })
      .lean<VoiceoverJob[]>();
  }
}
