import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  ICoachSceneScore,
  ICoachScoreCriterion,
} from '../interface/score.interface';

@Schema({ collection: 'coach_scene_scores' })
export class CoachSceneScore
  extends AbstractDocument
  implements ICoachSceneScore
{
  @Prop({ type: String, required: true })
  userId: string;

  @Prop({ type: String, required: true })
  habitId: string;

  @Prop({ type: String, default: null })
  situationId?: string | null;

  @Prop({ type: Number, default: 1, min: 1, max: 5 })
  level: number;

  // Mixed rather than a sub-schema: the criteria keys are authored per habit in
  // admin, so the shape is data, not a model this file gets to fix.
  @Prop({ type: [Object], default: [] })
  criteria: ICoachScoreCriterion[];

  @Prop({ type: Number, default: 0, min: 0, max: 10 })
  overall: number;

  @Prop({ type: String, default: null })
  strength?: string | null;

  @Prop({ type: String, default: null })
  improve?: string | null;

  @Prop({ type: String, default: null })
  tip?: string | null;

  @Prop({ type: Boolean, default: false })
  retry: boolean;
}

export const CoachSceneScoreSchema =
  SchemaFactory.createForClass(CoachSceneScore);

// Every read is "this reader, this skill, most recent first" — the skill number
// on the habit and the "you used to…" line in the recap are the same query.
CoachSceneScoreSchema.index({ userId: 1, habitId: 1, createdAt: -1 });
