import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes, Types } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { HabitPracticeStatus } from '../enum/habit-practice.enum';
import { IHabitPractice } from '../interface/habit-practice.interface';

/**
 * Which authored content serves as practice for a habit. A pointer, never
 * content: the questions/video/roleplay live in `learning_item`, which already
 * has a field set per `LearningItemType` and Flutter renderers for each.
 *
 * An OVERRIDE, not the default. A habit with no row here still has practice —
 * the exercises of the keypoint it hangs off, derived on read by
 * `HabitPracticeService.deriveFromKeypoints`. A row is how an author says "not
 * this keypoint's exercises, THESE items", and is the only way to offer a video
 * or roleplay, since derivation covers exercises only. So an empty collection is
 * the healthy state, and rows are the exception.
 *
 * Deliberately a join collection rather than a `habitId` field on
 * `learning_item`:
 *
 * - The practice's method is just `learningItem.type`, so adding video or
 *   roleplay practices later needs no schema change here at all.
 * - `learning_item` stays unaware that habits exist, so none of its existing
 *   queries change meaning. In particular the daily warm-up auto-tagging job
 *   (`runDailyWarmUpTagging`) bulk-**writes** `questions[].isDailyWarmUp` over
 *   every `type: 'exercise'` folder it groups; its loop opens with
 *   `if (!folder.keypointId) continue`, so habit-only practice content authored
 *   without a keypointId is immune by construction.
 * - Many-to-many both ways, mirroring habit↔keypoint: one learning item can
 *   serve several habits, one habit can have several practices.
 *
 * Journal is NOT represented here. It has no authored content, so it is always
 * available for every habit; to disable it for one habit later, add a flag on
 * `habits` rather than a row here.
 */
@Schema({ collection: 'habit_practices' })
export class HabitPractice extends AbstractDocument implements IHabitPractice {
  @Prop({ type: SchemaTypes.ObjectId, required: true })
  habitId: Types.ObjectId;

  @Prop({ type: SchemaTypes.ObjectId, required: true })
  learningItemId: Types.ObjectId;

  @Prop({ type: Number, default: 0 })
  order: number;

  @Prop({
    type: String,
    enum: HabitPracticeStatus,
    default: HabitPracticeStatus.DRAFT,
  })
  status: HabitPracticeStatus;
}

export const HabitPracticeSchema = SchemaFactory.createForClass(HabitPractice);

// The app's read path: published practices for one habit, in author order.
HabitPracticeSchema.index({ habitId: 1, status: 1, order: 1 });

// Reverse lookup, so deleting a learning item can find and clear the rows that
// point at it instead of leaving practices aimed at nothing.
HabitPracticeSchema.index({ learningItemId: 1 });

// One learning item may serve many habits, but pointing the same habit at the
// same item twice is always a data-entry mistake — it would render the same
// practice twice in the picker.
HabitPracticeSchema.index({ habitId: 1, learningItemId: 1 }, { unique: true });
