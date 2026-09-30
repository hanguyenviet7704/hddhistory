import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { EntityCounts } from '../content-snapshot';

/**
 * One tag of one course's content — the git-tag half of the model the owner
 * asked for: content is edited freely in the working tree, and users keep
 * reading the tag `Course.currentVersionId` points at until someone publishes
 * a new one. Rolling back is re-pointing that field, never rewriting content.
 *
 * Rows are NEVER updated after insert. Unlike `paywall_configs`, the "which one
 * is live" flag does not live here: the pointer belongs to the course, so it is
 * `Course.currentVersionId`.
 *
 * `createdBy`/`createdAt` come from `AbstractDocument` and are what the admin
 * version table shows as "who tagged this, and when".
 *
 * See `plans/260907-course-content-versions/README.md` section 2.
 */
@Schema({ collection: 'course_content_versions' })
export class CourseContentVersion extends AbstractDocument {
  @Prop({ required: true })
  courseId: string;

  /** `vMAJOR.MINOR.PATCH`, chosen by the editor — see `course-version.util.ts`. */
  @Prop({ required: true })
  tag: string;

  @Prop({ type: String, default: null })
  note?: string | null;

  /** Shown in the admin table so a tag is identifiable at a glance. */
  @Prop({ type: SchemaTypes.Mixed, default: {} })
  entityCounts: EntityCounts;
}

export const CourseContentVersionSchema = SchemaFactory.createForClass(
  CourseContentVersion,
);

// One spelling per version per course — `isTagName` rejects leading zeros so
// this cannot be defeated by `v01.0.0`.
CourseContentVersionSchema.index({ courseId: 1, tag: 1 }, { unique: true });

// Backs the admin version list (newest first).
CourseContentVersionSchema.index({ courseId: 1, createdAt: -1 });
