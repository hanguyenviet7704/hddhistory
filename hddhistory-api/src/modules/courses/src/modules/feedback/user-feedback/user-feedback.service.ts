import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import * as ExcelJS from 'exceljs';
import { Model } from 'mongoose';
import { I18nContext } from 'nestjs-i18n/dist';

import { RequestService } from '@base/service/request.service';
import { ITranslation } from '@utils/interface/common.interface';

import { UpsertUserFeedbackDto } from './dto/upsert-user-feedback.dto';
import {
  GetUserFeedbackCommentsDto,
  GetUserFeedbackStatisticsDto,
} from './dto/user-feedback-statistics.dto';
import {
  FeedbackEntry,
  FeedbackType,
  IncompleteFeedbackReason,
} from './enum/user-feedback.enum';
import { UserFeedbackRepository } from './repository/user-feedback.repository';
import { Course } from '../../course/schema/course.schema';
import { Keypoint } from '../../keypoint/schema/keypoint.schema';
import { Lesson } from '../../lesson/schema/lesson.schema';

import type {
  IUserFeedbackAbandonedRow,
  IUserFeedbackComplete,
  IUserFeedbackIncomplete,
  IUserFeedbackMetricsRow,
  IUserFeedbackReasonSlice,
} from './interface/user-feedback.interface';

/**
 * Hard ceiling on export rows — see `listRecords`. Generous next to today's few
 * hundred records, low enough that the request never becomes a timeout.
 */
const FEEDBACK_EXPORT_ROW_LIMIT = 20000;

/**
 * Reader-facing labels for the export, kept in step with the admin screen
 * (`lesson-feedback-utils.ts`). The file is read by people, and a sheet that
 * says `hard_to_understand` where the screen says "Khó hiểu" makes them wonder
 * which one is the real data. The raw enum still travels in the API payload for
 * anything that needs to match on a key.
 */
const EXPORT_REASON_LABELS: Record<string, string> = {
  [IncompleteFeedbackReason.HARD_TO_UNDERSTAND]: 'Khó hiểu',
  [IncompleteFeedbackReason.NOT_ENGAGING]: 'Không cuốn',
  [IncompleteFeedbackReason.POOR_VISUALS]: 'Hình ảnh chưa tốt',
  [IncompleteFeedbackReason.HARD_QUESTIONS]: 'Câu hỏi khó',
  [IncompleteFeedbackReason.NEEDS_MORE_EXAMPLES]: 'Cần thêm ví dụ',
};

const EXPORT_ENTRY_LABELS: Record<string, string> = {
  [FeedbackEntry.KEYPOINT]: 'Keypoint',
  [FeedbackEntry.ROLEPLAY]: 'Roleplay',
};

const EXPORT_TYPE_LABELS: Record<string, string> = {
  [FeedbackType.COMPLETE]: 'Hoàn thành',
  [FeedbackType.INCOMPLETE]: 'Bỏ dở',
};

/** Unknown values pass through raw rather than vanishing from the sheet. */
const label = (table: Record<string, string>, value?: string) =>
  (value && table[value]) || value || '';

@Injectable()
export class FeedbackService {
  constructor(
    private readonly userFeedbackRepository: UserFeedbackRepository,
    private readonly requestService: RequestService,
    @InjectModel(Course.name)
    private readonly courseModel: Model<Course>,
    @InjectModel(Lesson.name)
    private readonly lessonModel: Model<Lesson>,
    @InjectModel(Keypoint.name)
    private readonly keypointModel: Model<Keypoint>,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  /** Active request locale — titles in the export follow it. */
  private get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  private resolveSectionKey(entry: FeedbackEntry, type: FeedbackType) {
    const entryKey = entry === FeedbackEntry.ROLEPLAY ? 'roleplay' : 'keypoint';
    const typeKey = type === FeedbackType.COMPLETE ? 'Complete' : 'Incomplete';
    return `${entryKey}${typeKey}`;
  }

  async upsert(dto: UpsertUserFeedbackDto) {
    if (dto.entry === FeedbackEntry.KEYPOINT && !dto.keypointId) {
      throw new BadRequestException('keypointId is required for keypoint');
    }

    if (
      dto.type === FeedbackType.COMPLETE &&
      (dto.overallRating === undefined ||
        dto.contentRating === undefined ||
        dto.experienceRating === undefined)
    ) {
      throw new BadRequestException('complete feedback requires ratings');
    }

    const hasReasons = Array.isArray(dto.reasons) && dto.reasons.length > 0;
    const hasComment = Boolean(dto.comment?.trim());
    if (dto.type === FeedbackType.INCOMPLETE && !hasReasons && !hasComment) {
      throw new BadRequestException('incomplete feedback requires reason');
    }

    const now = new Date();
    const sectionKey = this.resolveSectionKey(dto.entry, dto.type);

    const [course, lesson, keypoint] = await Promise.all([
      this.courseModel.findById(dto.courseId, { title: 1 }).lean(),
      this.lessonModel.findById(dto.lessonId, { title: 1 }).lean(),
      dto.keypointId
        ? this.keypointModel.findById(dto.keypointId, { title: 1 }).lean()
        : Promise.resolve(null),
    ]);

    const sectionPayload: Record<string, any> = {
      courseId: dto.courseId,
      lessonId: dto.lessonId,
      comment: dto.comment,
      submittedAt: now,
    };
    if (course?.title) sectionPayload.courseTitle = course.title;
    if (lesson?.title) sectionPayload.lessonTitle = lesson.title;

    if (dto.keypointId) {
      sectionPayload.keypointId = dto.keypointId;
      sectionPayload.keypointTitle = keypoint?.title;
    }
    if (dto.type === FeedbackType.COMPLETE) {
      sectionPayload.overallRating = dto.overallRating;
      sectionPayload.contentRating = dto.contentRating;
      sectionPayload.experienceRating = dto.experienceRating;
    } else {
      sectionPayload.reasons = dto.reasons ?? [];
    }

    return this.userFeedbackRepository.upsertByUserId(dto.userId, {
      $set: { [sectionKey]: sectionPayload },
      $setOnInsert: { userId: dto.userId, createdAt: now },
      $currentDate: { updatedAt: true },
    });
  }

  async myFeedback() {
    const userId = this.user?.id;
    if (!userId) {
      throw new BadRequestException('userId is required');
    }

    return this.getFeedbackByUserId(userId);
  }

  async getFeedbackByUserId(userId: string) {
    if (!userId) {
      throw new BadRequestException('userId is required');
    }

    const emptyFeedback: {
      userId: string;
      roleplayComplete: IUserFeedbackComplete | null;
      roleplayIncomplete: IUserFeedbackIncomplete | null;
      keypointComplete: IUserFeedbackComplete | null;
      keypointIncomplete: IUserFeedbackIncomplete | null;
    } = {
      userId,
      roleplayComplete: null,
      roleplayIncomplete: null,
      keypointComplete: null,
      keypointIncomplete: null,
    };

    const data = await this.userFeedbackRepository.findByUserId(userId);
    return data ? { ...emptyFeedback, ...data } : emptyFeedback;
  }

  async deleteByUserId(userId: string) {
    if (!userId) {
      throw new BadRequestException('userId is required');
    }

    return this.userFeedbackRepository.deleteOne({ userId });
  }

  // ---------------------------------------------------------------------------
  // Statistics (admin)
  //
  // NOTE ON WHAT THESE NUMBERS MEAN. `user_feedback` is unique per user and
  // holds ONE slot per (entry, type) — a later submission overwrites the
  // earlier one. So every count here is "how many users' LATEST feedback looks
  // like this", never "how many times this happened". `perUserLatestOnly: true`
  // travels with the payload so the admin screen can say so out loud instead of
  // letting a reader assume event counts.
  // ---------------------------------------------------------------------------

  /**
   * Resolves the requested window and the equal-length window before it (for
   * the deltas), mirroring the in-app-survey overview.
   *
   * An open-ended request (no dates) has no meaningful "previous period", so
   * the deltas come back null rather than a fabricated 0.
   */
  private resolveRange(dto: GetUserFeedbackStatisticsDto) {
    const startDate = dto.startDate ? new Date(dto.startDate) : undefined;
    const endDate = dto.endDate ? this.endOfDay(new Date(dto.endDate)) : undefined;

    if (startDate && isNaN(startDate.getTime())) {
      throw new BadRequestException('startDate is not a valid date');
    }
    if (endDate && isNaN(endDate.getTime())) {
      throw new BadRequestException('endDate is not a valid date');
    }
    if (startDate && endDate && startDate > endDate) {
      throw new BadRequestException('startDate must be before endDate');
    }

    let previousStartDate: Date | undefined;
    let previousEndDate: Date | undefined;
    if (startDate && endDate) {
      const span = endDate.getTime() - startDate.getTime();
      previousEndDate = new Date(startDate.getTime() - 1);
      previousStartDate = new Date(previousEndDate.getTime() - span);
    }

    return { startDate, endDate, previousStartDate, previousEndDate };
  }

  private endOfDay(date: Date) {
    // The client sends a plain day ("2026-08-31"), which parses to midnight —
    // matching `$lte` against that would drop everything submitted that day.
    date.setHours(23, 59, 59, 999);
    return date;
  }

  private emptyMetrics(): IUserFeedbackMetricsRow {
    return {
      records: 0,
      users: 0,
      complete: 0,
      incomplete: 0,
      keypoint: 0,
      roleplay: 0,
      withComment: 0,
      averageOverall: null,
      averageContent: null,
      averageExperience: null,
      unrated: 0,
    };
  }

  /**
   * Ranks the reasons behind one abandoned item.
   *
   * The repository hands over every reason occurrence (duplicates kept) because
   * the previous `$setUnion` collapsed to "all five reasons" on every busy row
   * — true, and useless. Tallying is a few dozen entries per row, so it happens
   * here rather than growing the pipeline.
   */
  private rankReasons(reasons: IncompleteFeedbackReason[] = []) {
    const tally = new Map<IncompleteFeedbackReason, number>();
    for (const reason of reasons) {
      tally.set(reason, (tally.get(reason) ?? 0) + 1);
    }
    return [...tally.entries()]
      .map(([reason, count]) => ({ reason, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 3);
  }

  /** Percentage change, or null when there is nothing to compare against. */
  private delta(current: number, previous: number | null) {
    if (previous === null) return null;
    if (previous === 0) return current === 0 ? 0 : 100;
    return Math.round(((current - previous) / previous) * 1000) / 10;
  }

  private round(value?: number | null) {
    if (value === null || value === undefined) return null;
    return Math.round(value * 10) / 10;
  }

  async getStatisticsOverview(dto: GetUserFeedbackStatisticsDto) {
    const range = this.resolveRange(dto);
    const filter = {
      startDate: range.startDate,
      endDate: range.endDate,
      entry: dto.entry,
      type: dto.type,
    };

    const [current, previous, distributions] = await Promise.all([
      this.userFeedbackRepository.aggregateMetrics(filter),
      range.previousStartDate
        ? this.userFeedbackRepository.aggregateMetrics({
            ...filter,
            startDate: range.previousStartDate,
            endDate: range.previousEndDate,
          })
        : Promise.resolve(null),
      this.userFeedbackRepository.aggregateDistributions(filter),
    ]);

    const now = current ?? this.emptyMetrics();
    const before = previous ?? (range.previousStartDate ? this.emptyMetrics() : null);
    const totalIncomplete = distributions.reasons.reduce(
      (sum: number, item: IUserFeedbackReasonSlice) => sum + item.count,
      0,
    );

    return {
      range,
      perUserLatestOnly: true,
      metrics: {
        records: { value: now.records, delta: this.delta(now.records, before?.records ?? null) },
        users: { value: now.users, delta: this.delta(now.users, before?.users ?? null) },
        complete: { value: now.complete, delta: this.delta(now.complete, before?.complete ?? null) },
        incomplete: {
          value: now.incomplete,
          delta: this.delta(now.incomplete, before?.incomplete ?? null),
        },
        keypoint: { value: now.keypoint },
        roleplay: { value: now.roleplay },
        withComment: { value: now.withComment },
        unrated: { value: now.unrated },
        averageOverall: { value: this.round(now.averageOverall) },
        averageContent: { value: this.round(now.averageContent) },
        averageExperience: { value: this.round(now.averageExperience) },
      },
      // Shares are of the reason TOTAL, not of feedback count: one incomplete
      // feedback can carry several reasons, so these deliberately sum to 100%
      // across reasons rather than to the number of feedbacks.
      reasonDistribution: distributions.reasons.map((item: IUserFeedbackReasonSlice) => ({
        ...item,
        percent: totalIncomplete
          ? Math.round((item.count / totalIncomplete) * 1000) / 10
          : 0,
      })),
      ratingDistribution: distributions.ratings,
      topAbandoned: distributions.topAbandoned.map(
        (row: IUserFeedbackAbandonedRow) => ({
          ...row,
          topReasons: this.rankReasons(row.reasons),
        }),
      ),
    };
  }

  /**
   * The filtered feedback as an .xlsx, mirroring the in-app-survey export:
   * one raw sheet to pivot on, one summary sheet holding the same numbers the
   * screen shows so a shared file explains itself.
   */
  async exportStatisticsWorkbook(dto: GetUserFeedbackStatisticsDto) {
    const range = this.resolveRange(dto);
    const filter = {
      startDate: range.startDate,
      endDate: range.endDate,
      entry: dto.entry,
      type: dto.type,
    };

    const [records, overview] = await Promise.all([
      this.userFeedbackRepository.listRecords(filter, FEEDBACK_EXPORT_ROW_LIMIT),
      this.getStatisticsOverview(dto),
    ]);

    const workbook = new ExcelJS.Workbook();

    const sheet = workbook.addWorksheet('feedback');
    sheet.columns = [
      { header: 'User ID', key: 'userId', width: 28 },
      { header: 'Loại nội dung', key: 'entry', width: 14 },
      { header: 'Trạng thái', key: 'type', width: 14 },
      { header: 'Khoá học', key: 'course', width: 38 },
      { header: 'Bài học', key: 'lesson', width: 38 },
      { header: 'Keypoint', key: 'keypoint', width: 38 },
      { header: 'Lý do bỏ dở', key: 'reasons', width: 42 },
      { header: 'Điểm tổng', key: 'overallRating', width: 12 },
      { header: 'Điểm nội dung', key: 'contentRating', width: 14 },
      { header: 'Điểm trải nghiệm', key: 'experienceRating', width: 16 },
      { header: 'Bình luận', key: 'comment', width: 60 },
      { header: 'Thời gian gửi', key: 'submittedAt', width: 22 },
    ];

    for (const record of records) {
      sheet.addRow({
        userId: record.userId,
        entry: label(EXPORT_ENTRY_LABELS, record.entry),
        type: label(EXPORT_TYPE_LABELS, record.type),
        course: this.translate(record.courseTitle),
        lesson: this.translate(record.lessonTitle),
        keypoint: this.translate(record.keypointTitle),
        reasons: (record.reasons ?? [])
          .map((reason) => label(EXPORT_REASON_LABELS, reason))
          .join(', '),
        // A rating below 1 is "unrated" (see aggregateMetrics) — leave the cell
        // empty so Excel's own AVERAGE() agrees with the summary sheet instead
        // of averaging in zeros.
        overallRating: record.overallRating >= 1 ? record.overallRating : null,
        contentRating: record.contentRating >= 1 ? record.contentRating : null,
        experienceRating:
          record.experienceRating >= 1 ? record.experienceRating : null,
        comment: record.comment?.trim() || '',
        submittedAt: record.submittedAt ?? null,
      });
    }

    this.styleHeader(sheet, 'L1');
    sheet.getColumn('submittedAt').numFmt = 'yyyy-mm-dd hh:mm:ss';
    sheet.getColumn('comment').alignment = { wrapText: true };
    sheet.getColumn('reasons').alignment = { wrapText: true };

    const summary = workbook.addWorksheet('tong-quan');
    summary.columns = [
      { header: 'Chỉ số', key: 'label', width: 42 },
      { header: 'Giá trị', key: 'value', width: 18 },
    ];
    const m = overview.metrics;
    const rows: [string, string | number | null][] = [
      ['Khoảng ngày', dto.startDate && dto.endDate ? `${dto.startDate} → ${dto.endDate}` : 'Tất cả'],
      ['Feedback (số người)', m.records.value],
      ['Số người dùng', m.users.value],
      ['Hoàn thành', m.complete.value],
      ['Bỏ dở', m.incomplete.value],
      ['Keypoint', m.keypoint.value],
      ['Roleplay', m.roleplay.value],
      ['Có bình luận', m.withComment.value],
      ['Chưa chấm điểm', m.unrated.value],
      ['Điểm tổng trung bình', m.averageOverall.value],
      ['Điểm nội dung trung bình', m.averageContent.value],
      ['Điểm trải nghiệm trung bình', m.averageExperience.value],
      ['', null],
      ['Lý do bỏ dở', 'Số lượt chọn'],
      ...overview.reasonDistribution.map(
        (item): [string, number] => [
          label(EXPORT_REASON_LABELS, item.reason),
          item.count,
        ],
      ),
      ['', null],
      ['Điểm', 'Số feedback'],
      ...overview.ratingDistribution.map(
        (item): [string, number] => [`${item.rating} sao`, item.count],
      ),
    ];
    for (const [label, value] of rows) summary.addRow({ label, value });
    this.styleHeader(summary, 'B1');

    // Same caveat the screen prints, carried into the file: without it a
    // spreadsheet passed around reads as a count of submissions.
    summary.addRow({});
    summary.addRow({
      label:
        'Lưu ý: mỗi người dùng chỉ lưu feedback MỚI NHẤT của từng loại, nên đây là số người, không phải số lượt gửi.',
    });
    if (records.length >= FEEDBACK_EXPORT_ROW_LIMIT) {
      summary.addRow({
        label: `Lưu ý: file bị cắt ở ${FEEDBACK_EXPORT_ROW_LIMIT} dòng, hãy thu hẹp khoảng ngày.`,
      });
    }

    const output = await workbook.xlsx.writeBuffer();
    return Buffer.from(output);
  }

  private translate(value?: ITranslation) {
    if (!value) return '';
    // Index through a keyof cast: `lang` is a plain string off the i18n
    // context, and ITranslation only declares the five shipped locales.
    const active = value[this.lang as keyof ITranslation];
    return active || value.vi || value.en || '';
  }

  private styleHeader(sheet: ExcelJS.Worksheet, lastHeaderCell: string) {
    const header = sheet.getRow(1);
    header.font = { bold: true };
    header.alignment = { vertical: 'middle', horizontal: 'center' };
    header.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFE2E8F0' },
    };
    sheet.views = [{ state: 'frozen', ySplit: 1 }];
    sheet.autoFilter = { from: 'A1', to: lastHeaderCell };
  }

  async getStatisticsComments(dto: GetUserFeedbackCommentsDto) {
    const range = this.resolveRange(dto);
    const page = dto.page && dto.page > 0 ? dto.page : 1;
    const take = dto.take && dto.take > 0 ? dto.take : 20;

    const { items, total } = await this.userFeedbackRepository.aggregateComments(
      {
        startDate: range.startDate,
        endDate: range.endDate,
        entry: dto.entry,
        type: dto.type,
      },
      page,
      take,
    );

    return {
      items,
      currentPage: page,
      itemsPerPage: take,
      totalPages: Math.ceil(total / take),
      totalItems: total,
    };
  }
}
