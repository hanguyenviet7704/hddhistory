import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { ContentEntityType } from '../content-snapshot';

export const CONTENT_ENTITY_TYPES: ContentEntityType[] = [
  'course',
  'roadmap',
  'lesson',
  'keypoint',
  'learningItem',
];

/**
 * The frozen checkout of a tag: one row per content document, `doc` a verbatim
 * copy taken when the tag was made.
 *
 * One row per entity rather than one JSON blob per tag, for two reasons that
 * both come from the existing schema: a course with five-locale theory text
 * would risk Mongo's 16MB document cap, and `keypoint.schema.ts` has no
 * `courseId`, so `coach`/`habit` could not answer "which course does this
 * keypoint belong to" from a blob. Carrying `courseId` on the row makes that an
 * indexed lookup.
 *
 * Ids inside `doc` are the working tree's real ids, which is why `UserProgress`
 * (keyed by `lessonId`/`keypointId`/`exerciseId`) still matches across tags and
 * why voiceover never has to be regenerated for a new tag.
 *
 * See `plans/260907-course-content-versions/README.md` section 2.
 */
@Schema({ collection: 'published_content' })
export class PublishedContent extends AbstractDocument {
  @Prop({ required: true })
  versionId: string;

  @Prop({ required: true })
  courseId: string;

  @Prop({ required: true, enum: CONTENT_ENTITY_TYPES })
  entityType: ContentEntityType;

  @Prop({ required: true })
  entityId: string;

  @Prop({ type: SchemaTypes.Mixed, required: true })
  doc: Record<string, unknown>;

  /** `contentHash(doc)`, so the pending-changes diff never re-hashes the tag. */
  @Prop({ required: true })
  docHash: string;
}

export const PublishedContentSchema =
  SchemaFactory.createForClass(PublishedContent);

// The read path: "give me this entity as of this version".
PublishedContentSchema.index(
  { versionId: 1, entityType: 1, entityId: 1 },
  { unique: true },
);

// Reverse lookup `keypointId -> courseId`, which the content schema cannot do.
PublishedContentSchema.index({ entityType: 1, entityId: 1 });

// "Every lesson of this version" — the roadmap and export paths.
PublishedContentSchema.index({ versionId: 1, entityType: 1 });
