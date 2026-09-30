import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { IOutputPracticeUsage } from '../interface/output-practice-usage.interface';

@Schema({ collection: 'output_practice_usages' })
export class OutputPracticeUsage
  extends AbstractDocument
  implements IOutputPracticeUsage
{
  @Prop({ required: true })
  userId: string;

  @Prop({ required: true })
  sectionId: string;

  // Quota resets automatically because each month writes to a new key,
  // for example: 2026-03, 2026-04.
  @Prop({ required: true })
  monthKey: string;

  @Prop({ type: Number, default: 0, min: 0 })
  usedCount: number;
}

export const OutputPracticeUsageSchema =
  SchemaFactory.createForClass(OutputPracticeUsage);

OutputPracticeUsageSchema.index(
  { userId: 1, sectionId: 1, monthKey: 1 },
  { unique: true },
);
