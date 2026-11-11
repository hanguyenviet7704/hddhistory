import { Injectable, NotFoundException } from '@nestjs/common';

import {
  courseLessonChip,
  keypointBrief,
  lessonBrief,
} from './content-projection';
import { ContentEntityType } from './content-snapshot';
import {
  allowDraftFromHeaders,
  resolveVersionRequest,
} from './content-version.resolver';
import { AudioResolver } from './audio-resolver.service';
import { CourseContentExperimentService } from './course-content-experiment.service';
import { CourseContentVersionRepository } from './repository/course-content-version.repository';
import { PublishedContentRepository } from './repository/published-content.repository';
import { CourseRepository } from '../course/repository/course.repository';
import { RoadmapRepository } from '../course/repository/roadmap.repository';
import { Course } from '../course/schema/course.schema';
import { KeypointRepository } from '../keypoint/repository/keypoint.repository';
import { LearningItemRepository } from '../learning-item/repository/learning-item.repository';
import { LessonRepository } from '../lesson/repository/lesson.repository';

type Doc = Record<string, unknown>;

/**
 * Reads course content either from the collections the admin panel edits or
 * from a frozen tag, and is the only place that knows the difference.
 *
 * `versionId === null` means the working tree and MUST behave exactly as the
 * code did before content versions existed -- every untagged course depends on
 * that, and it is what makes the rollout invisible.
 *
 * Deliberately a singleton: it takes `versionId` as an argument and injects
 * nothing request-scoped, because it sits on the app read path and the courses
 * module already carries a request-scope DI bleed problem.
 *
 * See `plans/260907-course-content-versions/README.md` section 3.
 */
@Injectable()
export class ContentSource {
  constructor(
    private readonly publishedContentRepository: PublishedContentRepository,
    private readonly courseVersionRepository: CourseContentVersionRepository,
    private readonly courseRepository: CourseRepository,
    private readonly roadmapRepository: RoadmapRepository,
    private readonly lessonRepository: LessonRepository,
    private readonly keypointRepository: KeypointRepository,
    private readonly learningItemRepository: LearningItemRepository,
    private readonly experiments: CourseContentExperimentService,
    private readonly audioResolver: AudioResolver,
  ) {}

  /**
   * The version this request should read, resolved once per request and passed
   * down. `null` = the working tree.
   */
  async resolveVersionId(
    course: Pick<Course, '_id' | 'currentVersionId'>,
    headers: Record<string, any> | undefined,
    requested?: string | null,
  ): Promise<string | null> {
    const request = resolveVersionRequest({
      currentVersionId: course.currentVersionId ?? null,
      allowDraft: allowDraftFromHeaders(headers),
      requested,
    });

    if (request.source === 'working') return null;
    if (request.source === 'version') return request.versionId;

    const version = await this.courseVersionRepository.findOneByTag(
      String(course._id),
      request.tag,
    );
    if (!version) {
      throw new NotFoundException(`tag ${request.tag} was not found`);
    }

    return String(version._id);
  }

  /**
   * The version to read a course's content at. The convenience form of
   * `resolveVersionId` for the eight content services, which already inject
   * `RequestService` (they are already request-scoped) and so can read the
   * panel header off `this.requestService.headers` without any controller
   * threading.
   *
   * An unknown course resolves to the working tree rather than throwing: this
   * sits on read paths that must not turn a missing course into a 500.
   */
  /**
   * Bản đầy đủ: trả cả nhánh A/B khi đợt áp dụng, để đường đọc khoá chuyển
   * `contentExperiment` xuống app — app phải đóng dấu `key` + `arm` lên event,
   * không có nó thì bảng kết quả toàn số 0 và trông y như "không khác biệt".
   */
  async resolveContentVersion(
    courseId: string,
    headers: Record<string, any> | undefined,
    requested?: string | null,
    viewerId?: string | null,
  ): Promise<{
    versionId: string | null;
    experiment?: { key: string; arm: 'A' | 'B' };
  }> {
    if (!requested && allowDraftFromHeaders(headers)) {
      return { versionId: null };
    }

    const course = await this.courseRepository.findById(courseId);
    if (!course) return { versionId: null };

    // Đợt A/B chỉ hỏi tới khi có người xem định danh được; khách bị loại khỏi
    // test nên khỏi tra gì cả.
    const experiment = viewerId
      ? await this.experiments.factsFor(courseId, viewerId)
      : null;

    const request = resolveVersionRequest({
      currentVersionId: course.currentVersionId ?? null,
      allowDraft: allowDraftFromHeaders(headers),
      requested,
      viewerId,
      experiment,
    });

    if (request.source === 'working') return { versionId: null };
    if (request.source === 'version') {
      return { versionId: request.versionId, experiment: request.experiment };
    }

    const version = await this.courseVersionRepository.findOneByTag(
      courseId,
      request.tag,
    );
    if (!version) {
      throw new NotFoundException(`tag ${request.tag} was not found`);
    }

    return { versionId: String(version._id) };
  }

  async versionForCourse(
    courseId: string,
    headers: Record<string, any> | undefined,
    requested?: string | null,
    viewerId?: string | null,
  ): Promise<string | null> {
    const { versionId } = await this.resolveContentVersion(
      courseId,
      headers,
      requested,
      viewerId,
    );

    return versionId;
  }

  /**
   * The version to read one entity at, resolved through the course that tagged
   * it. This is how a read that only has an id (`GET /courses-lessons/:id`,
   * `GET /courses-learning-items/:id`) finds its version without first reading
   * the working tree — a draft entity may not exist in the tag at all, so
   * reading it to find the course would answer from the wrong bank.
   *
   * Null (the working tree) when the entity has never been tagged, or when its
   * course has no current version.
   */
  async versionForEntity(
    entityType: ContentEntityType,
    entityId: string,
    headers: Record<string, any> | undefined,
    requested?: string | null,
    viewerId?: string | null,
  ): Promise<string | null> {
    if (!requested && allowDraftFromHeaders(headers)) return null;

    const courseId = await this.publishedContentRepository.findCourseIdByEntity(
      entityType,
      entityId,
    );
    if (!courseId) return null;

    return this.versionForCourse(courseId, headers, requested, viewerId);
  }

  /** `versionForEntity` for a keypoint — the most common case. */
  async versionForKeypoint(
    keypointId: string,
    headers: Record<string, any> | undefined,
    requested?: string | null,
    viewerId?: string | null,
  ): Promise<string | null> {
    return this.versionForEntity(
      'keypoint',
      keypointId,
      headers,
      requested,
      viewerId,
    );
  }

  /**
   * The batch form, for cross-course lists (saved cards, the study journal,
   * my-courses, daily warm-up) whose entities can each sit on a different tag.
   * Two queries total instead of two per item.
   */
  async versionsForEntities(
    entityType: ContentEntityType,
    entityIds: string[],
    headers: Record<string, any> | undefined,
  ): Promise<Map<string, string | null>> {
    const map = new Map<string, string | null>();
    if (!entityIds.length) return map;

    if (allowDraftFromHeaders(headers)) {
      for (const id of entityIds) map.set(id, null);

      return map;
    }

    const owners = await this.publishedContentRepository.findCourseIdsByEntities(
      entityType,
      entityIds,
    );
    const pointers = await this.courseRepository.findVersionPointers(
      [...new Set(owners.map(owner => owner.courseId))],
    );
    const versionByCourse = new Map(
      pointers.map(course => [
        String(course._id),
        course.currentVersionId ? String(course.currentVersionId) : null,
      ]),
    );
    const courseByKeypoint = new Map(
      owners.map(owner => [owner.entityId, owner.courseId]),
    );

    for (const id of entityIds) {
      const courseId = courseByKeypoint.get(id);
      map.set(id, courseId ? versionByCourse.get(courseId) ?? null : null);
    }

    return map;
  }

  /** `versionsForEntities` for keypoints — the most common case. */
  async versionsForKeypoints(
    keypointIds: string[],
    headers: Record<string, any> | undefined,
  ): Promise<Map<string, string | null>> {
    return this.versionsForEntities('keypoint', keypointIds, headers);
  }

  /**
   * Split a mixed list into the bank each id must be read from: one bucket per
   * tag, plus a `null` bucket for entities whose course has no current version.
   */
  private async groupIdsByVersion(
    entityType: ContentEntityType,
    ids: string[],
    headers: Record<string, any> | undefined,
  ): Promise<Map<string | null, string[]>> {
    const versions = await this.versionsForEntities(entityType, ids, headers);
    const groups = new Map<string | null, string[]>();

    for (const id of ids) {
      const versionId = versions.get(id) ?? null;
      const bucket = groups.get(versionId) ?? [];
      bucket.push(id);
      groups.set(versionId, bucket);
    }

    return groups;
  }

  /**
   * Keypoint briefs for a list spanning several courses and tags. The brief
   * shape matters: `audio.text` is a five-language transcript that must never
   * ride along in a list, whichever bank answered.
   */
  async getKeypointBriefsAcrossVersions(
    keypointIds: string[],
    headers: Record<string, any> | undefined,
  ): Promise<Doc[]> {
    if (!keypointIds.length) return [];

    const out: Doc[] = [];
    for (const [versionId, ids] of await this.groupIdsByVersion(
      'keypoint',
      keypointIds,
      headers,
    )) {
      if (versionId) {
        const rows = await this.publishedContentRepository.findEntities(
          versionId,
          'keypoint',
          ids,
        );
        // BEFORE the projection, which keeps only `audio.url` — resolving
        // afterwards would find nothing left to fill and the roadmap would go
        // silent with no error anywhere.
        out.push(
          ...(await this.withResolvedAudio(rows, versionId)).map(keypointBrief),
        );
      } else {
        out.push(
          ...((await this.keypointRepository.findBriefByIds(
            ids,
          )) as unknown as Doc[]),
        );
      }
    }

    return out;
  }

  /**
   * Whole learning items by id, each read from the bank its own course points
   * at. `coach` and `habit` treat content as raw material and never know which
   * course, let alone which tag, an item came from.
   */
  async getLearningItemsAcrossVersions(
    itemIds: string[],
    headers: Record<string, any> | undefined,
  ): Promise<Doc[]> {
    if (!itemIds.length) return [];

    const out: Doc[] = [];
    for (const [versionId, ids] of await this.groupIdsByVersion(
      'learningItem',
      itemIds,
      headers,
    )) {
      if (versionId) {
        out.push(
          ...(await this.publishedContentRepository.findEntities(
            versionId,
            'learningItem',
            ids,
          )),
        );
      } else {
        out.push(
          ...((await this.learningItemRepository.findByIds(
            ids,
          )) as unknown as Doc[]),
        );
      }
    }

    return out;
  }

  /**
   * Every learning item of these keypoints, each keypoint read at its own
   * course's tag. Callers narrow with the pure filters in
   * `content-projection.ts` (`narratableItemsOf`, `exercisesWithQuestionsOf`)
   * so the repository-level filters are mirrored in exactly one place.
   */
  async getLearningItemsByKeypointIdsAcrossVersions(
    keypointIds: string[],
    headers: Record<string, any> | undefined,
  ): Promise<Doc[]> {
    if (!keypointIds.length) return [];

    const out: Doc[] = [];
    for (const [versionId, ids] of await this.groupIdsByVersion(
      'keypoint',
      keypointIds,
      headers,
    )) {
      out.push(...(await this.getLearningItemsByKeypointIds(ids, versionId)));
    }

    return out;
  }

  /**
   * The lessons of one course as chips — same shape and order as
   * `LessonRepository.findBriefByCourse` (index descending).
   */
  async getLessonChipsByCourse(
    courseId: string,
    headers: Record<string, any> | undefined,
  ): Promise<Doc[]> {
    const versionId = await this.versionForCourse(courseId, headers);
    if (!versionId) {
      return (await this.lessonRepository.findBriefByCourse(
        courseId,
      )) as unknown as Doc[];
    }

    return (await this.getLessonsByCourse(courseId, versionId))
      .map(courseLessonChip)
      .sort((a, b) => Number(b.index ?? 0) - Number(a.index ?? 0));
  }

  /** The lesson equivalent — same shape as `LessonRepository.findByIds`. */
  async getLessonBriefsAcrossVersions(
    lessonIds: string[],
    headers: Record<string, any> | undefined,
  ): Promise<Doc[]> {
    if (!lessonIds.length) return [];

    const out: Doc[] = [];
    for (const [versionId, ids] of await this.groupIdsByVersion(
      'lesson',
      lessonIds,
      headers,
    )) {
      if (versionId) {
        const rows = await this.publishedContentRepository.findEntities(
          versionId,
          'lesson',
          ids,
        );
        out.push(...rows.map(lessonBrief));
      } else {
        out.push(
          ...((await this.lessonRepository.findByIds(ids)) as unknown as Doc[]),
        );
      }
    }

    return out;
  }

  /**
   * Which course a keypoint belongs to — the lookup the content schema cannot
   * do, since `keypoint.schema.ts` has no `courseId`. `coach` and `habit` need
   * it to find the tag a keypoint should be read at. Null means the keypoint
   * has never been tagged, which the caller reads as "use the working tree".
   */
  async resolveCourseOfKeypoint(keypointId: string): Promise<string | null> {
    return this.publishedContentRepository.findCourseIdByEntity(
      'keypoint',
      keypointId,
    );
  }

  // ------------------------------------------------------------------- reads

  /**
   * Field biên tập (title/description/image) đã đóng băng trong một tag.
   * Đường thường không cần nó — `Course.published` là cache của tag đang phát
   * hành, rẻ hơn một query. Chỉ khi xem lại một tag KHÁC (`?version=v1.0.0`)
   * thì mới phải đọc từ chính row đóng băng.
   */
  async getCourseFields(
    courseId: string,
    versionId: string,
  ): Promise<Doc | null> {
    return this.publishedContentRepository.findEntity(
      versionId,
      'course',
      courseId,
    );
  }

  async getRoadmap(courseId: string, versionId: string | null): Promise<Doc | null> {
    if (versionId) {
      const [roadmap] = await this.publishedContentRepository.findAllOfType(
        versionId,
        'roadmap',
      );

      return roadmap ?? null;
    }

    const [roadmap] = await this.roadmapRepository.findByCourseIds([courseId]);

    return (roadmap as unknown as Doc) ?? null;
  }

  async getLessonsByCourse(
    courseId: string,
    versionId: string | null,
  ): Promise<Doc[]> {
    if (versionId) {
      return this.publishedContentRepository.findAllOfType(versionId, 'lesson');
    }

    return (await this.lessonRepository.findAllForExport(
      courseId,
    )) as unknown as Doc[];
  }

  async getLessonsByIds(
    ids: string[],
    versionId: string | null,
  ): Promise<Doc[]> {
    if (versionId) {
      return this.publishedContentRepository.findEntities(
        versionId,
        'lesson',
        ids,
      );
    }

    return (await this.lessonRepository.findFullByIds(ids)) as unknown as Doc[];
  }

  async getLesson(id: string, versionId: string | null): Promise<Doc | null> {
    if (versionId) {
      return this.publishedContentRepository.findEntity(versionId, 'lesson', id);
    }

    const [lesson] = await this.lessonRepository.findFullByIds([id]);

    return (lesson as unknown as Doc) ?? null;
  }

  async getKeypointsByIds(
    ids: string[],
    versionId: string | null,
  ): Promise<Doc[]> {
    if (versionId) {
      const rows = await this.publishedContentRepository.findEntities(
        versionId,
        'keypoint',
        ids,
      );

      return this.withResolvedAudio(rows, versionId);
    }

    return (await this.keypointRepository.findKeypointsByIds(
      ids,
    )) as unknown as Doc[];
  }

  async getKeypoint(id: string, versionId: string | null): Promise<Doc | null> {
    if (versionId) {
      const row = await this.publishedContentRepository.findEntity(
        versionId,
        'keypoint',
        id,
      );
      if (!row) return null;

      const [resolved] = await this.withResolvedAudio([row], versionId);

      return resolved;
    }

    const [keypoint] = await this.keypointRepository.findKeypointsByIds([id]);

    return (keypoint as unknown as Doc) ?? null;
  }

  /**
   * One learning item as of a tag. There is no working-tree branch: the caller
   * only reaches this once `versionForEntity` said a tag applies.
   */
  async getLearningItem(id: string, versionId: string): Promise<Doc | null> {
    return this.publishedContentRepository.findEntity(
      versionId,
      'learningItem',
      id,
    );
  }

  async getLearningItemsByKeypointIds(
    keypointIds: string[],
    versionId: string | null,
  ): Promise<Doc[]> {
    if (!versionId) {
      return (await this.learningItemRepository.findAllByKeypointIds(
        keypointIds,
      )) as unknown as Doc[];
    }

    // The tag holds every learning item of the course, so filtering by
    // keypoint happens here rather than in a per-keypoint query.
    const wanted = new Set(keypointIds);
    const items = await this.publishedContentRepository.findAllOfType(
      versionId,
      'learningItem',
    );

    return items.filter(item => wanted.has(String(item.keypointId)));
  }

  /**
   * Fill a tag's keypoints with the audio that matches THAT TAG's text.
   *
   * The frozen keypoints carry an `audio` of their own; it is not usable —
   * see [AudioResolver]. The learning-item read is handed over as a thunk so a
   * fully cached batch never performs it.
   */
  private async withResolvedAudio(
    keypoints: Doc[],
    versionId: string,
  ): Promise<Doc[]> {
    const ids = keypoints.map(keypoint => String(keypoint._id));

    return this.audioResolver.attach(keypoints, versionId, () =>
      this.getLearningItemsByKeypointIds(ids, versionId),
    );
  }
}
