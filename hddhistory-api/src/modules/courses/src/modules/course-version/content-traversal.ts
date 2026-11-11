/**
 * The shapes tagging needs, kept loose on purpose: it walks `Roadmap` and
 * `Lesson` documents that arrive lean from Mongo, where `_id` is an ObjectId
 * and the roadmap levels are stored as `SchemaTypes.Array` of plain objects.
 */
interface RoadmapNodeLike {
  lessonIds?: (string | null)[];
  openingVideoId?: string | null;
  roleplayId?: string | null;
  outputId?: string | null;
  closingVideoId?: string | null;
}

interface RoadmapLevelLike {
  keypointIds?: (string | null)[];
  nodes?: RoadmapNodeLike[];
}

interface RoadmapLike {
  levels?: RoadmapLevelLike[];
}

interface LessonLike {
  _id: unknown;
  keypoints?: (string | null)[];
}

/** First-seen order, blanks dropped — snapshots must be reproducible. */
export const uniqueIds = (values: Iterable<unknown>): string[] => {
  const out: string[] = [];
  const seen = new Set<string>();

  for (const value of values) {
    if (!value) continue;
    const id = String(value);
    if (!id || seen.has(id)) continue;
    seen.add(id);
    out.push(id);
  }

  return out;
};

/**
 * Every lesson that belongs to the tag: the union of the lessons carrying this
 * `courseId` and the lessons the roadmap references. Union rather than either
 * alone, because a lesson can exist before it is placed on the roadmap, and a
 * roadmap can reference a lesson whose `courseId` was never backfilled.
 */
export const collectLessonIds = ({
  courseLessons,
  roadmap,
}: {
  courseLessons: LessonLike[];
  roadmap?: RoadmapLike | null;
}): string[] => {
  const referenced: unknown[] = courseLessons.map(lesson => lesson._id);

  for (const level of roadmap?.levels ?? []) {
    for (const node of level.nodes ?? []) {
      referenced.push(
        ...(node.lessonIds ?? []),
        node.openingVideoId,
        node.roleplayId,
        node.outputId,
        node.closingVideoId,
      );
    }
  }

  return uniqueIds(referenced);
};

/**
 * Keypoints reachable from the tag. `keypoint` documents have no `courseId`,
 * so the only way in is `lesson.keypoints[]` plus the roadmap's own
 * `levels[].keypointIds`.
 */
export const collectKeypointIds = ({
  lessons,
  roadmap,
}: {
  lessons: LessonLike[];
  roadmap?: RoadmapLike | null;
}): string[] => {
  const referenced: unknown[] = [];

  for (const lesson of lessons) referenced.push(...(lesson.keypoints ?? []));
  for (const level of roadmap?.levels ?? [])
    referenced.push(...(level.keypointIds ?? []));

  return uniqueIds(referenced);
};
