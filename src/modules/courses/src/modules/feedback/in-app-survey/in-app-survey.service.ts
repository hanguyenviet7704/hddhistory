import { randomUUID } from 'crypto';

import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import ExcelJS from 'exceljs';

import { RequestService } from '@base/service/request.service';
import { OrderType } from '@utils/type/orderByType';
import {
  assertNoImportErrors,
  createMultiSheetTemplateWorkbook,
  getRows,
  getSheet,
  ImportValidationError,
  numberValue,
  readWorkbook,
  text,
  translationColumnLabel,
  translationFromValues,
} from 'src/modules/courses/src/modules/import/excel-import.util';
import {
  UserRole,
  UserStatus,
} from 'src/modules/user/src/modules/auth/enum/user.enum';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import { GetInAppSurveyResponsesDto } from './dto/get-in-app-survey-responses.dto';
import {
  InAppSurveyBranchDto,
  InAppSurveyOptionDto,
  UpsertInAppSurveyConfigDto,
} from './dto/in-app-survey-config.dto';
import {
  ExportInAppSurveyResponsesDto,
  GetInAppSurveyBranchResponsesDto,
  GetInAppSurveyUserResponsesDto,
  InAppSurveyDateRangeDto,
  StartInAppSurveySessionDto,
} from './dto/in-app-survey-statistics.dto';
import { SubmitInAppSurveyResponseDto } from './dto/submit-in-app-survey-response.dto';
import { InAppSurveyClosedQuestionType } from './enum/in-app-survey.enum';
import {
  IInAppSurveyBranch,
  IInAppSurveyClosedQuestion,
  IInAppSurveyConfig,
  IInAppSurveyOption,
  IInAppSurveyUserSnapshot,
} from './interface/in-app-survey.interface';
import { InAppSurveyConfigRepository } from './repository/in-app-survey-config.repository';
import { InAppSurveyResponseRepository } from './repository/in-app-survey-response.repository';
import { InAppSurveySessionRepository } from './repository/in-app-survey-session.repository';
import { IN_APP_SURVEY_CONFIG_KEY } from './schema/in-app-survey-config.schema';

interface DateRange {
  startDate: Date;
  endDate: Date;
  previousStartDate: Date;
  previousEndDate: Date;
}

const SURVEY_LANGS = ['vi', 'en', 'zh', 'ja', 'ko'] as const;

const SURVEY_SHEET_HEADERS = [
  'question_vi',
  'question_en',
  'question_zh',
  'question_ja',
  'question_ko',
  'guide_vi',
  'guide_en',
  'guide_zh',
  'guide_ja',
  'guide_ko',
];

const BRANCH_SHEET_HEADERS = [
  'branch_key',
  'emoji_name',
  'emoji_darkUrl',
  'emoji_lightUrl',
  'closedType',
  'index',
  'score',
  'closedQuestion_vi',
  'closedQuestion_en',
  'closedQuestion_zh',
  'closedQuestion_ja',
  'closedQuestion_ko',
  'closedGuide_vi',
  'closedGuide_en',
  'closedGuide_zh',
  'closedGuide_ja',
  'closedGuide_ko',
  'openQuestion_vi',
  'openQuestion_en',
  'openQuestion_zh',
  'openQuestion_ja',
  'openQuestion_ko',
  'openGuide_vi',
  'openGuide_en',
  'openGuide_zh',
  'openGuide_ja',
  'openGuide_ko',
];

const OPTION_SHEET_HEADERS = [
  'branch_key',
  'option_id',
  'icon',
  'value_vi',
  'value_en',
  'value_zh',
  'value_ja',
  'value_ko',
];

const surveyTrCells = (value?: Record<string, string>) =>
  SURVEY_LANGS.map(lang => value?.[lang] ?? '');

const SAMPLE_SURVEY_IMPORT_ROWS: {
  survey: any[][];
  branches: any[][];
  options: any[][];
} = {
  survey: [
    [
      'Trải nghiệm của bạn thế nào?',
      'How was your experience?',
      '你的体验如何？',
      'ご利用体験はいかがでしたか？',
      '경험이 어떠셨나요?',
      'Chọn cảm xúc phù hợp',
      'Pick what feels right',
      '选择合适的表情',
      'しっくりくるものを選んでください',
      '맞는 것을 선택하세요',
    ],
  ],
  branches: [
    [
      'angry',
      'Angry',
      'https://cdn.example.com/emoji/angry-dark.png',
      'https://cdn.example.com/emoji/angry-light.png',
      'multiple_choice',
      1,
      1,
      'Điều gì chưa ổn?',
      "What's not working?",
      '哪里不对劲？',
      '何がうまくいきませんか？',
      '무엇이 잘못되었나요?',
      'Chọn tất cả mục phù hợp',
      'Tap all that apply',
      '选择所有适用项',
      '当てはまるものをすべて選択',
      '해당하는 항목을 모두 선택',
      'Điều gì sẽ giúp bạn quay lại?',
      'What would bring you back?',
      '什么会让你回来？',
      '何があれば戻ってきますか？',
      '무엇이 당신을 다시 오게 할까요?',
      '',
      '',
      '',
      '',
      '',
    ],
    [
      'happy',
      'Happy',
      'https://cdn.example.com/emoji/happy-dark.png',
      'https://cdn.example.com/emoji/happy-light.png',
      'multiple_choice',
      2,
      5,
      'Bạn thích điều gì nhất?',
      'What did you like most?',
      '你最喜欢什么？',
      '何が一番気に入りましたか？',
      '무엇이 가장 좋았나요?',
      '',
      '',
      '',
      '',
      '',
      'Chúng tôi có thể làm gì tốt hơn?',
      'What could we do even better?',
      '我们可以做得更好的是什么？',
      'さらに改善できる点は何ですか？',
      '무엇을 더 잘할 수 있을까요?',
      '',
      '',
      '',
      '',
      '',
    ],
  ],
  options: [
    [
      'angry',
      '',
      'https://cdn.example.com/icon/bug.png',
      'Quá nhiều lỗi',
      'Too many bugs',
      '太多错误',
      'バグが多すぎる',
      '버그가 너무 많아요',
    ],
    [
      'angry',
      '',
      'https://cdn.example.com/icon/slow.png',
      'Ứng dụng chậm',
      'The app is slow',
      '应用很慢',
      'アプリが遅い',
      '앱이 느려요',
    ],
    [
      'happy',
      '',
      'https://cdn.example.com/icon/content.png',
      'Nội dung hữu ích',
      'Helpful content',
      '内容有用',
      '役立つコンテンツ',
      '유용한 콘텐츠',
    ],
  ],
};

@Injectable()
export class InAppSurveyService {
  constructor(
    private readonly configRepository: InAppSurveyConfigRepository,
    private readonly responseRepository: InAppSurveyResponseRepository,
    private readonly sessionRepository: InAppSurveySessionRepository,
    private readonly requestService: RequestService,
    private readonly userRepository: UserRepository,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  private get currentUserId() {
    return this.user?.id;
  }

  async getConfig() {
    const config = await this.configRepository.findDefault();
    if (!config) {
      return {
        configKey: IN_APP_SURVEY_CONFIG_KEY,
        introQuestion: {
          question: {},
          guide: {},
        },
        branches: [] as IInAppSurveyBranch[],
      };
    }

    return this.normalizeConfigResponse(config);
  }

  async upsertConfig(dto: UpsertInAppSurveyConfigDto) {
    const now = new Date();
    const payload = this.buildConfigPayload(dto);
    const { configKey: _configKey, ...configPayload } = payload;

    return this.configRepository.upsertDefault({
      $set: {
        ...configPayload,
        updatedBy: this.user,
        updatedAt: now,
      },
      $setOnInsert: {
        configKey: IN_APP_SURVEY_CONFIG_KEY,
        createdBy: this.user,
        createdAt: now,
      },
    });
  }

  async getSurveyImportTemplate() {
    // If a survey already exists, return its current content (with branch_key
    // and option_id filled in) so editors can download → edit → re-import.
    // Otherwise return a blank sample template.
    const existing = await this.configRepository.findDefault();
    const rows =
      existing?.branches?.length || existing?.introQuestion
        ? this.configToImportRows(existing)
        : SAMPLE_SURVEY_IMPORT_ROWS;
    return this.buildSurveyImportWorkbook(rows);
  }

  private buildSurveyImportWorkbook(rows: {
    survey: any[][];
    branches: any[][];
    options: any[][];
  }) {
    return createMultiSheetTemplateWorkbook([
      {
        sheetName: 'survey',
        headers: SURVEY_SHEET_HEADERS,
        sampleRows: rows.survey,
      },
      {
        sheetName: 'branches',
        headers: BRANCH_SHEET_HEADERS,
        sampleRows: rows.branches,
      },
      {
        sheetName: 'options',
        headers: OPTION_SHEET_HEADERS,
        sampleRows: rows.options,
      },
    ]);
  }

  private configToImportRows(config: any): {
    survey: any[][];
    branches: any[][];
    options: any[][];
  } {
    const survey = [
      [
        ...surveyTrCells(config?.introQuestion?.question),
        ...surveyTrCells(config?.introQuestion?.guide),
      ],
    ];
    const branches: any[][] = [];
    const options: any[][] = [];

    (config?.branches ?? []).forEach((branch: any, index: number) => {
      branches.push([
        branch.id ?? '',
        branch.emoji?.name ?? '',
        branch.emoji?.darkUrl ?? '',
        branch.emoji?.lightUrl ?? '',
        branch.closedQuestion?.type ??
          InAppSurveyClosedQuestionType.MULTIPLE_CHOICE,
        branch.index ?? index + 1,
        branch.score ?? index + 1,
        ...surveyTrCells(branch.closedQuestion?.question),
        ...surveyTrCells(branch.closedQuestion?.guide),
        ...surveyTrCells(branch.openQuestion?.question),
        ...surveyTrCells(branch.openQuestion?.guide),
      ]);

      (branch.closedQuestion?.options ?? []).forEach((option: any) => {
        options.push([
          branch.id ?? '',
          option.id ?? '',
          option.icon ?? '',
          ...surveyTrCells(option.value),
        ]);
      });
    });

    return { survey, branches, options };
  }

  async importSurvey(file: Express.Multer.File) {
    const workbook = await readWorkbook(file);
    const surveySheet = getSheet(workbook, ['survey'], true);
    const branchSheet = getSheet(workbook, ['branches'], true);
    const optionSheet = getSheet(workbook, ['options'], true);
    const surveyRows = getRows(surveySheet);
    const branchRows = getRows(branchSheet);
    const optionRows = getRows(optionSheet);
    const errors: ImportValidationError[] = [];

    // Existing config — import is additive (merge), not a full replace.
    const existing = await this.configRepository.findDefault();
    const existingIntro = existing?.introQuestion;
    const existingBranches: IInAppSurveyBranch[] = existing?.branches ?? [];
    const hasExistingIntro =
      !!existingIntro?.question &&
      Object.values(existingIntro.question).some(value => !!value);

    // --- intro question (optional: keep existing when blank) ---
    const introRow = surveyRows[0];
    const introQuestion = translationFromValues(
      introRow?.values ?? {},
      'question',
    );
    const introGuide = translationFromValues(introRow?.values ?? {}, 'guide');
    if (!introQuestion && !hasExistingIntro) {
      errors.push({
        sheet: 'survey',
        row: introRow?.rowNumber ?? 2,
        column: translationColumnLabel('question'),
        message: 'At least one intro question translation is required',
      });
    }

    // --- options grouped by branch_key ---
    const optionsByBranch = new Map<string, InAppSurveyOptionDto[]>();
    for (const row of optionRows) {
      const branchKey = text(row.values.branch_key);
      if (!branchKey) {
        errors.push({
          sheet: 'options',
          row: row.rowNumber,
          column: 'branch_key',
          message: 'branch_key is required',
        });
        continue;
      }
      const icon = text(row.values.icon);
      const value = translationFromValues(row.values, 'value');
      if (!icon) {
        errors.push({
          sheet: 'options',
          row: row.rowNumber,
          column: 'icon',
          message: 'icon is required',
        });
      }
      if (!value) {
        errors.push({
          sheet: 'options',
          row: row.rowNumber,
          column: translationColumnLabel('value'),
          message: 'At least one option value translation is required',
        });
      }
      const list = optionsByBranch.get(branchKey) ?? [];
      list.push({
        ...(text(row.values.option_id)
          ? { id: text(row.values.option_id) }
          : {}),
        icon,
        value: value ?? {},
      });
      optionsByBranch.set(branchKey, list);
    }

    // --- branches ---
    const branchKeys = new Set<string>();
    const branches: Array<InAppSurveyBranchDto & { _index: number }> = [];
    for (const row of branchRows) {
      const branchKey = text(row.values.branch_key);
      if (!branchKey) {
        errors.push({
          sheet: 'branches',
          row: row.rowNumber,
          column: 'branch_key',
          message: 'branch_key is required',
        });
        continue;
      }
      if (branchKeys.has(branchKey)) {
        errors.push({
          sheet: 'branches',
          row: row.rowNumber,
          column: 'branch_key',
          message: 'branch_key must be unique',
        });
        continue;
      }
      branchKeys.add(branchKey);

      const darkUrl = text(row.values.emoji_darkUrl);
      if (!darkUrl) {
        errors.push({
          sheet: 'branches',
          row: row.rowNumber,
          column: 'emoji_darkUrl',
          message: 'emoji_darkUrl is required',
        });
      }

      const closedQuestion = translationFromValues(
        row.values,
        'closedQuestion',
      );
      if (!closedQuestion) {
        errors.push({
          sheet: 'branches',
          row: row.rowNumber,
          column: translationColumnLabel('closedQuestion'),
          message: 'At least one closed question translation is required',
        });
      }

      const openQuestion = translationFromValues(row.values, 'openQuestion');
      if (!openQuestion) {
        errors.push({
          sheet: 'branches',
          row: row.rowNumber,
          column: translationColumnLabel('openQuestion'),
          message: 'At least one open question translation is required',
        });
      }

      const closedType = text(row.values.closedType);
      if (
        closedType &&
        !Object.values(InAppSurveyClosedQuestionType).includes(
          closedType as InAppSurveyClosedQuestionType,
        )
      ) {
        errors.push({
          sheet: 'branches',
          row: row.rowNumber,
          column: 'closedType',
          message: `closedType must be one of: ${Object.values(
            InAppSurveyClosedQuestionType,
          ).join(', ')}`,
        });
      }

      const options = optionsByBranch.get(branchKey) ?? [];
      if (!options.length) {
        errors.push({
          sheet: 'branches',
          row: row.rowNumber,
          column: 'branch_key',
          message: `branch "${branchKey}" has no options in the options sheet`,
        });
      }

      branches.push({
        id: branchKey,
        emoji: {
          ...(text(row.values.emoji_name)
            ? { name: text(row.values.emoji_name) }
            : {}),
          darkUrl,
          ...(text(row.values.emoji_lightUrl)
            ? { lightUrl: text(row.values.emoji_lightUrl) }
            : {}),
        },
        closedQuestion: {
          question: closedQuestion ?? {},
          guide: translationFromValues(row.values, 'closedGuide'),
          type: (closedType as InAppSurveyClosedQuestionType) || undefined,
          options,
        },
        openQuestion: {
          question: openQuestion ?? {},
          guide: translationFromValues(row.values, 'openGuide'),
        },
        score: numberValue(row.values.score),
        _index: numberValue(row.values.index) ?? branches.length + 1,
      });
    }

    // options referencing a branch_key that doesn't exist
    for (const branchKey of optionsByBranch.keys()) {
      if (!branchKeys.has(branchKey)) {
        errors.push({
          sheet: 'options',
          row: 0,
          column: 'branch_key',
          message: `branch_key "${branchKey}" was not found in the branches sheet`,
        });
      }
    }

    if (!branches.length && !existingBranches.length) {
      errors.push({
        sheet: 'branches',
        row: 2,
        message: 'At least one branch is required',
      });
    }

    assertNoImportErrors(errors);

    const orderedBranches = branches
      .sort((a, b) => a._index - b._index)
      .map(({ _index, ...branch }) => branch);

    // Merge by branch id (= branch_key): update matching existing branches,
    // append new ones, and keep existing branches not present in the file.
    const importedById = new Map(
      orderedBranches.map(branch => [branch.id, branch]),
    );
    const usedIds = new Set<string>();
    const mergedBranches: any[] = [];
    for (const existingBranch of existingBranches) {
      const existingId = (existingBranch.id ?? '').toString();
      if (importedById.has(existingId)) {
        mergedBranches.push(importedById.get(existingId));
        usedIds.add(existingId);
      } else {
        mergedBranches.push(existingBranch);
      }
    }
    for (const importedBranch of orderedBranches) {
      if (!usedIds.has(importedBranch.id as string)) {
        mergedBranches.push(importedBranch);
      }
    }

    const finalIntroQuestion = introQuestion
      ? { question: introQuestion, guide: introGuide }
      : {
          question: existingIntro?.question ?? {},
          guide: existingIntro?.guide,
        };

    await this.upsertConfig({
      introQuestion: finalIntroQuestion,
      branches: mergedBranches,
    } as UpsertInAppSurveyConfigDto);

    // Return a full snapshot of the saved survey (branch_key + option_id
    // filled with the stored ids) so the editor can edit and re-import it.
    const saved = await this.configRepository.findDefault();
    return this.buildSurveyImportWorkbook(
      this.configToImportRows(
        saved ?? {
          introQuestion: finalIntroQuestion,
          branches: mergedBranches,
        },
      ),
    );
  }

  async startSession(dto: StartInAppSurveySessionDto) {
    const userId = this.currentUserId;
    if (!userId) {
      throw new BadRequestException('userId is required');
    }

    return this.sessionRepository.create(
      {
        userId,
        userSnapshot: this.buildUserSnapshot(),
        configKey: IN_APP_SURVEY_CONFIG_KEY,
        startedAt: dto.startedAt ? new Date(dto.startedAt) : new Date(),
      },
      this.user,
    );
  }

  async submitResponse(dto: SubmitInAppSurveyResponseDto) {
    const userId = this.currentUserId;
    if (!userId) {
      throw new BadRequestException('userId is required');
    }

    const config = await this.getConfig();
    const branch = config.branches?.find(item => item.id === dto.branchId);
    if (!branch) {
      throw new NotFoundException('in-app survey branch not found');
    }

    const selectedOptions = this.resolveSelectedOptions(
      branch.closedQuestion.options ?? [],
      dto.selectedOptionIds,
    );
    this.validateClosedQuestionSelection(
      branch.closedQuestion,
      selectedOptions,
    );

    const now = new Date();
    const ratingScore = this.resolveBranchScore(branch);
    const response = await this.responseRepository.create(
      {
        userId,
        userSnapshot: this.buildUserSnapshot(),
        branchId: branch.id,
        branchIndex: branch.index,
        branchName: branch.emoji.name,
        ratingScore,
        introQuestion: config.introQuestion,
        branch: {
          emoji: branch.emoji,
          closedQuestion: {
            question: branch.closedQuestion.question,
            guide: branch.closedQuestion.guide,
            type: branch.closedQuestion.type,
          },
          openQuestion: branch.openQuestion,
        },
        selectedOptions,
        feedback: dto.feedback,
        submittedAt: now,
        completedAt: now,
      },
      this.user,
    );

    await this.completeOrCreateSession(dto.sessionId, {
      userId,
      responseId: String((response as any)._id),
      branchId: branch.id,
      ratingScore,
      completedAt: now,
    });

    return response;
  }

  async getMyResponses() {
    const userId = this.currentUserId;
    if (!userId) {
      throw new BadRequestException('userId is required');
    }

    return this.getResponsesByUserId(userId);
  }

  async getResponsesByUserId(userId: string) {
    if (!userId) {
      throw new BadRequestException('userId is required');
    }

    return this.responseRepository.findByUserId(userId);
  }

  async getResponses(dto: GetInAppSurveyResponsesDto) {
    return this.responseRepository.findAll(dto);
  }

  async getStatisticsOverview(dto: InAppSurveyDateRangeDto) {
    const range = this.resolveDateRange(dto);
    const config = await this.getConfig();
    const configuredBranches = this.getConfiguredBranches(config);
    const scoreByBranch = new Map(
      configuredBranches.map(branch => [branch.branchId, branch.ratingScore]),
    );
    const scoreByBranchIndex = new Map(
      configuredBranches.map(branch => [branch.branchIndex, branch.ratingScore]),
    );
    const [current, previous, ratingDistribution, optionDistribution, totalUsers] =
      await Promise.all([
        this.getMetricSummary(
          range.startDate,
          range.endDate,
          scoreByBranch,
          scoreByBranchIndex,
        ),
        this.getMetricSummary(
          range.previousStartDate,
          range.previousEndDate,
          scoreByBranch,
          scoreByBranchIndex,
        ),
        this.getRatingDistribution(
          range.startDate,
          range.endDate,
          configuredBranches,
        ),
        this.getOptionDistribution(range.startDate, range.endDate),
        this.countActiveUsers(),
      ]);

    const responseRate =
      totalUsers > 0 ? this.roundPercent(current.distinctUsers / totalUsers) : 0;
    const previousResponseRate =
      totalUsers > 0
        ? this.roundPercent(previous.distinctUsers / totalUsers)
        : 0;
    const branches = await this.getBranchSummaries(
      range.startDate,
      range.endDate,
      ratingDistribution,
      optionDistribution,
      current.totalResponses,
    );

    return {
      range,
      metrics: {
        totalResponses: {
          value: current.totalResponses,
          delta: this.calculateDeltaPercent(
            current.totalResponses,
            previous.totalResponses,
          ),
        },
        averageRating: {
          value: current.averageRating,
          delta: this.roundNumber(
            current.averageRating - previous.averageRating,
          ),
        },
        completionRate: {
          value: current.completionRate,
          delta: this.roundNumber(
            current.completionRate - previous.completionRate,
          ),
        },
        responseRate: {
          value: responseRate,
          delta: this.roundNumber(responseRate - previousResponseRate),
        },
      },
      ratingDistribution: ratingDistribution.map(item => ({
        ...item,
        percent: this.percentOf(item.count, current.totalResponses),
      })),
      branches,
    };
  }

  async getBranchResponses(
    branchId: string,
    dto: GetInAppSurveyBranchResponsesDto,
  ) {
    const range = this.resolveDateRange(dto);
    const config = await this.getConfig();
    const configuredBranch = this.getConfiguredBranches(config).find(
      branch => branch.branchId === branchId,
    );
    const page = Math.max(Number(dto.page) || 1, 1);
    const take = Math.max(Number(dto.take) || 20, 1);
    const where: any = {
      submittedAt: { $gte: range.startDate, $lte: range.endDate },
      ...this.buildBranchWhere(branchId, configuredBranch),
    };
    if (dto.optionId) {
      where['selectedOptions.id'] = dto.optionId;
    }
    if (dto.search?.trim()) {
      where.feedback = { $regex: this.escapeRegex(dto.search), $options: 'i' };
    }

    const [items, total, optionCounts, branchInfo] = await Promise.all([
      this.responseRepository.model
        .find(where)
        .sort({ submittedAt: dto.order === OrderType.ASC ? 1 : -1 })
        .skip((page - 1) * take)
        .limit(take)
        .lean(),
      this.responseRepository.model.countDocuments(where),
      this.getOptionDistribution(range.startDate, range.endDate, {
        branchId,
        ratingScore: configuredBranch?.ratingScore,
        branchIndex: configuredBranch?.branchIndex,
      }),
      this.responseRepository.model
        .findOne({
          ...this.buildBranchWhere(branchId, configuredBranch),
        })
        .sort({ submittedAt: -1 })
        .lean(),
    ]);

    return {
      branch: configuredBranch ?? this.mapResponseBranch(branchInfo),
      optionFilters: optionCounts.map(item => ({
        option: item.option,
        count: item.count,
      })),
      items,
      total,
      totalPages: Math.ceil(total / take) || 1,
      currentPage: page,
      itemsPerPage: take,
    };
  }

  async getUserResponses(dto: GetInAppSurveyUserResponsesDto) {
    const range = this.resolveDateRange(dto);
    const config = await this.getConfig();
    const configuredBranches = this.getConfiguredBranches(config);
    const page = Math.max(Number(dto.page) || 1, 1);
    const take = Math.max(Number(dto.take) || 20, 1);
    const where: any = {
      submittedAt: { $gte: range.startDate, $lte: range.endDate },
    };
    if (dto.branchId) {
      where.branchId = dto.branchId;
    }
    if (dto.search?.trim()) {
      const search = { $regex: this.escapeRegex(dto.search), $options: 'i' };
      where.$or = [
        { userId: search },
        { 'userSnapshot.name': search },
        { 'userSnapshot.email': search },
        { feedback: search },
      ];
    }

    const sortDirection = dto.order === OrderType.ASC ? 1 : -1;
    const [items, total, branchFilters, distinctUsers] = await Promise.all([
      this.responseRepository.model
        .find(where)
        .sort({ submittedAt: sortDirection })
        .skip((page - 1) * take)
        .limit(take)
        .lean(),
      this.responseRepository.model.countDocuments(where),
      this.getRatingDistribution(
        range.startDate,
        range.endDate,
        configuredBranches,
      ),
      this.responseRepository.model.distinct('userId', where),
    ]);

    return {
      branchFilters,
      distinctUsers: distinctUsers.length,
      items,
      total,
      totalPages: Math.ceil(total / take) || 1,
      currentPage: page,
      itemsPerPage: take,
    };
  }

  async exportResponses(dto: ExportInAppSurveyResponsesDto) {
    const responses = await this.findExportResponses(dto);
    const lang = dto.lang || 'vi';

    return responses.map((item: any) => this.mapExportResponse(item, lang));
  }

  async exportResponsesWorkbook(dto: ExportInAppSurveyResponsesDto) {
    const rows = await this.exportResponses(dto);
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('in-app-survey');

    sheet.columns = [
      { header: 'User ID', key: 'user_id', width: 28 },
      { header: 'User Name', key: 'user_name', width: 24 },
      { header: 'User Email', key: 'user_email', width: 32 },
      { header: 'Emoji Level', key: 'emoji_level', width: 14 },
      { header: 'Emoji Name', key: 'emoji_name', width: 20 },
      { header: 'Selected Options', key: 'selected_options', width: 48 },
      { header: 'Feedback', key: 'feedback', width: 48 },
      { header: 'Submitted At', key: 'submitted_at', width: 22 },
    ];

    sheet.getRow(1).font = { bold: true };
    sheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };
    sheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFE2E8F0' },
    };

    for (const row of rows) {
      sheet.addRow(row);
    }

    sheet.views = [{ state: 'frozen', ySplit: 1 }];
    sheet.autoFilter = {
      from: 'A1',
      to: 'H1',
    };
    sheet.getColumn('submitted_at').numFmt = 'yyyy-mm-dd hh:mm:ss';
    sheet.getColumn('selected_options').alignment = { wrapText: true };
    sheet.getColumn('feedback').alignment = { wrapText: true };

    const output = await workbook.xlsx.writeBuffer();
    return Buffer.from(output);
  }

  private async findExportResponses(dto: ExportInAppSurveyResponsesDto) {
    const range = this.resolveDateRange(dto);
    const where: any = {
      submittedAt: { $gte: range.startDate, $lte: range.endDate },
    };
    if (dto.branchId) {
      where.branchId = dto.branchId;
    }

    return this.responseRepository.model
      .find(where)
      .sort({ submittedAt: -1 })
      .lean();
  }

  private mapExportResponse(item: any, lang: string) {
    return {
      user_id: item.userId,
      user_name: item.userSnapshot?.name ?? '',
      user_email: item.userSnapshot?.email ?? '',
      emoji_level: item.ratingScore ?? (item.branchIndex ?? 0) + 1,
      emoji_name: item.branchName ?? item.branch?.emoji?.name ?? '',
      selected_options: (item.selectedOptions ?? [])
        .map((option: IInAppSurveyOption) =>
          this.getTranslationValue(option.value, lang),
        )
        .filter(Boolean)
        .join('; '),
      feedback: item.feedback ?? '',
      submitted_at: item.submittedAt ?? item.createdAt ?? null,
    };
  }

  private buildConfigPayload(
    dto: UpsertInAppSurveyConfigDto,
  ): IInAppSurveyConfig {
    return {
      configKey: IN_APP_SURVEY_CONFIG_KEY,
      introQuestion: dto.introQuestion,
      branches: this.normalizeBranches(dto.branches),
    };
  }

  private normalizeBranches(branches: InAppSurveyBranchDto[]) {
    const branchIds = new Set<string>();

    return branches.map((branch, index): IInAppSurveyBranch => {
      const id = branch.id?.trim() || randomUUID();
      if (branchIds.has(id)) {
        throw new BadRequestException('branch ids must be unique');
      }
      branchIds.add(id);

      return {
        id,
        emoji: {
          ...(branch.emoji.name?.trim()
            ? { name: branch.emoji.name.trim() }
            : {}),
          darkUrl: branch.emoji.darkUrl.trim(),
          ...(branch.emoji.lightUrl?.trim()
            ? { lightUrl: branch.emoji.lightUrl.trim() }
            : {}),
        },
        closedQuestion: {
          question: branch.closedQuestion.question,
          guide: branch.closedQuestion.guide,
          type:
            branch.closedQuestion.type ??
            InAppSurveyClosedQuestionType.MULTIPLE_CHOICE,
          options: this.normalizeOptions(branch.closedQuestion.options),
        },
        openQuestion: branch.openQuestion,
        index,
        score: branch.score ?? index + 1,
      };
    });
  }

  private normalizeOptions(options: InAppSurveyOptionDto[]) {
    const optionIds = new Set<string>();

    return options.map(option => {
      const id = option.id?.trim() || randomUUID();
      if (optionIds.has(id)) {
        throw new BadRequestException('option ids must be unique per branch');
      }
      optionIds.add(id);

      return {
        id,
        icon: option.icon,
        value: option.value,
      };
    });
  }

  private normalizeConfigResponse(config: any): IInAppSurveyConfig {
    return {
      ...config,
      branches: (config.branches ?? []).map((branch: any, index: number) => {
        const { url: _legacyUrl, ...emoji } = branch.emoji ?? {};

        return {
          ...branch,
          index: branch.index ?? index,
          score: branch.score ?? (branch.index ?? index) + 1,
          emoji: {
            ...emoji,
            darkUrl: emoji.darkUrl ?? _legacyUrl ?? '',
          },
        };
      }),
    };
  }

  private resolveSelectedOptions(
    options: IInAppSurveyOption[],
    selectedOptionIds: string[],
  ) {
    const uniqueSelectedIds = [...new Set(selectedOptionIds)];
    const optionById = new Map(options.map(option => [option.id, option]));

    const invalidIds = uniqueSelectedIds.filter(id => !optionById.has(id));
    if (invalidIds.length > 0) {
      throw new BadRequestException('selectedOptionIds contains invalid id');
    }

    return uniqueSelectedIds.map(id => optionById.get(id)!);
  }

  private validateClosedQuestionSelection(
    closedQuestion: IInAppSurveyClosedQuestion,
    selectedOptions: IInAppSurveyOption[],
  ) {
    if (
      closedQuestion.type === InAppSurveyClosedQuestionType.SINGLE_CHOICE &&
      selectedOptions.length > 1
    ) {
      throw new BadRequestException(
        'single_choice closed question accepts only one selected option',
      );
    }
  }

  private buildUserSnapshot(): IInAppSurveyUserSnapshot | null {
    const snapshot = {
      ...(this.user?.name ? { name: this.user.name } : {}),
      ...(this.user?.email ? { email: this.user.email } : {}),
      ...(this.user?.avatar ? { avatar: this.user.avatar } : {}),
    };

    return Object.keys(snapshot).length ? snapshot : null;
  }

  private async completeOrCreateSession(
    sessionId: string | undefined,
    update: {
      userId: string;
      responseId: string;
      branchId: string;
      ratingScore: number;
      completedAt: Date;
    },
  ) {
    if (sessionId) {
      const completed = await this.sessionRepository.completeSession(sessionId, {
        responseId: update.responseId,
        branchId: update.branchId,
        ratingScore: update.ratingScore,
        completedAt: update.completedAt,
      });
      if (completed) return completed;
    }

    return this.sessionRepository.create(
      {
        userId: update.userId,
        userSnapshot: this.buildUserSnapshot(),
        configKey: IN_APP_SURVEY_CONFIG_KEY,
        startedAt: update.completedAt,
        completedAt: update.completedAt,
        responseId: update.responseId,
        branchId: update.branchId,
        ratingScore: update.ratingScore,
      },
      this.user,
    );
  }

  private resolveBranchScore(branch: IInAppSurveyBranch) {
    return branch.score ?? branch.index + 1;
  }

  private resolveDateRange(dto: InAppSurveyDateRangeDto): DateRange {
    const endDate = dto.endDate
      ? this.parseDateRangeBoundary(dto.endDate, 'end')
      : new Date();
    const startDate = dto.startDate
      ? this.parseDateRangeBoundary(dto.startDate, 'start')
      : new Date(endDate.getTime() - 30 * 24 * 60 * 60 * 1000);
    if (startDate > endDate) {
      throw new BadRequestException('startDate must be before endDate');
    }
    const duration = endDate.getTime() - startDate.getTime();

    return {
      startDate,
      endDate,
      previousStartDate: new Date(startDate.getTime() - duration),
      previousEndDate: new Date(startDate.getTime()),
    };
  }

  private parseDateRangeBoundary(value: string, boundary: 'start' | 'end') {
    const date = new Date(value);
    if (/^\d{4}-\d{2}-\d{2}$/.test(value)) {
      date.setHours(
        boundary === 'start' ? 0 : 23,
        boundary === 'start' ? 0 : 59,
        boundary === 'start' ? 0 : 59,
        boundary === 'start' ? 0 : 999,
      );
    }

    return date;
  }

  private async getMetricSummary(
    startDate: Date,
    endDate: Date,
    scoreByBranch: Map<string, number>,
    scoreByBranchIndex: Map<number, number>,
  ) {
    const responseMatch = { submittedAt: { $gte: startDate, $lte: endDate } };
    const responses = await this.responseRepository.model
      .find(responseMatch, {
        userId: 1,
        branchId: 1,
        branchIndex: 1,
        ratingScore: 1,
      })
      .lean();
    const totalResponses = responses.length;
    const ratingSum = responses.reduce((sum: number, item: any) => {
      const score =
        scoreByBranch.get(item.branchId) ??
        scoreByBranchIndex.get(item.branchIndex) ??
        item.ratingScore ??
        (item.branchIndex !== undefined ? item.branchIndex + 1 : 0);

      return sum + score;
    }, 0);
    const users = new Set<string>();
    responses.forEach((item: any) => {
      if (item.userId) users.add(item.userId);
    });
    const [started, completed] = await Promise.all([
      this.sessionRepository.model.countDocuments({
        startedAt: { $gte: startDate, $lte: endDate },
      }),
      this.sessionRepository.model.countDocuments({
        startedAt: { $gte: startDate, $lte: endDate },
        completedAt: { $exists: true, $ne: null },
      }),
    ]);
    const completionRate =
      started > 0
        ? this.roundPercent(completed / started)
        : totalResponses > 0
          ? 100
          : 0;

    return {
      totalResponses,
      averageRating:
        totalResponses > 0 ? this.roundNumber(ratingSum / totalResponses) : 0,
      distinctUsers: users.size,
      completionRate,
    };
  }

  private async getRatingDistribution(
    startDate: Date,
    endDate: Date,
    configuredBranches: any[],
  ) {
    const items = await this.responseRepository.model
      .find(
        { submittedAt: { $gte: startDate, $lte: endDate } },
        {
          branchId: 1,
          branchIndex: 1,
          branchName: 1,
          ratingScore: 1,
          branch: 1,
        },
      )
      .lean();
    const configuredIds = new Set(
      configuredBranches.map(branch => branch.branchId),
    );
    const branchIdByScore = new Map(
      configuredBranches.map(branch => [branch.ratingScore, branch.branchId]),
    );
    const countByBranch = new Map<string, any>();
    const unknownByKey = new Map<string, any>();

    items.forEach((item: any) => {
      const key = this.resolveStatisticsBranchKey(
        item,
        configuredIds,
        branchIdByScore,
      );
      const current = countByBranch.get(key) ?? unknownByKey.get(key);
      const next = {
        ...item,
        branchId: key,
        emoji: item.branch?.emoji,
        closedQuestion: item.branch?.closedQuestion,
        openQuestion: item.branch?.openQuestion,
        count: (current?.count ?? 0) + 1,
      };

      if (configuredIds.has(key)) {
        countByBranch.set(key, next);
      } else {
        unknownByKey.set(key, next);
      }
    });
    const configuredItems = configuredBranches.map(branch => ({
      ...branch,
      count: countByBranch.get(branch.branchId)?.count ?? 0,
      percent: 0,
    }));
    const unknownItems = Array.from(unknownByKey.values())
      .map(item => ({
        branchId: item.branchId,
        branchIndex: item.branchIndex ?? item.ratingScore - 1,
        branchName: item.branchName ?? item.emoji?.name ?? '',
        ratingScore: item.ratingScore ?? (item.branchIndex ?? 0) + 1,
        emoji: item.emoji,
        closedQuestion: item.closedQuestion,
        openQuestion: item.openQuestion,
        count: item.count,
        percent: 0,
      }))
      .sort((a, b) => a.ratingScore - b.ratingScore);

    return [...configuredItems, ...unknownItems];
  }

  private async getOptionDistribution(
    startDate: Date,
    endDate: Date,
    branchFilter?: {
      branchId: string;
      ratingScore?: number;
      branchIndex?: number;
    },
  ) {
    const match: any = { submittedAt: { $gte: startDate, $lte: endDate } };
    if (branchFilter) {
      Object.assign(
        match,
        this.buildBranchWhere(branchFilter.branchId, branchFilter),
      );
    }

    return this.responseRepository.model.aggregate([
      { $match: match },
      { $unwind: '$selectedOptions' },
      {
        $group: {
          _id: {
            branchId: '$branchId',
            optionId: '$selectedOptions.id',
          },
          count: { $sum: 1 },
          branchId: { $first: '$branchId' },
          ratingScore: { $first: '$ratingScore' },
          branchIndex: { $first: '$branchIndex' },
          option: { $first: '$selectedOptions' },
        },
      },
      { $sort: { count: -1 } },
    ]);
  }

  private async getBranchSummaries(
    startDate: Date,
    endDate: Date,
    ratingDistribution: any[],
    optionDistribution: any[],
    totalResponses: number,
  ) {
    const configuredIds = new Set(
      ratingDistribution.map(branch => branch.branchId),
    );
    const branchIdByScore = new Map(
      ratingDistribution.map(branch => [branch.ratingScore, branch.branchId]),
    );
    const feedbacks = await this.responseRepository.model
      .find(
        {
          submittedAt: { $gte: startDate, $lte: endDate },
          feedback: { $exists: true, $ne: null },
        },
        {
          feedback: 1,
          submittedAt: 1,
          selectedOptions: 1,
          branchId: 1,
          ratingScore: 1,
          branchIndex: 1,
        },
      )
      .sort({ submittedAt: -1 })
      .lean();
    const feedbackByBranch = new Map<string, any[]>();
    feedbacks.forEach((item: any) => {
      if (!String(item.feedback ?? '').trim()) return;
      const key = this.resolveStatisticsBranchKey(
        item,
        configuredIds,
        branchIdByScore,
      );
      const items = feedbackByBranch.get(key) ?? [];
      if (items.length >= 7) return;
      items.push({
        _id: item._id,
        feedback: item.feedback,
        submittedAt: item.submittedAt,
        selectedOptions: item.selectedOptions,
      });
      feedbackByBranch.set(key, items);
    });
    const optionsByBranch = new Map<string, any[]>();
    optionDistribution.forEach(item => {
      const key = this.resolveStatisticsBranchKey(
        item,
        configuredIds,
        branchIdByScore,
      );
      const list = optionsByBranch.get(key) ?? [];
      list.push(item);
      optionsByBranch.set(key, list);
    });

    return ratingDistribution.map(branch => {
      const options = optionsByBranch.get(branch.branchId) ?? [];
      const totalOptionSelections = options.reduce(
        (sum, item) => sum + item.count,
        0,
      );

      return {
        ...branch,
        percent: this.percentOf(branch.count, totalResponses),
        options: options.map(item => ({
          option: item.option,
          count: item.count,
          percent: this.percentOf(item.count, totalOptionSelections),
        })),
        feedbacks: feedbackByBranch.get(branch.branchId) ?? [],
      };
    });
  }

  private mapResponseBranch(response: any) {
    if (!response) return null;

    return {
      branchId: response.branchId,
      branchIndex: response.branchIndex,
      branchName: response.branchName ?? response.branch?.emoji?.name,
      ratingScore: response.ratingScore ?? (response.branchIndex ?? 0) + 1,
      emoji: response.branch?.emoji,
      closedQuestion: response.branch?.closedQuestion,
      openQuestion: response.branch?.openQuestion,
    };
  }

  private async countActiveUsers() {
    return this.userRepository.model.countDocuments({
      role: UserRole.USER,
      status: UserStatus.ACTIVE,
    });
  }

  private getConfiguredBranches(config: IInAppSurveyConfig) {
    return (config.branches ?? [])
      .map((branch, index) => ({
        branchId: branch.id,
        branchIndex: branch.index ?? index,
        branchName: branch.emoji?.name ?? '',
        ratingScore: this.resolveBranchScore({
          ...branch,
          index: branch.index ?? index,
        }),
        emoji: branch.emoji,
        closedQuestion: {
          question: branch.closedQuestion.question,
          guide: branch.closedQuestion.guide,
          type: branch.closedQuestion.type,
        },
        openQuestion: branch.openQuestion,
      }))
      .sort((a, b) => a.branchIndex - b.branchIndex);
  }

  private resolveStatisticsBranchKey(
    item: any,
    configuredIds: Set<string>,
    branchIdByScore: Map<number, string>,
  ) {
    if (configuredIds.has(item.branchId)) return item.branchId;

    const score =
      item.ratingScore ??
      (item.branchIndex !== undefined ? item.branchIndex + 1 : undefined);

    return score ? branchIdByScore.get(score) ?? item.branchId : item.branchId;
  }

  private buildBranchWhere(
    branchId: string,
    branch?: { ratingScore?: number; branchIndex?: number },
  ) {
    const branches: any[] = [{ branchId }];
    if (branch?.ratingScore !== undefined) {
      branches.push({ ratingScore: branch.ratingScore });
    }
    if (branch?.branchIndex !== undefined) {
      branches.push({ branchIndex: branch.branchIndex });
    }

    return { $or: branches };
  }

  private calculateDeltaPercent(current: number, previous: number) {
    if (previous === 0) return current > 0 ? 100 : 0;
    return this.roundNumber(((current - previous) / previous) * 100);
  }

  private percentOf(value: number, total: number) {
    return total > 0 ? this.roundPercent(value / total) : 0;
  }

  private roundPercent(value: number) {
    return this.roundNumber(value * 100);
  }

  private roundNumber(value: number) {
    return Math.round(value * 10) / 10;
  }

  private escapeRegex(value: string) {
    return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  private getTranslationValue(value: any, lang: string) {
    if (!value) return '';
    if (typeof value === 'string') return value;
    return value[lang] ?? value.vi ?? value.en ?? Object.values(value)[0] ?? '';
  }
}
