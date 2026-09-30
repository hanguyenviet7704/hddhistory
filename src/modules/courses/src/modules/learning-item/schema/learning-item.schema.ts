import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import { LearningItemType } from '../enum/learning-item.enum';
import {
  ExerciseInput,
  ILearningItem,
} from '../interface/learning-item.interface';
import { IRoleplay } from '../interface/roleplays/roleplay.interface';
import { ITheoryDocument } from '../interface/theories/theory.interface';
import { IVideoQuestion } from '../interface/videos/video-question.interface';

@Schema({ collection: 'learning_item' })
export class LearningItem extends AbstractDocument implements ILearningItem {
  @Prop()
  keypointId: string;

  @Prop({ type: SchemaTypes.Mixed })
  title: ITranslation;

  @Prop({ type: SchemaTypes.Mixed })
  description: ITranslation;

  @Prop()
  image: string;

  @Prop({ enum: LearningItemType })
  type: LearningItemType;

  @Prop({ type: SchemaTypes.Array })
  questions: ExerciseInput[];

  @Prop({ type: SchemaTypes.Array })
  subQuestions: ExerciseInput[];

  @Prop({ type: SchemaTypes.Array })
  videoQuestions?: IVideoQuestion[];

  @Prop({ type: SchemaTypes.Array })
  documents: ITheoryDocument[];

  @Prop({ type: SchemaTypes.Mixed })
  roleplay: IRoleplay;

  @Prop({ type: SchemaTypes.Array })
  tag: string[];

  @Prop()
  index: number;

  @Prop({ type: SchemaTypes.Boolean })
  isSub: boolean;
}

export const LearningItemSchema = SchemaFactory.createForClass(LearningItem);

LearningItemSchema.index({ keypointId: 1, type: 1 });

// Standalone `type` index: findAllExerciseFolders() (used by the daily
// warm-up auto-tagging scan) filters on `type` alone, which can't use the
// compound { keypointId: 1, type: 1 } index above (type isn't the leading
// key). Cheap to add — doesn't conflict with the compound index.
LearningItemSchema.index({ type: 1 });

// Per-language indexes backing LearningItemRepository.findOption()'s
// `title.${lang}` / `description.${lang}` regex search and
// checkExitsTitle()'s `title.${lang}` exact-match uniqueness check (see
// course.schema.ts for why per-locale indexes are needed on a Mixed
// ITranslation field instead of a single compound one).
LearningItemSchema.index({ 'title.en': 1 });
LearningItemSchema.index({ 'title.vi': 1 });
LearningItemSchema.index({ 'title.zh': 1 });
LearningItemSchema.index({ 'title.ja': 1 });
LearningItemSchema.index({ 'title.ko': 1 });
LearningItemSchema.index({ 'description.en': 1 });
LearningItemSchema.index({ 'description.vi': 1 });
LearningItemSchema.index({ 'description.zh': 1 });
LearningItemSchema.index({ 'description.ja': 1 });
LearningItemSchema.index({ 'description.ko': 1 });
