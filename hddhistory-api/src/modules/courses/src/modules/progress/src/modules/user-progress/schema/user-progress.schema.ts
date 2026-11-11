import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { CourseLevel } from 'src/modules/courses/src/modules/course/enum/course.enum';
import {
  ExerciseType,
  FormDragDropType,
} from 'src/modules/courses/src/modules/learning-item/enum/learning-item.enum';
import { IDragDropOptions } from 'src/modules/courses/src/modules/learning-item/interface/excercises/drag-drop.interface';
import { IExerciseChoiceOption } from 'src/modules/courses/src/modules/learning-item/interface/excercises/multiple-choice.interface';
import { IRecordAnswer } from 'src/modules/courses/src/modules/learning-item/interface/excercises/record.interface';
import { IExerciseSingleChoiceNoCorrectAnswerOption } from 'src/modules/courses/src/modules/learning-item/interface/excercises/single-choice-no-correct-answer.interface';
import { LessonType } from 'src/modules/courses/src/modules/lesson/enum/lesson.enum';

import { IUserProgress } from '../interface/user-progress.interface';

// --- ExerciseResult ---
@Schema({ _id: false })
export class ExerciseResult {
  @Prop({ required: true })
  exerciseId: string;

  @Prop({ enum: ExerciseType })
  type: ExerciseType;

  @Prop({ enum: FormDragDropType })
  form: FormDragDropType;

  @Prop({ type: Boolean })
  passed?: boolean;

  @Prop({ type: Number, default: 0 })
  score: number;

  @Prop({ type: SchemaTypes.Array })
  multipleAnswer?: (
    | IExerciseChoiceOption
    | IExerciseSingleChoiceNoCorrectAnswerOption
  )[];

  @Prop({ type: SchemaTypes.Mixed })
  singleAnswer?: IExerciseChoiceOption;

  @Prop({ type: SchemaTypes.Array })
  dragDropAnswer?: IDragDropOptions[];

  @Prop({ type: SchemaTypes.Mixed })
  recordAnswer?: IRecordAnswer;
}
export const ExerciseResultSchema =
  SchemaFactory.createForClass(ExerciseResult);

// --- KeypointResult ---
@Schema({ _id: false })
export class KeypointResult {
  @Prop({ required: true })
  keypointId: string;

  @Prop({ type: Number, default: 0 })
  averageScore: number;

  @Prop({ default: false })
  passed: boolean;

  @Prop({ type: [ExerciseResultSchema], default: [] })
  exercisesResult: ExerciseResult[];

  @Prop({ type: Date, default: Date.now })
  submittedAt?: Date;

  @Prop({ required: false })
  reviews?: string;
}
export const KeypointResultSchema =
  SchemaFactory.createForClass(KeypointResult);

// --- LessonResult ---
@Schema({ _id: false })
export class LessonResult {
  @Prop({ required: true })
  lessonId: string;

  @Prop({ type: Number, default: 0 })
  averageScore: number;

  @Prop({ default: false })
  passed: boolean;

  @Prop({ type: [KeypointResultSchema], default: [] })
  keypointsResult: KeypointResult[];

  @Prop({ enum: LessonType })
  lessonType?: LessonType;

  @Prop({ type: Date, default: Date.now })
  submittedAt?: Date;

  @Prop({ required: false })
  reviews?: string;
}
export const LessonResultSchema = SchemaFactory.createForClass(LessonResult);

// --- CompletedLevel ---
@Schema({ _id: false })
export class CompletedLevelAdditionalContentRequest {
  @Prop({ type: Boolean, required: true })
  requested: boolean;

  @Prop({ required: false })
  requestText?: string;

  @Prop({ type: Date, default: Date.now })
  submittedAt: Date;
}
export const CompletedLevelAdditionalContentRequestSchema =
  SchemaFactory.createForClass(CompletedLevelAdditionalContentRequest);

@Schema({ _id: false })
export class CompletedLevel {
  @Prop({ required: true, enum: CourseLevel })
  level: CourseLevel;

  @Prop({ type: Date, default: Date.now })
  completedAt: Date;

  @Prop({ type: CompletedLevelAdditionalContentRequestSchema })
  additionalContentRequest?: CompletedLevelAdditionalContentRequest;
}
export const CompletedLevelSchema =
  SchemaFactory.createForClass(CompletedLevel);

@Schema({ _id: false })
export class StopAt {
  @Prop({ required: true })
  lessonId: string;

  @Prop({ required: false })
  keypointId?: string;
}
export const StopAtSchema = SchemaFactory.createForClass(StopAt);

@Schema({ collection: 'user_progress' })
export class UserProgress extends AbstractDocument implements IUserProgress {
  @Prop({ required: true })
  userId: string;

  @Prop({ required: true })
  courseId: string;

  @Prop({ type: [LessonResultSchema], default: [] })
  lessonsResult: LessonResult[];

  @Prop({ type: [CompletedLevelSchema], default: [] })
  completedLevels: CompletedLevel[];

  @Prop({ type: [String], default: [] })
  keypointOptional: string[];

  @Prop({ type: Date, default: Date.now })
  lastTime?: Date;

  @Prop({ type: StopAtSchema })
  stopAt?: StopAt;
}

export const UserProgressSchema = SchemaFactory.createForClass(UserProgress);

UserProgressSchema.index({ userId: 1 });
// Backs the admin drop-off aggregation (`aggregateDropOffByCourse`): it matches
// on courseId ALONE, which neither userId-first index can serve — without this
// every dashboard read is a collection scan that only gets slower as users grow.
UserProgressSchema.index({ courseId: 1 });
UserProgressSchema.index({ userId: 1, courseId: 1 });
