import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { IHabitConfig } from '../interface/habit-config.interface';

export const HABIT_CONFIG_KEY = 'default';

/** Default free-tier cap when no config document exists yet. */
export const DEFAULT_FREE_ACTIVE_HABIT_SLOTS = 3;

@Schema({ collection: 'habit_configs' })
export class HabitConfig extends AbstractDocument implements IHabitConfig {
  @Prop({
    required: true,
    default: HABIT_CONFIG_KEY,
  })
  configKey: string;

  @Prop({
    type: Number,
    required: true,
    default: DEFAULT_FREE_ACTIVE_HABIT_SLOTS,
    min: 1,
  })
  freeActiveSlots: number;
}

export const HabitConfigSchema = SchemaFactory.createForClass(HabitConfig);

HabitConfigSchema.index({ configKey: 1 }, { unique: true });
