import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes, Types } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import { HabitLibraryStatus } from '../enum/habit-library.enum';
import { IHabitLibrary } from '../interface/habit-library.interface';

@Schema({ collection: 'habits' })
export class HabitLibrary extends AbstractDocument implements IHabitLibrary {
  @Prop({ type: SchemaTypes.Mixed, required: true })
  title: ITranslation;

  @Prop({ type: SchemaTypes.ObjectId, required: true })
  skillsetId: Types.ObjectId;

  @Prop({
    type: String,
    enum: HabitLibraryStatus,
    default: HabitLibraryStatus.DRAFT,
  })
  status: HabitLibraryStatus;

  /**
   * The habit's own picture, an absolute CDN url as everywhere else in the
   * catalog. Null until an editor sets one, and the app falls back to the
   * skillset's logo then, so an unset habit looks exactly as it did before.
   */
  @Prop({ type: String, default: null })
  image?: string;

  /** See `IHabitLibrary.description`. */
  @Prop({ type: SchemaTypes.Mixed, default: null })
  description?: ITranslation | null;

  /** See `IHabitLibrary.contexts` — one moment per line, per locale. */
  @Prop({ type: SchemaTypes.Mixed, default: null })
  contexts?: ITranslation | null;

  /** See `IHabitLibrary.rubric` — one `key | label` criterion per line. */
  @Prop({ type: SchemaTypes.Mixed, default: null })
  rubric?: ITranslation | null;

  /** See `IHabitLibrary.ladder` — one `<level> | <shape>` rung per line. */
  @Prop({ type: SchemaTypes.Mixed, default: null })
  ladder?: ITranslation | null;

  @Prop()
  defaultReminderTime?: string;

  @Prop({ type: Number, default: 0 })
  order: number;

  // Keypoints this habit can be suggested in (many-to-many: a habit may be
  // suggested by several keypoints, a keypoint may suggest several habits).
  @Prop({ type: [SchemaTypes.ObjectId], default: [] })
  keypointIds: Types.ObjectId[];
}

export const HabitLibrarySchema = SchemaFactory.createForClass(HabitLibrary);

HabitLibrarySchema.index({ skillsetId: 1, status: 1, order: 1 });
HabitLibrarySchema.index({ keypointIds: 1, status: 1 });
