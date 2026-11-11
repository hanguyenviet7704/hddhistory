import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { CoachPersona } from '../../../shared/coach.enum';
import { ICoachProfile } from '../interface/profile.interface';

@Schema({ collection: 'coach_profiles' })
export class CoachProfile extends AbstractDocument implements ICoachProfile {
  @Prop({ required: true })
  userId: string;

  @Prop({ type: String, enum: [...Object.values(CoachPersona), null], default: null })
  lastPersona?: CoachPersona | null;

  // Dead since the 👍/👎 toast was removed (2026-09-14); every document written
  // before then still has them, so the props stay rather than silently dropping
  // fields a reader of the collection can still see.
  @Prop({ type: Number, default: 0, min: 0 })
  ratingSkipCount: number;

  @Prop({ type: Boolean, default: false })
  ratingHidden: boolean;

  /** Luồng 6 — the rating sheet after ⟨Vẫn đóng⟩; see `rating-ask-gate.ts`. */
  @Prop({ type: Date, default: null })
  ratingAskedAt?: Date | null;

  @Prop({ type: Date, default: null })
  ratingSnoozedAt?: Date | null;

  @Prop({ type: Number, default: 0, min: 0 })
  ratingAskCount: number;

  @Prop({ type: Number, default: 0, min: 0 })
  exitCount: number;

  /** Luồng 6 — see `EXIT_PLEA_OFF_AFTER`. */
  @Prop({ type: Number, default: 0, min: 0 })
  exitDeclinedStreak: number;

  /** Luồng 6 — they have told us once why they left; ⟨Đóng⟩ pleads from now on. */
  @Prop({ type: Boolean, default: false })
  exitFeedbackGiven: boolean;

  /** Luồng 6 — asks closed without an answer; see `EXIT_FEEDBACK_OFF_AFTER`. */
  @Prop({ type: Number, default: 0, min: 0 })
  exitFeedbackSkips: number;

  // ---- luồng 1 — Onboarding Coach, once per reader ----------------------
  /** How the Coach addresses them: bạn · anh · chị · em, or a name they gave. */
  @Prop({ type: String, default: null })
  address?: string | null;

  /** "Chị muốn cải thiện điều gì nhất?" — a chip's value or their own words. */
  @Prop({ type: String, default: null })
  goalText?: string | null;

  /** "Điều gì đang cản chị nhiều nhất?" — kept verbatim; ranks habits at T2. */
  @Prop({ type: String, default: null })
  barrierText?: string | null;

  /** "Giờ chị đang làm gì cho việc đó?" — so the Coach never suggests what they already do. */
  @Prop({ type: String, default: null })
  currentPractice?: string | null;

  /** read · example · practice. */
  @Prop({ type: String, default: null })
  learningStyle?: string | null;

  /** One of six groups; scene caches read the group, never the raw words. */
  @Prop({ type: String, default: null })
  occupation?: string | null;

  @Prop({ type: String, default: null })
  occupationRaw?: string | null;

  @Prop({ type: Date, default: null })
  onboardedAt?: Date | null;

  @Prop({ type: Number, default: null })
  onboardVersion?: number | null;
}

export const CoachProfileSchema = SchemaFactory.createForClass(CoachProfile);

CoachProfileSchema.index({ userId: 1 }, { unique: true });
