import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

export type SavedCourseDocument = SavedCourse & Document;

@Schema({ timestamps: true, collection: 'saved_courses' })
export class SavedCourse extends AbstractDocument {
  @Prop({ required: true, index: true })
  userId: string;

  @Prop({ required: true })
  courseId: string;
}

export const SavedCourseSchema = SchemaFactory.createForClass(SavedCourse);

// One bookmark per (user, course) — save is idempotent, so the write is an
// upsert and this index is what makes a double-tap a no-op instead of a
// duplicate row.
SavedCourseSchema.index({ userId: 1, courseId: 1 }, { unique: true });
// Most-recently-saved first, the order the Saved list reads in.
SavedCourseSchema.index({ userId: 1, updatedAt: -1 });
