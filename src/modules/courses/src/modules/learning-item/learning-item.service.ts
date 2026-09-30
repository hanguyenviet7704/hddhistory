import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Types } from 'mongoose';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { RequestService } from '@base/service/request.service';
import {
  getTranslationValue,
  hasAnyTranslationValue,
} from '@utils/translate';

import { buildDocuments } from '../import/document-import.util';
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
import {
  buildExerciseQuestions,
  groupExerciseRows,
} from '../import/exercise-import.util';
import { CreateLearningItemDto } from './dto/create-learning-item.dto';
import { DailyWarmUpTaggingResultDto } from './dto/daily-warm-up-tagging.dto';
import { GetListLearningItemDto } from './dto/get-learning-item.dto';
import {
  UpdateLearningItemDto,
  UpdateLearningItemIndexDto,
} from './dto/update-learning-item.dto';
import {
  DocumentType,
  LearningItemType,
  RoleplayContentType,
} from './enum/learning-item.enum';
import {
  ExerciseInput,
  ILearningItem,
} from './interface/learning-item.interface';
import { ITheoryDocument } from './interface/theories/theory.interface';
import { LearningItemRepository } from './repository/learning-item.repository';
import { LearningItem } from './schema/learning-item.schema';
import { AvatarRepository } from '../avatar/repository/avatar.repository';
import { ContentSource } from '../course-version/content-source.service';
import { KeypointRepository } from '../keypoint/repository/keypoint.repository';
import { LessonRepository } from '../lesson/repository/lesson.repository';
import { TagRepository } from '../tags/repository/tag.repository';

interface TheoryGroup {
  rows: ImportRow[];
  firstRow: ImportRow;
}

@Injectable()
export class LearningItemService {
  constructor(
    private readonly learningItemRepository: LearningItemRepository,
    private readonly keypointRepository: KeypointRepository,
    private readonly tagRepository: TagRepository,
    private readonly avatarRepository: AvatarRepository,
    private readonly lessonRepository: LessonRepository,
    private readonly requestService: RequestService,
    private readonly i18n: I18nService,
    private readonly configService: ConfigService,
    private readonly contentSource: ContentSource,
  ) {}

  private get user() {
    return this.requestService.user;
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  private ensureExerciseId(items?: ExerciseInput[]) {
    if (!items?.length) return false;
    let updated = false;

    for (const item of items) {
      if (item && !item.exerciseId) {
        item.exerciseId = new Types.ObjectId().toString();
        updated = true;
      }
    }

    return updated;
  }

  private ensureExerciseIdsInPayload(payload?: Record<string, any>) {
    if (!payload) return false;
    let updated = false;

    updated = this.ensureExerciseId(payload.questions) || updated;
    updated = this.ensureExerciseId(payload.subQuestions) || updated;

    if (payload.roleplay?.contents?.length) {
      for (const content of payload.roleplay.contents) {
        if (content.exercise && !content.exercise.exerciseId) {
          content.exercise.exerciseId = new Types.ObjectId().toString();
          updated = true;
        }
      }
    }

    if (payload.videoQuestions?.length) {
      for (const videoQuestion of payload.videoQuestions) {
        if (videoQuestion.exercise && !videoQuestion.exercise.exerciseId) {
          videoQuestion.exercise.exerciseId = new Types.ObjectId().toString();
          updated = true;
        }
      }
    }

    return updated;
  }

  async create(
    createLearningItemDto: CreateLearningItemDto,
  ): Promise<LearningItem> {
    const { title, keypointId } = createLearningItemDto;
    const titleByLang = getTranslationValue(title, this.lang);

    if (!titleByLang && !hasAnyTranslationValue(title)) {
      throw new BadRequestException('title is required');
    }

    if (titleByLang) {
      // check title exits
      const titleExits = await this.learningItemRepository.checkExitsTitle(
        titleByLang,
        keypointId,
        this.lang,
      );
      if (titleExits)
        throw new ConflictException(
          this.i18n.t('error.COURSE_LEARNING_ITEM.TITLE_EXISTS', {
            lang: this.lang,
          }),
        );
    }

    const nextIndex = await this.learningItemRepository.getNextIndex(
      keypointId,
    );

    const learningItemPayload: ILearningItem & Record<string, any> = {
      ...createLearningItemDto,
      index: nextIndex,
    } as ILearningItem;

    this.ensureExerciseIdsInPayload(learningItemPayload);

    const learningItem = await this.learningItemRepository.create(
      learningItemPayload,
      this.user,
    );

    return learningItem;
  }

  async findAll(getListLearningItemDto: GetListLearningItemDto) {
    const result = await this.learningItemRepository.findOption(
      getListLearningItemDto,
    );

    return result;
  }

  /**
   * `versionId` null = bản đang sửa (hành vi cũ). Khác null = đọc tag đang
   * phát hành của khoá chứa item này.
   * Xem `plans/260907-course-content-versions/README.md`.
   */
  async findOne(
    id: string,
    requested?: string | null,
  ): Promise<LearningItem> {
    const versionId = await this.contentSource.versionForEntity(
      'learningItem',
      id,
      this.requestService.headers,
      requested,
      this.user?.id,
    );

    const learningItem = versionId
      ? ((await this.contentSource.getLearningItem(
          id,
          versionId,
        )) as unknown as LearningItem | null)
      : await this.learningItemRepository.findOne({ _id: id });
    if (!learningItem)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_LEARNING_ITEM.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    // Backfill id câu hỏi CHỈ trên bản đang sửa. Một tag là bất biến; ghi lại
    // bản đóng băng lên collection sẽ là ghi nội dung của tag lên bản đang
    // sửa của người khác.
    const needsExerciseId =
      !versionId &&
      this.ensureExerciseIdsInPayload(learningItem as Record<string, any>);

    if (needsExerciseId) {
      await this.learningItemRepository.updateOne(
        { _id: learningItem._id },
        learningItem as ILearningItem,
        this.user,
      );
    }

    // gán lại tag — chỉ load đúng các tag/keypoint/avatar được tham chiếu
    const toIdString = (value: any): string | null => {
      if (!value) return null;
      return typeof value === 'object'
        ? value._id?.toString?.() ?? null
        : value?.toString?.() ?? null;
    };

    // Thu thập trước toàn bộ id được tham chiếu để load theo lô.
    const tagIdSet = new Set<string>();
    const keypointIdSet = new Set<string>();
    const avatarIdSet = new Set<string>();

    const collectTagId = (items?: any[] | any) => {
      if (!items) return;
      const list = Array.isArray(items) ? items : [items];
      for (const item of list) {
        const tagId = toIdString(item?.tagId);
        if (tagId) tagIdSet.add(tagId);
      }
    };

    const hasRoleplay = Object.keys(learningItem.roleplay ?? {}).length > 0;
    if (hasRoleplay) {
      learningItem.roleplay.contents?.forEach(content => {
        if (content.type === RoleplayContentType.EXERCISE) {
          const keypointId = toIdString(content.exercise?.keypointId);
          if (keypointId) keypointIdSet.add(keypointId);
          collectTagId(content.exercise as any);
        }
        if (content.type === RoleplayContentType.CONVERSATION) {
          const avatarId = toIdString(content.conversation?.avatarId);
          if (avatarId) avatarIdSet.add(avatarId);
        }
      });
    }
    collectTagId(learningItem.documents);
    collectTagId(learningItem.questions);
    collectTagId(learningItem.subQuestions);

    const [tags, keypoints, avatars] = await Promise.all([
      this.tagRepository.findBriefByIds([...tagIdSet]).then(res => res.list),
      keypointIdSet.size
        ? this.keypointRepository.findBriefByIds([...keypointIdSet])
        : Promise.resolve([]),
      avatarIdSet.size
        ? this.avatarRepository
            .findBriefByIds([...avatarIdSet])
            .then(res => res.list)
        : Promise.resolve([]),
    ]);

    const tagMap = new Map(tags.map(tag => [tag._id.toString(), tag]));
    const keypointMap = new Map(keypoints.map(k => [k._id.toString(), k]));
    const avatar = new Map(avatars.map(a => [a._id.toString(), a]));

    const hydrateTag = (item?: any) => {
      if (!item) return;
      const tagId = toIdString(item.tagId);
      const found = tagId ? tagMap.get(tagId) ?? null : null;
      item.tag = found;
    };

    const enrichTag = (items?: any[] | any) => {
      if (!items) return;
      if (Array.isArray(items)) {
        for (const item of items) {
          hydrateTag(item);
        }
        return;
      }

      hydrateTag(items);
    };

    if (hasRoleplay) {
      learningItem.roleplay.contents?.forEach(content => {
        // gán lại thông tin keypoint
        if (content.type === RoleplayContentType.EXERCISE) {
          (content.exercise as any).keypoint =
            keypointMap.get(content.exercise.keypointId) ?? null;
        }

        // gán lại thông tin tag
        enrichTag(content.exercise as any);

        // gán lại thông tin avatar
        if (content.type === RoleplayContentType.CONVERSATION) {
          (content.conversation.avatar as any) =
            avatar.get(content.conversation.avatarId.toString()) || null;
        }
      });
    }

    enrichTag(learningItem.documents);
    enrichTag(learningItem.questions);
    enrichTag(learningItem.subQuestions);

    return learningItem;
  }

  async update(id: string, updateLearningItemDto: UpdateLearningItemDto) {
    const { title, keypointId } = updateLearningItemDto;
    const learningItem = await this.learningItemRepository.findOne({ _id: id });
    if (!learningItem)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_LEARNING_ITEM.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    if (title) {
      const titleByLang = getTranslationValue(title, this.lang);
      const mergedTitle = { ...(learningItem.title ?? {}), ...title };
      const targetKeypointId = keypointId || learningItem.keypointId;

      if (!titleByLang && !hasAnyTranslationValue(mergedTitle)) {
        throw new BadRequestException('title is required');
      }

      if (titleByLang) {
        // check title exits
        const titleExits = await this.learningItemRepository.checkExitsTitle(
          titleByLang,
          targetKeypointId,
          this.lang,
        );
        if (titleExits && titleExits._id.toString() !== id)
          throw new ConflictException(
            this.i18n.t('error.COURSE_LEARNING_ITEM.TITLE_EXISTS', {
              lang: this.lang,
            }),
          );
      }
    }

    const updatePayload = {
      ...updateLearningItemDto,
    } as Record<string, any>;

    this.ensureExerciseIdsInPayload(updatePayload);

    const update = await this.learningItemRepository.updateOne(
      { _id: id },
      updatePayload as ILearningItem,
      this.user,
    );

    return update;
  }

  async updateLearningItemIndex(dto: UpdateLearningItemIndexDto) {
    const { keypointId, learningItems } = dto;
    if (!learningItems?.length) return false;
    try {
      const bulkOps = learningItems.map(item => ({
        updateOne: {
          filter: { _id: item.id },
          update: { $set: { index: item.index, keypointId } },
        },
      }));
      await this.learningItemRepository.bulkWrite(bulkOps);
      return true;
    } catch (error) {
      throw error;
    }
  }

  /**
   * Deterministic full-sync computation for the daily warm-up rule. Shared by
   * preview (counts only) and apply (counts + persistence). See the plan's
   * "Rule" section: per lesson, order its EXERCISE folders by keypoint
   * position in `lesson.keypoints` then `index`; 1 folder -> tick all; 2+
   * folders -> tick the last folder only, untick the rest. Re-runnable and
   * idempotent — the second consecutive run produces zero changes.
   */
  private async computeDailyWarmUpTagging(): Promise<{
    result: DailyWarmUpTaggingResultDto;
    bulkOps: {
      updateOne: {
        filter: { _id: LearningItem['_id'] };
        update: { $set: { questions: ExerciseInput[] } };
      };
    }[];
  }> {
    const [lessons, folders] = await Promise.all([
      this.lessonRepository.findAllWithKeypoints(),
      this.learningItemRepository.findAllExerciseFolders(),
    ]);

    // Group exercise folders by keypoint, each group ordered by `index` asc
    // (with `_id` as a deterministic tiebreak when indexes collide from
    // data-entry mistakes).
    const foldersByKeypoint = new Map<string, LearningItem[]>();
    for (const folder of folders) {
      if (!folder.keypointId) continue;
      const group = foldersByKeypoint.get(folder.keypointId) ?? [];
      group.push(folder);
      foldersByKeypoint.set(folder.keypointId, group);
    }
    for (const group of foldersByKeypoint.values()) {
      group.sort(
        (a, b) =>
          (a.index ?? 0) - (b.index ?? 0) ||
          a._id.toString().localeCompare(b._id.toString()),
      );
    }

    // Desired uniform `isDailyWarmUp` value per folder id, driven by the rule.
    // A folder whose keypoint belongs to no lesson stays out of this map and
    // is therefore left untouched.
    const desiredByFolderId = new Map<string, boolean>();
    for (const lesson of lessons) {
      const keypointIds = (lesson.keypoints ?? []).filter(Boolean);
      const lessonFolders = keypointIds.flatMap(
        keypointId => foldersByKeypoint.get(keypointId) ?? [],
      );
      if (!lessonFolders.length) continue;

      if (lessonFolders.length === 1) {
        desiredByFolderId.set(lessonFolders[0]._id.toString(), true);
      } else {
        const lastIndex = lessonFolders.length - 1;
        lessonFolders.forEach((folder, index) => {
          desiredByFolderId.set(folder._id.toString(), index === lastIndex);
        });
      }
    }

    // Diff desired vs current; one bulkWrite op per folder whose questions
    // actually change (no-op folders are skipped to avoid pointless writes).
    let foldersChanged = 0;
    let questionsToTickOn = 0;
    let questionsToTickOff = 0;
    const bulkOps: {
      updateOne: {
        filter: { _id: LearningItem['_id'] };
        update: { $set: { questions: ExerciseInput[] } };
      };
    }[] = [];

    for (const folder of folders) {
      const folderId = folder._id.toString();
      if (!desiredByFolderId.has(folderId)) continue;

      const desired = desiredByFolderId.get(folderId);
      const questions = (folder.questions ?? []) as ExerciseInput[];

      let changed = false;
      const updatedQuestions = questions.map(question => {
        const current = !!question.isDailyWarmUp;
        if (current !== desired) {
          changed = true;
          if (desired) questionsToTickOn++;
          else questionsToTickOff++;
        }
        return { ...question, isDailyWarmUp: desired };
      }) as ExerciseInput[];

      if (!changed) continue;

      foldersChanged++;
      bulkOps.push({
        updateOne: {
          filter: { _id: folder._id },
          update: { $set: { questions: updatedQuestions } },
        },
      });
    }

    return {
      result: {
        lessonsScanned: lessons.length,
        foldersChanged,
        questionsToTickOn,
        questionsToTickOff,
      },
      bulkOps,
    };
  }

  async previewDailyWarmUpTagging(): Promise<DailyWarmUpTaggingResultDto> {
    const { result } = await this.computeDailyWarmUpTagging();
    return result;
  }

  async applyDailyWarmUpTagging(): Promise<DailyWarmUpTaggingResultDto> {
    const { result, bulkOps } = await this.computeDailyWarmUpTagging();
    if (bulkOps.length) {
      await this.learningItemRepository.bulkWrite(bulkOps);
    }
    return result;
  }

  async exportTheories() {
    return createMultiSheetTemplateWorkbook(
      await this.buildTheoryExportSheets(),
    );
  }

  /** `preloaded` exports a content tag rather than the working tree. */
  async buildTheoryExportSheets(keypointIds?: string[], preloaded?: any[]) {
    const items =
      preloaded ??
      (await this.learningItemRepository.findAllByTypeForExport(
        LearningItemType.THEORY,
        keypointIds,
      ));
    const theoryRows: any[][] = [];
    const documentRows: any[][] = [];
    const optionRows: any[][] = [];

    for (const item of items) {
      const itemId = item._id.toString();
      const baseCells = [
        itemId,
        item.keypointId ?? '',
        ...translationCells(item.title),
        ...translationCells(item.description),
        item.image ?? '',
        item.index ?? '',
      ];
      // Continuation rows repeat only the id: consecutive rows carrying the
      // same id are merged back into one item on import.
      const continuationCells = [
        itemId,
        '',
        ...translationCells(undefined),
        ...translationCells(undefined),
        '',
        '',
      ];
      const theoryDocuments = (item.documents ?? []) as ITheoryDocument[];

      if (!theoryDocuments.length) {
        theoryRows.push([...baseCells, `${itemId}_1`, '']);
        continue;
      }

      theoryDocuments.forEach((theoryDocument, docIndex) => {
        const theoryCode = `${itemId}_${docIndex + 1}`;
        theoryRows.push([
          ...(docIndex === 0 ? baseCells : continuationCells),
          theoryCode,
          theoryDocument.tagId ?? '',
        ]);

        for (const document of theoryDocument.document ?? []) {
          const options = document.data?.options ?? [];
          const explanationCode =
            document.type === DocumentType.EXPLANATION && options.length
              ? `${theoryCode}_e${document.id}`
              : '';
          documentRows.push([
            theoryCode,
            document.type ?? '',
            ...translationCells(document.data?.content),
            ...translationCells(document.data?.url),
            document.data?.thumbnail ?? '',
            explanationCode,
          ]);
          if (!explanationCode) continue;
          for (const option of options) {
            optionRows.push([
              explanationCode,
              option.icon ?? '',
              ...translationCells(option.value),
              ...translationCells(option.explanation),
            ]);
          }
        }
      });
    }

    return [
      {
        sheetName: 'theories',
        headers: [
          'id',
          'keypoint_id',
          ...translationHeaders('title'),
          ...translationHeaders('description'),
          'image',
          'index',
          'theory_code',
          'tag_id',
        ],
        sampleRows: theoryRows,
      },
      {
        sheetName: 'theory_documents',
        headers: [
          'theory_code',
          'document_type',
          ...translationHeaders('document_content'),
          ...translationHeaders('document_url'),
          'document_thumbnail',
          'explanation_code',
        ],
        sampleRows: documentRows,
      },
      {
        sheetName: 'theory_explanation_options',
        headers: [
          'explanation_code',
          'icon',
          ...translationHeaders('value'),
          ...translationHeaders('explanation'),
        ],
        sampleRows: optionRows,
      },
    ];
  }

  async exportExercises() {
    return createMultiSheetTemplateWorkbook(
      await this.buildExerciseExportSheets(),
    );
  }

  /** `preloaded` exports a content tag rather than the working tree. */
  async buildExerciseExportSheets(keypointIds?: string[], preloaded?: any[]) {
    const items =
      preloaded ??
      (await this.learningItemRepository.findAllByTypeForExport(
        LearningItemType.EXERCISE,
        keypointIds,
      ));
    const exerciseRows: any[][] = [];
    const documentRows: any[][] = [];
    const optionRows: any[][] = [];
    const documentGroupRows: any[][] = [];

    for (const item of items) {
      const itemId = item._id.toString();
      const questions = (item.questions ?? []) as any[];
      // The exercises sheet requires question_code/question_type on every
      // row, so an exercise without questions has no importable
      // representation — leaving it out keeps the exported file valid.
      if (!questions.length) continue;

      const baseCells = [
        itemId,
        item.keypointId ?? '',
        ...translationCells(item.title),
        ...translationCells(item.description),
        item.image ?? '',
        item.index ?? '',
      ];
      const continuationCells = [
        itemId,
        '',
        ...translationCells(undefined),
        ...translationCells(undefined),
        '',
        '',
      ];

      questions.forEach((question, questionIndex) => {
        const questionCode = `${itemId}_q${questionIndex + 1}`;
        exerciseRows.push([
          ...(questionIndex === 0 ? baseCells : continuationCells),
          questionCode,
          question.type ?? '',
          question.exerciseId ?? '',
          ...translationCells(question.explanation),
          (question.level ?? []).join('|'),
          question.maxScore ?? 0,
          question.isDailyWarmUp ? 'true' : 'false',
          question.form ?? '',
          ...translationCells(question.targetArea),
          question.record ?? '',
          question.maxDuration ?? '',
          question.maxCharacter ?? '',
        ]);

        for (const document of question.document ?? []) {
          documentRows.push([
            questionCode,
            document.type ?? '',
            ...translationCells(document.data?.content),
            ...translationCells(document.data?.url),
            document.data?.thumbnail ?? '',
          ]);
        }

        // Gap answers are re-associated positionally on import (the option
        // rows that carry answer values become the answer list, in order).
        const answers = (question.answer ?? []) as any[];
        (question.options ?? []).forEach((option: any, optionIndex: number) => {
          optionRows.push([
            questionCode,
            ...translationCells(option.value ?? option.text),
            option.isCorrect === undefined
              ? ''
              : option.isCorrect
              ? 'true'
              : 'false',
            option.documentGroupId ?? '',
            ...translationCells(answers[optionIndex]?.correctAnswer),
          ]);
        });

        for (const group of question.documentGroups ?? []) {
          for (const document of group.documents ?? []) {
            documentGroupRows.push([
              questionCode,
              group.id ?? '',
              document.type ?? '',
              ...translationCells(document.data?.content),
              ...translationCells(document.data?.url),
              document.data?.thumbnail ?? '',
            ]);
          }
        }
      });
    }

    return [
      {
        sheetName: 'exercises',
        headers: [
          'id',
          'keypoint_id',
          ...translationHeaders('title'),
          ...translationHeaders('description'),
          'image',
          'index',
          'question_code',
          'question_type',
          'exercise_id',
          ...translationHeaders('explanation'),
          'level',
          'max_score',
          'isDailyWarmUp',
          'drag_form',
          ...translationHeaders('target_area'),
          'record_url',
          'record_max_duration',
          'record_max_character',
        ],
        sampleRows: exerciseRows,
      },
      {
        sheetName: 'exercise_documents',
        headers: [
          'question_code',
          'document_type',
          ...translationHeaders('document_content'),
          ...translationHeaders('document_url'),
          'document_thumbnail',
        ],
        sampleRows: documentRows,
      },
      {
        sheetName: 'exercise_options',
        headers: [
          'question_code',
          ...translationHeaders('value'),
          'is_correct',
          'document_group_id',
          ...translationHeaders('answer'),
        ],
        sampleRows: optionRows,
      },
      {
        sheetName: 'exercise_document_groups',
        headers: [
          'question_code',
          'document_group_id',
          'document_type',
          ...translationHeaders('document_content'),
          ...translationHeaders('document_url'),
          'document_thumbnail',
        ],
        sampleRows: documentGroupRows,
      },
    ];
  }

  async importTheories(file: Express.Multer.File) {
    const workbook = await readWorkbook(file);
    const sheet = getSheet(workbook, ['theories'], true);
    const theoryRows = getRows(sheet);
    const documentRows = getRows(
      getSheet(workbook, ['theory_documents', 'documents']),
    );
    const optionRows = getRows(
      getSheet(workbook, ['theory_explanation_options', 'explanation_options']),
    );
    const groups = this.groupTheoryRows(theoryRows);
    const errors = await this.validateTheoryGroups(groups);
    this.validateTheoryDocumentOwners(errors, documentRows, theoryRows);
    this.validateExplanationOwners(errors, optionRows, documentRows);
    assertNoImportErrors(errors);

    for (const group of groups) {
      const id = text(group.firstRow.values.id);
      const theoryCodes = group.rows
        .map(row => text(row.values.theory_code))
        .filter(Boolean);
      const childRows = documentRows.filter(item =>
        theoryCodes.includes(text(item.values.theory_code)),
      );
      const existing = id
        ? await this.learningItemRepository.findOne({ _id: id })
        : null;
      const payload = await this.buildLearningItemBasePayload(
        group.firstRow.values,
        LearningItemType.THEORY,
        !id,
      );

      if (!id || childRows.length) {
        payload.documents = this.buildTheoryDocuments(
          group.rows,
          documentRows,
          optionRows,
        );
      }

      if (id) {
        await this.learningItemRepository.updateOne(
          { _id: id },
          payload as any,
          this.user,
        );
      } else {
        const created = await this.learningItemRepository.create(
          payload as any,
          this.user,
        );
        for (const row of group.rows) {
          setCellByHeader(sheet, row.rowNumber, 'id', created._id.toString());
        }
      }

      if (existing && !childRows.length) {
        continue;
      }
    }

    return workbookToBuffer(workbook);
  }

  async importExercises(file: Express.Multer.File) {
    const workbook = await readWorkbook(file);
    const sheet = getSheet(workbook, ['exercises'], true);
    const groups = groupExerciseRows(getRows(sheet));
    const documentRows = getRows(
      getSheet(workbook, ['exercise_documents', 'documents']),
    );
    const optionRows = getRows(getSheet(workbook, ['exercise_options']));
    const documentGroupRows = getRows(
      getSheet(workbook, ['exercise_document_groups', 'document_groups']),
    );
    const errors = await this.validateExerciseGroups(groups);
    this.validateChildOwners(
      errors,
      'exercise_documents',
      documentRows,
      'question_code',
      groups.flatMap(group => group.rows),
    );
    this.validateChildOwners(
      errors,
      'exercise_options',
      optionRows,
      'question_code',
      groups.flatMap(group => group.rows),
    );
    this.validateChildOwners(
      errors,
      'exercise_document_groups',
      documentGroupRows,
      'question_code',
      groups.flatMap(group => group.rows),
    );
    assertNoImportErrors(errors);

    for (const group of groups) {
      const id = text(group.firstRow.values.id);
      const existing = id
        ? await this.learningItemRepository.findOne({ _id: id })
        : null;
      const payload = await this.buildLearningItemBasePayload(
        group.firstRow.values,
        LearningItemType.EXERCISE,
        !id,
      );
      const hasChildRows = this.hasExerciseChildRows(
        group.rows,
        documentRows,
        optionRows,
        documentGroupRows,
      );

      if (!id || hasChildRows) {
        payload.questions = buildExerciseQuestions(
          group.rows,
          documentRows,
          optionRows,
          documentGroupRows,
          (existing?.questions ?? []) as ExerciseInput[],
          this.configService.get<string>('CLOUDFLARE_R2_CDN'),
        );
      }

      if (id) {
        await this.learningItemRepository.updateOne(
          { _id: id },
          payload as any,
          this.user,
        );
        continue;
      }

      const created = await this.learningItemRepository.create(
        payload as any,
        this.user,
      );
      for (const row of group.rows) {
        setCellByHeader(sheet, row.rowNumber, 'id', created._id.toString());
      }
    }

    return workbookToBuffer(workbook);
  }

  private async validateLearningItemRows(
    sheet: string,
    rows: ImportRow[],
  ): Promise<ImportValidationError[]> {
    const errors: ImportValidationError[] = [];

    for (const row of rows) {
      const id = text(row.values.id);
      if (id) {
        await this.validateExistingLearningItem(errors, sheet, row, id);
      } else {
        this.validateRequiredCreateFields(errors, sheet, row);
      }

      const keypointId = text(row.values.keypoint_id);
      if (keypointId) {
        await this.validateKeypoint(errors, sheet, row, keypointId);
      }
    }

    return errors;
  }

  private groupTheoryRows(rows: ImportRow[]) {
    const groups: TheoryGroup[] = [];
    let current: TheoryGroup | undefined;

    for (const row of rows) {
      const id = text(row.values.id);
      const startsItem =
        id ||
        text(row.values.keypoint_id) ||
        hasTranslationValueForPrefix(row.values, 'title');
      // Result files write the created id back onto every row of a group, so
      // consecutive rows carrying the same id are one item, not new ones.
      const continuesCurrent =
        id && current && text(current.firstRow.values.id) === id;

      if ((startsItem && !continuesCurrent) || !current) {
        current = { firstRow: row, rows: [] };
        groups.push(current);
      }

      current.rows.push(row);
    }

    return groups;
  }

  private async validateTheoryGroups(groups: TheoryGroup[]) {
    const errors = await this.validateLearningItemRows(
      'theories',
      groups.map(group => group.firstRow),
    );
    validateNoDuplicateValues(
      'theories',
      groups.map(group => group.firstRow),
      errors,
    );

    for (const group of groups) {
      for (const row of group.rows) {
        if (!text(row.values.theory_code)) {
          errors.push({
            sheet: 'theories',
            row: row.rowNumber,
            column: 'theory_code',
            message: 'theory_code is required',
          });
        }
      }
    }

    return errors;
  }

  private async validateExerciseGroups(
    groups: { firstRow: ImportRow; rows: ImportRow[] }[],
  ) {
    const errors = await this.validateLearningItemRows(
      'exercises',
      groups.map(group => group.firstRow),
    );
    validateNoDuplicateValues(
      'exercises',
      groups.map(group => group.firstRow),
      errors,
    );

    for (const group of groups) {
      for (const row of group.rows) {
        if (!text(row.values.question_code)) {
          errors.push({
            sheet: 'exercises',
            row: row.rowNumber,
            column: 'question_code',
            message: 'question_code is required',
          });
        }
        if (!text(row.values.question_type)) {
          errors.push({
            sheet: 'exercises',
            row: row.rowNumber,
            column: 'question_type',
            message: 'question_type is required',
          });
        }
      }
    }

    return errors;
  }

  private async validateExistingLearningItem(
    errors: ImportValidationError[],
    sheet: string,
    row: ImportRow,
    id: string,
  ) {
    if (!Types.ObjectId.isValid(id)) {
      errors.push({
        sheet,
        row: row.rowNumber,
        column: 'id',
        message: 'id is not a valid ObjectId',
      });
      return;
    }

    const existing = await this.learningItemRepository.findOne({ _id: id });
    if (!existing) {
      errors.push({
        sheet,
        row: row.rowNumber,
        column: 'id',
        message: 'learning item was not found',
      });
    }
  }

  private async validateKeypoint(
    errors: ImportValidationError[],
    sheet: string,
    row: ImportRow,
    keypointId: string,
  ) {
    if (!Types.ObjectId.isValid(keypointId)) {
      errors.push({
        sheet,
        row: row.rowNumber,
        column: 'keypoint_id',
        message: 'keypoint_id is not a valid ObjectId',
      });
      return;
    }

    const keypoint = await this.keypointRepository.findOne({ _id: keypointId });
    if (!keypoint) {
      errors.push({
        sheet,
        row: row.rowNumber,
        column: 'keypoint_id',
        message: 'keypoint was not found',
      });
    }
  }

  private validateRequiredCreateFields(
    errors: ImportValidationError[],
    sheet: string,
    row: ImportRow,
  ) {
    if (!text(row.values.keypoint_id)) {
      errors.push({
        sheet,
        row: row.rowNumber,
        column: 'keypoint_id',
        message: 'keypoint_id is required when creating',
      });
    }
    if (!hasTranslationValueForPrefix(row.values, 'title')) {
      errors.push({
        sheet,
        row: row.rowNumber,
        column: translationColumnLabel('title'),
        message:
          'At least one supported title translation is required when creating',
      });
    }
  }

  private validateChildOwners(
    errors: ImportValidationError[],
    sheet: string,
    childRows: ImportRow[],
    ownerColumn: string,
    parentRows: ImportRow[],
  ) {
    const owners = new Set(
      parentRows.map(row => text(row.values[ownerColumn])),
    );
    for (const row of childRows) {
      const owner = text(row.values[ownerColumn]);
      if (!owner || owners.has(owner)) continue;
      errors.push({
        sheet,
        row: row.rowNumber,
        column: ownerColumn,
        message: `${ownerColumn} does not exist in parent sheet`,
      });
    }
  }

  private validateTheoryDocumentOwners(
    errors: ImportValidationError[],
    documentRows: ImportRow[],
    theoryRows: ImportRow[],
  ) {
    const owners = new Set(
      theoryRows.map(row => text(row.values.theory_code)).filter(Boolean),
    );

    for (const row of documentRows) {
      const code = text(row.values.theory_code);
      if (!code || owners.has(code)) continue;
      errors.push({
        sheet: 'theory_documents',
        row: row.rowNumber,
        column: 'theory_code',
        message: 'theory_code does not exist in parent sheet',
      });
    }
  }

  private validateExplanationOwners(
    errors: ImportValidationError[],
    optionRows: ImportRow[],
    documentRows: ImportRow[],
  ) {
    const codes = new Set(
      documentRows
        .map(row => text(row.values.explanation_code))
        .filter(Boolean),
    );

    for (const row of optionRows) {
      const code = text(row.values.explanation_code);
      if (!code || codes.has(code)) continue;
      errors.push({
        sheet: 'theory_explanation_options',
        row: row.rowNumber,
        column: 'explanation_code',
        message: 'explanation_code does not exist in theory_documents',
      });
    }
  }

  private async buildLearningItemBasePayload(
    values: Record<string, any>,
    type: LearningItemType,
    isCreate: boolean,
  ) {
    const cdn = this.configService.get<string>('CLOUDFLARE_R2_CDN');
    const payload: Record<string, any> = {};
    const title = translationFromValues(values, 'title');
    const description = translationFromValues(values, 'description');
    const image = resolveAssetUrl(values.image, cdn);
    const keypointId = text(values.keypoint_id);
    const index = numberValue(values.index);

    if (isCreate) {
      payload.type = type;
      payload.index =
        index ?? (await this.learningItemRepository.getNextIndex(keypointId));
      if (title) payload.title = title;
      if (description) payload.description = description;
      if (keypointId) payload.keypointId = keypointId;
    } else {
      this.assignTranslationUpdate(payload, 'title', title);
      this.assignTranslationUpdate(payload, 'description', description);
      if (keypointId) payload.keypointId = keypointId;
      if (index !== undefined) payload.index = index;
    }
    if (image) payload.image = image;

    return payload;
  }

  private buildTheoryDocuments(
    theoryRows: ImportRow[],
    documentRows: ImportRow[],
    optionRows: ImportRow[],
  ): ITheoryDocument[] {
    return theoryRows
      .filter(row => text(row.values.theory_code))
      .map((row, index) => ({
        id: index + 1,
        tagId: text(row.values.tag_id),
        document: buildDocuments(
          documentRows,
          'theory_code',
          text(row.values.theory_code),
          this.configService.get<string>('CLOUDFLARE_R2_CDN'),
          optionRows,
        ),
      }));
  }

  private hasExerciseChildRows(
    rows: ImportRow[],
    documentRows: ImportRow[],
    optionRows: ImportRow[],
    documentGroupRows: ImportRow[],
  ) {
    const questionCodes = new Set(
      rows.map(row => text(row.values.question_code)).filter(Boolean),
    );
    const hasOwner = (row: ImportRow) =>
      questionCodes.has(text(row.values.question_code));

    return (
      documentRows.some(hasOwner) ||
      optionRows.some(hasOwner) ||
      documentGroupRows.some(hasOwner)
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

  async remove(id: string) {
    const learningItem = await this.learningItemRepository.findOne({ _id: id });
    if (!learningItem)
      throw new NotFoundException(
        this.i18n.t('error.COURSE_LEARNING_ITEM.NOT_FOUND', {
          lang: this.lang,
        }),
      );
    const res = await this.learningItemRepository.deleteOne({ _id: id });
    return res;
  }
}
