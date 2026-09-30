import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  CoachSituationSource,
  CoachSituationVariant,
} from '../enum/situation.enum';
import {
  ICoachSituation,
  ICoachSituationOption,
} from '../interface/situation.interface';

@Schema({ collection: 'coach_situations' })
export class CoachSituation
  extends AbstractDocument
  implements ICoachSituation
{
  @Prop({ type: String, required: true })
  habitId: string;

  @Prop({ type: String, required: true })
  locale: string;

  @Prop({ type: String, enum: CoachSituationVariant, required: true })
  variant: CoachSituationVariant;

  // Who the scene is written for — the age band parsed from the reader's
  // onboarding answer. Part of the cache key: a scene that fits a working
  // adult does not fit a teenager, and one row cannot serve both.
  @Prop({ type: String, default: 'unknown' })
  audience: string;

  // The reader's onboarding learning goal, as the option's stable trackingLabel
  // ('unknown' when they never answered). Key, not decoration, for the same
  // reason as audience.
  @Prop({ type: String, default: 'unknown' })
  goalKey: string;

  /**
   * Position in the key's pool, 0-based. Rows cached before the pool existed
   * have no slot and are read as slot 0 — see the repository.
   */
  @Prop({ type: Number, default: 0, min: 0 })
  slot: number;

  // Which corner of life — see CoachSituationContextGroup. Null on rows written
  // before the group existed; those are treated as NEUTRAL.
  @Prop({ type: String, default: null })
  contextGroup?: string | null;

  @Prop({ type: String, required: true })
  prompt: string;

  // The same scene told in the third person, for a low-mood day. Null = only
  // the second-person telling exists.
  @Prop({ type: String, default: null })
  promptThirdPerson?: string | null;

  // Nhịp 4 — the scene's written SECOND stage: the other person reacts and the
  // situation turns one notch harder. Null = one-stage scene, nhịp 4/5 skipped.
  @Prop({ type: String, default: null })
  promptStage2?: string | null;

  @Prop({ type: String, default: null })
  promptStage2ThirdPerson?: string | null;

  @Prop({ type: [String], default: [] })
  samples: string[];

  // The three named ways to answer stage one, written with the scene. Stored
  // as plain subdocuments with no _id of their own — they are a fixed trio read
  // and rewritten together, never addressed one at a time. Empty on every row
  // written before this existed, which the renderer treats as "no block".
  @Prop({
    type: [{ _id: false, key: String, label: String, text: String }],
    default: [],
  })
  openingOptions: ICoachSituationOption[];

  // The scene's script — ordered probe intents the Coach walks (1–2). Absent on
  // rows written before scripts existed; those run the old single-probe path.
  @Prop({ type: [String], default: [] })
  beats: string[];

  // The other person's line per beat, index-aligned with `beats`. Empty entry =
  // probe rather than perform. See the interface.
  @Prop({ type: [String], default: [] })
  beatLines: string[];

  // Difficulty 1..5. Legacy rows have none and are read as the easiest band.
  @Prop({ type: Number, default: null, min: 1, max: 5 })
  level?: number | null;

  // Who the reader is talking to when a beat is performed rather than probed.
  @Prop({ type: String, default: null })
  counterpart?: string | null;

  // The lesson this scene lands, in the closing reply. Null on legacy rows.
  @Prop({ type: String, default: null })
  takeaway?: string | null;

  // The concrete move for this scene's moment — the reminder's default pre-fill.
  @Prop({ type: String, default: null })
  goodMove?: string | null;

  @Prop({
    type: String,
    enum: CoachSituationSource,
    default: CoachSituationSource.GENERATED,
  })
  source: CoachSituationSource;

  @Prop({ type: String, default: null })
  model?: string | null;

  /**
   * Written ahead of time FOR THIS READER, and not handed to them yet.
   *
   * Pre-generation exists because the scene call is the longest wait in the
   * product (5.6–13.2s measured) and the reader spends far longer than that
   * reading an invite or answering the scene before this one. Writing the next
   * one during that gap makes it arrive instantly.
   *
   * Reserved rather than shared on purpose. Handing one reader's pre-written
   * scene to another is how the pool went back to repeating itself
   * (2026-08-28, "tình huống bị lặp lại"); a reservation keeps every scene
   * unique per reader and only moves WHEN it was written. Cleared the moment
   * it is claimed, after which the row is an ordinary pool scene and can serve
   * as anybody's fallback — so a reservation nobody collects is never wasted.
   */
  @Prop({ type: String, default: null })
  reservedForUserId?: string | null;
}

export const CoachSituationSchema = SchemaFactory.createForClass(CoachSituation);

// Unique is the cache contract: two concurrent readers race to generate the
// same slot, and the loser's insert must fail rather than duplicate — see the
// repository's upsert. The repository syncs indexes on boot, so the OLD
// key-without-slot unique index is dropped — left in place it would reject
// every second scene of a pool as a duplicate of the first.
CoachSituationSchema.index(
  { habitId: 1, locale: 1, variant: 1, audience: 1, goalKey: 1, slot: 1 },
  { unique: true },
);

// "Is one already written for me?" — asked at the top of every practice, so it
// must not scan the habit's pool. Partial: only the handful of rows actually
// waiting for someone are in it.
CoachSituationSchema.index(
  { habitId: 1, locale: 1, reservedForUserId: 1 },
  { partialFilterExpression: { reservedForUserId: { $type: 'string' } } },
);
