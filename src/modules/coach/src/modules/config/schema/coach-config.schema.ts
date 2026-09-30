import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  RATING_ASK_ENABLED_DEFAULT,
  RATING_ASK_EVERY_NTH_EXIT_DEFAULT,
  RATING_ASK_MAX_PER_USER_DEFAULT,
  RATING_ASK_MIN_DAYS_DEFAULT,
  RATING_ASK_PROBABILITY_DEFAULT,
  RATING_ASK_SNOOZE_DAYS_DEFAULT,
  TALK_FREE_MAX_TURNS_DEFAULT,
} from '../../../shared/coach.constant';
import {
  ICoachConfig,
  ICoachHotline,
} from '../interface/coach-config.interface';

export const COACH_CONFIG_KEY = 'default';

/**
 * The line shown when ⑧ fires and nothing better is configured.
 *
 * Deliberately NOT a phone number. 115 is Vietnam's emergency line and would be
 * actively wrong for four of the five locales we ship; a generic sentence that
 * points at local emergency services is the only thing that is safe everywhere.
 * Configure real numbers per locale in admin — this exists so a misconfigured
 * environment still says something useful rather than nothing.
 */
export const DEFAULT_COACH_HOTLINES: ICoachHotline[] = [];

@Schema({ collection: 'coach_configs' })
export class CoachConfig extends AbstractDocument implements ICoachConfig {
  @Prop({ required: true, default: COACH_CONFIG_KEY })
  configKey: string;

  // Defaults to false: Coach reaches real people talking about hard things, so
  // it turns on when someone decides to turn it on, not because a document was
  // created.
  @Prop({ type: Boolean, required: true, default: false })
  enabled: boolean;

  @Prop({ type: SchemaTypes.Mixed, default: DEFAULT_COACH_HOTLINES })
  hotlines: ICoachHotline[];

  // Model overrides, editable from admin — null falls through to env/code.
  @Prop({ type: String, default: null })
  geminiModel?: string | null;

  @Prop({ type: String, default: null })
  geminiSceneModel?: string | null;

  // Where a busy model hands the turn on to — comma-separated, best first.
  @Prop({ type: String, default: null })
  geminiFallbackModels?: string | null;

  // Luồng 1 — the four optional onboarding questions. The four main ones
  // (address, goal, barrier, current practice) are always asked.
  @Prop({ type: Boolean, default: true })
  onboardAskStyle: boolean;

  @Prop({ type: Boolean, default: true })
  onboardAskAge: boolean;

  @Prop({ type: Boolean, default: true })
  onboardAskGender: boolean;

  @Prop({ type: Boolean, default: true })
  onboardAskJob: boolean;

  /**
   * Luồng 2 — how many follow-up questions the reader may ask after the
   * grading turn. 0 closes the floor entirely (back to the old behaviour).
   *
   * Here rather than in code because every turn is a Gemini call on top of the
   * two the branch already spends: if that bill surprises anyone, it has to be
   * possible to pull the number down without a deploy.
   */
  @Prop({ type: Number, default: TALK_FREE_MAX_TURNS_DEFAULT })
  talkFreeMaxTurns: number;

  // Luồng 6 — the rating ask after ⟨Vẫn đóng⟩. One AND-ed gate per knob; see
  // `rating-ask-gate.ts` for what each neutral value means.
  @Prop({ type: Boolean, default: RATING_ASK_ENABLED_DEFAULT })
  ratingAskEnabled: boolean;

  @Prop({ type: Number, default: RATING_ASK_MIN_DAYS_DEFAULT, min: 0 })
  ratingAskMinDays: number;

  @Prop({ type: Number, default: RATING_ASK_SNOOZE_DAYS_DEFAULT, min: 0 })
  ratingAskSnoozeDays: number;

  @Prop({ type: Number, default: RATING_ASK_EVERY_NTH_EXIT_DEFAULT, min: 1 })
  ratingAskEveryNthExit: number;

  @Prop({ type: Number, default: RATING_ASK_PROBABILITY_DEFAULT, min: 0, max: 100 })
  ratingAskProbability: number;

  @Prop({ type: Number, default: RATING_ASK_MAX_PER_USER_DEFAULT, min: 0 })
  ratingAskMaxPerUser: number;
}

export const CoachConfigSchema = SchemaFactory.createForClass(CoachConfig);

CoachConfigSchema.index({ configKey: 1 }, { unique: true });
