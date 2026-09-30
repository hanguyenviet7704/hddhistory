import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

export type RecentlyViewedCourseDocument = RecentlyViewedCourse & Document;

@Schema({ timestamps: true, collection: 'recently_viewed_courses' })
export class RecentlyViewedCourse extends AbstractDocument {
  @Prop({ required: true, index: true })
  userId: string;

  @Prop({ required: true })
  courseId: string;
}

export const RecentlyViewedCourseSchema =
  SchemaFactory.createForClass(RecentlyViewedCourse);

RecentlyViewedCourseSchema.index({ userId: 1, courseId: 1 }, { unique: true });
RecentlyViewedCourseSchema.index({ userId: 1, updatedAt: -1 });
// Explore's weekly-popular strip scans by time across ALL users, which neither
// userId-first index can serve -- without this it is a collection scan on every
// open of the tab.
RecentlyViewedCourseSchema.index({ updatedAt: -1 });
