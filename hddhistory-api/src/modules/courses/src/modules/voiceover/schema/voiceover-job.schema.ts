import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  VoiceoverJobMode,
  VoiceoverJobScope,
  VoiceoverJobStatus,
} from '../enum/voiceover-job.enum';

/**
 * Live progress of a dub run.
 *
 * This used to be a `Map` in `VoiceoverJobService`, which had two consequences
 * the admin felt directly: a deploy or restart mid-run wiped the progress (the
 * banner vanished while nothing was actually finished), and under more than one
 * replica the POST that started a job and the GET that read its status could
 * land on different workers, so the status came back `null`.
 *
 * The DB (`keypoint.audio`) is still the source of truth for RESULTS — this
 * collection only tracks a run — so a document going stale costs nothing but
 * the progress readout, and re-triggering resumes via the per-keypoint hash
 * skip.
 */
@Schema({ collection: 'voiceover_jobs' })
export class VoiceoverJob extends AbstractDocument {
  @Prop({ type: String, enum: VoiceoverJobScope, required: true })
  scope: VoiceoverJobScope;

  // '' for the global job. An explicit empty string rather than leaving the
  // field unset, so the unique { scope, courseId } index below reads as "one
  // document per scope" without depending on how Mongo indexes a missing key.
  @Prop({ type: String, default: '' })
  courseId: string;

  @Prop({
    type: String,
    enum: VoiceoverJobStatus,
    default: VoiceoverJobStatus.RUNNING,
  })
  status: VoiceoverJobStatus;

  @Prop({
    type: String,
    enum: VoiceoverJobMode,
    default: VoiceoverJobMode.NEEDED,
  })
  mode: VoiceoverJobMode;

  @Prop({ type: Number, default: 0 })
  totalCourses: number;

  @Prop({ type: Number, default: 0 })
  processedCourses: number;

  // Counted up front (one aggregation over lessons) rather than accumulated per
  // course, so the progress bar and the ETA have a denominator that doesn't
  // move under them.
  @Prop({ type: Number, default: 0 })
  totalKeypoints: number;

  @Prop({ type: Number, default: 0 })
  processed: number;

  @Prop({ type: Number, default: 0 })
  generated: number;

  @Prop({ type: Number, default: 0 })
  skipped: number;

  @Prop({ type: Number, default: 0 })
  failed: number;

  @Prop({ type: String, default: '' })
  currentCourseId: string;

  // The whole multilingual title map, not a single rendered string: the admin
  // panel picks the language itself, and storing it here is what lets the batch
  // page name the course being dubbed without a second lookup per poll.
  @Prop({ type: Object, default: {} })
  currentCourseTitle: Record<string, string>;

  @Prop({ type: String, default: '' })
  currentKeypointId: string;

  @Prop({ type: Object, default: {} })
  currentKeypointTitle: Record<string, string>;

  // Courses this run has yet to reach / has finished — the two lists behind the
  // per-row "Đang chờ" / "Xong" badges, and what lets a resumed run skip the
  // courses already done instead of walking them again for the hash check.
  @Prop({ type: [String], default: [] })
  queuedCourseIds: string[];

  @Prop({ type: [String], default: [] })
  doneCourseIds: string[];

  @Prop({ type: String, default: '' })
  lastError: string;

  @Prop({ type: Date })
  startedAt: Date;

  @Prop({ type: Date })
  finishedAt?: Date;

  // Written at every keypoint boundary. A `RUNNING` document whose heartbeat has
  // gone quiet is a run whose process died (deploy, restart, crash) — see
  // `VoiceoverJobStatus.INTERRUPTED`.
  @Prop({ type: Date })
  heartbeatAt: Date;
}

export const VoiceoverJobSchema = SchemaFactory.createForClass(VoiceoverJob);

// One document per scope, and the guard behind the single-flight claim: when a
// live run already holds the slot the claim's filter misses, its upsert tries to
// insert, and this index turns that into a duplicate-key error the repository
// reads as "already running". Without the uniqueness two clicks (or two
// replicas) would each get their own document and dub the catalogue twice.
VoiceoverJobSchema.index({ scope: 1, courseId: 1 }, { unique: true });
// Backs the admin poll: every run currently in flight, in one query.
VoiceoverJobSchema.index({ status: 1, heartbeatAt: -1 });
