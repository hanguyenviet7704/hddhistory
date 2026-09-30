import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { OutputPracticeConversationStatus } from '../enum/output-practice-conversation.enum';
import { IOutputPracticeConversation } from '../interface/output-practice-conversation.interface';

import type { OutputPracticeAiReply } from '../../ai/output-practice-ai.service';

@Schema({ collection: 'output_practice_conversations' })
export class OutputPracticeConversation
  extends AbstractDocument
  implements IOutputPracticeConversation
{
  @Prop({ required: true })
  userId: string;

  @Prop({ required: true })
  sectionId: string;

  @Prop({ required: true })
  language: string;

  @Prop({ required: true })
  threadId: string;

  // Atomic sequence counter for messages in this conversation.
  @Prop({ default: 0 })
  lastSeq: number;

  @Prop({ type: Object, default: null })
  reply: OutputPracticeAiReply | null;

  @Prop({
    enum: OutputPracticeConversationStatus,
    default: OutputPracticeConversationStatus.ACTIVE,
  })
  status: OutputPracticeConversationStatus;
}

export const OutputPracticeConversationSchema =
  SchemaFactory.createForClass(OutputPracticeConversation);

OutputPracticeConversationSchema.index({ userId: 1, sectionId: 1, createdAt: -1 });
OutputPracticeConversationSchema.index({ threadId: 1 }, { unique: true });
OutputPracticeConversationSchema.index({ userId: 1, createdAt: -1 });
