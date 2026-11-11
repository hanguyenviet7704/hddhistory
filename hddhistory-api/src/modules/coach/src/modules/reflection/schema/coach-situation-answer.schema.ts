import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { ICoachSituationAnswer } from '../interface/reflection.interface';

@Schema({ collection: 'coach_situation_answers' })
export class CoachSituationAnswer
  extends AbstractDocument
  implements ICoachSituationAnswer
{
  @Prop({ required: true })
  userId: string;

  @Prop({ type: String, required: true })
  sessionId: string;

  @Prop({ type: String, required: true })
  situationId: string;

  @Prop({ type: String, default: null })
  habitId?: string | null;

  @Prop({ type: String, required: true })
  variant: string;

  @Prop({ type: String, required: true })
  content: string;

  /**
   * The question this answer answered, frozen at write time.
   *
   * `situationId` alone is not enough to get the question back: an editor
   * rebuilding a habit's pool DELETES every AI-generated scene, and the answers
   * outlive it. Without this, an admin reading a month-old thread sees a column
   * of replies to nothing. Null on rows written before this field existed —
   * those still fall back to joining the catalogue.
   */
  @Prop({ type: String, default: null })
  promptSnapshot?: string | null;

  /**
   * Which answer to this scene this is: 1 the first, 2 the one after hearing
   * another way of saying it.
   *
   * Both are kept, and both are the reader's own words — nhịp 5 names the
   * difference between them and the recap can do the same weeks later.
   */
  @Prop({ type: Number, default: 1 })
  round?: number;
}

export const CoachSituationAnswerSchema = SchemaFactory.createForClass(
  CoachSituationAnswer,
);

// The ⑤ "ĐỔI THAY" read: same reader, same situation, ordered in time.
CoachSituationAnswerSchema.index({ userId: 1, situationId: 1, createdAt: 1 });
CoachSituationAnswerSchema.index({ userId: 1, createdAt: -1 });
