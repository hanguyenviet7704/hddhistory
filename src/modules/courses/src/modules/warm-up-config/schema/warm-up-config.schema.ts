import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { WarmUpInactivityUnit } from '../enum/warm-up-inactivity-unit.enum';
import { IWarmUpConfig } from '../interface/warm-up-config.interface';

export const WARM_UP_CONFIG_KEY = 'default';

@Schema({ collection: 'warm_up_configs' })
export class WarmUpConfig extends AbstractDocument implements IWarmUpConfig {
  @Prop({
    required: true,
    default: WARM_UP_CONFIG_KEY,
  })
  configKey: string;

  @Prop({ type: Boolean, required: true, default: false })
  enabled: boolean;

  @Prop({ type: Number, required: true, default: 3, min: 1 })
  inactivityValue: number;

  @Prop({
    type: String,
    required: true,
    enum: WarmUpInactivityUnit,
    default: WarmUpInactivityUnit.DAYS,
  })
  inactivityUnit: WarmUpInactivityUnit;

  /**
   * @deprecated Superseded by inactivityValue + inactivityUnit. Kept declared
   * (optional) so pre-existing documents still round-trip on read; no code
   * writes to it anymore.
   */
  @Prop({ type: Number, required: false, min: 1 })
  inactivityDays?: number;
}

export const WarmUpConfigSchema = SchemaFactory.createForClass(WarmUpConfig);

WarmUpConfigSchema.index({ configKey: 1 }, { unique: true });
