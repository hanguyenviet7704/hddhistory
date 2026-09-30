import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { ContentEntityType, SnapshotRow } from '../content-snapshot';
import { PublishedContent } from '../schema/published-content.schema';

/** What the pending-changes diff needs, without dragging `doc` along. */
export interface PublishedHash {
  entityType: ContentEntityType;
  entityId: string;
  docHash: string;
}

@Injectable()
export class PublishedContentRepository extends AbstractRepository<PublishedContent> {
  protected readonly logger = new Logger(PublishedContentRepository.name);

  constructor(
    @InjectModel(PublishedContent.name) model: Model<PublishedContent>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async insertRows(
    versionId: string,
    courseId: string,
    rows: SnapshotRow[],
  ): Promise<number> {
    if (!rows.length) return 0;

    const docs = rows.map(row => ({ ...row, versionId, courseId }));
    const inserted = await this.model.insertMany(docs);

    return inserted.length;
  }

  async findEntity(
    versionId: string,
    entityType: ContentEntityType,
    entityId: string,
  ): Promise<Record<string, unknown> | null> {
    const row = await this.model
      .findOne({ versionId, entityType, entityId })
      .lean<PublishedContent>();

    return row?.doc ?? null;
  }

  async findEntities(
    versionId: string,
    entityType: ContentEntityType,
    entityIds: string[],
  ): Promise<Record<string, unknown>[]> {
    if (!entityIds.length) return [];

    const rows = await this.model
      .find({ versionId, entityType, entityId: { $in: entityIds } })
      .lean<PublishedContent[]>();

    return rows.map(row => row.doc);
  }

  async findAllOfType(
    versionId: string,
    entityType: ContentEntityType,
  ): Promise<Record<string, unknown>[]> {
    const rows = await this.model
      .find({ versionId, entityType })
      .lean<PublishedContent[]>();

    return rows.map(row => row.doc);
  }

  async findHashes(versionId: string): Promise<PublishedHash[]> {
    return this.model
      .find({ versionId }, { entityType: 1, entityId: 1, docHash: 1, _id: 0 })
      .lean<PublishedHash[]>();
  }

  /**
   * `keypointId -> courseId`. The only way `coach`/`habit` can find which
   * course a keypoint belongs to, since `keypoint.schema.ts` has no `courseId`.
   * Returns null for an entity that has never been tagged, which the caller
   * reads as "fall back to the working tree".
   */
  async findCourseIdByEntity(
    entityType: ContentEntityType,
    entityId: string,
  ): Promise<string | null> {
    const row = await this.model
      .findOne({ entityType, entityId }, { courseId: 1, _id: 0 })
      .lean<{ courseId: string }>();

    return row?.courseId ?? null;
  }

  /** The batch form of `findCourseIdByEntity`, for cross-course lists. */
  async findCourseIdsByEntities(
    entityType: ContentEntityType,
    entityIds: string[],
  ): Promise<Array<{ entityId: string; courseId: string }>> {
    if (!entityIds.length) return [];

    const rows = await this.model
      .find(
        { entityType, entityId: { $in: entityIds } },
        { entityId: 1, courseId: 1, _id: 0 },
      )
      .lean<Array<{ entityId: string; courseId: string }>>();

    // One entity can appear in many versions; they all belong to the same
    // course, so the first row per entity is enough.
    const byEntity = new Map<string, string>();
    for (const row of rows)
      if (!byEntity.has(row.entityId)) byEntity.set(row.entityId, row.courseId);

    return [...byEntity].map(([entityId, courseId]) => ({ entityId, courseId }));
  }

  async deleteByVersion(versionId: string): Promise<number> {
    const result = await this.model.deleteMany({ versionId });

    return result.deletedCount ?? 0;
  }
}
