import { Injectable, NotFoundException } from '@nestjs/common';
import { Types } from 'mongoose';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';

import {
  createMultiSheetTemplateWorkbook,
  getHeaders,
  getRows,
  getSheet,
  ImportValidationError,
  readWorkbook,
  setCellByHeader,
  text,
  validateNoDuplicateValues,
  workbookToBuffer,
} from './excel-import.util';
import { ICourseImportJobError } from './interface/course-import-job.interface';
import { VERSION_SHEET, buildVersionSheet } from './version-sheet';
import { CourseService } from '../course/course.service';
import { CourseRepository } from '../course/repository/course.repository';
import { ContentSource } from '../course-version/content-source.service';
import { collectKeypointIds, uniqueIds } from '../course-version/content-traversal';
import { CourseVersionService } from '../course-version/course-version.service';
import { PublishedContentRepository } from '../course-version/repository/published-content.repository';
import { KeypointService } from '../keypoint/keypoint.service';
import { LearningItemType } from '../learning-item/enum/learning-item.enum';
import { LearningItemService } from '../learning-item/learning-item.service';
import { LessonService } from '../lesson/lesson.service';
import { LessonRepository } from '../lesson/repository/lesson.repository';

import type ExcelJS from 'exceljs';

export interface EntityImportStats {
  created: number;
  updated: number;
}

export type CourseContentImportStats = Record<
  'courses' | 'lessons' | 'keypoints' | 'theories' | 'exercises',
  EntityImportStats
>;

export interface CourseContentImportResult {
  buffer: Buffer;
  errors: ICourseImportJobError[];
  /**
   * Courses this workbook wrote to. An import lands in the WORKING TREE, so on
   * a tagged course nothing reaches the app until a tag is made -- the caller
   * surfaces this so a sheet editor is never left thinking it went live.
   * See `plans/260907-course-content-versions/README.md`.
   */
  touchedCourseIds?: string[];
  /** Tags published by `autoTag`, empty when the option was off. */
  autoTagged?: { courseId: string; tag: string }[];
  /** created = rows that gained an id; updated = rows that came in with one
   *  (on a failed run these are the attempted counts up to the failing pass). */
  stats: CourseContentImportStats;
}

const ERROR_SHEET = 'import_errors';
const STAT_SHEETS = [
  'courses',
  'lessons',
  'keypoints',
  'theories',
  'exercises',
] as const;

/**
 * One workbook per course: every content sheet the per-entity importers read,
 * plus workbook-local ref keys (`course_key`, `lesson_key`, `keypoint_key`)
 * so a brand-new course can wire lesson↔keypoint↔roadmap relations before any
 * id exists. Import runs the entity importers in dependency order and
 * resolves keys to the ids each pass writes back.
 */
@Injectable()
export class CourseContentTransferService {
  constructor(
    private readonly courseService: CourseService,
    private readonly lessonService: LessonService,
    private readonly keypointService: KeypointService,
    private readonly learningItemService: LearningItemService,
    private readonly lessonRepository: LessonRepository,
    private readonly courseRepository: CourseRepository,
    private readonly contentSource: ContentSource,
    private readonly publishedContentRepository: PublishedContentRepository,
    private readonly courseVersionService: CourseVersionService,
  ) {}

  /**
   * `versionId` exports a frozen tag instead of the working tree. Ids inside a
   * tag are the working tree's real ids, so re-importing such a workbook
   * restores that tag's content over the working tree -- the cheapest
   * "revert my edits" there is, at no extra cost.
   */
  async exportCourseFull(
    courseId: string,
    versionId: string | null = null,
    /**
     * Tag vừa được đánh, để sheet `_VERSION` nói được "lần sync vừa rồi đã
     * phát hành thành v1.0.4". Chỉ đường ghi lại sau khi sync truyền vào.
     */
    publishedAs?: string | null,
  ): Promise<Buffer> {
    if (versionId) {
      return this.exportCourseAtVersion(courseId, versionId, publishedAs);
    }

    const courseSheets = await this.courseService.buildCourseExportSheets(
      courseId,
    );
    if (!courseSheets[0]?.sampleRows?.length) {
      throw new NotFoundException('course was not found');
    }

    const lessons = await this.lessonRepository.findAllForExport(courseId);
    const keypointIds = [
      ...new Set(
        lessons.flatMap(lesson => (lesson.keypoints ?? []).map(String)),
      ),
    ];

    const lessonSheet = await this.lessonService.buildLessonExportSheet(
      courseId,
    );
    const keypointSheet = await this.keypointService.buildKeypointExportSheet(
      keypointIds,
    );
    const theorySheets = await this.learningItemService.buildTheoryExportSheets(
      keypointIds,
    );
    const exerciseSheets =
      await this.learningItemService.buildExerciseExportSheets(keypointIds);

    return createMultiSheetTemplateWorkbook([
      // `_VERSION` đứng ĐẦU: người mở sheet trên Drive phải thấy ngay mình
      // đang sửa bản nháp hay bản đang phát hành, trước khi sửa gì.
      await this.buildVersionSheetFor(courseId, null, publishedAs),
      ...courseSheets,
      lessonSheet,
      keypointSheet,
      ...theorySheets,
      ...exerciseSheets,
    ]);
  }

  /**
   * Nhãn phiên bản cho workbook. `publishedAs` chỉ truyền ở đường ghi lại sau
   * import — lúc đó tag mới vừa được đánh xong.
   */
  private async buildVersionSheetFor(
    courseId: string,
    versionId: string | null,
    publishedAs?: string | null,
  ) {
    const [course, overview] = await Promise.all([
      this.courseRepository.findById(courseId),
      this.courseVersionService.versionOverview(courseId, versionId),
    ]);
    const title = (course?.title ?? {}) as Record<string, string>;

    return buildVersionSheet({
      courseTitle: title.vi || title.en || courseId,
      liveTag: overview.liveTag,
      contentTag: overview.contentTag,
      exportedAt: new Date(),
      publishedAs: publishedAs ?? null,
      history: overview.history,
    });
  }

  private async exportCourseAtVersion(
    courseId: string,
    versionId: string,
    publishedAs?: string | null,
  ): Promise<Buffer> {
    const liveCourse = await this.courseRepository.findById(courseId);
    if (!liveCourse) throw new NotFoundException('course was not found');

    // A tag freezes editorial fields only, so the row is the live course
    // document overlaid with what the tag froze -- status, prices and market
    // gating are deliberately not part of a content tag.
    const frozenCourse = await this.publishedContentRepository.findEntity(
      versionId,
      'course',
      courseId,
    );
    // `.toObject()` BẮT BUỘC: `liveCourse` là một Mongoose Document thật
    // (`courseRepository.findById` không `.lean()`), và spread thẳng một
    // Document (`{ ...liveCourse }`) không sao chép được field nào -- Mongoose
    // lộ `_id`/`title`/... qua getter trên prototype, spread chỉ lấy
    // own-enumerable-property nên kết quả chỉ còn `$__`/`_doc` nội bộ.
    // `courseDoc._id` thành `undefined`, và `buildCourseExportSheets` gọi
    // `course._id.toString()` không có guard -- production 2026-09-10, một
    // 500 thô "Cannot read properties of undefined (reading 'toString')"
    // không liên quan gì tới Drive dù triệu chứng ban đầu tưởng vậy.
    const courseDoc = {
      ...(liveCourse as any).toObject(),
      ...(frozenCourse ?? {}),
    };

    const roadmap = await this.contentSource.getRoadmap(courseId, versionId);
    const lessons = await this.contentSource.getLessonsByCourse(
      courseId,
      versionId,
    );
    const keypointIds = collectKeypointIds({
      lessons: lessons as any[],
      roadmap: roadmap as any,
    });
    const keypoints = await this.contentSource.getKeypointsByIds(
      keypointIds,
      versionId,
    );
    const items = await this.contentSource.getLearningItemsByKeypointIds(
      keypointIds,
      versionId,
    );
    const ofType = (type: LearningItemType) =>
      items.filter(item => item.type === type);

    const courseSheets = await this.courseService.buildCourseExportSheets(
      courseId,
      { courses: [courseDoc], roadmaps: roadmap ? [roadmap] : [] },
    );
    const lessonSheet = await this.lessonService.buildLessonExportSheet(
      courseId,
      lessons as any[],
    );
    const keypointSheet = await this.keypointService.buildKeypointExportSheet(
      keypointIds,
      keypoints as any[],
    );
    const theorySheets = await this.learningItemService.buildTheoryExportSheets(
      keypointIds,
      ofType(LearningItemType.THEORY) as any[],
    );
    const exerciseSheets =
      await this.learningItemService.buildExerciseExportSheets(
        keypointIds,
        ofType(LearningItemType.EXERCISE) as any[],
      );

    return createMultiSheetTemplateWorkbook([
      await this.buildVersionSheetFor(courseId, versionId, publishedAs),
      ...courseSheets,
      lessonSheet,
      keypointSheet,
      ...theorySheets,
      ...exerciseSheets,
    ]);
  }

  async buildFullTemplate(): Promise<Buffer> {
    // A filter that matches nothing yields every sheet with headers only.
    const noneId = '000000000000000000000000';
    const courseSheets = await this.courseService.buildCourseExportSheets(
      noneId,
    );
    const lessonSheet = await this.lessonService.buildLessonExportSheet(noneId);
    const keypointSheet = await this.keypointService.buildKeypointExportSheet(
      [],
    );
    const theorySheets = await this.learningItemService.buildTheoryExportSheets(
      [],
    );
    const exerciseSheets =
      await this.learningItemService.buildExerciseExportSheets([]);

    const byHeaders = (headers: string[], values: Record<string, any>) =>
      headers.map(header => values[header] ?? '');

    courseSheets[0].sampleRows = [
      byHeaders(courseSheets[0].headers, {
        course_key: 'khoa-moi',
        title_vi: 'Tên khoá học',
        title_en: 'Course title',
        status: 'draft',
      }),
    ];
    courseSheets[1].sampleRows = [
      byHeaders(courseSheets[1].headers, {
        course_key: 'khoa-moi',
        level_key: 'level-1',
        id: 1,
        level: 'level 1',
        titleBadge_vi: 'Huy hiệu 1',
        titleBadge_en: 'Badge 1',
      }),
    ];
    courseSheets[2].sampleRows = [
      byHeaders(courseSheets[2].headers, {
        course_key: 'khoa-moi',
        level_key: 'level-1',
        title_vi: 'Chặng 1',
        title_en: 'Stage 1',
        lessonIds: 'bai-1',
      }),
    ];
    lessonSheet.sampleRows = [
      byHeaders(lessonSheet.headers, {
        lesson_key: 'bai-1',
        courseId: 'khoa-moi',
        title_vi: 'Bài 1',
        title_en: 'Lesson 1',
        keypointId: 'diem-1\ndiem-2',
        keypointIndex: '1\n2',
      }),
    ];
    keypointSheet.sampleRows = [
      byHeaders(keypointSheet.headers, {
        keypoint_key: 'diem-1',
        title_vi: 'Điểm chính 1',
        title_en: 'Keypoint 1',
      }),
      byHeaders(keypointSheet.headers, {
        keypoint_key: 'diem-2',
        title_vi: 'Điểm chính 2',
        title_en: 'Keypoint 2',
      }),
    ];
    theorySheets[0].sampleRows = [
      byHeaders(theorySheets[0].headers, {
        keypoint_id: 'diem-1',
        title_vi: 'Lý thuyết 1',
        title_en: 'Theory 1',
        theory_code: 'T1',
      }),
    ];
    theorySheets[1].sampleRows = [
      byHeaders(theorySheets[1].headers, {
        theory_code: 'T1',
        document_type: 'text',
        document_content_vi: 'Nội dung thẻ 1',
        document_content_en: 'Card 1 content',
      }),
    ];
    exerciseSheets[0].sampleRows = [
      byHeaders(exerciseSheets[0].headers, {
        keypoint_id: 'diem-2',
        title_vi: 'Bài tập 1',
        title_en: 'Exercise 1',
        question_code: 'Q1',
        question_type: 'single_choice',
        max_score: 10,
      }),
    ];
    exerciseSheets[2].sampleRows = [
      byHeaders(exerciseSheets[2].headers, {
        question_code: 'Q1',
        value_vi: 'Đáp án A',
        value_en: 'Option A',
        is_correct: 'true',
      }),
      byHeaders(exerciseSheets[2].headers, {
        question_code: 'Q1',
        value_vi: 'Đáp án B',
        value_en: 'Option B',
        is_correct: 'false',
      }),
    ];

    return createMultiSheetTemplateWorkbook([
      ...courseSheets,
      lessonSheet,
      keypointSheet,
      ...theorySheets,
      ...exerciseSheets,
    ]);
  }

  /**
   * Multi-pass import. Never throws for content problems: the returned
   * workbook always carries the ids created so far (so nothing silently
   * orphans), and any validation errors land in an `import_errors` sheet.
   */
  async importCourseContent(
    file: Express.Multer.File,
    /**
     * `autoTag` publishes the result: after a clean import every touched
     * course gets its next patch tag and is pointed at it. Off by default,
     * because freezing content and publishing it are separate decisions -- but
     * the Google Sheet workflow (edit sheet, sync, see it live) needs it.
     */
    opts: { autoTag?: boolean; actor?: IUserMeta | null } = {},
  ): Promise<CourseContentImportResult> {
    let workbook = await readWorkbook(file);
    this.removeErrorSheet(workbook);
    const idsBefore = this.collectIdSets(workbook);

    const preflight = this.preflightRefs(workbook);
    if (preflight.length) {
      return this.finish(workbook, preflight, idsBefore);
    }

    try {
      // Pass 0 — course rows only (roadmap comes last: its nodes reference
      // lessons that may not exist yet).
      if (this.hasRows(workbook, 'courses')) {
        const coursesOnly = await createMultiSheetTemplateWorkbook([
          this.sheetToDef(workbook, 'courses'),
        ]);
        const result = await this.courseService.importCourses(
          this.toFile(coursesOnly),
        );
        const resultWorkbook = await readWorkbook(this.toFile(result));
        const courseMap = this.mapKeyToId(resultWorkbook, 'courses', 'course_key');
        this.applyIdsFromMap(workbook, 'courses', 'course_key', courseMap);
        this.substituteColumn(workbook, 'lessons', 'courseId', courseMap);
      }

      // Pass 1 — keypoints, then resolve every keypoint ref.
      if (this.hasRows(workbook, 'keypoints')) {
        workbook = await this.runPass(workbook, buffer =>
          this.keypointService.importKeypoints(buffer),
        );
      }
      const keypointMap = this.mapKeyToId(workbook, 'keypoints', 'keypoint_key');
      this.substituteColumn(workbook, 'theories', 'keypoint_id', keypointMap);
      this.substituteColumn(workbook, 'exercises', 'keypoint_id', keypointMap);
      this.substituteMultilineColumn(
        workbook,
        'lessons',
        'keypointId',
        keypointMap,
      );

      // Pass 2 — learning items.
      if (this.hasRows(workbook, 'theories')) {
        workbook = await this.runPass(workbook, buffer =>
          this.learningItemService.importTheories(buffer),
        );
      }
      if (this.hasRows(workbook, 'exercises')) {
        workbook = await this.runPass(workbook, buffer =>
          this.learningItemService.importExercises(buffer),
        );
      }

      // Pass 3 — lessons, then resolve lesson refs in the roadmap.
      if (this.hasRows(workbook, 'lessons')) {
        workbook = await this.runPass(workbook, buffer =>
          this.lessonService.importLessons(buffer),
        );
      }
      const lessonMap = this.mapKeyToId(workbook, 'lessons', 'lesson_key');
      for (const column of [
        'openingVideoId',
        'roleplayId',
        'outputId',
        'closingVideoId',
      ]) {
        this.substituteColumn(workbook, 'roadmap_nodes', column, lessonMap);
      }
      this.substituteListColumn(workbook, 'roadmap_nodes', 'lessonIds', lessonMap);

      // Pass 4 — courses again, now with the roadmap sheets resolvable.
      if (this.hasRows(workbook, 'courses')) {
        workbook = await this.runPass(workbook, buffer =>
          this.courseService.importCourses(buffer),
        );
      }
    } catch (error: any) {
      return this.finish(workbook, this.resolveErrors(error), idsBefore);
    }

    const result = await this.finish(workbook, [], idsBefore);
    result.touchedCourseIds = await this.resolveTouchedCourseIds(workbook);
    result.autoTagged = opts.autoTag
      ? await this.autoTagCourses(result.touchedCourseIds, opts.actor)
      : [];

    return result;
  }

  /**
   * Which courses this workbook wrote to. The `courses` sheet is the direct
   * answer; a workbook that only carries lessons gives its course away through
   * the `courseId` column; and a keypoint-only workbook gives nothing at all,
   * since `keypoint.schema.ts` has no `courseId` -- for those the tagged
   * content index answers it in reverse.
   */
  private async resolveTouchedCourseIds(
    workbook: ExcelJS.Workbook,
  ): Promise<string[]> {
    const direct = this.rowsOf(workbook, 'courses').map(row =>
      text(row.values.id),
    );
    const fromLessons = this.rowsOf(workbook, 'lessons').map(row =>
      text(row.values.courseId),
    );

    const keypointIds = uniqueIds([
      ...this.rowsOf(workbook, 'keypoints').map(row => text(row.values.id)),
      ...this.rowsOf(workbook, 'theories').map(row =>
        text(row.values.keypoint_id),
      ),
      ...this.rowsOf(workbook, 'exercises').map(row =>
        text(row.values.keypoint_id),
      ),
    ]);
    const fromKeypoints = await Promise.all(
      keypointIds.map(id => this.contentSource.resolveCourseOfKeypoint(id)),
    );

    return uniqueIds([...direct, ...fromLessons, ...fromKeypoints]);
  }

  private async autoTagCourses(
    courseIds: string[],
    actor?: IUserMeta | null,
  ): Promise<{ courseId: string; tag: string }[]> {
    const tagged: { courseId: string; tag: string }[] = [];

    for (const courseId of courseIds) {
      const view = await this.courseVersionService.autoTag(courseId, actor);
      tagged.push({ courseId, tag: view.tag });
    }

    return tagged;
  }

  private async runPass(
    workbook: ExcelJS.Workbook,
    importer: (file: Express.Multer.File) => Promise<Buffer>,
  ): Promise<ExcelJS.Workbook> {
    const buffer = await workbookToBuffer(workbook);
    const result = await importer(this.toFile(buffer));
    return readWorkbook(this.toFile(result));
  }

  /**
   * Cross-sheet checks the per-entity importers cannot do: create rows need a
   * key, keys must be unique, and every non-ObjectId ref must point at a key
   * defined in this workbook.
   */
  private preflightRefs(workbook: ExcelJS.Workbook): ImportValidationError[] {
    const errors: ImportValidationError[] = [];

    const courseRows = this.rowsOf(workbook, 'courses');
    const lessonRows = this.rowsOf(workbook, 'lessons');
    const keypointRows = this.rowsOf(workbook, 'keypoints');

    validateNoDuplicateValues('lessons', lessonRows, errors, 'lesson_key');
    validateNoDuplicateValues('keypoints', keypointRows, errors, 'keypoint_key');

    for (const row of courseRows) {
      if (!text(row.values.id) && !text(row.values.course_key)) {
        errors.push({
          sheet: 'courses',
          row: row.rowNumber,
          column: 'course_key',
          message: 'course_key is required when creating via full import',
        });
      }
    }

    const courseKeys = new Set(
      courseRows.map(row => text(row.values.course_key)).filter(Boolean),
    );
    const lessonKeys = new Set(
      lessonRows.map(row => text(row.values.lesson_key)).filter(Boolean),
    );
    const keypointKeys = new Set(
      keypointRows.map(row => text(row.values.keypoint_key)).filter(Boolean),
    );

    const checkRef = (
      sheet: string,
      row: { rowNumber: number },
      column: string,
      value: string,
      keys: Set<string>,
      keyName: string,
    ) => {
      if (!value || Types.ObjectId.isValid(value) || keys.has(value)) return;
      errors.push({
        sheet,
        row: row.rowNumber,
        column,
        message: `"${value}" is neither an ObjectId nor a ${keyName} defined in this file`,
      });
    };

    for (const row of lessonRows) {
      checkRef(
        'lessons',
        row,
        'courseId',
        text(row.values.courseId),
        courseKeys,
        'course_key',
      );
      for (const token of this.splitMultiline(row.values.keypointId)) {
        checkRef('lessons', row, 'keypointId', token, keypointKeys, 'keypoint_key');
      }
    }

    for (const sheet of ['theories', 'exercises']) {
      for (const row of this.rowsOf(workbook, sheet)) {
        checkRef(
          sheet,
          row,
          'keypoint_id',
          text(row.values.keypoint_id),
          keypointKeys,
          'keypoint_key',
        );
      }
    }

    for (const row of this.rowsOf(workbook, 'roadmap_nodes')) {
      for (const column of [
        'openingVideoId',
        'roleplayId',
        'outputId',
        'closingVideoId',
      ]) {
        checkRef(
          'roadmap_nodes',
          row,
          column,
          text(row.values[column]),
          lessonKeys,
          'lesson_key',
        );
      }
      for (const token of this.splitList(row.values.lessonIds)) {
        checkRef('roadmap_nodes', row, 'lessonIds', token, lessonKeys, 'lesson_key');
      }
    }

    return errors;
  }

  private async finish(
    workbook: ExcelJS.Workbook,
    errors: ImportValidationError[],
    idsBefore: Record<string, Set<string>>,
  ): Promise<CourseContentImportResult> {
    if (errors.length) {
      const sheet = workbook.addWorksheet(ERROR_SHEET);
      sheet.addRow(['sheet', 'row', 'column', 'message']);
      for (const error of errors) {
        sheet.addRow([error.sheet, error.row, error.column ?? '', error.message]);
      }
    }

    const idsAfter = this.collectIdSets(workbook);
    const stats = {} as CourseContentImportStats;
    for (const sheetName of STAT_SHEETS) {
      const before = idsBefore[sheetName] ?? new Set();
      const after = idsAfter[sheetName] ?? new Set();
      let created = 0;
      for (const id of after) {
        if (!before.has(id)) created++;
      }
      stats[sheetName] = { created, updated: before.size };
    }

    await this.restampVersionSheet(workbook);

    return { buffer: await workbookToBuffer(workbook), errors, stats };
  }

  /**
   * Đóng dấu lại `_VERSION` lên workbook kết quả.
   *
   * Cần vì `runPass` đẩy workbook qua từng importer con, và mỗi importer trả
   * về workbook CHỈ CHỨA sheet nó biết — nên `_VERSION` bị rơi ngay sau pass
   * đầu tiên. Đường sync sạch lỗi thì không sao (nó xuất mới hoàn toàn), nhưng
   * đường CÓ LỖI ghi lại chính workbook này lên Drive, và mất thông tin phiên
   * bản đúng lúc đang có sự cố là mất nó ở đúng lúc cần nhất.
   *
   * Tab nằm ở CUỐI chứ không đầu: ExcelJS thêm sheet vào cuối và không có cách
   * chèn lên đầu cho gọn. Ở đường này thì đúng thứ tự đó lại hợp — tab người
   * ta cần đọc trước là `import_errors`.
   *
   * Bỏ qua khi workbook chạm nhiều hơn một khoá: một sheet `_VERSION` không
   * nói được về ba khoá cùng lúc, và header `X-Touched-Courses` đã trả lời
   * trường hợp đó.
   */
  private async restampVersionSheet(
    workbook: ExcelJS.Workbook,
  ): Promise<void> {
    if (workbook.getWorksheet(VERSION_SHEET)) return;

    try {
      const courseIds = await this.resolveTouchedCourseIds(workbook);
      if (courseIds.length !== 1) return;

      const def = await this.buildVersionSheetFor(courseIds[0], null);
      const sheet = workbook.addWorksheet(def.sheetName);
      sheet.addRow(def.headers);
      for (const row of def.sampleRows ?? []) sheet.addRow(row);
    } catch {
      // Thông tin phụ trợ. Không được làm gãy một lần import đã chạy xong.
    }
  }

  private collectIdSets(workbook: ExcelJS.Workbook) {
    const sets: Record<string, Set<string>> = {};
    for (const sheetName of STAT_SHEETS) {
      const ids = new Set<string>();
      for (const row of this.rowsOf(workbook, sheetName)) {
        const id = text(row.values.id);
        if (id) ids.add(id);
      }
      sets[sheetName] = ids;
    }
    return sets;
  }

  private resolveErrors(error: any): ImportValidationError[] {
    const response =
      typeof error?.getResponse === 'function' ? error.getResponse() : null;
    if (response?.errors?.length) return response.errors;
    return [
      {
        sheet: 'workbook',
        row: 0,
        message: error?.message || 'Course content import failed',
      },
    ];
  }

  private removeErrorSheet(workbook: ExcelJS.Workbook) {
    const sheet = getSheet(workbook, [ERROR_SHEET]);
    if (sheet) workbook.removeWorksheet(sheet.id);
  }

  private rowsOf(workbook: ExcelJS.Workbook, sheetName: string) {
    return getRows(getSheet(workbook, [sheetName]));
  }

  private hasRows(workbook: ExcelJS.Workbook, sheetName: string) {
    return this.rowsOf(workbook, sheetName).length > 0;
  }

  private sheetToDef(workbook: ExcelJS.Workbook, sheetName: string) {
    const sheet = getSheet(workbook, [sheetName], true);
    const headers = getHeaders(sheet);
    const sampleRows = getRows(sheet).map(row =>
      headers.map(header => row.values[header] ?? ''),
    );
    return { sheetName, headers, sampleRows };
  }

  private mapKeyToId(
    workbook: ExcelJS.Workbook,
    sheetName: string,
    keyColumn: string,
  ) {
    const map = new Map<string, string>();
    for (const row of this.rowsOf(workbook, sheetName)) {
      const key = text(row.values[keyColumn]);
      const id = text(row.values.id);
      if (key && id) map.set(key, id);
    }
    return map;
  }

  private applyIdsFromMap(
    workbook: ExcelJS.Workbook,
    sheetName: string,
    keyColumn: string,
    map: Map<string, string>,
  ) {
    const sheet = getSheet(workbook, [sheetName]);
    if (!sheet) return;
    for (const row of getRows(sheet)) {
      const key = text(row.values[keyColumn]);
      if (!text(row.values.id) && key && map.has(key)) {
        setCellByHeader(sheet, row.rowNumber, 'id', map.get(key));
      }
    }
  }

  private substituteColumn(
    workbook: ExcelJS.Workbook,
    sheetName: string,
    column: string,
    map: Map<string, string>,
  ) {
    if (!map.size) return;
    const sheet = getSheet(workbook, [sheetName]);
    if (!sheet) return;
    for (const row of getRows(sheet)) {
      const value = text(row.values[column]);
      if (value && !Types.ObjectId.isValid(value) && map.has(value)) {
        setCellByHeader(sheet, row.rowNumber, column, map.get(value));
      }
    }
  }

  private substituteMultilineColumn(
    workbook: ExcelJS.Workbook,
    sheetName: string,
    column: string,
    map: Map<string, string>,
  ) {
    if (!map.size) return;
    const sheet = getSheet(workbook, [sheetName]);
    if (!sheet) return;
    for (const row of getRows(sheet)) {
      const tokens = this.splitMultiline(row.values[column]);
      if (!tokens.length) continue;
      const resolved = tokens.map(token =>
        !Types.ObjectId.isValid(token) && map.has(token)
          ? (map.get(token) as string)
          : token,
      );
      if (resolved.some((token, index) => token !== tokens[index])) {
        setCellByHeader(sheet, row.rowNumber, column, resolved.join('\n'));
      }
    }
  }

  private substituteListColumn(
    workbook: ExcelJS.Workbook,
    sheetName: string,
    column: string,
    map: Map<string, string>,
  ) {
    if (!map.size) return;
    const sheet = getSheet(workbook, [sheetName]);
    if (!sheet) return;
    for (const row of getRows(sheet)) {
      const tokens = this.splitList(row.values[column]);
      if (!tokens.length) continue;
      const resolved = tokens.map(token =>
        !Types.ObjectId.isValid(token) && map.has(token)
          ? (map.get(token) as string)
          : token,
      );
      if (resolved.some((token, index) => token !== tokens[index])) {
        setCellByHeader(sheet, row.rowNumber, column, resolved.join('|'));
      }
    }
  }

  private splitMultiline(value: any) {
    return text(value)
      .split(/\r?\n/)
      .map(item => item.trim())
      .filter(Boolean);
  }

  private splitList(value: any) {
    return text(value)
      .split(/\r?\n|\|/)
      .map(item => item.trim())
      .filter(Boolean);
  }

  private toFile(buffer: Buffer): Express.Multer.File {
    return {
      buffer,
      originalname: 'course-content.xlsx',
      mimetype:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      size: buffer.length,
    } as Express.Multer.File;
  }
}
