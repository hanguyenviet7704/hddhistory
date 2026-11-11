import { contentHash } from './content-hash.util';

export type ContentEntityType =
  | 'course'
  | 'roadmap'
  | 'lesson'
  | 'keypoint'
  | 'learningItem';

export interface SnapshotRow {
  entityType: ContentEntityType;
  entityId: string;
  doc: Record<string, unknown>;
  docHash: string;
}

export interface EntityCounts {
  lessons: number;
  keypoints: number;
  learningItems: number;
}

interface DocLike {
  _id: unknown;
  [key: string]: unknown;
}

export interface SnapshotInput {
  course: DocLike;
  roadmap?: DocLike | null;
  lessons: DocLike[];
  keypoints: DocLike[];
  learningItems: DocLike[];
}

/**
 * The editorial half of a course document. Everything else on `Course` —
 * `status`, `publishAt`, `isNew`, `newDurationDays`, `countries`, `prices`,
 * `author`, `viewCount` — deliberately stays live so the publish scheduler,
 * market gating and pricing keep working without a content tag.
 * See `plans/260907-course-content-versions/README.md` §1 decision 3.
 */
const editorialCourseFields = (course: DocLike): Record<string, unknown> => ({
  title: course.title,
  description: course.description,
  image: course.image,
});

const rowOf = (
  entityType: ContentEntityType,
  entityId: unknown,
  doc: Record<string, unknown>,
): SnapshotRow => ({
  entityType,
  entityId: String(entityId),
  doc,
  docHash: contentHash(doc),
});

/**
 * Turn one course's working-tree documents into the immutable rows a tag is
 * made of. Pure: the caller does the reads and the writes, so the same
 * function produces both the rows to insert and the rows to diff against.
 */
export const buildSnapshot = ({
  course,
  roadmap,
  lessons,
  keypoints,
  learningItems,
}: SnapshotInput): { rows: SnapshotRow[]; entityCounts: EntityCounts } => {
  const rows: SnapshotRow[] = [
    rowOf('course', course._id, editorialCourseFields(course)),
  ];

  if (roadmap) rows.push(rowOf('roadmap', roadmap._id, roadmap));
  for (const lesson of lessons) rows.push(rowOf('lesson', lesson._id, lesson));
  for (const keypoint of keypoints)
    rows.push(rowOf('keypoint', keypoint._id, keypoint));
  for (const item of learningItems)
    rows.push(rowOf('learningItem', item._id, item));

  return {
    rows,
    entityCounts: {
      lessons: lessons.length,
      keypoints: keypoints.length,
      learningItems: learningItems.length,
    },
  };
};

export interface ContentEntityRef {
  entityType: ContentEntityType;
  entityId: string;
}

export interface SnapshotDiff {
  added: ContentEntityRef[];
  changed: ContentEntityRef[];
  removed: ContentEntityRef[];
  total: number;
}

interface HashedRef extends ContentEntityRef {
  docHash: string;
}

/** Ids repeat across entity types, so identity is the pair. */
const keyOf = (ref: ContentEntityRef): string =>
  `${ref.entityType}:${ref.entityId}`;

const refOf = ({ entityType, entityId }: HashedRef): ContentEntityRef => ({
  entityType,
  entityId,
});

/**
 * What an editor still has to publish: the working tree read as snapshot rows,
 * compared against the rows of the tag the app is currently serving.
 */
export const diffSnapshots = (
  live: HashedRef[],
  published: HashedRef[],
): SnapshotDiff => {
  const publishedByKey = new Map(published.map(row => [keyOf(row), row]));
  const liveKeys = new Set(live.map(keyOf));

  const added: ContentEntityRef[] = [];
  const changed: ContentEntityRef[] = [];

  for (const row of live) {
    const before = publishedByKey.get(keyOf(row));
    if (!before) added.push(refOf(row));
    else if (before.docHash !== row.docHash) changed.push(refOf(row));
  }

  const removed = published
    .filter(row => !liveKeys.has(keyOf(row)))
    .map(refOf);

  return {
    added,
    changed,
    removed,
    total: added.length + changed.length + removed.length,
  };
};
