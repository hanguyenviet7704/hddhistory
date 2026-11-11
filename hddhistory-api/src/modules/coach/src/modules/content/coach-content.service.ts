import { Injectable, NotFoundException } from '@nestjs/common';

import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import { CoachContentKind } from './coach-content.enum';
import {
  GetCoachContentsDto,
  GetCoachContentUsersDto,
} from './dto/coach-content.dto';
import { CoachSessionDipRepository } from './repository/coach-session-dip.repository';
import { CoachStatementKind } from '../reflection/interface/reflection.interface';
import { CoachEvidenceRepository } from '../reflection/repository/coach-evidence.repository';
import { CoachProblemStatementRepository } from '../reflection/repository/coach-problem-statement.repository';
import { CoachSituationAnswerRepository } from '../reflection/repository/coach-situation-answer.repository';
import { CoachSituationRepository } from '../situation/repository/coach-situation.repository';

const DEFAULT_LIMIT = 200;

/** Which of the six kinds a `coach_problem_statements` row actually is. */
const STATEMENT_KIND_MAP: Record<string, CoachContentKind> = {
  [CoachStatementKind.PROBLEM_STATEMENT]: CoachContentKind.PROBLEM_STATEMENT,
  [CoachStatementKind.QUICK_NOTE]: CoachContentKind.QUICK_NOTE,
  [CoachStatementKind.BARRIER]: CoachContentKind.BARRIER,
};

/**
 * Which of the six kinds a statement row reads as.
 *
 * A row written before the `kind` field existed reads as the statement it was —
 * the same fallback the feed applies, kept in one place so a delete and the row
 * it was aimed at can never disagree about what that row is.
 */
const statementKindOf = (row: { kind?: string }): CoachContentKind =>
  STATEMENT_KIND_MAP[row?.kind] ?? CoachContentKind.PROBLEM_STATEMENT;

export interface ICoachContentRow {
  id: string;
  kind: CoachContentKind;
  userId: string;
  content: string;
  habitId: string | null;
  sessionId: string | null;
  createdAt: Date;
  /** Kind-specific extras, so the screen can show context without more calls. */
  meta: Record<string, unknown>;
}

/** Who wrote, how much, and when they last did — one row per reader. */
export interface ICoachContentUserRow {
  userId: string;
  /** Null when the account is gone: the words outlive the user document. */
  name: string | null;
  email: string | null;
  anonymous: boolean;
  firstAt: Date;
  lastAt: Date;
  total: number;
  /** Every kind, zeros included, so the table has fixed columns. */
  byKind: Record<CoachContentKind, number>;
}

/**
 * Where a thread's Coach lines came from.
 *
 * `transcript` — read back from `coach_sessions.turns`, word for word.
 * `derived` — the session document is gone (TTL), so the thread is rebuilt out
 * of what the reader left behind: their own words are exact, the Coach side is
 * only the authored question where one survives.
 */
export type CoachThreadSource = 'transcript' | 'derived';

export interface ICoachThreadMessage {
  at: Date;
  role: 'coach' | 'user';
  /**
   * Null on a rebuilt Coach turn whose wording is not recoverable — the screen
   * renders the fixed question for `kind` instead, marked as reconstructed.
   */
  text: string | null;
  /** Set on a reader message that also left a durable row. */
  kind?: CoachContentKind;
  step?: string | null;
  /** True when this line was rebuilt rather than read back. */
  derived?: boolean;
  meta?: Record<string, unknown>;
}

export interface ICoachThreadSession {
  /** Null for the bucket of rows written outside any session (câu kể). */
  sessionId: string | null;
  entry: string | null;
  habitId: string | null;
  startedAt: Date;
  endedAt: Date;
  source: CoachThreadSource;
  messages: ICoachThreadMessage[];
}

const emptyByKind = (): Record<CoachContentKind, number> =>
  Object.values(CoachContentKind).reduce(
    (acc, kind) => ({ ...acc, [kind]: 0 }),
    {} as Record<CoachContentKind, number>,
  );

/**
 * One feed of everything a reader has typed into the coach.
 *
 * Four collections read separately and merged here rather than a `$unionWith`
 * aggregation: the shapes differ in more than field names (one carries a round
 * number, one a plan id, one is a field on a session), and a union would have to
 * project them into a common shape anyway — in a query language, where the
 * mapping would be much harder to read than the map above.
 *
 * The coach's own words are NOT here. It does keep them — `coach_sessions.turns`
 * holds both roles — but that document carries a TTL of
 * `COACH_SESSION_TTL_HOURS` and Mongo deletes it, so a transcript is a thing
 * this screen could only ever show for two days and then lose. What it shows
 * instead is the six things a session deliberately leaves behind, plus, for a
 * situation answer, the authored scene it was answering: that text belongs to
 * the catalogue, not to the session, so it is still there a month later.
 */
@Injectable()
export class CoachContentService {
  constructor(
    private readonly evidenceRepository: CoachEvidenceRepository,
    private readonly problemStatementRepository: CoachProblemStatementRepository,
    private readonly situationAnswerRepository: CoachSituationAnswerRepository,
    private readonly dipRepository: CoachSessionDipRepository,
    private readonly situationRepository: CoachSituationRepository,
    private readonly userRepository: UserRepository,
  ) {}

  async findForAdmin(dto: GetCoachContentsDto): Promise<{
    rows: ICoachContentRow[];
    total: number;
    truncated: boolean;
    limit: number;
    /** Only when the caller asked for one user — the thread's header. */
    user?: { userId: string; name: string | null; email: string | null };
  }> {
    const limit = dto.limit ?? DEFAULT_LIMIT;
    const wanted = dto.kinds?.length ? new Set(dto.kinds) : null;
    const filter = { ...this.window(dto), limit };

    // A source whose kinds were all filtered out is not queried at all — the
    // point of the kind filter is to read less, not to read everything and throw
    // most of it away.
    const needs = (...kinds: CoachContentKind[]) =>
      !wanted || kinds.some(kind => wanted.has(kind));

    const [evidence, statements, answers, dips] = await Promise.all([
      needs(CoachContentKind.EVIDENCE)
        ? this.evidenceRepository.findForAdmin(filter)
        : [],
      needs(
        CoachContentKind.PROBLEM_STATEMENT,
        CoachContentKind.QUICK_NOTE,
        CoachContentKind.BARRIER,
      )
        ? this.problemStatementRepository.findForAdmin(filter)
        : [],
      needs(CoachContentKind.SITUATION_ANSWER)
        ? this.situationAnswerRepository.findForAdmin(filter)
        : [],
      needs(CoachContentKind.DIP)
        ? this.dipRepository.findDipsForAdmin(filter)
        : [],
    ]);

    const rows: ICoachContentRow[] = [
      ...evidence.map((row: any) => ({
        id: String(row._id),
        kind: CoachContentKind.EVIDENCE,
        userId: row.userId,
        content: row.content,
        habitId: row.habitId ?? null,
        sessionId: null,
        createdAt: row.createdAt,
        meta: { planId: row.planId ?? null },
      })),
      ...statements.map((row: any) => ({
        id: String(row._id),
        kind: statementKindOf(row),
        userId: row.userId,
        content: row.content,
        habitId: row.habitId ?? null,
        sessionId: row.sessionId ?? null,
        createdAt: row.createdAt,
        meta: {
          planId: row.planId ?? null,
          // How much of the AI's two-column draft the reader had to drag out.
          // Near zero across many rows is the direct signal that the draft is
          // imposing a reading rather than offering one.
          draftProposedCount: row.draftProposedCount ?? null,
          draftKeptCount: row.draftKeptCount ?? null,
        },
      })),
      ...answers.map((row: any) => ({
        id: String(row._id),
        kind: CoachContentKind.SITUATION_ANSWER,
        userId: row.userId,
        content: row.content,
        habitId: row.habitId ?? null,
        sessionId: row.sessionId ?? null,
        createdAt: row.createdAt,
        meta: {
          situationId: row.situationId ?? null,
          variant: row.variant ?? null,
          round: row.round ?? null,
          // Frozen at write time; the catalogue join below only fills the gap
          // left by rows written before the snapshot existed.
          situationPrompt: row.promptSnapshot ?? undefined,
        },
      })),
      ...dips.map((row: any) => ({
        id: `${String(row._id)}:dip`,
        kind: CoachContentKind.DIP,
        userId: row.userId,
        content: row.dip,
        habitId: row.habitId ?? null,
        sessionId: String(row._id),
        createdAt: row.createdAt,
        meta: {},
      })),
    ];

    rows.sort(
      (left, right) =>
        new Date(right.createdAt).getTime() - new Date(left.createdAt).getTime(),
    );

    // Each source was capped at `limit`, so the merge can hold up to 4× that.
    // Reported rather than hidden: a truncated feed that looks complete is how
    // somebody concludes a quiet week from a full one.
    const truncated = rows.length > limit;
    const page = rows.slice(0, limit);

    // The scenes are joined AFTER the slice: the rows thrown away by the cap
    // must not cost a second query.
    await this.attachSituationPrompts(page);

    return {
      rows: page,
      total: rows.length,
      truncated,
      limit,
      ...(dto.userId ? { user: await this.identity(dto.userId) } : {}),
    };
  }

  /**
   * The readers behind the feed, most recently active first.
   *
   * Four roll-ups merged the same way the feed is, because the same six kinds
   * come from the same four places. `lastAt` is what the screen sorts on: the
   * question this list answers is "who has been writing", and the answer is
   * useless in id order.
   */
  async findUsersForAdmin(dto: GetCoachContentUsersDto): Promise<{
    rows: ICoachContentUserRow[];
    total: number;
    truncated: boolean;
    limit: number;
  }> {
    const limit = dto.limit ?? DEFAULT_LIMIT;
    const wanted = dto.kinds?.length ? new Set(dto.kinds) : null;
    const filter = this.window(dto);

    const needs = (...kinds: CoachContentKind[]) =>
      !wanted || kinds.some(kind => wanted.has(kind));

    const [evidence, statements, answers, dips] = await Promise.all([
      needs(CoachContentKind.EVIDENCE)
        ? this.evidenceRepository.aggregateUsersForAdmin(filter)
        : [],
      needs(
        CoachContentKind.PROBLEM_STATEMENT,
        CoachContentKind.QUICK_NOTE,
        CoachContentKind.BARRIER,
      )
        ? this.problemStatementRepository.aggregateUsersForAdmin(filter)
        : [],
      needs(CoachContentKind.SITUATION_ANSWER)
        ? this.situationAnswerRepository.aggregateUsersForAdmin(filter)
        : [],
      needs(CoachContentKind.DIP)
        ? this.dipRepository.aggregateUsersForAdmin(filter)
        : [],
    ]);

    const merged = new Map<string, ICoachContentUserRow>();

    const fold = (
      rollup: { userId: string; count: number; firstAt: Date; lastAt: Date },
      kind: CoachContentKind,
    ) => {
      const current =
        merged.get(rollup.userId) ??
        ({
          userId: rollup.userId,
          name: null,
          email: null,
          anonymous: false,
          firstAt: rollup.firstAt,
          lastAt: rollup.lastAt,
          total: 0,
          byKind: emptyByKind(),
        } as ICoachContentUserRow);

      current.total += rollup.count;
      current.byKind[kind] += rollup.count;
      if (new Date(rollup.firstAt) < new Date(current.firstAt)) {
        current.firstAt = rollup.firstAt;
      }
      if (new Date(rollup.lastAt) > new Date(current.lastAt)) {
        current.lastAt = rollup.lastAt;
      }

      merged.set(rollup.userId, current);
    };

    evidence.forEach(row => fold(row, CoachContentKind.EVIDENCE));
    answers.forEach(row => fold(row, CoachContentKind.SITUATION_ANSWER));
    dips.forEach(row => fold(row, CoachContentKind.DIP));
    statements.forEach(row => {
      // Three of the six kinds share this collection, so a row that maps onto a
      // kind the caller filtered out is dropped here rather than in the query.
      const kind =
        STATEMENT_KIND_MAP[row.kind ?? ''] ??
        CoachContentKind.PROBLEM_STATEMENT;
      if (wanted && !wanted.has(kind)) return;
      fold(row, kind);
    });

    const all = [...merged.values()].sort(
      (left, right) =>
        new Date(right.lastAt).getTime() - new Date(left.lastAt).getTime(),
    );
    const page = all.slice(0, limit);

    const identities = await this.userRepository.findAdminIdentitiesByIds(
      page.map(row => row.userId),
    );
    const byId = new Map(
      identities.map((user: any) => [String(user._id), user]),
    );
    for (const row of page) {
      const user = byId.get(row.userId);
      row.name = user?.name ?? null;
      row.email = user?.email ?? null;
      row.anonymous = user?.anonymous ?? false;
    }

    return { rows: page, total: all.length, truncated: all.length > limit, limit };
  }


  /**
   * One reader's Coach history, rebuilt into conversations.
   *
   * Two sources, and which one a session gets is simply whether its document is
   * still alive: within `COACH_SESSION_TTL_HOURS` the exchange is read back from
   * `turns` exactly as it happened; after that only the durable rows remain and
   * the thread is reconstructed around them. The screen says which, per session,
   * because "Coach asked X" and "Coach asks X at this step" are not the same
   * claim and an admin drawing conclusions needs to know which they are reading.
   */
  async findThreadForAdmin(dto: GetCoachContentsDto & { userId: string }): Promise<{
    user: { userId: string; name: string | null; email: string | null };
    sessions: ICoachThreadSession[];
    truncated: boolean;
    limit: number;
  }> {
    const limit = dto.limit ?? DEFAULT_LIMIT;
    const [feed, sessions, user] = await Promise.all([
      this.findForAdmin({ ...dto, limit }),
      this.dipRepository.findSessionsForAdmin({
        userId: dto.userId,
        ...this.dateWindow(dto),
        limit,
      }),
      this.identity(dto.userId),
    ]);

    // Rows are consumed as they are matched, so whatever is left over at the
    // end is exactly the set whose session has already expired.
    const unclaimed = new Map<string, ICoachContentRow[]>();
    for (const row of feed.rows) {
      const key = row.sessionId ?? '';
      unclaimed.set(key, [...(unclaimed.get(key) ?? []), row]);
    }

    const threads: ICoachThreadSession[] = [];

    for (const session of sessions as any[]) {
      const sessionId = String(session._id);
      const turns = (session.turns ?? []) as Array<{
        role: string;
        text: string;
        step?: string;
        at: Date;
      }>;
      const rows = unclaimed.get(sessionId) ?? [];
      unclaimed.delete(sessionId);

      if (!turns.length) {
        // An empty transcript is a session nobody said anything in. If it left
        // rows behind, they are still worth showing — rebuilt, like an expired
        // one; if it left nothing, it is not a conversation and is dropped.
        if (rows.length) threads.push(this.rebuild(sessionId, session, rows));
        continue;
      }

      const claimed = new Set<string>();
      const messages: ICoachThreadMessage[] = turns.map((turn) => {
        const message: ICoachThreadMessage = {
          at: turn.at,
          role: turn.role === 'coach' ? 'coach' : 'user',
          text: turn.text,
          step: turn.step ?? null,
        };
        if (message.role === 'user') {
          // The same sentence is in both places when a step files it: one
          // bubble, carrying the label the row gives it.
          const row = rows.find(
            (candidate) =>
              !claimed.has(candidate.id) &&
              candidate.content?.trim() === turn.text?.trim(),
          );
          if (row) {
            claimed.add(row.id);
            message.kind = row.kind;
            message.meta = row.meta;
          }
        }
        return message;
      });

      // A row whose text never appears in the transcript — a dip lifted out of
      // a longer sentence, say — is appended at its own time rather than
      // dropped, because it IS something the reader wrote.
      for (const row of rows) {
        if (claimed.has(row.id)) continue;
        messages.push({
          at: row.createdAt,
          role: 'user',
          text: row.content,
          kind: row.kind,
          meta: row.meta,
        });
      }

      messages.sort(
        (left, right) =>
          new Date(left.at).getTime() - new Date(right.at).getTime(),
      );

      threads.push({
        sessionId,
        entry: session.entry ?? null,
        habitId: session.habitId ?? null,
        startedAt: session.createdAt,
        endedAt: messages[messages.length - 1]?.at ?? session.createdAt,
        source: 'transcript',
        messages,
      });
    }

    // Everything still unclaimed belongs to a session Mongo has already
    // deleted — or, for `câu kể`, to no session at all.
    for (const [key, rows] of Array.from(unclaimed.entries())) {
      if (key) {
        threads.push(this.rebuild(key, null, rows));
        continue;
      }
      // Câu kể is written on the habit screen, not inside a session. Grouping
      // it by day rather than hanging it off the nearest session keeps the
      // thread from claiming a context it never had.
      const byDay = new Map<string, ICoachContentRow[]>();
      for (const row of rows) {
        const day = new Date(row.createdAt).toISOString().slice(0, 10);
        byDay.set(day, [...(byDay.get(day) ?? []), row]);
      }
      for (const [, dayRows] of Array.from(byDay.entries())) {
        threads.push(this.rebuild(null, null, dayRows));
      }
    }

    threads.sort(
      (left, right) =>
        new Date(left.startedAt).getTime() - new Date(right.startedAt).getTime(),
    );

    return {
      user,
      sessions: threads,
      truncated: feed.truncated,
      limit,
    };
  }

  /**
   * A conversation rebuilt from the rows it left behind.
   *
   * Each row becomes two messages: the question, then the answer. The question
   * is real text only for a scene — everything else the Coach says at that step
   * is a fixed line the client renders from its own translations, so it is left
   * null with the row's kind for the screen to fill in and mark.
   */
  private rebuild(
    sessionId: string | null,
    session: any,
    rows: ICoachContentRow[],
  ): ICoachThreadSession {
    const ordered = [...rows].sort(
      (left, right) =>
        new Date(left.createdAt).getTime() - new Date(right.createdAt).getTime(),
    );

    const messages: ICoachThreadMessage[] = [];
    for (const row of ordered) {
      const prompt = row.meta?.situationPrompt as string | undefined;
      messages.push({
        at: row.createdAt,
        role: 'coach',
        text: prompt ?? null,
        kind: row.kind,
        derived: true,
      });
      messages.push({
        at: row.createdAt,
        role: 'user',
        text: row.content,
        kind: row.kind,
        meta: row.meta,
      });
    }

    return {
      sessionId,
      entry: session?.entry ?? null,
      habitId: session?.habitId ?? ordered[0]?.habitId ?? null,
      startedAt: ordered[0]?.createdAt,
      endedAt: ordered[ordered.length - 1]?.createdAt,
      source: 'derived',
      messages,
    };
  }

  /** The filters shared by the reads, dates parsed once. */
  private window(dto: GetCoachContentsDto | GetCoachContentUsersDto) {
    return {
      userId: (dto as GetCoachContentsDto).userId,
      habitId: dto.habitId,
      ...this.dateWindow(dto),
      search: dto.search?.trim() || undefined,
    };
  }

  private dateWindow(dto: GetCoachContentsDto | GetCoachContentUsersDto) {
    return {
      from: dto.from ? new Date(`${dto.from}T00:00:00`) : undefined,
      // End of day: `to` names a whole day, and `$lte` on its midnight would
      // silently drop everything written during it.
      to: dto.to ? new Date(`${dto.to}T23:59:59.999`) : undefined,
    };
  }

  private async identity(userId: string) {
    const [user] = await this.userRepository.findAdminIdentitiesByIds([userId]);

    return {
      userId,
      name: (user as any)?.name ?? null,
      email: (user as any)?.email ?? null,
    };
  }

  /**
   * Hangs the authored scene text onto every situation answer in the page.
   *
   * One query for the whole page rather than one per row, and a miss is left as
   * null rather than reported: a scene deleted from the catalogue must not blank
   * out the answer somebody typed into it.
   */
  private async attachSituationPrompts(rows: ICoachContentRow[]) {
    const ids = [
      ...new Set(
        rows
          .filter(
            row =>
              row.kind === CoachContentKind.SITUATION_ANSWER &&
              !row.meta.situationPrompt,
          )
          .map(row => row.meta.situationId as string | null)
          .filter((id): id is string => !!id),
      ),
    ];
    if (!ids.length) return;

    const situations = await this.situationRepository.findPromptsByIds(ids);
    const byId = new Map(
      situations.map((situation: any) => [String(situation._id), situation]),
    );

    for (const row of rows) {
      if (row.kind !== CoachContentKind.SITUATION_ANSWER) continue;
      if (row.meta.situationPrompt) continue;
      const situation = byId.get(String(row.meta.situationId ?? ''));
      if (!situation) continue;

      // Round 2 and up are answers to the scene's second stage, which is a
      // different question — showing the opening prompt against them would
      // misrepresent what the reader was replying to.
      const round = Number(row.meta.round ?? 1);
      row.meta.situationPrompt =
        (round > 1 ? situation.promptStage2 : null) ?? situation.prompt ?? null;
      row.meta.situationLevel = situation.level ?? null;
    }
  }

  /**
   * Xoá một dòng khỏi màn nội dung — sáu loại, bốn nguồn, một cửa.
   *
   * Hard delete có chủ ý: màn này dùng để dọn rác và để xoá theo yêu cầu của
   * người viết, mà cả hai việc đó thì một cờ `deletedAt` không làm xong.
   *
   * Riêng `evidence` còn được `WeekRecapService` đọc để dựng "Tuần qua" của
   * user, nên xoá một câu kể là đổi bản tổng kết tuần của họ — admin được cảnh
   * báo trước ở hộp xác nhận.
   */
  async removeForAdmin(kind: CoachContentKind, id: string): Promise<void> {
    switch (kind) {
      case CoachContentKind.EVIDENCE:
        return this.assertDeleted(
          await this.evidenceRepository.deleteOne({ _id: id }),
        );

      case CoachContentKind.SITUATION_ANSWER:
        return this.assertDeleted(
          await this.situationAnswerRepository.deleteOne({ _id: id }),
        );

      case CoachContentKind.PROBLEM_STATEMENT:
      case CoachContentKind.QUICK_NOTE:
      case CoachContentKind.BARRIER: {
        // Ba loại chung một collection, nên id thôi chưa đủ: đọc dòng ra và
        // đối chiếu loại trước. Id đúng mà loại sai là bấm nhầm dòng chứ không
        // phải một lệnh xoá hợp lệ, và nó sẽ xoá mất chữ của người khác.
        const row = await this.problemStatementRepository.findById(id);
        if (!row || statementKindOf(row) !== kind) {
          throw new NotFoundException('Coach content not found');
        }
        return this.assertDeleted(
          await this.problemStatementRepository.deleteOne({ _id: id }),
        );
      }

      case CoachContentKind.DIP: {
        // Feed phát id dạng `<sessionId>:dip` vì dịp là field chứ không phải
        // bản ghi. Bỏ hậu tố rồi mới xuống repository.
        const result = await this.dipRepository.clearDip(
          id.replace(/:dip$/, ''),
        );
        if (!result?.modifiedCount) {
          throw new NotFoundException('Coach content not found');
        }
        return;
      }

      default:
        throw new NotFoundException('Coach content not found');
    }
  }

  /**
   * Một lượt xoá không trúng gì là dòng đã bị người khác xoá trước, hoặc id
   * sai. Báo ra, chứ trả về thành công thì màn hình sẽ gỡ mất một dòng vẫn
   * đang nằm trong database.
   */
  private assertDeleted(result: { deletedCount?: number }): void {
    if (!result?.deletedCount) {
      throw new NotFoundException('Coach content not found');
    }
  }
}
