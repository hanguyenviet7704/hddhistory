import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Types } from 'mongoose';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';
import { v4 as uuidv4 } from 'uuid';


import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { RequestService } from '@base/service/request.service';
import { viewerMarketsForRequest } from '@utils/market-query.util';
import { getTranslationValue, hasAnyTranslationValue } from '@utils/translate';
import { normalizeCountryCodes } from '@utils/viewer-market.util';

import { CourseStatus } from './enum/course.enum';
import {
  applyPublishedFields,
  toPlainDoc,
  keypointBrief,
  lessonBrief,
} from '../course-version/content-projection';
import { ContentSource } from '../course-version/content-source.service';
import { allowDraftFromHeaders } from '../course-version/content-version.resolver';
import { CourseVersionService } from '../course-version/course-version.service';
import {
  assertNoImportErrors,
  createMultiSheetTemplateWorkbook,
  getRows,
  getSheet,
  hasTranslationValueForPrefix,
  ImportRow,
  ImportValidationError,
  numberValue,
  readWorkbook,
  resolveAssetUrl,
  setCellByHeader,
  text,
  translationCells,
  translationColumnLabel,
  translationFromValues,
  translationHeaders,
  validateNoDuplicateValues,
  workbookToBuffer,
} from '../import/excel-import.util';
import { CreateCourseDto } from './dto/create-course.dto';
import { GetListCourseDto } from './dto/get-list-course.dto';
import { UpdateCourseDto } from './dto/update-course.dto';
import { UpdateRoadmapDto } from './dto/update-roadmap.dto';
import { CourseRepository } from './repository/course.repository';
import { RoadmapRepository } from './repository/roadmap.repository';
import { Course } from './schema/course.schema';
import { Roadmap } from './schema/roadmap.schema';
import { KeypointRepository } from '../keypoint/repository/keypoint.repository';
import { LessonType } from '../lesson/enum/lesson.enum';
import { LessonRepository } from '../lesson/repository/lesson.repository';
import {
  GradeResultType,
  ProcessEnum,
} from '../progress/src/modules/user-progress/enum/user-progress.enum';
import { UserProgressRepository } from '../progress/src/modules/user-progress/repository/user-progress.repository';
import { TagRepository } from '../tags/repository/tag.repository';

@Injectable()
export class CourseService {
  constructor(
    private readonly courseRepository: CourseRepository,
    private readonly tagRepository: TagRepository,
    private readonly lessonRepository: LessonRepository,
    private readonly keypointRepository: KeypointRepository,
    private readonly roadmapRepository: RoadmapRepository,
    private readonly userProgressRepository: UserProgressRepository,
    private readonly requestService: RequestService,
    private readonly i18n: I18nService,
    private readonly configService: ConfigService,
    private readonly contentSource: ContentSource,
    private readonly courseVersionService: CourseVersionService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  /**
   * Markets to scope the catalogue to for the caller, or `null` for the admin
   * panel, which must see every course. See `viewerMarketsForRequest`.
   */
  private get viewerMarkets(): string[] | null {
    return viewerMarketsForRequest(this.requestService.headers);
  }

  /**
   * True cho request của app: đọc nội dung đã phát hành. False cho admin
   * panel, chỗ phải thấy bản đang sửa. Xem `IGNORE_CONTENT_VERSION_HEADER`.
   */
  private get readsPublished(): boolean {
    return !allowDraftFromHeaders(this.requestService.headers);
  }

  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async create(createCourseDto: CreateCourseDto): Promise<Course> {
    const { title } = createCourseDto;
    const titleByLang = getTranslationValue(title, this.lang);

    if (!titleByLang && !hasAnyTranslationValue(title)) {
      throw new BadRequestException('title is required');
    }

    if (titleByLang) {
      // check title exits
      const titleExits = await this.courseRepository.checkExitsTitle(
        titleByLang,
        this.lang,
      );
      if (titleExits)
        throw new ConflictException(
          this.i18n.t('error.COURSE.TITLE_EXISTS', {
            lang: this.lang,
          }),
        );
    }

    const course = await this.courseRepository.create(
      { ...createCourseDto, ...this.normalizedCountries(createCourseDto) },
      this.user,
    );

    // create roadmap
    await this.roadmapRepository.create({
      courseId: course._id.toString(),
      levels: [],
    });

    return course;
  }

  /**
   * `countries` as it should be STORED, or nothing at all when the caller did
   * not send the field.
   *
   * Spread over the dto rather than mutating it, and returning `{}` for an
   * absent field rather than `{ countries: [] }`, because `UpdateCourseDto` is
   * a PartialType: writing `[]` for a field the admin never touched would
   * silently un-restrict a course on every unrelated edit. An explicit `[]`
   * from the admin still means "publish everywhere" and still gets written.
   *
   * Normalising here -- on the way IN -- is what lets every read path compare
   * with a plain `$in`. A lower-case `vn` reaching Mongo would fail to match
   * with nothing in the logs to show for it.
   */
  private normalizedCountries(dto: {
    countries?: string[];
  }): { countries?: string[] } {
    if (!dto.countries) return {};

    return { countries: normalizeCountryCodes(dto.countries) };
  }

  async findAll(getListCourseDto: GetListCourseDto) {
    const readsPublished = this.readsPublished;
    const result = await this.courseRepository.findOption(
      getListCourseDto,
      this.viewerMarkets,
      readsPublished,
    );

    if (!readsPublished) return result;

    // App đọc title/description/image đã đóng băng, không đọc bản nháp editor
    // đang sửa. Khoá chưa có tag thì `published` null và trả về y như cũ.
    return {
      ...result,
      items: result.items.map(course => applyPublishedFields(course)),
    };
  }

  /**
   * `requested` là `?version=` — chỉ panel dùng được, để xem lại một tag cũ
   * hoặc xem đúng cái user thật thấy (`?version=current`).
   */
  async findOne(id: string, requested?: string | null): Promise<Course> {
    const course = await this.courseRepository.findOne({ _id: id });
    if (!course)
      throw new NotFoundException(
        this.i18n.t('error.COURSE.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    if (requested) {
      // `Course.published` chỉ là cache của tag ĐANG PHÁT HÀNH, nên xem lại
      // tag khác phải đọc từ chính row đã đóng băng.
      const versionId = await this.contentSource.versionForCourse(
        id,
        this.requestService.headers,
        requested,
      );
      if (!versionId) return course;

      const frozen = await this.contentSource.getCourseFields(id, versionId);

      // Cùng cái bẫy trải document như `applyPublishedFields`: phải phẳng hoá
      // trước, không thì bản xem lại tag cũ trả về `_doc` thay vì khoá học.
      return (frozen ? { ...toPlainDoc(course), ...frozen } : course) as Course;
    }

    return applyPublishedFields(course, this.readsPublished);
  }

  async getLessons(ids: string[] = []) {
    const lessons = await this.lessonRepository.findByIds(ids);

    const lessonsMap = new Map(lessons.map(k => [k._id.toString(), k]));

    const ordered = ids
      .map(id => lessonsMap.get(id))
      .filter((lesson): lesson is (typeof lessons)[number] => lesson != null);

    return { lessons: ordered };
  }

  /**
   * `versionId` null = bản đang sửa (hành vi cũ). Khác null = đọc tag đang
   * phát hành. Đây là màn chính của app, nên đường đọc theo tag phải trả ĐÚNG
   * projection như đường cũ — `keypointBrief` bỏ `audio.text` (~8KB/keypoint,
   * từng chiếm ~95% payload) và `lessonBrief` chỉ giữ `video.thumbnail`.
   * Xem `plans/260907-course-content-versions/README.md`.
   */
  async findRoadmap(id: string, requested?: string | null): Promise<Roadmap> {
    const { versionId, experiment } =
      await this.contentSource.resolveContentVersion(
        id,
        this.requestService.headers,
        requested,
        this.user?.id,
      );

    const roadmap = (await this.contentSource.getRoadmap(
      id,
      versionId,
    )) as unknown as Roadmap | null;

    if (!roadmap)
      throw new NotFoundException(
        this.i18n.t('error.COURSE.ROADMAP_NOT_FOUND', {
          lang: this.lang,
        }),
      );

    const { levels: levelsWithNodeIds, hasChanges: hasNodeIdUpdates } =
      this.ensureRoadmapNodeIds(roadmap.levels);
    roadmap.levels = levelsWithNodeIds as any;

    const resolveObjectId = (value: any) => {
      if (!value) return '';
      if (typeof value === 'object') {
        return value._id?.toString?.() ?? value.toString?.();
      }
      return value.toString();
    };
    const resolveRoleplayId = (node: any) =>
      node?.roleplayId ?? (node as any)?.entranceId;

    // Collect every referenced lesson id up-front (was ~6 sequential queries
    // per node) so they can be fetched in a single batched query below.
    const lessonIdSet = new Set<string>();
    for (const item of roadmap.levels) {
      for (const node of item.nodes || []) {
        const roleplayId = resolveRoleplayId(node);
        if (roleplayId) lessonIdSet.add(roleplayId.toString());
        if (node.openingVideoId) lessonIdSet.add(node.openingVideoId.toString());
        if (Array.isArray(node.lessonIds)) {
          for (const lessonId of node.lessonIds) {
            if (lessonId) lessonIdSet.add(lessonId.toString());
          }
        }
        if (node.outputId) lessonIdSet.add(node.outputId.toString());
        if (node.closingVideoId) lessonIdSet.add(node.closingVideoId.toString());
      }
    }

    // These four queries are independent of each other, so run them
    // concurrently instead of serially (tags, user progress, lessons, and the
    // optional node-id persistence). Keypoints depend on lessons, so they are
    // fetched afterwards.
    const [tagsResult, userProgress, allLessons] = await Promise.all([
      this.tagRepository.findAllBrief(),
      this.userProgressRepository.getUserProgress({
        userId: this.user.id,
        courseId: id,
        grade: GradeResultType.COURSE,
      }),
      versionId
        ? this.contentSource
            .getLessonsByIds([...lessonIdSet], versionId)
            .then(lessons => lessons.map(lessonBrief) as any[])
        : this.lessonRepository.findByIds([...lessonIdSet]),
      // Backfill node id CHỈ trên bản đang sửa. Một tag là bất biến; ghi
      // levels của bản đóng băng vào collection sẽ là ghi nội dung của tag
      // lên bản đang sửa của người khác.
      hasNodeIdUpdates && !versionId
        ? this.roadmapRepository.updateOne({ courseId: id }, {
            levels: levelsWithNodeIds,
          } as any)
        : Promise.resolve(null),
    ]);

    const tags = tagsResult.list;
    const tagMap = new Map(tags.map(tag => [tag._id.toString(), tag]));
    const lessonsResult =
      userProgress && userProgress.length && 'lessonsResult' in userProgress[0]
        ? (userProgress[0].lessonsResult as any[])
        : [];
    const lessonProgressMap = new Map<string, any>(
      lessonsResult.map((lesson: any) => [lesson.lessonId.toString(), lesson]),
    );

    // Lessons are shallow-cloned per use below so each node keeps its own
    // mutable copy, matching the original "fresh document per getLessons call".
    const lessonById = new Map(
      allLessons.map(lesson => [lesson._id.toString(), lesson]),
    );
    const getLessonsLocal = (ids: any[] = []) => {
      const ordered = ids
        .map(id => lessonById.get(id?.toString?.() ?? id))
        .filter(
          (lesson): lesson is (typeof allLessons)[number] => lesson != null,
        )
        .map(lesson => ({ ...lesson }));
      return { lessons: ordered };
    };

    const keypointIdSet = new Set<string>();
    for (const item of roadmap.levels) {
      for (const node of item.nodes || []) {
        for (const lessonId of node.lessonIds || []) {
          const lesson = lessonById.get(lessonId?.toString?.() ?? lessonId);
          if (lesson?.type !== LessonType.LESSON) continue;
          if (!Array.isArray(lesson.keypoints)) continue;
          for (const keypoint of lesson.keypoints) {
            const keypointId = resolveObjectId(keypoint);
            if (keypointId) keypointIdSet.add(keypointId);
          }
        }
      }
    }
    const allKeypoints = !keypointIdSet.size
      ? []
      : versionId
      ? (
          await this.contentSource.getKeypointsByIds(
            [...keypointIdSet],
            versionId,
          )
        ).map(keypointBrief)
      : await this.keypointRepository.findBriefByIds([...keypointIdSet]);
    const keypointById = new Map(
      allKeypoints.map(keypoint => [keypoint._id.toString(), keypoint]),
    );

    for (const item of roadmap.levels) {
      // Không trả keypointIds trong response
      delete (item as any).keypointIds;

      if (item.nodes.length) {
        // gán lại thông tin lesson
        for (let nodeIndex = 0; nodeIndex < item.nodes.length; nodeIndex++) {
          const node = item.nodes[nodeIndex];
          const roleplayId = resolveRoleplayId(node);
          const legacyEntranceId = (node as any)?.entranceId;
          if (!node.roleplayId && legacyEntranceId) {
            node.roleplayId = legacyEntranceId;
            delete (node as any).entranceId;
          }
          const roleplay = roleplayId
            ? getLessonsLocal([roleplayId]).lessons
            : [];

          const openingVideo = node.openingVideoId
            ? getLessonsLocal([node.openingVideoId]).lessons
            : [];

          const lessons = getLessonsLocal(node.lessonIds).lessons;

          const output = node.outputId
            ? getLessonsLocal([node.outputId]).lessons
            : [];

          const closingVideo = node.closingVideoId
            ? getLessonsLocal([node.closingVideoId]).lessons
            : [];

          node.openingVideo = openingVideo.length
            ? openingVideo[0]?.type === LessonType.VIDEO
              ? openingVideo[0]
              : null
            : (null as any);
          node.closingVideo = closingVideo.length
            ? closingVideo[0]?.type === LessonType.VIDEO
              ? closingVideo[0]
              : null
            : (null as any);
          node.roleplay = roleplay.length ? roleplay[0] : (null as any);
          node.lessons = lessons.filter(l => l != null) as any;
          node.output = output.length ? output[0] : (null as any);

          const lessonKeypointIds = new Set<string>();
          for (const lesson of lessons) {
            if (lesson?.type !== LessonType.LESSON) continue;
            if (!Array.isArray(lesson.keypoints)) continue;
            for (const keypoint of lesson.keypoints) {
              const keypointId = resolveObjectId(keypoint);
              if (keypointId) lessonKeypointIds.add(keypointId);
            }
          }

          const keypoints = lessonKeypointIds.size
            ? [...lessonKeypointIds]
                .map(keypointId => keypointById.get(keypointId))
                .filter(
                  (keypoint): keypoint is (typeof allKeypoints)[number] =>
                    keypoint != null,
                )
            : [];
          const keypointMap = new Map(
            keypoints.map(keypoint => [keypoint._id.toString(), keypoint]),
          );

          const roleplayLesson = roleplay[0] ?? null;
          const roleplayProgress = roleplayLesson
            ? lessonProgressMap.get(roleplayLesson._id.toString())
            : null;
          const keypointScoreMap = new Map<string, number>();
          if (roleplayProgress?.keypointsResult?.length) {
            for (const keypointResult of roleplayProgress.keypointsResult) {
              const keypointId = resolveObjectId(keypointResult.keypointId);
              if (keypointId) {
                keypointScoreMap.set(
                  keypointId,
                  keypointResult.averageScore ?? 0,
                );
              }
            }
          }
          const openingVideoLesson =
            openingVideo[0]?.type === LessonType.VIDEO ? openingVideo[0] : null;
          const outputLesson = output[0] ?? null;
          const closingVideoLesson =
            closingVideo[0]?.type === LessonType.VIDEO ? closingVideo[0] : null;
          const nodeLessonList: any[] = [
            ...(openingVideoLesson ? [openingVideoLesson] : []),
            ...(roleplayLesson ? [roleplayLesson] : []),
            ...lessons,
            ...(outputLesson ? [outputLesson] : []),
            ...(closingVideoLesson ? [closingVideoLesson] : []),
          ];

          for (const lesson of nodeLessonList) {
            // gán lại icon
            const iconValue = lesson.icon as any;
            const iconId =
              typeof iconValue === 'object' && iconValue !== null
                ? iconValue._id?.toString?.()
                : iconValue?.toString?.();

            const checkIcon = iconId ? tagMap.get(iconId) ?? null : null;
            lesson.icon = checkIcon;

            const lightIconValue = lesson.lightIcon as any;
            const lightIconId =
              typeof lightIconValue === 'object' && lightIconValue !== null
                ? lightIconValue._id?.toString?.()
                : lightIconValue?.toString?.();

            const lightCheckIcon = lightIconId
              ? tagMap.get(lightIconId) ?? null
              : null;
            lesson.lightIcon = lightCheckIcon;

            // gán lại userProgress
            const lessonProgress = lessonProgressMap.get(lesson._id.toString());
            if (!lessonProgress) {
              lesson.progess = ProcessEnum.NOT_STARTED;
            } else if (lessonProgress.passed) {
              lesson.progess = ProcessEnum.DONE;
            } else {
              lesson.progess = ProcessEnum.IN_PROGRESS;
            }
          }

          // gán thông tin keypoints chi tiết cho lesson
          nodeLessonList.map(lesson => {
            if (
              lesson?.type !== LessonType.LESSON ||
              !Array.isArray(lesson.keypoints)
            ) {
              return lesson;
            }

            const lessonProgress = lessonProgressMap.get(lesson._id.toString());
            const keypointProgressMap = new Map<string, any>();
            if (lessonProgress?.keypointsResult?.length) {
              for (const keypointResult of lessonProgress.keypointsResult) {
                const keypointId = resolveObjectId(keypointResult.keypointId);
                if (keypointId) {
                  keypointProgressMap.set(keypointId, keypointResult);
                }
              }
            }

            const resolvedKeypoints = lesson.keypoints
              .map((keypoint: any) => {
                const keypointId = resolveObjectId(keypoint);
                if (!keypointId) return null;
                const matched = keypointMap.get(keypointId);
                if (!matched) return null;
                const keypointProgress = keypointProgressMap.get(keypointId);
                return {
                  ...matched,
                  averageScore: keypointScoreMap.get(keypointId) ?? null,
                  progess: keypointProgress
                    ? keypointProgress.passed
                      ? ProcessEnum.DONE
                      : ProcessEnum.IN_PROGRESS
                    : ProcessEnum.NOT_STARTED,
                };
              })
              .filter(Boolean);
            lesson.keypoints = resolvedKeypoints as any;
            return lesson;
          });

          item.nodes[nodeIndex] = {
            id: node.id,
            title: node.title,
            description: node.description,
            openingVideoId: node.openingVideoId,
            roleplayId: node.roleplayId,
            lessonIds: node.lessonIds,
            outputId: node.outputId,
            closingVideoId: node.closingVideoId,
            openingVideo: node.openingVideo,
            roleplay: node.roleplay,
            lessons: node.lessons,
            output: node.output,
            closingVideo: node.closingVideo,
          } as any;
        }
      }
    }

    // The course blurb the roadmap header prints under "Inside this course".
    //
    // It rides on the roadmap rather than on the skillsets/course LIST payload
    // on purpose: that list deliberately drops `description` because it is an
    // ITranslation across 5 languages and was ~30% of /skillsets, and no list
    // surface renders it. The roadmap is fetched for ONE course, so carrying it
    // here costs a single copy and saves the app a second round trip.
    const course = await this.courseRepository.findOne(
      { _id: id },
      { description: 1 },
      { lean: true },
    );

    // Khi đang phục vụ một tag, description phải lấy từ CHÍNH tag đó, không
    // phải từ bản đang sửa — nếu không thì khoá đã tag vẫn trả mô tả bản nháp
    // (lỗi này lọt trong đợt chuyển đường đọc sang tag). Không dùng
    // `Course.published` được vì cache đó chỉ ứng với tag ĐANG PHÁT HÀNH, còn
    // ở đây versionId có thể là nhánh A/B hoặc một tag xin qua `?version=`.
    const frozen = versionId
      ? await this.contentSource.getCourseFields(id, versionId)
      : null;
    (roadmap as any).courseDescription =
      (frozen?.description as any) ?? course?.description ?? {};

    // Nhánh A/B đi kèm roadmap vì đây là thứ app lấy khi mở một khoá, và app
    // PHẢI đóng dấu `key` + `arm` lên event — không có nó thì bảng kết quả
    // toàn số 0 và trông y như "hai bản không khác gì nhau".
    (roadmap as any).contentExperiment = experiment ?? null;

    return roadmap;
  }

  private ensureRoadmapNodeIds(levels: any[] = []) {
    let hasChanges = false;
    const getNormalizedNodeId = (id: unknown) =>
      typeof id === 'string' ? id.trim() : '';

    const normalizedLevels = levels.map(level => ({
      ...level,
      nodes: (level?.nodes || []).map((node: any) => {
        const normalizedNodeId = getNormalizedNodeId(node?.id);
        if (normalizedNodeId) {
          if (normalizedNodeId !== node.id) {
            hasChanges = true;
            return {
              ...node,
              id: normalizedNodeId,
            };
          }
          return node;
        }

        hasChanges = true;
        return {
          ...node,
          id: uuidv4().toString(),
        };
      }),
    }));

    return {
      levels: normalizedLevels,
      hasChanges,
    };
  }

  private async computeLevelKeypointIds(levels: any[] = []) {
    // Batch fetch keypoints for every lesson across all levels in a single
    // query, then resolve per-level in-memory (was one query per level).
    const lessonIdSet = new Set<string>();
    for (const level of levels) {
      for (const node of level?.nodes || []) {
        if (Array.isArray(node.lessonIds)) {
          for (const lessonId of node.lessonIds) {
            if (lessonId) lessonIdSet.add(lessonId);
          }
        }
      }
    }

    const allLessonIds = [...lessonIdSet];
    const lessonKeypointMap = new Map<string, any[]>();
    if (allLessonIds.length) {
      const lessons = await this.lessonRepository.model
        .find({ _id: { $in: allLessonIds } }, { _id: 1, keypoints: 1 })
        .lean();

      for (const lesson of lessons) {
        lessonKeypointMap.set(
          lesson._id.toString(),
          Array.isArray((lesson as any).keypoints)
            ? (lesson as any).keypoints
            : [],
        );
      }
    }

    const computed: any[] = [];
    for (const level of levels) {
      const lessonIds: string[] = [];

      for (const node of level?.nodes || []) {
        if (Array.isArray(node.lessonIds)) {
          lessonIds.push(...node.lessonIds.filter(Boolean));
        }
      }

      const uniqueLessonIds = [...new Set(lessonIds)];
      const collected = uniqueLessonIds.flatMap(
        id => lessonKeypointMap.get(id) ?? [],
      );
      const keypointIds = [...new Set(collected.filter(Boolean))];

      const { keypointIds: _omit, ...restLevel } = level;

      computed.push({
        ...restLevel,
        keypointIds,
      });
    }

    return computed;
  }

  private collectLessonIdsFromLevels(levels: any[] = []) {
    const lessonIds = new Set<string>();

    for (const level of levels) {
      for (const node of level?.nodes || []) {
        if (node?.openingVideoId) lessonIds.add(node.openingVideoId.toString());
        if (node?.roleplayId) lessonIds.add(node.roleplayId.toString());
        if (Array.isArray(node?.lessonIds)) {
          for (const lessonId of node.lessonIds) {
            if (lessonId) lessonIds.add(lessonId.toString());
          }
        }
        if (node?.outputId) lessonIds.add(node.outputId.toString());
        if (node?.closingVideoId) lessonIds.add(node.closingVideoId.toString());
      }
    }

    return lessonIds;
  }

  private collectRoadmapLessonIdsFromLevels(levels: any[] = []) {
    const lessonIds = new Set<string>();

    for (const level of levels) {
      for (const node of level?.nodes || []) {
        if (node?.openingVideoId) lessonIds.add(node.openingVideoId.toString());
        if (node?.roleplayId) lessonIds.add(node.roleplayId.toString());
        if (node?.outputId) lessonIds.add(node.outputId.toString());
        if (node?.closingVideoId) lessonIds.add(node.closingVideoId.toString());
      }
    }

    return lessonIds;
  }

  private collectLessonIdsForKeypointCount(levels: any[] = []) {
    const lessonIds = new Set<string>();

    for (const level of levels) {
      for (const node of level?.nodes || []) {
        if (!Array.isArray(node?.lessonIds)) continue;
        for (const lessonId of node.lessonIds) {
          if (lessonId) lessonIds.add(lessonId.toString());
        }
      }
    }

    return lessonIds;
  }

  private async countKeypointsInLessons(lessonIds: Set<string>) {
    if (!lessonIds.size) return 0;

    const lessons = await this.lessonRepository.model
      .find({ _id: { $in: [...lessonIds] } }, { keypoints: 1 })
      .lean();

    return lessons.reduce((total, lesson: any) => {
      const keypoints = Array.isArray(lesson?.keypoints)
        ? lesson.keypoints
        : [];
      return total + keypoints.length;
    }, 0);
  }

  private async filterMissingLessonsFromLevels(levels: any[] = []) {
    const lessonIds = this.collectLessonIdsFromLevels(levels);
    if (!lessonIds.size) return levels;

    const lessons = await this.lessonRepository.model
      .find({ _id: { $in: [...lessonIds] } }, { _id: 1, type: 1 })
      .lean();
    const existingIds = new Set(lessons.map(lesson => lesson._id.toString()));
    const lessonTypeMap = new Map(
      lessons.map(lesson => [lesson._id.toString(), (lesson as any).type]),
    );

    return levels.map(level => ({
      ...level,
      nodes: (level?.nodes || []).map((node: any) => {
        const cleaned = { ...node };
        if (
          cleaned.openingVideoId &&
          (!existingIds.has(cleaned.openingVideoId.toString()) ||
            lessonTypeMap.get(cleaned.openingVideoId.toString()) !==
              LessonType.VIDEO)
        ) {
          delete cleaned.openingVideoId;
        }

        if (
          cleaned.roleplayId &&
          !existingIds.has(cleaned.roleplayId.toString())
        ) {
          delete cleaned.roleplayId;
        }

        if (cleaned.outputId && !existingIds.has(cleaned.outputId.toString())) {
          delete cleaned.outputId;
        }

        if (
          cleaned.closingVideoId &&
          (!existingIds.has(cleaned.closingVideoId.toString()) ||
            lessonTypeMap.get(cleaned.closingVideoId.toString()) !==
              LessonType.VIDEO)
        ) {
          delete cleaned.closingVideoId;
        }

        if (Array.isArray(cleaned.lessonIds)) {
          cleaned.lessonIds = cleaned.lessonIds.filter((lessonId: string) =>
            existingIds.has(lessonId.toString()),
          );
        }

        return cleaned;
      }),
    }));
  }

  async updateNumberOfLessonFromLevels(courseId: string, levels: any[] = []) {
    const roadmapLessonCount =
      this.collectRoadmapLessonIdsFromLevels(levels).size;
    const keypointLessonIds = this.collectLessonIdsForKeypointCount(levels);
    const keypointCount = await this.countKeypointsInLessons(keypointLessonIds);
    const count = roadmapLessonCount + keypointCount;
    await this.courseRepository.updateNumberOfLesson(count, courseId);
  }

  /**
   * Một khoá không được lên live mà chưa có tag: khoá như thế sẽ phục vụ BẢN
   * ĐANG SỬA cho user thật, kể cả những chỗ sửa còn dở. Đây là chốt cho đường
   * publish thủ công từ admin; `course-publish.scheduler.ts` lo đường hẹn giờ.
   * Idempotent, nên gọi lại bao nhiêu lần cũng không sao.
   * Xem `plans/260907-course-content-versions/README.md`.
   */
  private async ensureTagIfGoingLive(
    courseId: string,
    status?: CourseStatus,
  ): Promise<void> {
    if (status !== CourseStatus.PUBLISHED) return;

    await this.courseVersionService.ensureInitialTag(
      courseId,
      this.user as unknown as IUserMeta,
    );
  }

  async update(id: string, updateCourseDto: UpdateCourseDto) {
    const { title } = updateCourseDto;
    const course = await this.courseRepository.findOne({ _id: id });
    if (!course)
      throw new NotFoundException(
        this.i18n.t('error.COURSE.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    if (title) {
      const titleByLang = getTranslationValue(title, this.lang);
      const mergedTitle = { ...(course.title ?? {}), ...title };

      if (!titleByLang && !hasAnyTranslationValue(mergedTitle)) {
        throw new BadRequestException('title is required');
      }

      if (!titleByLang) {
        const updated = await this.courseRepository.updateOne(
          { _id: id },
          {
            ...updateCourseDto,
            ...this.normalizedCountries(updateCourseDto),
          },
          this.user,
        );
        await this.ensureTagIfGoingLive(id, updateCourseDto.status);

        return updated;
      }

      const titleExits = await this.courseRepository.checkExitsTitle(
        titleByLang,
        this.lang,
      );
      if (titleExits && titleExits._id.toString() !== id)
        throw new ConflictException(
          this.i18n.t('error.COURSE.TITLE_EXISTS', {
            lang: this.lang,
          }),
        );
    }

    const update = await this.courseRepository.updateOne(
      { _id: id },
      {
        ...updateCourseDto,
        ...this.normalizedCountries(updateCourseDto),
      },
      this.user,
    );
    await this.ensureTagIfGoingLive(id, updateCourseDto.status);

    return update;
  }

  async updateRoadmap(id: string, dto: UpdateRoadmapDto) {
    const roadmap = await this.roadmapRepository.findOne({ courseId: id });

    if (!roadmap)
      throw new NotFoundException(
        this.i18n.t('error.COURSE.ROADMAP_NOT_FOUND', {
          lang: this.lang,
        }),
      );

    const cleanedLevels =
      dto?.levels && dto.levels.length
        ? await this.filterMissingLessonsFromLevels(dto.levels)
        : dto.levels;
    const levelsWithNodeIds = Array.isArray(cleanedLevels)
      ? this.ensureRoadmapNodeIds(cleanedLevels).levels
      : cleanedLevels;
    const levels = Array.isArray(levelsWithNodeIds)
      ? await this.computeLevelKeypointIds(levelsWithNodeIds)
      : levelsWithNodeIds;

    const update = await this.roadmapRepository.updateOne({ courseId: id }, {
      ...dto,
      levels,
    } as any);

    if (Array.isArray(levels)) {
      await this.updateNumberOfLessonFromLevels(id, levels);
    }

    return update;
  }

  async removeLessonFromRoadmap(courseId: string, lessonId: string) {
    const roadmap = await this.roadmapRepository.findOne(
      { courseId },
      { levels: 1 },
      { lean: true },
    );

    if (!roadmap?.levels?.length) {
      await this.courseRepository.updateNumberOfLesson(0, courseId);
      return;
    }

    const levels = roadmap.levels.map(level => ({
      ...level,
      nodes: (level?.nodes || []).map((node: any) => {
        const cleaned = { ...node };
        if (cleaned.openingVideoId?.toString() === lessonId) {
          delete cleaned.openingVideoId;
        }

        if (cleaned.roleplayId?.toString() === lessonId) {
          delete cleaned.roleplayId;
        }

        if (cleaned.outputId?.toString() === lessonId) {
          delete cleaned.outputId;
        }

        if (cleaned.closingVideoId?.toString() === lessonId) {
          delete cleaned.closingVideoId;
        }

        if (Array.isArray(cleaned.lessonIds)) {
          cleaned.lessonIds = cleaned.lessonIds.filter(
            (id: string) => id?.toString() !== lessonId,
          );
        }

        return cleaned;
      }),
    }));

    const levelsWithKeypoints = await this.computeLevelKeypointIds(levels);

    await this.roadmapRepository.updateOne({ courseId }, {
      levels: levelsWithKeypoints,
    } as any);
    await this.updateNumberOfLessonFromLevels(courseId, levelsWithKeypoints);
  }

  async remove(id: string) {
    const roadmap = await this.roadmapRepository.findOne({ courseId: id });

    if (!roadmap)
      throw new NotFoundException(
        this.i18n.t('error.COURSE.ROADMAP_NOT_FOUND', {
          lang: this.lang,
        }),
      );
    await this.roadmapRepository.deleteOne({ courseId: id });
    const res = await this.courseRepository.deleteOne({ _id: id });
    return res;
  }

  async getCourseImportTemplate() {
    return createMultiSheetTemplateWorkbook([
      {
        sheetName: 'courses',
        headers: [
          'id',
          'course_key',
          'title_vi',
          'title_en',
          'title_zh',
          'title_ja',
          'title_ko',
          'description_vi',
          'description_en',
          'description_zh',
          'description_ja',
          'description_ko',
          'image',
          'skillsetId',
          'status',
        ],
        sampleRows: [
          [
            '',
            'english-basic',
            'Tiếng Anh cơ bản',
            'Basic English',
            '基础英语',
            '基礎英語',
            '기초 영어',
            'Khóa học tiếng Anh dành cho người mới bắt đầu',
            'English course for beginners',
            '',
            '',
            '',
            'english-basic.jpg',
            '',
            'draft',
          ],
          [
            '',
            'japanese-comm',
            'Tiếng Nhật giao tiếp',
            'Japanese Communication',
            '日本語コミュニケーション',
            '日本語コミュニケーション',
            '일본어 커뮤니케이션',
            'Học tiếng Nhật thực tế trong cuộc sống hàng ngày',
            'Practical Japanese for daily life',
            '',
            '',
            '',
            'japanese-comm.jpg',
            '',
            'draft',
          ],
          [
            '<id_khóa_học_cần_sửa>',
            'business-comm',
            'Giao tiếp thương mại',
            'Business Communication',
            '商务沟通',
            'ビジネスコミュニケーション',
            '비즈니스 커뮤니케이션',
            'Kỹ năng giao tiếp trong môi trường kinh doanh',
            'Communication skills in business environment',
            '',
            '',
            '',
            'business-comm.jpg',
            '',
            'published',
          ],
        ],
      },
      {
        sheetName: 'roadmap_levels',
        headers: [
          'course_key',
          'level_key',
          'id',
          'level',
          'titleBadge_vi',
          'titleBadge_en',
          'titleBadge_zh',
          'titleBadge_ja',
          'titleBadge_ko',
          'lightBadge',
          'darkBadge',
        ],
        sampleRows: [
          [
            'english-basic',
            'level-1',
            1,
            'level 1',
            'Huy hiệu cơ bản',
            'Basic badge',
            '',
            '',
            '',
            'badge-light.png',
            'badge-dark.png',
          ],
        ],
      },
      {
        sheetName: 'roadmap_nodes',
        headers: [
          'course_key',
          'level_key',
          'node_id',
          'title_vi',
          'title_en',
          'title_zh',
          'title_ja',
          'title_ko',
          'description_vi',
          'description_en',
          'description_zh',
          'description_ja',
          'description_ko',
          'openingVideoId',
          'roleplayId',
          'lessonIds',
          'outputId',
          'closingVideoId',
        ],
        sampleRows: [
          [
            'english-basic',
            'level-1',
            '',
            'Chặng 1',
            'Stage 1',
            '',
            '',
            '',
            'Bắt đầu khóa học',
            'Start the course',
            '',
            '',
            '',
            '',
            '<roleplayLessonId>',
            '<lessonId1>|<lessonId2>',
            '<outputLessonId>',
            '',
          ],
        ],
      },
    ]);
  }

  async exportCourses() {
    return createMultiSheetTemplateWorkbook(await this.buildCourseExportSheets());
  }

  /**
   * `preloaded` exports a content TAG instead of the working tree: the caller
   * hands over the frozen documents and no query runs. Distribution and
   * pricing are not frozen by a tag, so a tag export carries the live course
   * document overlaid with the tag's editorial fields -- see
   * `plans/260907-course-content-versions/README.md`.
   */
  async buildCourseExportSheets(
    courseId?: string,
    preloaded?: { courses: any[]; roadmaps: any[] },
  ) {
    const courses =
      preloaded?.courses ??
      (await this.courseRepository.findAllForExport(courseId));
    const roadmaps =
      preloaded?.roadmaps ??
      (await this.roadmapRepository.findByCourseIds(
        courses.map((course: any) => course._id.toString()),
      ));
    const roadmapByCourse = new Map<string, (typeof roadmaps)[number]>();
    for (const roadmap of roadmaps) {
      roadmapByCourse.set(String(roadmap.courseId), roadmap);
    }

    const courseRows: any[][] = [];
    const levelRows: any[][] = [];
    const nodeRows: any[][] = [];

    for (const course of courses) {
      const courseId = course._id.toString();
      courseRows.push([
        courseId,
        courseId,
        ...translationCells(course.title),
        ...translationCells(course.description),
        course.image ?? '',
        course.skillsetId ?? '',
        course.status ?? '',
      ]);

      const levels = (roadmapByCourse.get(courseId)?.levels ?? []) as any[];
      levels.forEach((level, levelIndex) => {
        const levelKey = `level-${levelIndex + 1}`;
        levelRows.push([
          courseId,
          levelKey,
          level.id ?? levelIndex + 1,
          level.level ?? '',
          ...translationCells(level.titleBadge),
          level.lightBadge ?? '',
          level.darkBadge ?? '',
        ]);
        for (const node of level.nodes ?? []) {
          nodeRows.push([
            courseId,
            levelKey,
            node.id ?? '',
            ...translationCells(node.title),
            ...translationCells(node.description),
            node.openingVideoId ?? '',
            node.roleplayId ?? '',
            (node.lessonIds ?? []).join('|'),
            node.outputId ?? '',
            node.closingVideoId ?? '',
          ]);
        }
      });
    }

    return [
      {
        sheetName: 'courses',
        headers: [
          'id',
          'course_key',
          ...translationHeaders('title'),
          ...translationHeaders('description'),
          'image',
          'skillsetId',
          'status',
        ],
        sampleRows: courseRows,
      },
      {
        sheetName: 'roadmap_levels',
        headers: [
          'course_key',
          'level_key',
          'id',
          'level',
          ...translationHeaders('titleBadge'),
          'lightBadge',
          'darkBadge',
        ],
        sampleRows: levelRows,
      },
      {
        sheetName: 'roadmap_nodes',
        headers: [
          'course_key',
          'level_key',
          'node_id',
          ...translationHeaders('title'),
          ...translationHeaders('description'),
          'openingVideoId',
          'roleplayId',
          'lessonIds',
          'outputId',
          'closingVideoId',
        ],
        sampleRows: nodeRows,
      },
    ];
  }

  async importCourses(file: Express.Multer.File) {
    const workbook = await readWorkbook(file);
    const sheet = getSheet(workbook, ['courses'], true);
    const roadmapLevelSheet = getSheet(workbook, ['roadmap_levels']);
    const roadmapNodeSheet = getSheet(workbook, ['roadmap_nodes']);
    const rows = getRows(sheet);
    const roadmapLevelRows = getRows(roadmapLevelSheet);
    const roadmapNodeRows = getRows(roadmapNodeSheet);
    const errors: ImportValidationError[] = [];
    validateNoDuplicateValues('courses', rows, errors);
    validateNoDuplicateValues('courses', rows, errors, 'course_key');
    const courseRefs = new Set(
      rows.map(row => this.getCourseImportRef(row)).filter(Boolean),
    );
    const roadmapLevelsByCourse = this.buildCourseImportRoadmaps(
      roadmapLevelRows,
      roadmapNodeRows,
      courseRefs,
      errors,
    );

    for (const row of rows) {
      const id = text(row.values.id);
      if (!id) {
        if (!hasTranslationValueForPrefix(row.values, 'title')) {
          errors.push({
            sheet: 'courses',
            row: row.rowNumber,
            column: translationColumnLabel('title'),
            message:
              'At least one supported title translation is required when creating',
          });
        }
        continue;
      }

      if (!Types.ObjectId.isValid(id)) {
        errors.push({
          sheet: 'courses',
          row: row.rowNumber,
          column: 'id',
          message: 'id is not a valid ObjectId',
        });
        continue;
      }

      const existing = await this.courseRepository.findOne({ _id: id });
      if (!existing) {
        errors.push({
          sheet: 'courses',
          row: row.rowNumber,
          column: 'id',
          message: 'course was not found',
        });
      }
    }

    assertNoImportErrors(errors);

    for (const row of rows) {
      const id = text(row.values.id);
      const courseRef = this.getCourseImportRef(row);
      const payload = this.buildCourseImportPayload(row.values, !id);

      if (id) {
        if (Object.keys(payload).length) {
          await this.courseRepository.updateOne(
            { _id: id },
            payload,
            this.user,
          );
        }
        if (courseRef) {
          if (roadmapLevelsByCourse.has(courseRef)) {
            await this.upsertCourseImportRoadmap(
              id,
              roadmapLevelsByCourse.get(courseRef) ?? [],
            );
          }
        } else if (roadmapLevelsByCourse.has(id)) {
          await this.upsertCourseImportRoadmap(
            id,
            roadmapLevelsByCourse.get(id) ?? [],
          );
        }
        continue;
      }

      const created = await this.courseRepository.create(
        payload as any,
        this.user,
      );
      setCellByHeader(sheet, row.rowNumber, 'id', created._id.toString());
      await this.upsertCourseImportRoadmap(
        created._id.toString(),
        courseRef ? roadmapLevelsByCourse.get(courseRef) ?? [] : [],
      );
    }

    return workbookToBuffer(workbook);
  }

  private buildCourseImportPayload(
    values: Record<string, any>,
    isCreate: boolean,
  ) {
    const cdn = this.configService.get<string>('CLOUDFLARE_R2_CDN');
    const payload: Record<string, any> = {};
    const title = translationFromValues(values, 'title');
    const description = translationFromValues(values, 'description');
    const image = resolveAssetUrl(values.image, cdn);
    const skillsetId = text(values.skillsetId);
    const status = text(values.status);

    if (isCreate) {
      if (title) payload.title = title;
      if (description) payload.description = description;
    } else {
      this.assignTranslationUpdate(payload, 'title', title);
      this.assignTranslationUpdate(payload, 'description', description);
    }
    if (image) payload.image = image;
    if (skillsetId) payload.skillsetId = skillsetId;
    if (status) payload.status = status;

    return payload;
  }

  private getCourseImportRef(row: ImportRow) {
    return text(row.values.course_key) || text(row.values.id);
  }

  private buildCourseImportRoadmaps(
    levelRows: ImportRow[],
    nodeRows: ImportRow[],
    courseRefs: Set<string>,
    errors: ImportValidationError[],
  ) {
    const levelsByCourse = new Map<string, any[]>();
    const levelByCourseAndKey = new Map<string, any>();

    for (const row of levelRows) {
      const courseRef = text(row.values.course_key);
      const levelKey = text(row.values.level_key);

      if (
        !this.validateRoadmapRefRow(
          row,
          courseRef,
          levelKey,
          courseRefs,
          errors,
        )
      ) {
        continue;
      }

      const titleBadge = translationFromValues(row.values, 'titleBadge');
      if (!titleBadge) {
        errors.push({
          sheet: 'roadmap_levels',
          row: row.rowNumber,
          column: translationColumnLabel('titleBadge'),
          message: 'titleBadge translation is required',
        });
      }

      const levels = levelsByCourse.get(courseRef) ?? [];
      const level: any = {
        id: numberValue(row.values.id) ?? levels.length + 1,
        level: text(row.values.level) || 'level 1',
        lightBadge: resolveAssetUrl(
          row.values.lightBadge,
          this.configService.get<string>('CLOUDFLARE_R2_CDN'),
        ),
        darkBadge: resolveAssetUrl(
          row.values.darkBadge,
          this.configService.get<string>('CLOUDFLARE_R2_CDN'),
        ),
        titleBadge: titleBadge ?? {},
        nodes: [],
      };
      levels.push(level);
      levelsByCourse.set(courseRef, levels);
      levelByCourseAndKey.set(
        this.getRoadmapLevelMapKey(courseRef, levelKey),
        level,
      );
    }

    for (const row of nodeRows) {
      const courseRef = text(row.values.course_key);
      const levelKey = text(row.values.level_key);

      if (
        !this.validateRoadmapRefRow(
          row,
          courseRef,
          levelKey,
          courseRefs,
          errors,
        )
      ) {
        continue;
      }

      const level = levelByCourseAndKey.get(
        this.getRoadmapLevelMapKey(courseRef, levelKey),
      );
      if (!level) {
        errors.push({
          sheet: 'roadmap_nodes',
          row: row.rowNumber,
          column: 'level_key',
          message: 'level_key was not found in roadmap_levels',
        });
        continue;
      }

      const title = translationFromValues(row.values, 'title');
      if (!title) {
        errors.push({
          sheet: 'roadmap_nodes',
          row: row.rowNumber,
          column: translationColumnLabel('title'),
          message: 'title translation is required',
        });
      }

      const node = this.buildCourseImportRoadmapNode(row);
      this.validateRoadmapNodeLessonRefs(row, node, errors);
      level.nodes.push(node);
    }

    return levelsByCourse;
  }

  private validateRoadmapRefRow(
    row: ImportRow,
    courseRef: string,
    levelKey: string,
    courseRefs: Set<string>,
    errors: ImportValidationError[],
  ) {
    const sheet =
      row.values.node_id !== undefined ? 'roadmap_nodes' : 'roadmap_levels';
    let valid = true;

    if (!courseRef) {
      errors.push({
        sheet,
        row: row.rowNumber,
        column: 'course_key',
        message: 'course_key is required',
      });
      valid = false;
    } else if (!courseRefs.has(courseRef)) {
      errors.push({
        sheet,
        row: row.rowNumber,
        column: 'course_key',
        message: 'course_key was not found in courses sheet',
      });
      valid = false;
    }

    if (!levelKey) {
      errors.push({
        sheet,
        row: row.rowNumber,
        column: 'level_key',
        message: 'level_key is required',
      });
      valid = false;
    }

    return valid;
  }

  private buildCourseImportRoadmapNode(row: ImportRow) {
    const node: Record<string, any> = {};
    const id = text(row.values.node_id);
    const title = translationFromValues(row.values, 'title');
    const description = translationFromValues(row.values, 'description');
    const lessonIds = [
      ...new Set(this.splitCourseImportList(row.values.lessonIds)),
    ];

    if (id) node.id = id;
    if (title) node.title = title;
    if (description) node.description = description;
    if (text(row.values.openingVideoId)) {
      node.openingVideoId = text(row.values.openingVideoId);
    }
    if (text(row.values.roleplayId)) {
      node.roleplayId = text(row.values.roleplayId);
    }
    if (lessonIds.length) {
      node.lessonIds = lessonIds;
    }
    if (text(row.values.outputId)) {
      node.outputId = text(row.values.outputId);
    }
    if (text(row.values.closingVideoId)) {
      node.closingVideoId = text(row.values.closingVideoId);
    }

    return node;
  }

  private validateRoadmapNodeLessonRefs(
    row: ImportRow,
    node: Record<string, any>,
    errors: ImportValidationError[],
  ) {
    const validateObjectId = (column: string, value?: string) => {
      if (value && !Types.ObjectId.isValid(value)) {
        errors.push({
          sheet: 'roadmap_nodes',
          row: row.rowNumber,
          column,
          message: `${column} is not a valid ObjectId`,
        });
      }
    };

    validateObjectId('openingVideoId', node.openingVideoId);
    validateObjectId('roleplayId', node.roleplayId);
    validateObjectId('outputId', node.outputId);
    validateObjectId('closingVideoId', node.closingVideoId);

    for (const lessonId of node.lessonIds ?? []) {
      if (!Types.ObjectId.isValid(lessonId)) {
        errors.push({
          sheet: 'roadmap_nodes',
          row: row.rowNumber,
          column: 'lessonIds',
          message: `lessonId ${lessonId} is not a valid ObjectId`,
        });
      }
    }
  }

  private getRoadmapLevelMapKey(courseRef: string, levelKey: string) {
    return `${courseRef}::${levelKey}`;
  }

  private splitCourseImportList(value: any) {
    return text(value)
      .split(/\r?\n|\|/)
      .map(item => item.trim())
      .filter(Boolean);
  }

  private async upsertCourseImportRoadmap(courseId: string, levels: any[]) {
    const cleanedLevels = levels.length
      ? await this.filterMissingLessonsFromLevels(levels)
      : [];
    const levelsWithNodeIds = this.ensureRoadmapNodeIds(cleanedLevels).levels;
    const levelsWithKeypoints = await this.computeLevelKeypointIds(
      levelsWithNodeIds,
    );
    const existing = await this.roadmapRepository.findOne({ courseId });

    if (existing) {
      await this.roadmapRepository.updateOne({ courseId }, {
        levels: levelsWithKeypoints,
      } as any);
    } else {
      await this.roadmapRepository.create({
        courseId,
        levels: levelsWithKeypoints,
      } as any);
    }

    await this.updateNumberOfLessonFromLevels(courseId, levelsWithKeypoints);
    await this.backfillLessonCourseId(courseId, levelsWithKeypoints);
  }

  private async backfillLessonCourseId(courseId: string, levels: any[]) {
    const lessonIds = new Set<string>();
    for (const level of levels) {
      for (const node of level.nodes ?? []) {
        if (node.openingVideoId) lessonIds.add(node.openingVideoId.toString());
        if (node.roleplayId) lessonIds.add(node.roleplayId.toString());
        if (node.outputId) lessonIds.add(node.outputId.toString());
        if (node.closingVideoId) lessonIds.add(node.closingVideoId.toString());
        for (const id of node.lessonIds ?? []) {
          lessonIds.add(id.toString());
        }
      }
    }
    if (!lessonIds.size) return;
    // Only assign to lessons not already tied to a course (missing, null or
    // empty courseId) so we never steal a lesson from another course.
    await this.lessonRepository.updateMany(
      {
        _id: { $in: Array.from(lessonIds) },
        $or: [
          { courseId: { $exists: false } },
          { courseId: { $in: [null, ''] } },
        ],
      },
      { $set: { courseId } } as any,
    );
  }

  private assignTranslationUpdate(
    payload: Record<string, any>,
    path: string,
    value?: Record<string, string>,
  ) {
    if (!value) return;
    for (const [lang, textValue] of Object.entries(value)) {
      payload[`${path}.${lang}`] = textValue;
    }
  }
}
