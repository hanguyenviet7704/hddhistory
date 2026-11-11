import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  OutputPracticeMessageRole,
  OutputPracticeMessageType,
} from '../enum/output-practice-message.enum';
import { IOutputPracticeMessage } from '../interface/output-practice-message.interface';

@Schema({ collection: 'output_practice_messages' })
export class OutputPracticeMessage
  extends AbstractDocument
  implements IOutputPracticeMessage
{
  @Prop({ required: true })
  conversationId: string;

  @Prop({ required: true })
  seq: number;

  @Prop({ required: true })
  content: string;

  @Prop({ enum: OutputPracticeMessageType, required: true })
  type: OutputPracticeMessageType;

  @Prop({ enum: OutputPracticeMessageRole, required: true })
  role: OutputPracticeMessageRole;
}

export const OutputPracticeMessageSchema =
  SchemaFactory.createForClass(OutputPracticeMessage);

OutputPracticeMessageSchema.index({ conversationId: 1, seq: 1 }, { unique: true });
OutputPracticeMessageSchema.index({ conversationId: 1, createdAt: 1 });
