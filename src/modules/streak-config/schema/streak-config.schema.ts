import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

// Singleton lookup key -- there is only ever one StreakConfig document.
export const STREAK_CONFIG_KEY = 'default';

/**
 * Two minutes. The trigger used to be "finished a keypoint", which only ever
 * fired for people already deep in a lesson -- exactly the users who least
 * needed reminding. Time-in-app reaches everyone.
 */
export const DEFAULT_TRIGGER_AFTER_SECONDS = 120;

/** Matches the design note: the toast slides in, then leaves on its own. */
export const DEFAULT_AUTO_HIDE_SECONDS = 3;

// No `timestamps: true` on purpose. AbstractDocument already declares
// createdAt/updatedAt as props and the repository sets them explicitly; adding
// Mongoose's automatic timestamps makes it write `updatedAt` too, and the
// upsert then dies with "Updating the path 'updatedAt' would create a conflict
// at 'updatedAt'" — a 500 on every read of this config.
@Schema({ collection: 'streak_configs' })
export class StreakConfig extends AbstractDocument {
  @Prop({ type: String, default: STREAK_CONFIG_KEY, unique: true })
  configKey: string;

  @Prop({
    type: Boolean,
    default: true,
    comment: 'Kill switch -- false hides the popup without shipping an app build',
  })
  popupEnabled: boolean;

  @Prop({
    type: Number,
    default: DEFAULT_TRIGGER_AFTER_SECONDS,
    comment:
      'Cumulative foreground seconds in the current day before the popup ' +
      'shows. Cumulative, not per-session: someone who opens the app six ' +
      'times for twenty seconds is as engaged as someone who stays two ' +
      'minutes once.',
  })
  triggerAfterSeconds: number;

  @Prop({
    type: Number,
    default: DEFAULT_AUTO_HIDE_SECONDS,
    comment: 'Seconds the toast stays before dismissing itself. 0 = stay until tapped',
  })
  autoHideSeconds: number;
}

export const StreakConfigSchema = SchemaFactory.createForClass(StreakConfig);

// Enforces the singleton invariant at the DB level.
StreakConfigSchema.index({ configKey: 1 }, { unique: true });
