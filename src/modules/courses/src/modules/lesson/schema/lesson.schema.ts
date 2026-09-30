import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import { LessonStatus, LessonType } from '../enum/lesson.enum';
import { ILesson } from '../interface/lesson.interface';

@Schema()
export class Lesson extends AbstractDocument implements ILesson {
  @Prop()
  courseId: string;

  @Prop()
  learningItemId: string;

  @Prop({ enum: LessonType, default: LessonType.LESSON })
  type: LessonType;

  @Prop({ type: SchemaTypes.Mixed })
  title: ITranslation;

  @Prop({ type: SchemaTypes.Mixed })
  description: ITranslation;

  @Prop()
  image: string;

  @Prop({ type: SchemaTypes.Mixed })
  video?: ILesson['video'];

  @Prop({ enum: LessonStatus, default: LessonStatus.DRAFT })
  status: LessonStatus;

  @Prop({ type: SchemaTypes.Array })
  keypoints: string[];

  @Prop({ type: SchemaTypes.Mixed })
  estimateCompleTime: ITranslation;

  // Numeric estimate in minutes for backend calculations.
  // Keep text estimateCompleTime for display only.
  @Prop({ type: Number, default: 0, min: 0 })
  estimateCompleTimeNumber?: number;

  @Prop()
  icon: string;

  @Prop()
  lightIcon: string;

  @Prop()
  AIConfig: string;

  @Prop()
  animation: string;

  @Prop()
  index: number;
}

export const LessonSchema = SchemaFactory.createForClass(Lesson);

LessonSchema.index({ courseId: 1 });
LessonSchema.index({ courseId: 1, index: 1 });

// Per-language indexes backing LessonRepository.findOption()'s
// `title.${lang}` / `description.${lang}` regex search and
// checkExitsTitle()'s `title.${lang}` exact-match uniqueness check (see
// course.schema.ts for why per-locale indexes are needed on a Mixed
// ITranslation field instead of a single compound one).
LessonSchema.index({ 'title.en': 1 });
LessonSchema.index({ 'title.vi': 1 });
LessonSchema.index({ 'title.zh': 1 });
LessonSchema.index({ 'title.ja': 1 });
LessonSchema.index({ 'title.ko': 1 });
LessonSchema.index({ 'description.en': 1 });
LessonSchema.index({ 'description.vi': 1 });
LessonSchema.index({ 'description.zh': 1 });
LessonSchema.index({ 'description.ja': 1 });
LessonSchema.index({ 'description.ko': 1 });
