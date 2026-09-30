import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  CoachMemoryStatus,
  CoachMemoryType,
  ICoachMemory,
} from '../interface/memory.interface';

/**
 * MEMORY — what the raw conversations add up to about the reader, one row
 * per thing known. Refined by evidence: the same thing heard again raises
 * `evidenceCount` and `confidence` on the SAME row rather than adding another.
 */
@Schema({ collection: 'coach_memories', timestamps: true })
export class CoachMemory extends AbstractDocument implements ICoachMemory {
  @Prop({ type: String, required: true, index: true })
  userId: string;

  @Prop({ type: String, required: true, enum: CoachMemoryType })
  type: CoachMemoryType;

  @Prop({ type: String, required: true })
  content: string;

  @Prop({ type: Number, required: true })
  confidence: number;

  @Prop({ type: Number, default: 1 })
  evidenceCount: number;

  @Prop({ type: Date, required: true })
  firstSeen: Date;

  @Prop({ type: Date, required: true })
  lastSeen: Date;

  @Prop({
    type: String,
    enum: CoachMemoryStatus,
    default: CoachMemoryStatus.POSSIBLE,
  })
  status: CoachMemoryStatus;

  @Prop({ type: [String], default: [] })
  sourceSessionIds: string[];
}

export const CoachMemorySchema = SchemaFactory.createForClass(CoachMemory);
CoachMemorySchema.index({ userId: 1, status: 1, confidence: -1, lastSeen: -1 });
