import { BadRequestException, Injectable } from '@nestjs/common';
import * as ExcelJS from 'exceljs';

import { IResponseListPage } from '@utils/interface/paging/page.interface';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import {
  GetAdminUserHabitDetailDto,
  GetAdminUserHabitsDto,
} from './dto/get-admin-user-habits.dto';
import { GetHabitCheckinStatisticsDto } from './dto/get-habit-checkin-statistics.dto';
import { HabitCheckinMethod, UserHabitState } from './enum/user-habit.enum';
import {
  IAdminHabitUser,
  IAdminUserHabitDetail,
  IAdminUserHabitDetailItem,
  IAdminUserHabitSummary,
  IUserHabitCheckinLogItem,
} from './interface/user-habit.interface';
import {
  HabitCheckinRepository,
  IHabitCheckinExportRow,
} from './repository/habit-checkin.repository';
import { UserHabitRepository } from './repository/user-habit.repository';
import { normalizeDateOnly } from './user-habit.helper';
import { HabitLibraryService } from '../habit-library/habit-library.service';

/**
 * Ceiling on the export's row sheet.
 *
 * `habit_checkins` grows one row per habit per day per user, so an all-time
 * window is unbounded by nature. The cap keeps a single request from loading the
 * whole collection into memory; when it bites, the summary sheet says so rather
 * than the file quietly ending early.
 */
const HABIT_CHECKIN_EXPORT_ROW_LIMIT = 20000;

/**
 * Reader-facing labels, kept in step with the admin screen
 * (`habitCheckinLabels.tsx`). A sheet that says `exercise` where the screen says
 * "Quiz" makes whoever opens it wonder which one is the real data. The raw enum
 * still travels in the API payload for anything matching on a key.
 */
const EXPORT_METHOD_LABELS: Record<string, string> = {
  [HabitCheckinMethod.TAP]: 'Tap',
  [HabitCheckinMethod.JOURNAL]: 'Journal',
  [HabitCheckinMethod.EXERCISE]: 'Quiz',
  [HabitCheckinMethod.VIDEO]: 'Video',
  [HabitCheckinMethod.ROLEPLAY]: 'Roleplay',
};

/** Mood is a 1-based 3-level scale (see habit-checkin.schema.ts). */
const EXPORT_MOOD_LABELS: Record<number, string> = {
  1: '😕 Tough',
  2: '🙂 Okay',
  3: '😄 Great',
};

/**
 * Read-only admin view of what users actually do with their habits: who adopted
 * what, how often they check in, and — for the journal method — the diary text
 * they wrote.
 *
 * Kept apart from [UserHabitService] on purpose. That service is caller-scoped
 * (every read goes through `requestService.user`), so folding cross-user reads
 * into it would put two different trust models in one class. Everything here is
 * reached only through [UserHabitAdminController], and nothing here writes.
 * That controller is AuthGuard-only — see its own note on why the ADMIN role
 * gate had to come off — so treat these reads as reachable by any signed-in
 * caller until role enforcement is made real.
 */
@Injectable()
export class UserHabitAdminService {
  constructor(
    private readonly userHabitRepository: UserHabitRepository,
    private readonly habitCheckinRepository: HabitCheckinRepository,
    private readonly habitLibraryService: HabitLibraryService,
    private readonly userRepository: UserRepository,
  ) {}

  private toAdminUser(doc: any, fallbackId: string): IAdminHabitUser | null {
    if (!doc) return null;
    return {
      id: (doc._id ?? fallbackId)?.toString(),
      email: doc.email,
      name: doc.name,
      role: doc.role,
      status: doc.status,
    };
  }

  private toLogItem(checkin: any): IUserHabitCheckinLogItem {
    return {
      date: normalizeDateOnly(checkin.date).toISOString().slice(0, 10),
      done: checkin.done,
      ...(checkin.note !== undefined ? { note: checkin.note } : {}),
      ...(checkin.method !== undefined ? { method: checkin.method } : {}),
      ...(checkin.mood !== undefined ? { mood: checkin.mood } : {}),
      ...(checkin.score !== undefined ? { score: checkin.score } : {}),
    };
  }

  async findUserSummaries(
    dto: GetAdminUserHabitsDto,
  ): Promise<IResponseListPage<IAdminUserHabitSummary>> {
    const page = dto.page ?? 1;
    const take = dto.take ?? 10;

    const { items, total } =
      await this.userHabitRepository.aggregateAdminUserSummaries({
        page,
        take,
        search: dto.search,
        state: dto.state,
      });

    return {
      items: items.map(row => ({
        userId: row._id?.toString(),
        user: this.toAdminUser(row.user, row._id?.toString()),
        habitCount: row.habitCount ?? 0,
        activeCount: row.activeCount ?? 0,
        totalCheckIns: row.totalCheckIns ?? 0,
        bestStreak: row.bestStreak ?? 0,
        lastCheckInDate: row.lastCheckInDate ?? null,
        checkinRows: row.checkinRows ?? 0,
        doneCount: row.doneCount ?? 0,
        journalCount: row.journalCount ?? 0,
        quizCount: row.quizCount ?? 0,
      })),
      itemsPerPage: take,
      totalPages: take > 0 ? Math.ceil(total / take) : 0,
      currentPage: page,
    };
  }

  async findUserDetail(
    userId: string,
    dto: GetAdminUserHabitDetailDto,
  ): Promise<IAdminUserHabitDetail> {
    // A user with no habits is a valid, empty answer — not a 404. The admin
    // reaches this page from a list of ids and from search, and an id that has
    // since had its habits removed should render an empty state rather than an
    // error.
    const [userDoc, userHabits] = await Promise.all([
      this.userRepository.findById(userId).catch(() => null),
      this.userHabitRepository.findForUser(userId),
    ]);

    const from = dto.from ? normalizeDateOnly(dto.from) : undefined;
    const to = dto.to ? normalizeDateOnly(dto.to) : undefined;

    const userHabitIds = userHabits.map(habit => habit._id.toString());
    const [libraryHabits, checkins] = await Promise.all([
      this.habitLibraryService.findByIds(
        Array.from(new Set(userHabits.map(h => h.habitId?.toString()))),
      ),
      this.habitCheckinRepository.findAllForUserHabits(userHabitIds, from, to),
    ]);

    const titleById = new Map(
      libraryHabits.map(habit => [habit._id.toString(), habit.title]),
    );

    // Group the single cross-habit query back onto each habit.
    const checkinsByHabit = new Map<string, IUserHabitCheckinLogItem[]>();
    for (const checkin of checkins as any[]) {
      const key = checkin.userHabitId?.toString();
      const list = checkinsByHabit.get(key) ?? [];
      list.push(this.toLogItem(checkin));
      checkinsByHabit.set(key, list);
    }

    const habits: IAdminUserHabitDetailItem[] = userHabits.map(habit => {
      const id = habit._id.toString();
      return {
        id,
        habitId: habit.habitId?.toString(),
        // Null when the library entry was deleted — the habit is orphaned. The
        // app hides these; the admin shows them, since an orphan is exactly the
        // kind of thing this view exists to make visible.
        title: (titleById.get(habit.habitId?.toString()) as any) ?? null,
        state: habit.state,
        reminderTime: habit.reminderTime,
        packLength: habit.packLength,
        startedAt: habit.startedAt,
        currentStreak: habit.currentStreak ?? 0,
        bestStreak: habit.bestStreak ?? 0,
        totalCheckIns: habit.totalCheckIns ?? 0,
        lastCheckInDate: habit.lastCheckInDate ?? null,
        sourceKeypointId: habit.sourceKeypointId?.toString() ?? null,
        sourceCourseId: habit.sourceCourseId?.toString() ?? null,
        reanchorReason: habit.reanchorReason ?? null,
        checkins: checkinsByHabit.get(id) ?? [],
      };
    });

    const allCheckins = habits.flatMap(habit => habit.checkins);

    return {
      user: this.toAdminUser(userDoc, userId),
      habits,
      totals: {
        habitCount: habits.length,
        activeCount: habits.filter(h => h.state === UserHabitState.ACTIVE)
          .length,
        checkinRows: allCheckins.length,
        doneCount: allCheckins.filter(c => c.done).length,
        journalCount: allCheckins.filter(c => !!c.note?.trim()).length,
        quizCount: allCheckins.filter(c => c.score !== undefined).length,
      },
    };
  }

  // ---------------------------------------------------------------------------
  // Statistics (admin "Thống kê" tab)
  //
  // These are event counts, not snapshots: `habit_checkins` holds one row per
  // habit per day, so "12 check-in" means twelve real days of practice. That is
  // the opposite of the lesson-feedback statistics, which can only ever report
  // each user's latest submission.
  // ---------------------------------------------------------------------------

  /** Buckets for the best-streak histogram: 1, 2-3, 4-7, 8-14, 15+. */
  private static readonly STREAK_EDGES = [1, 2, 4, 8, 15];

  private parseDay(value?: string, label = 'date') {
    if (!value) return undefined;
    const parsed = new Date(value);
    if (isNaN(parsed.getTime())) {
      throw new BadRequestException(`${label} is not a valid date`);
    }
    // Check-in dates are stored at UTC midnight (normalizeDateOnly), so the
    // window has to be compared at midnight too — a local-time parse would
    // shift the boundary a day for anyone east of UTC.
    return new Date(
      Date.UTC(parsed.getUTCFullYear(), parsed.getUTCMonth(), parsed.getUTCDate()),
    );
  }

  private percent(part: number, whole: number) {
    if (!whole) return 0;
    return Math.round((part / whole) * 1000) / 10;
  }

  private delta(current: number, previous: number | null) {
    if (previous === null) return null;
    if (previous === 0) return current === 0 ? 0 : 100;
    return Math.round(((current - previous) / previous) * 1000) / 10;
  }

  async getCheckinStatistics(dto: GetHabitCheckinStatisticsDto) {
    const from = this.parseDay(dto.startDate, 'startDate');
    const to = this.parseDay(dto.endDate, 'endDate');
    if (from && to && from > to) {
      throw new BadRequestException('startDate must be before endDate');
    }

    // Equal-length preceding window, for the deltas. Absent when the request is
    // open-ended: an all-time figure has no previous period to move against.
    let previousFrom: Date | undefined;
    let previousTo: Date | undefined;
    if (from && to) {
      const span = to.getTime() - from.getTime();
      previousTo = new Date(from.getTime() - 86400000);
      previousFrom = new Date(previousTo.getTime() - span);
    }

    const [current, previous, adoption] = await Promise.all([
      this.habitCheckinRepository.aggregateStatistics(from, to),
      previousFrom
        ? this.habitCheckinRepository.aggregateStatistics(previousFrom, previousTo)
        : Promise.resolve(null),
      this.userHabitRepository.aggregateAdoption(
        UserHabitAdminService.STREAK_EDGES,
      ),
    ]);

    const totals = current.totals ?? {
      checkins: 0,
      done: 0,
      users: 0,
      habits: 0,
      withNote: 0,
      moodSum: 0,
      moodCount: 0,
      quizCount: 0,
      quizScoreSum: 0,
    };
    const before = previous?.totals ?? (previousFrom ? { checkins: 0, done: 0, users: 0 } : null);

    const stateCounts: Record<string, number> = {};
    for (const row of adoption.byState) stateCounts[row.state] = row.count;

    return {
      range: { startDate: from ?? null, endDate: to ?? null },
      metrics: {
        checkins: {
          value: totals.checkins,
          delta: this.delta(totals.checkins, before?.checkins ?? null),
        },
        users: {
          value: totals.users,
          delta: this.delta(totals.users, before?.users ?? null),
        },
        // Share of check-in rows marked done. A row can exist with done:false
        // (the reader un-toggled the day), so this is not always 100%.
        doneRate: { value: this.percent(totals.done, totals.checkins) },
        habitsTouched: { value: totals.habits },
        withNote: { value: totals.withNote },
        averageMood: {
          value: totals.moodCount
            ? Math.round((totals.moodSum / totals.moodCount) * 10) / 10
            : null,
        },
        quizCount: { value: totals.quizCount },
        averageQuizScore: {
          value: totals.quizCount
            ? Math.round((totals.quizScoreSum / totals.quizCount) * 10) / 10
            : null,
        },
        activeHabits: { value: stateCounts.active ?? 0 },
        draftHabits: { value: stateCounts.draft ?? 0 },
        archivedHabits: { value: stateCounts.archived ?? 0 },
        adoptedByUsers: { value: adoption.users },
      },
      daily: current.daily,
      methodDistribution: current.methods.map((row: any) => ({
        ...row,
        percent: this.percent(row.count, totals.checkins),
      })),
      moodDistribution: current.moods.map((row: any) => ({
        ...row,
        percent: this.percent(row.count, totals.moodCount),
      })),
      topHabits: current.topHabits.map((row: any) => ({
        ...row,
        doneRate: this.percent(row.done, row.checkins),
      })),
      streakBuckets: adoption.streaks.map((row: any) => ({
        from: row._id === 'overflow' ? UserHabitAdminService.STREAK_EDGES.at(-1) : row._id,
        isOverflow: row._id === 'overflow',
        count: row.count,
      })),
      notes: current.notes,
    };
  }

  /**
   * The statistics tab as a spreadsheet: every check-in in the window on one
   * sheet, the aggregate figures on another.
   *
   * Both sheets come from the SAME window the screen is showing — the overview
   * is re-read here rather than passed in, so a file can never mix one period's
   * rows with another's totals. Journal text ships in full: it is the reason
   * anyone exports this, and it is already on the screen beside it.
   */
  async exportCheckinStatisticsWorkbook(dto: GetHabitCheckinStatisticsDto) {
    const from = this.parseDay(dto.startDate, 'startDate');
    const to = this.parseDay(dto.endDate, 'endDate');
    if (from && to && from > to) {
      throw new BadRequestException('startDate must be before endDate');
    }

    const [records, overview] = await Promise.all([
      this.habitCheckinRepository.listRecords(
        from,
        to,
        HABIT_CHECKIN_EXPORT_ROW_LIMIT,
      ),
      this.getCheckinStatistics(dto),
    ]);

    const workbook = new ExcelJS.Workbook();

    const sheet = workbook.addWorksheet('check-ins');
    sheet.columns = [
      { header: 'Ngày', key: 'date', width: 14 },
      { header: 'User ID', key: 'userId', width: 28 },
      { header: 'Habit', key: 'habit', width: 40 },
      { header: 'Habit ID', key: 'habitId', width: 28 },
      { header: 'Hoàn thành', key: 'done', width: 12 },
      { header: 'Hình thức', key: 'method', width: 14 },
      { header: 'Mood', key: 'mood', width: 14 },
      { header: 'Điểm quiz', key: 'score', width: 12 },
      { header: 'Nhật ký', key: 'note', width: 70 },
    ];

    for (const record of records) {
      sheet.addRow({
        // Date-only at UTC midnight in the DB; written as a plain `yyyy-mm-dd`
        // string so no spreadsheet's local timezone can shift it a day.
        date: this.exportDay(record),
        userId: record.userId?.toString() ?? '',
        habit: this.exportHabitTitle(record),
        habitId: record.habitId?.toString() ?? '',
        done: record.done ? 'x' : '',
        method: EXPORT_METHOD_LABELS[record.method ?? HabitCheckinMethod.TAP] ?? record.method ?? '',
        mood: record.mood ? EXPORT_MOOD_LABELS[record.mood] ?? record.mood : '',
        // 0 is a real quiz score, so only `null`/`undefined` may blank the cell.
        score: record.score ?? null,
        note: record.note?.trim() || '',
      });
    }

    this.styleHeader(sheet, 'I1');
    sheet.getColumn('note').alignment = { wrapText: true };

    const summary = workbook.addWorksheet('tong-quan');
    summary.columns = [
      { header: 'Chỉ số', key: 'label', width: 44 },
      { header: 'Giá trị', key: 'value', width: 18 },
    ];
    const m = overview.metrics;
    const rows: [string, string | number | null][] = [
      [
        'Khoảng ngày',
        dto.startDate && dto.endDate
          ? `${dto.startDate} → ${dto.endDate}`
          : 'Tất cả',
      ],
      ['Số lượt check-in', m.checkins.value],
      ['Số người check-in', m.users.value],
      ['Tỷ lệ hoàn thành (%)', m.doneRate.value],
      ['Số habit được check-in', m.habitsTouched.value],
      ['Lượt có nhật ký', m.withNote.value],
      ['Mood trung bình', m.averageMood.value],
      ['Lượt làm quiz', m.quizCount.value],
      ['Điểm quiz trung bình', m.averageQuizScore.value],
      ['Habit đang theo (active)', m.activeHabits.value],
      ['Habit nháp (draft)', m.draftHabits.value],
      ['Habit đã lưu trữ (archived)', m.archivedHabits.value],
      ['Số người đã nhận habit', m.adoptedByUsers.value],
      ['', null],
      ['Hình thức check-in', 'Số lượt'],
      ...overview.methodDistribution.map(
        (item: any): [string, number] => [
          EXPORT_METHOD_LABELS[item.method] ?? item.method,
          item.count,
        ],
      ),
      ['', null],
      ['Mood', 'Số lượt'],
      ...overview.moodDistribution.map(
        (item: any): [string, number] => [
          EXPORT_MOOD_LABELS[item.mood] ?? String(item.mood),
          item.count,
        ],
      ),
      ['', null],
      ['Habit nhiều check-in nhất', 'Số lượt'],
      ...overview.topHabits.map(
        (item: any): [string, number] => [
          this.pickTranslation(item.title) || item.habitId?.toString() || '',
          item.checkins,
        ],
      ),
      ['', null],
      ['Check-in theo ngày', 'Số lượt'],
      ...overview.daily.map(
        (item: any): [string, number] => [
          this.exportDay(item),
          item.checkins,
        ],
      ),
    ];
    for (const [label, value] of rows) summary.addRow({ label, value });
    this.styleHeader(summary, 'B1');

    if (records.length >= HABIT_CHECKIN_EXPORT_ROW_LIMIT) {
      summary.addRow({});
      summary.addRow({
        label: `Lưu ý: file bị cắt ở ${HABIT_CHECKIN_EXPORT_ROW_LIMIT} dòng (lấy các ngày mới nhất), hãy thu hẹp khoảng ngày.`,
      });
    }

    const output = await workbook.xlsx.writeBuffer();
    return Buffer.from(output);
  }

  /** `yyyy-mm-dd` from a stored UTC-midnight check-in date. */
  private exportDay(row: { date?: Date | string | null }) {
    if (!row?.date) return '';
    const date = row.date instanceof Date ? row.date : new Date(row.date);
    if (isNaN(date.getTime())) return '';
    return date.toISOString().slice(0, 10);
  }

  private exportHabitTitle(record: IHabitCheckinExportRow) {
    return (
      this.pickTranslation(record.habitTitle) ||
      record.habitId?.toString() ||
      ''
    );
  }

  /**
   * Vietnamese first: this file is read by the Vietnamese-speaking admin team,
   * and unlike the app there is no request locale to honour here.
   */
  private pickTranslation(value?: Record<string, string> | null) {
    if (!value || typeof value !== 'object') return '';
    return value.vi || value.en || Object.values(value).find(Boolean) || '';
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
}
