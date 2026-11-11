import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import {
  CourseCollectionSlot,
  CourseCollectionStatus,
} from '../enum/course-collection.enum';

/**
 * An editor-authored strip of courses on the Explore tab.
 *
 * Deliberately one collection type rather than a slug per section: "Phù hợp để
 * bắt đầu" differs from "Chữa lành bản thân" only by its audience, so it is a
 * row here with `segmentIds` set, not a branch in the code. Adding a section is
 * then an admin action, not a deploy.
 */
@Schema({ collection: 'course_collections', timestamps: true })
export class CourseCollection extends AbstractDocument {
  @Prop({ type: SchemaTypes.Mixed })
  title: ITranslation;

  @Prop({
    type: String,
    enum: CourseCollectionStatus,
    default: CourseCollectionStatus.DRAFT,
  })
  status: CourseCollectionStatus;

  @Prop({
    type: String,
    enum: CourseCollectionSlot,
    default: CourseCollectionSlot.BOTTOM,
  })
  slot: CourseCollectionSlot;

  @Prop({ type: Number, default: 0 })
  index: number;

  /**
   * Audience, by the same mechanism home-banner slides use: empty means
   * everyone, otherwise the viewer must match ANY of these segments. The
   * "new user" section is a segment with `lifecycle 0–7`, not a flag here —
   * which is why D0–D7 needed no matching code of its own.
   *
   * A deleted segment leaves a dangling id that simply never matches, so it
   * widens targeting rather than breaking the collection.
   */
  @Prop({ type: [String], default: [] })
  segmentIds: string[];

  /** Course ids in the order the editor arranged them. */
  @Prop({ type: [String], default: [] })
  courseIds: string[];
}

export const CourseCollectionSchema =
  SchemaFactory.createForClass(CourseCollection);

// The Explore read: published rows, in slot then editor order. One index
// serves it because the tab always asks for both slots at once.
CourseCollectionSchema.index({ status: 1, slot: 1, index: 1 });
