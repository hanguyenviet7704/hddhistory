import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  ImportJobStage,
  ImportJobStatus,
  ImportSourceType,
} from '../enum/learning-import.enum';
import {
  IImportError,
  IImportSource,
  IImportUsage,
} from '../interface/learning-import.interface';

/**
 * Progress of one import run.
 *
 * Lives in Mongo rather than in a `Map` on the service, which is the same lesson
 * `VoiceoverJob` records: in-memory progress is wiped by any deploy mid-run (the
 * user watches a spinner that will never finish), and across replicas the POST
 * that starts a run and the GET that polls it can land on different workers, so
 * the poll answers `null` about a job that is running fine.
 *
 * `user_lessons` is the source of truth for RESULTS -- this collection only
 * tracks a run -- so pruning a stale job document costs nothing but the progress
 * readout.
 */
// No `timestamps: true` -- see the note on UserLesson.
@Schema({ collection: 'learning_import_jobs' })
export class LearningImportJob extends AbstractDocument {
  @Prop({ type: String, required: true, index: true })
  userId: string;

  @Prop({ type: String, enum: ImportSourceType, required: true })
  sourceType: ImportSourceType;

  @Prop({ type: Object, required: true })
  source: IImportSource;

  @Prop({ type: String, required: true })
  outputLocale: string;

  @Prop({
    type: String,
    enum: ImportJobStatus,
    default: ImportJobStatus.QUEUED,
  })
  status: ImportJobStatus;

  /**
   * Which step a running job is on; null when it is not running.
   *
   * `null` has to be listed in the enum explicitly. Mongoose runs the enum
   * validator on the DEFAULT too, so `enum: ImportJobStage, default: null`
   * rejects the document at creation with "`null` is not a valid enum value" --
   * a 500 on every POST, before the job has done anything at all. Neither `tsc`
   * nor a DI boot can see it; it only shows up against a real Mongo.
   */
  @Prop({
    type: String,
    enum: [...Object.values(ImportJobStage), null],
    default: null,
  })
  stage: ImportJobStage | null;

  @Prop({ type: Number, default: 0 })
  percent: number;

  /**
   * Written at every stage boundary.
   *
   * A `PROCESSING` document whose heartbeat has gone quiet is a run whose process
   * died. Nothing is left alive to write a final status, so the read path derives
   * `INTERRUPTED` from this rather than letting the app insist a dead run is
   * still working -- see ImportJobStatus.
   */
  @Prop({ type: Date })
  heartbeatAt: Date;

  @Prop({ type: Date })
  startedAt: Date;

  @Prop({ type: Date })
  completedAt?: Date;

  @Prop({ type: Object, default: null })
  error: IImportError | null;

  @Prop({ type: String, default: '' })
  userLessonId: string;

  @Prop({ type: Object, default: null })
  usage: IImportUsage | null;

  /**
   * Whether this attempt consumes one of the user's monthly slots.
   *
   * The quota is counted by querying this collection, so this flag IS the
   * accounting -- there is no separate counter to drift out of sync. Set false
   * the moment a run fails, because a failed run left the user with no lesson.
   */
  @Prop({ type: Boolean, default: true })
  countsTowardQuota: boolean;
}

export const LearningImportJobSchema =
  SchemaFactory.createForClass(LearningImportJob);

// Backs both the user's job history and the monthly quota count.
LearningImportJobSchema.index({ userId: 1, createdAt: -1 });
// Backs the single-flight check ("does this user already have one running?").
LearningImportJobSchema.index({ userId: 1, status: 1, heartbeatAt: -1 });
// Backs the admin list, which is ordered by time across all users.
LearningImportJobSchema.index({ createdAt: -1 });
