import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { ICoachEpisode } from '../interface/memory.interface';

/** A moment that mattered — the situation, what it felt like, what they saw in it. */
@Schema({ collection: 'coach_episodes', timestamps: true })
export class CoachEpisode extends AbstractDocument implements ICoachEpisode {
  @Prop({ type: String, required: true, index: true })
  userId: string;

  @Prop({ type: String, required: true })
  sessionId: string;

  @Prop({ type: String, required: true })
  situation: string;

  @Prop({ type: String, default: null })
  emotion?: string | null;

  @Prop({ type: String, default: null })
  insight?: string | null;
}

export const CoachEpisodeSchema = SchemaFactory.createForClass(CoachEpisode);
CoachEpisodeSchema.index({ userId: 1, createdAt: -1 });
