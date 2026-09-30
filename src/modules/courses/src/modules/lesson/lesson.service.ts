import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ModuleRef } from '@nestjs/core';
import { Types } from 'mongoose';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';


import { RequestService } from '@base/service/request.service';
import { getTranslationValue, hasAnyTranslationValue } from '@utils/translate';

import {
  assertNoImportErrors,
  createTemplateWorkbook,
  getRows,
  getSheet,
  hasTranslationValueForPrefix,
  ImportRow,
  ImportValidationError,
  readWorkbook,
  setCellByHeader,
  text,
  translationCells,
  translationColumnLabel,
  translationFromValues,
  translationHeaders,
  validateNoDuplicateValues,
  workbookToBuffer,
} from '../import/excel-import.util';
import { CreateLessonDto } from './dto/create-lesson.dto';
import { GetListLessonDto } from './dto/get-list-lesson.dto';
import { UpdateLessonDto, UpdateLessonIndexDto } from './dto/update-lesson.dto';
import { LessonType } from './enum/lesson.enum';
import { LessonRepository } from './repository/lesson.repository';
import { Lesson } from './schema/lesson.schema';
import { AvatarRepository } from '../avatar/repository/avatar.repository';
import { CourseService } from '../course/course.service';
import { RoadmapRepository } from '../course/repository/roadmap.repository';
import { ContentSource } from '../course-version/content-source.service';
import { KeypointRepository } from '../keypoint/repository/keypoint.repository';
import { Keypoint } from '../keypoint/schema/keypoint.schema';
import {
  GradeResultType,
  ProcessEnum,
} from '../progress/src/modules/user-progress/enum/user-progress.enum';
import { UserProgressRepository } from '../progress/src/modules/user-progress/repository/user-progress.repository';
import { TagRepository } from '../tags/repository/tag.repository';

@Injectable()
export class LessonService {
  constructor(
    private readonly lessonRepository: LessonRepository,
    private readonly userProgressRepository: UserProgressRepository,
    private readonly requestService: RequestService,
    private readonly i18n: I18nService,
    private readonly keypointRepository: KeypointRepository,
    private readonly tagRepository: TagRepository,
    private readonly avatarRepository: AvatarRepository,
    private readonly roadmapRepository: RoadmapRepository,
    private readonly moduleRef: ModuleRef,
    private readonly contentSource: ContentSource,
  ) {}

  private get user() {
    return this.requestService.user;
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async create(createLessonDto: CreateLessonDto): Promise<Lesson> {
    const { title, courseId, type } = createLessonDto;
    const hasTitle =
      !!title &&
      Object.values(title).some(value => typeof value === 'string' && !!value);
    const isOutputLesson = type === LessonType.OUTPUT;
    const lessonTitle =
      isOutputLesson && !hasTitle ? { en: 'Practice' } : title;
    const titleByLang = getTranslationValue(lessonTitle, this.lang);

    if (!isOutputLesson) {
      if (!titleByLang && !hasAnyTranslationValue(lessonTitle)) {
        throw new BadRequestException('title is required');
      }

      if (titleByLang) {
        // check title exits
        const titleExits = await this.lessonRepository.checkExitsTitle(
          titleByLang,
          courseId,
          this.lang,
        );
        if (titleExits)
          throw new ConflictException(
            this.i18n.t('error.COURSE_LESSON.TITLE_EXISTS', {
              lang: this.lang,
            }),
          );
      }
    }

    const nextIndex = await this.lessonRepository.getNextIndex(courseId);

    const lesson = await this.lessonRepository.create(
      {
        ...createLessonDto,
        title: lessonTitle,
        index: nextIndex,
      } as Partial<Lesson>,
      this.user,
    );

    return lesson;
  }

  async findAll(getListLessonDto: GetListLessonDto) {
    const result = await this.lessonRepository.findOption(getListLessonDto);

    // gán lại icon — chỉ load đúng các tag/avatar được tham chiếu
    const toIdString = (value: any): string | null => {
      if (!value) return null;
      return typeof value === 'object'
        ? value._id?.toString?.() ?? null
        : value?.toString?.() ?? null;
    };

    const tagIdSet = new Set<string>();
    const avatarIdSet = new Set<string>();
    for (const item of result.items) {
      const iconId = toIdString(item.icon);
      if (iconId) tagIdSet.add(iconId);
      const lightIconId = toIdString(item.lightIcon);
      if (lightIconId) tagIdSet.add(lightIconId);
      const animationId = toIdString(item.animation);
      if (animationId) avatarIdSet.add(animationId);
    }

    const [tags, avatars] = await Promise.all([
      this.tagRepository
        .findBriefByIds([...tagIdSet])
        .then(res => res.list),
      this.avatarRepository
        .findBriefByIds([...avatarIdSet])
        .then(res => res.list),
    ]);
    const tagMap = new Map(tags.map(tag => [tag._id.toString(), tag]));
    const avatarMap = new Map(
      avatars.map(avatar => [avatar._id.toString(), avatar]),
    );

    for (const item of result.items) {
      const iconValue = item.icon as any;
      const iconId =
        typeof iconValue === 'object' && iconValue !== null
          ? iconValue._id?.toString?.()
          : iconValue?.toString?.();

      const found = iconId ? tagMap.get(iconId) ?? null : null;
      item.icon = found as any;

      const lightIconValue = item.lightIcon as any;
      const lightIconId =
        typeof lightIconValue === 'object' && lightIconValue !== null
          ? lightIconValue._id?.toString?.()
          : lightIconValue?.toString?.();

      const lightFound = lightIconId ? tagMap.get(lightIconId) ?? null : null;
      item.lightIcon = lightFound as any;

      const animationValue = item.animation as any;
      const animationId =
        typeof animationValue === 'object' && animationValue !== null
          ? animationValue._id?.toString?.()
          : animationValue?.toString?.();

      const animationFound = animationId
        ? avatarMap.get(animationId) ?? null
        : null;
      item.animation = animationFound as any;
    }

    return result;
  }

  /**
   * `versionId` null = bản đang sửa. Đây là đường "mở keypoint ra đọc" nên
   * lấy document đầy đủ (kể cả `audio.text`), khác với brief của roadmap.
   */
  async getKeypoints(ids: string[], versionId: string | null = null) {
    const keypoints = (await this.contentSource.getKeypointsByIds(
      ids,
      versionId,
    )) as unknown as Keypoint[];

    const keypointMap = new Map(keypoints.map(k => [k._id.toString(), k]));

    const orderedKeypoints = ids
      .map(id => keypointMap.get(id))
      .filter((k): k is Keypoint => !!k); // lọc bỏ undefined

    return { keypoints: orderedKeypoints };
  }

  /**
   * `versionId` null = bản đang sửa (hành vi cũ). Khác null = đọc tag đang
   * phát hành của khoá chứa bài này.
   * Xem `plans/260907-course-content-versions/README.md`.
   */
  async findOne(id: string, requested?: string | null): Promise<Lesson> {
    const versionId = await this.contentSource.versionForEntity(
      'lesson',
      id,
      this.requestService.headers,
      requested,
      this.user?.id,
    );

    const lesson = versionId
      ? ((await this.contentSource.getLesson(
          id,
          versionId,
        )) as unknown as Lesson | null)
      : await this.lessonRepository.findOne({ _id: id }, {}, { lean: true });
    if (!lesson)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_LESSON.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    // gán lại icon — chỉ load đúng các tag/avatar được tham chiếu
    const toIdString = (value: any): string | null => {
      if (!value) return null;
      return typeof value === 'object'
        ? value._id?.toString?.() ?? null
        : value?.toString?.() ?? null;
    };

    const tagIdSet = new Set<string>();
    const avatarIdSet = new Set<string>();
    const lessonIconId = toIdString(lesson.icon);
    if (lessonIconId) tagIdSet.add(lessonIconId);
    const lessonLightIconId = toIdString(lesson.lightIcon);
    if (lessonLightIconId) tagIdSet.add(lessonLightIconId);
    const lessonAnimationId = toIdString(lesson.animation);
    if (lessonAnimationId) avatarIdSet.add(lessonAnimationId);

    const [tags, avatars] = await Promise.all([
      this.tagRepository
        .findBriefByIds([...tagIdSet])
        .then(res => res.list),
      this.avatarRepository
        .findBriefByIds([...avatarIdSet])
        .then(res => res.list),
    ]);
    const tagMap = new Map(tags.map(tag => [tag._id.toString(), tag]));
    const avatarMap = new Map(
      avatars.map(avatar => [avatar._id.toString(), avatar]),
    );
    const iconValue = lesson.icon as any;
    const iconId =
      typeof iconValue === 'object' && iconValue !== null
        ? iconValue._id?.toString?.()
        : iconValue?.toString?.();

    const found = iconId ? tagMap.get(iconId) ?? null : null;
    lesson.icon = found as any;

    const lightIconValue = lesson.lightIcon as any;
    const lightIconId =
      typeof lightIconValue === 'object' && lightIconValue !== null
        ? lightIconValue._id?.toString?.()
        : lightIconValue?.toString?.();

    const lightFound = lightIconId ? tagMap.get(lightIconId) ?? null : null;
    lesson.lightIcon = lightFound as any;

    const animationValue = lesson.animation as any;
    const animationId =
      typeof animationValue === 'object' && animationValue !== null
        ? animationValue._id?.toString?.()
        : animationValue?.toString?.();

    const animationFound = animationId
      ? avatarMap.get(animationId) ?? null
      : null;
    lesson.animation = animationFound as any;

    // Fetch keypoints and user progress in parallel — independent queries on
    // different collections, no data dependency between them.
    const [keypointData, userProgress] = await Promise.all([
      this.getKeypoints(lesson.keypoints, versionId),
      this.userProgressRepository.getUserProgress({
        userId: this.user.id,
        courseId: lesson.courseId,
        lessonId: id,
        grade: GradeResultType.LESSON,
      }),
    ]);
    lesson.keypoints = keypointData.keypoints as unknown as string[];

    const keypoints = lesson.keypoints as unknown as Keypoint[];
    if (keypoints) {
      // Build a lookup once instead of scanning keypointsResult per keypoint.
      let keypointsResult = [];
      if (
        userProgress &&
        userProgress.length &&
        'keypointsResult' in userProgress[0].lesson
      ) {
        keypointsResult = userProgress[0].lesson.keypointsResult;
      }
      const keypointProgressMap = new Map<string, any>(
        keypointsResult.map((e: any) => [e.keypointId.toString(), e]),
      );

      for (const item of keypoints) {
        // gán lại userProgress
        const keypointProgress = keypointProgressMap.get(item._id.toString());
        if (keypointProgress) {
          if (keypointProgress.passed) {
            item.progess = ProcessEnum.DONE;
          } else {
            item.progess = ProcessEnum.IN_PROGRESS;
          }
        } else {
          item.progess = ProcessEnum.NOT_STARTED;
        }
      }
    }

    return lesson;
  }

  async update(id: string, updateLessonDto: UpdateLessonDto) {
    const { title, courseId } = updateLessonDto;
    const lesson = await this.lessonRepository.findOne({ _id: id });
    if (!lesson)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_LESSON.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    const targetType = (updateLessonDto.type || lesson.type) as LessonType;
    const targetCourseId = courseId || lesson.courseId;
    const titleByLang = getTranslationValue(title, this.lang);

    if (title && targetType !== LessonType.OUTPUT) {
      const mergedTitle = { ...(lesson.title ?? {}), ...title };

      if (!titleByLang && !hasAnyTranslationValue(mergedTitle)) {
        throw new BadRequestException('title is required');
      }

      if (titleByLang) {
        const titleExits = await this.lessonRepository.checkExitsTitle(
          titleByLang,
          targetCourseId,
          this.lang,
        );
        if (titleExits && titleExits._id.toString() !== id)
          throw new ConflictException(
            this.i18n.t('error.COURSE_LESSON.TITLE_EXISTS', {
              lang: this.lang,
            }),
          );
      }
    }

    const update = await this.lessonRepository.updateOne(
      { _id: id },
      {
        ...updateLessonDto,
      } as Partial<Lesson>,
      this.user,
    );

    if (
      updateLessonDto.keypoints &&
      !this.isSameKeypointSet(lesson.keypoints, updateLessonDto.keypoints)
    ) {
      const roadmap = await this.roadmapRepository.findOne({
        courseId: lesson.courseId,
      });

      if (roadmap?.levels?.length) {
        const isLessonInRoadmap = roadmap.levels.some(level =>
          (level.nodes || []).some(node =>
            Array.isArray(node.lessonIds) ? node.lessonIds.includes(id) : false,
          ),
        );

        if (isLessonInRoadmap) {
          const levelsWithKeypoints = await this.computeLevelKeypointIds(
            roadmap.levels,
          );
          const courseService = await this.moduleRef.resolve(CourseService);
          await Promise.all([
            this.roadmapRepository.updateOne(
              { courseId: lesson.courseId },
              { levels: levelsWithKeypoints } as any,
              this.user,
            ),
            courseService.updateNumberOfLessonFromLevels(
              lesson.courseId,
              levelsWithKeypoints,
            ),
          ]);
        }
      }
    }

    return update;
  }

  private isSameKeypointSet(a?: string[], b?: string[]) {
    if (!a && !b) return true;
    if (!a || !b) return false;
    if (a.length !== b.length) return false;

    const setA = new Set(a);
    if (setA.size !== b.length) return false;

    for (const id of b) {
      if (!setA.has(id)) return false;
    }
    return true;
  }

  async updateLessonIndex(dto: UpdateLessonIndexDto) {
    const { courseId, lessons } = dto;
    if (!lessons?.length) return false;
    try {
      const bulkOps = lessons.map(item => ({
        updateOne: {
          filter: { _id: item.id },
          update: { $set: { index: item.index, courseId } },
        },
      }));
      await this.lessonRepository.bulkWrite(bulkOps);
      return true;
    } catch (error) {
      throw error;
    }
  }

  private async computeLevelKeypointIds(levels: any[] = []) {
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
    const lessonKeypointMap = new Map<string, string[]>();

    if (allLessonIds.length) {
      const lessons = await this.lessonRepository.model
        .find({ _id: { $in: allLessonIds } }, { _id: 1, keypoints: 1 })
        .lean();

      for (const lesson of lessons) {
        const keypoints = Array.isArray((lesson as any).keypoints)
          ? (lesson as any).keypoints
          : [];
        lessonKeypointMap.set(lesson._id.toString(), keypoints);
      }
    }

    return levels.map(level => {
      const keypointIds: string[] = [];

      for (const node of level?.nodes || []) {
        if (!Array.isArray(node.lessonIds)) continue;
        for (const lessonId of node.lessonIds) {
          const kpIds = lessonKeypointMap.get(lessonId) || [];
          keypointIds.push(...kpIds);
        }
      }

      return {
        ...level,
        keypointIds: [...new Set(keypointIds.filter(Boolean))],
      };
    });
  }

  async remove(id: string) {
    const lesson = await this.lessonRepository.findOne({ _id: id });
    if (!lesson)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_LESSON.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    const res = await this.lessonRepository.deleteOne({ _id: id });

    const courseService = await this.moduleRef.resolve(CourseService);
    await courseService.removeLessonFromRoadmap(lesson.courseId, id);

    return res;
  }

  async getLessonImportTemplate() {
    const BLANK = '';

    return createTemplateWorkbook(
      'lessons',
      [
        'id',
        'courseId',
        'title_vi',
        'title_en',
        'title_zh',
        'title_ja',
        'title_ko',
        'icon',
        'lightIcon',
        'keypointId',
        'keypointIndex',
      ],
      [
        [
          BLANK,
          '<courseId>',
          'Bài 1: Chào hỏi',
          'Lesson 1: Greetings',
          '第1课：问候',
          '第1課：挨拶',
          '1과: 인사',
          '<tagId_icon>',
          '<tagId_lightIcon>',
          '<keypointId1>\n<keypointId2>\n<keypointId3>\n',
          '1\n2\n3\n',
        ],
        [
          BLANK,
          '<courseId>',
          'Bài 2: Số đếm và thời gian',
          'Lesson 2: Numbers and Time',
          '第2课：数字和时间',
          '第2課：数字と時間',
          '2과: 숫자와 시간',
          '<tagId_icon>',
          '<tagId_lightIcon>',
          BLANK,
          BLANK,
        ],
        [
          BLANK,
          '<courseId>',
          'Bài 3: Mua sắm',
          'Lesson 3: Shopping',
          '第3课：购物',
          '第3課：買い物',
          '3과: 쇼핑',
          '<tagId_icon>',
          '<tagId_lightIcon>',
          BLANK,
          BLANK,
        ],
      ],
    );
  }

  async exportLessons() {
    const sheet = await this.buildLessonExportSheet();
    return createTemplateWorkbook(
      sheet.sheetName,
      sheet.headers,
      sheet.sampleRows,
    );
  }

  /** `preloaded` exports a content tag rather than the working tree. */
  async buildLessonExportSheet(courseId?: string, preloaded?: Lesson[]) {
    const lessons =
      preloaded ?? (await this.lessonRepository.findAllForExport(courseId));
    const rows = lessons.map(lesson => {
      const keypointIds = (lesson.keypoints ?? []).map(String);
      return [
        lesson._id.toString(),
        '',
        lesson.courseId ?? '',
        ...translationCells(lesson.title),
        lesson.icon ?? '',
        lesson.lightIcon ?? '',
        keypointIds.join('\n'),
        keypointIds.map((_, index) => index + 1).join('\n'),
      ];
    });

    return {
      sheetName: 'lessons',
      headers: [
        'id',
        'lesson_key',
        'courseId',
        ...translationHeaders('title'),
        'icon',
        'lightIcon',
        'keypointId',
        'keypointIndex',
      ],
      sampleRows: rows,
    };
  }

  async importLessons(file: Express.Multer.File) {
    const workbook = await readWorkbook(file);
    const sheet = getSheet(workbook, ['lessons'], true);
    const allRows = getRows(sheet);

    const lessonRows = allRows.filter(
      row => !this.isKeypointOnlyRow(row.values),
    );
    const kpRows = allRows.filter(row => this.isKeypointOnlyRow(row.values));

    const errors: ImportValidationError[] = [];
    // Keypoint-only rows legitimately repeat a lesson id, so only the lesson
    // rows themselves are checked for duplicates.
    validateNoDuplicateValues('lessons', lessonRows, errors);

    const tagIds = new Set(
      (await this.tagRepository.findAllBrief()).list.map(t =>
        t._id.toString(),
      ),
    );
    const validateTagRef = (row: ImportRow, column: 'icon' | 'lightIcon') => {
      const value = text(row.values[column]);
      if (!value) return;
      if (!Types.ObjectId.isValid(value) || !tagIds.has(value)) {
        errors.push({
          sheet: 'lessons',
          row: row.rowNumber,
          column,
          message: `${column} is not a valid tag id`,
        });
      }
    };

    for (const row of lessonRows) {
      const id = text(row.values.id);
      validateTagRef(row, 'icon');
      validateTagRef(row, 'lightIcon');
      if (!id) {
        if (!hasTranslationValueForPrefix(row.values, 'title')) {
          errors.push({
            sheet: 'lessons',
            row: row.rowNumber,
            column: translationColumnLabel('title'),
            message:
              'At least one supported title translation is required when creating',
          });
        }
        this.validateKeypointEntries(row, errors);
        continue;
      }

      if (!Types.ObjectId.isValid(id)) {
        errors.push({
          sheet: 'lessons',
          row: row.rowNumber,
          column: 'id',
          message: 'id is not a valid ObjectId',
        });
        continue;
      }

      const existing = await this.lessonRepository.findOne({ _id: id });
      if (!existing) {
        errors.push({
          sheet: 'lessons',
          row: row.rowNumber,
          column: 'id',
          message: 'lesson was not found',
        });
      }
      this.validateKeypointEntries(row, errors);
    }

    for (const row of kpRows) {
      const lessonId = text(row.values.id);
      if (!lessonId) {
        errors.push({
          sheet: 'lessons',
          row: row.rowNumber,
          column: 'id',
          message: 'id (lessonId) is required for keypoint rows',
        });
        continue;
      }
      if (!Types.ObjectId.isValid(lessonId)) {
        errors.push({
          sheet: 'lessons',
          row: row.rowNumber,
          column: 'id',
          message: 'id is not a valid ObjectId',
        });
        continue;
      }
      this.validateKeypointEntries(row, errors);
    }

    await this.validateKeypointsExist(allRows, errors);

    assertNoImportErrors(errors);

    // Default icon/lightIcon when the column is blank: reuse the Tag IDs from
    // an existing lesson that already has them set. Purely ID-based and
    // environment-agnostic (no title matching).
    const refLesson = await this.lessonRepository.model
      .findOne(
        { icon: { $exists: true, $nin: [null, ''] } },
        { icon: 1, lightIcon: 1 },
      )
      .lean();
    const fallbackIcon = refLesson?.icon as string | undefined;
    const fallbackLightIcon = refLesson?.lightIcon as string | undefined;

    const createdLessonIds = new Map<number, string>();

    for (const row of lessonRows) {
      const id = text(row.values.id);
      const payload = this.buildLessonImportPayload(row.values, !id);

      if (id) {
        if (Object.keys(payload).length) {
          await this.lessonRepository.updateOne(
            { _id: id },
            payload as any,
            this.user,
          );
        }
        continue;
      }

      const courseId = text(row.values.courseId);
      const nextIndex = await this.lessonRepository.getNextIndex(courseId);
      const icon = text(row.values.icon) || fallbackIcon;
      const lightIcon = text(row.values.lightIcon) || fallbackLightIcon;
      const created = await this.lessonRepository.create(
        {
          ...payload,
          ...(courseId ? { courseId } : {}),
          index: nextIndex,
          ...(icon ? { icon } : {}),
          ...(lightIcon ? { lightIcon } : {}),
        } as any,
        this.user,
      );
      setCellByHeader(sheet, row.rowNumber, 'id', created._id.toString());
      createdLessonIds.set(row.rowNumber, created._id.toString());
    }

    const lessonKeypointsMap = new Map<
      string,
      Array<{ keypointId: string; index: number }>
    >();
    for (const row of [...lessonRows, ...kpRows]) {
      const lessonId =
        text(row.values.id) || createdLessonIds.get(row.rowNumber);
      if (!lessonId) continue;

      const keypointEntries = this.parseKeypointEntries(row.values);
      if (!keypointEntries.length) continue;

      if (!lessonKeypointsMap.has(lessonId)) {
        lessonKeypointsMap.set(lessonId, []);
      }
      lessonKeypointsMap.get(lessonId)!.push(...keypointEntries);
    }

    for (const [lessonId, entries] of lessonKeypointsMap) {
      const keypointIds = [
        ...new Set(
          entries.sort((a, b) => a.index - b.index).map(e => e.keypointId),
        ),
      ];
      await this.lessonRepository.updateOne(
        { _id: lessonId },
        { keypoints: keypointIds } as any,
        this.user,
      );
    }

    return workbookToBuffer(workbook);
  }

  private isKeypointOnlyRow(values: Record<string, any>) {
    if (!text(values.keypointId)) return false;

    return !['courseId', 'title'].some(prefix =>
      prefix === 'title'
        ? hasTranslationValueForPrefix(values, prefix)
        : Boolean(text(values[prefix])),
    );
  }

  private validateKeypointEntries(
    row: { rowNumber: number; values: Record<string, any> },
    errors: ImportValidationError[],
  ) {
    const keypointIds = this.splitMultilineCell(row.values.keypointId);
    const keypointIndexes = this.splitMultilineCell(row.values.keypointIndex);

    keypointIds.forEach((keypointId, index) => {
      if (!Types.ObjectId.isValid(keypointId)) {
        errors.push({
          sheet: 'lessons',
          row: row.rowNumber,
          column: 'keypointId',
          message: `keypointId at line ${index + 1} is not a valid ObjectId`,
        });
      }
    });

    keypointIndexes.forEach((keypointIndex, index) => {
      const parsed = Number(keypointIndex);
      if (!Number.isFinite(parsed)) {
        errors.push({
          sheet: 'lessons',
          row: row.rowNumber,
          column: 'keypointIndex',
          message: `keypointIndex at line ${index + 1} is not a valid number`,
        });
      }
    });
  }

  private async validateKeypointsExist(
    rows: ImportRow[],
    errors: ImportValidationError[],
  ) {
    const referencedIds = new Set<string>();
    for (const row of rows) {
      for (const keypointId of this.splitMultilineCell(row.values.keypointId)) {
        if (Types.ObjectId.isValid(keypointId)) {
          referencedIds.add(keypointId);
        }
      }
    }
    if (!referencedIds.size) return;

    const found = await this.keypointRepository.findKeypointsByIds([
      ...referencedIds,
    ]);
    const foundIds = new Set(found.map(kp => kp._id.toString()));

    for (const row of rows) {
      this.splitMultilineCell(row.values.keypointId).forEach(
        (keypointId, index) => {
          if (Types.ObjectId.isValid(keypointId) && !foundIds.has(keypointId)) {
            errors.push({
              sheet: 'lessons',
              row: row.rowNumber,
              column: 'keypointId',
              message: `keypointId at line ${index + 1} was not found`,
            });
          }
        },
      );
    }
  }

  private parseKeypointEntries(values: Record<string, any>) {
    const keypointIds = this.splitMultilineCell(values.keypointId);
    const keypointIndexes = this.splitMultilineCell(values.keypointIndex);

    return keypointIds.map((keypointId, index) => ({
      keypointId,
      index: Number(keypointIndexes[index] ?? index + 1),
    }));
  }

  private splitMultilineCell(value: any) {
    return text(value)
      .split(/\r?\n/)
      .map(item => item.trim())
      .filter(Boolean);
  }


private buildLessonImportPayload(
    values: Record<string, any>,
    isCreate: boolean,
  ) {
    const payload: Record<string, any> = {};
    const title = translationFromValues(values, 'title');
    if (isCreate) {
      if (title) payload.title = title;
    } else {
      this.assignTranslationUpdate(payload, 'title', title);
    }
    return payload;
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
