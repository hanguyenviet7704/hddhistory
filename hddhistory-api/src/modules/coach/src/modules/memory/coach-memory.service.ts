import { Injectable, Logger } from '@nestjs/common';

import {
  buildMemoryCard,
  rankByFreshness,
  splitForCard,
} from './coach-memory-card';
import { ExtractedMemory, mergeMemory } from './coach-memory-merge';
import { looksLikeRecallQuestion, recallKeywords } from './coach-memory-recall';
import { CoachAi } from '../ai/coach-ai.types';
import {
  CoachGoalStatus,
  CoachMemoryStatus,
  CoachMemoryType,
  ICoachMemory,
  ICoachMessage,
} from './interface/memory.interface';
import { CoachEpisodeRepository } from './repository/coach-episode.repository';
import { CoachMemoryCardRepository } from './repository/coach-memory-card.repository';
import { CoachGoalRepository } from './repository/coach-goal.repository';
import { CoachMemoryRepository } from './repository/coach-memory.repository';
import { CoachMessageRepository } from './repository/coach-message.repository';
import { CoachProgressRepository } from './repository/coach-progress.repository';
import {
  MEMORY_CARD_EPISODES_LIMIT,
  MEMORY_CARD_GOALS_LIMIT,
  MEMORY_CARD_PROGRESS_LIMIT,
  MEMORY_EXTRACT_KNOWN_LIMIT,
  MEMORY_EXTRACT_LOOKBACK_LINES,
  MEMORY_EXTRACT_MAX,
  MEMORY_EXTRACT_MIN_USER_LINES,
  MEMORY_GREETING_TOPIC_MAX_CHARS,
  MEMORY_LIVE_CAP,
  MEMORY_RANK_SCAN_LIMIT,
  MEMORY_RECALL_MAX_LINES,
  MEMORY_RECALL_SCAN_LINES,
} from '../../shared/coach.constant';

/**
 * The Coach's memory of a reader (owner's doc 2026-09-04).
 *
 *   RAW      = source of truth        → `record`
 *   MEMORY   = compressed knowledge   → `extractFromSession` (after a session)
 *   CARD     = cái đi vào prompt       → `rebuildCard` / `cardFor`
 *   RECALL   = chữ nguyên văn khi được hỏi → `recallFor`
 *
 * Từ 2026-09-17 tầng đọc KHÔNG còn dựng lại khối nhớ mỗi lượt. `contextFor` cũ
 * làm bốn query rồi nối thành một khối dài theo số dòng tìm được — nó lớn dần
 * theo lịch sử người dùng, đúng chỗ owner lo tràn context. Giờ thẻ được dựng
 * sẵn lúc cô đọng (off-clock) với cap cứng, và đường nóng chỉ còn một query.
 *
 * Vector search vẫn để sau. Nothing here runs on the reader's clock except
 * `cardFor`/`recallFor`, and every failure is logged, never surfaced.
 */
@Injectable()
export class CoachMemoryService {
  private readonly logger = new Logger(CoachMemoryService.name);

  constructor(
    private readonly messages: CoachMessageRepository,
    private readonly memories: CoachMemoryRepository,
    private readonly goals: CoachGoalRepository,
    private readonly episodes: CoachEpisodeRepository,
    private readonly progress: CoachProgressRepository,
    private readonly cards: CoachMemoryCardRepository,
    private readonly ai: CoachAi,
  ) {}

  /** RAW — every line, as it was said. Best effort; never blocks a reply. */
  async record(rows: ICoachMessage[]): Promise<void> {
    const kept = rows.filter((row) => row.content?.trim());
    if (!kept.length) return;
    try {
      await this.messages.recordMany(
        kept.map((row) => ({ ...row, content: row.content.trim() })),
      );
    } catch (error: any) {
      this.logger.warn(`Coach could not record messages: ${error?.message}`);
    }
  }

  /**
   * MEMORY — read what has been said SINCE the last time we read, and merge
   * what it adds.
   *
   * Existing rows are reinforced by id (evidence and confidence step up on the
   * same row); new ones start doubtful; a pattern heard once is only possible.
   * Skipped when the reader barely spoke — there is nothing to learn from a
   * session that was one tap.
   *
   * TĂNG DẦN từ 2026-09-17. Bản trước đọc lại TOÀN BỘ transcript mỗi lần cô
   * đọng, mà một phiên Home cô đọng lại mỗi `MEMORY_MIDSESSION_EVERY_LINES`
   * lượt: phiên 24 lượt đọc 60 dòng cho 24 dòng thật, và trả tiền token cho
   * đúng phần chênh đó. `since` là vạch của lần trước, do phiên giữ
   * (`memoryExtractedAt`) vì phiên là chủ của trạng thái ấy; hàm này trả về vạch
   * mới để chỗ gọi ghi lại, chứ không tự ghi vào doc của module khác.
   */
  async extractFromSession(params: {
    userId: string;
    sessionId: string;
    locale: string;
    /** Vạch của lần cô đọng trước trong CHÍNH phiên này. Null = chưa lần nào. */
    since?: Date | null;
    /** Phiên đã kết: xin thêm mảnh chủ đề cho câu chào lần mở sau. */
    final?: boolean;
  }): Promise<Date | null> {
    const { userId, sessionId, locale } = params;
    const startedAt = new Date();
    try {
      const { lines, alreadyRead } = (await this.messages.findForSessionAfter(
        sessionId,
        params.since ?? null,
        MEMORY_EXTRACT_LOOKBACK_LINES,
      )) as {
        lines: Array<{ role: 'user' | 'coach'; content: string }>;
        alreadyRead: number;
      };

      // Chỉ đếm dòng MỚI: mấy dòng ngữ cảnh đã được cô đọng ở lần trước, và
      // một cửa sổ chỉ có chúng thì không có gì để học — `close()` ngay sau một
      // lần cô đọng giữa phiên rơi đúng vào trường hợp này.
      const userLines = lines
        .slice(alreadyRead)
        .filter((l) => l.role === 'user').length;
      if (userLines < MEMORY_EXTRACT_MIN_USER_LINES) return null;

      const [known, activeGoals, card] = await Promise.all([
        this.memories.findLiveForUser(
          userId,
          MEMORY_EXTRACT_KNOWN_LIMIT,
        ) as Promise<Array<ICoachMemory & { _id: unknown }>>,
        this.goals.findActiveForUser(userId, 10) as Promise<
          Array<{ _id: unknown; goal: string; status: string }>
        >,
        this.cardFor(userId),
      ]);

      const extracted = await this.ai.extractMemory({
        locale,
        transcript: lines.map((l) => ({ role: l.role, text: l.content })),
        alreadyRead,
        memories: known.map((m) => ({
          id: String(m._id),
          type: m.type,
          content: m.content,
          status: m.status,
        })),
        goals: activeGoals.map((g) => ({
          id: String(g._id),
          goal: g.goal,
          status: g.status,
        })),
        card,
        wantGreeting: params.final === true,
      });

      const now = new Date();
      const knownById = new Map(known.map((m) => [String(m._id), m]));
      const types = Object.values(CoachMemoryType) as string[];
      const statuses = Object.values(CoachMemoryStatus) as string[];

      for (const raw of extracted.memories.slice(0, MEMORY_EXTRACT_MAX)) {
        if (!raw?.content?.trim() || !types.includes(raw.type)) continue;
        const item: ExtractedMemory = {
          id: raw.id ?? null,
          type: raw.type as CoachMemoryType,
          content: raw.content,
          confidence: Number(raw.confidence),
          status:
            raw.status && statuses.includes(raw.status)
              ? (raw.status as CoachMemoryStatus)
              : null,
        };
        const existing = item.id ? knownById.get(item.id) ?? null : null;
        const merged = mergeMemory(existing, item, sessionId, now);
        if (existing) {
          await this.memories.updateOne({ _id: existing._id }, merged);
        } else {
          await this.memories.create({ userId, ...merged } as never);
        }
      }

      const goalById = new Map(activeGoals.map((g) => [String(g._id), g]));
      const goalStatuses = Object.values(CoachGoalStatus) as string[];
      for (const raw of extracted.goals) {
        if (!raw?.goal?.trim()) continue;
        const status =
          raw.status && goalStatuses.includes(raw.status)
            ? (raw.status as CoachGoalStatus)
            : null;
        const progressValue =
          typeof raw.progress === 'number'
            ? Math.max(0, Math.min(100, Math.round(raw.progress)))
            : null;
        const existing = raw.id ? goalById.get(raw.id) : null;
        if (existing) {
          await this.goals.updateOne(
            { _id: existing._id },
            {
              ...(status ? { status } : {}),
              ...(progressValue !== null ? { progress: progressValue } : {}),
              $addToSet: { sourceSessionIds: sessionId },
            } as never,
          );
        } else {
          await this.goals.create({
            userId,
            goal: raw.goal.trim(),
            status: status ?? CoachGoalStatus.ACTIVE,
            priority: 0,
            progress: progressValue ?? 0,
            sourceSessionIds: [sessionId],
          } as never);
        }
      }

      for (const ep of extracted.episodes.slice(0, 2)) {
        if (!ep?.situation?.trim()) continue;
        await this.episodes.create({
          userId,
          sessionId,
          situation: ep.situation.trim(),
          emotion: ep.emotion?.trim() || null,
          insight: ep.insight?.trim() || null,
        } as never);
      }

      for (const step of extracted.progress) {
        if (!step?.goal?.trim() || !step?.action?.trim()) continue;
        await this.progress.create({
          userId,
          sessionId,
          goal: step.goal.trim(),
          action: step.action.trim(),
          result: (step.result ?? '').trim(),
        } as never);
      }

      await this.retireOverCap(userId);
      await this.rebuildCard(userId, {
        sessionId,
        greetingTopic: extracted.greetingTopic ?? null,
        greetingLocale: locale,
      });

      // Vạch là lúc BẮT ĐẦU đọc, không phải lúc xong: người ta vẫn đang nói
      // trong lúc call này chạy, và mấy dòng nói giữa lúc đó phải thuộc về lần
      // cô đọng SAU. Lấy mốc lúc xong là đánh rơi chúng vĩnh viễn.
      return startedAt;
    } catch (error: any) {
      this.logger.warn(
        `Coach memory extraction failed for session ${sessionId}: ${error?.message}`,
      );

      // Không trả vạch khi thất bại: lần sau phải đọc lại đúng đoạn đó.
      return null;
    }
  }

  /**
   * THẺ NHỚ — dựng lại từ bốn collection, bằng code, không token nào.
   *
   * Gọi sau mỗi lần cô đọng, tức off-clock. `greetingTopic` chỉ được ghi khi
   * lần cô đọng ấy là lần cuối của phiên (`final`), và ghi kèm locale để câu
   * chào không bao giờ chào bằng tiếng người ta vừa đổi đi.
   */
  async rebuildCard(
    userId: string,
    meta?: {
      sessionId?: string | null;
      greetingTopic?: string | null;
      greetingLocale?: string | null;
    },
  ): Promise<string | null> {
    try {
      const [live, goals, episodes, progress] = await Promise.all([
        this.memories.findRecentLiveForUser(
          userId,
          MEMORY_RANK_SCAN_LIMIT,
        ) as Promise<Array<ICoachMemory>>,
        this.goals.findActiveForUser(userId, MEMORY_CARD_GOALS_LIMIT) as Promise<
          Array<{ goal: string; progress: number }>
        >,
        this.episodes.findRecentForUser(
          userId,
          MEMORY_CARD_EPISODES_LIMIT,
        ) as Promise<
          Array<{ situation: string; emotion?: string | null; insight?: string | null }>
        >,
        this.progress.findRecentForUser(
          userId,
          MEMORY_CARD_PROGRESS_LIMIT,
        ) as Promise<Array<{ goal: string; action: string; result: string }>>,
      ]);

      const { people, patterns } = splitForCard(rankByFreshness(live));
      const card = buildMemoryCard({ people, goals, episodes, progress, patterns });

      const topic = (meta?.greetingTopic ?? '').trim();
      await this.cards.save(userId, {
        card,
        builtAt: new Date(),
        builtFromSessionId: meta?.sessionId ?? null,
        ...(topic
          ? {
              greetingTopic: topic.slice(0, MEMORY_GREETING_TOPIC_MAX_CHARS),
              greetingLocale: meta?.greetingLocale ?? null,
              greetingUsedAt: null,
            }
          : {}),
      });

      return card;
    } catch (error: any) {
      this.logger.warn(`Coach could not rebuild the memory card: ${error?.message}`);

      return null;
    }
  }

  /** Thẻ đã dựng sẵn — một query, thay cho bốn query dựng lại mỗi lượt. */
  async cardFor(userId: string): Promise<string | null> {
    try {
      const row = (await this.cards.findForUser(userId)) as {
        card?: string | null;
      } | null;

      return row?.card?.trim() || null;
    } catch (error: any) {
      this.logger.warn(`Coach could not read the memory card: ${error?.message}`);

      return null;
    }
  }

  /**
   * Mảnh chủ đề cho câu chào mở phiên, nếu có và còn dùng được.
   *
   * Im lặng khi: chưa có, đã chào rồi, hoặc được viết bằng ngôn ngữ khác ngôn
   * ngữ đang dùng. Trường hợp cuối là thật: người ta đổi ngôn ngữ app giữa hai
   * phiên, và một câu chào nửa tiếng Việt nửa tiếng Nhật tệ hơn không chào.
   */
  async greetingTopicFor(
    userId: string,
    locale: string,
  ): Promise<string | null> {
    try {
      const row = (await this.cards.findForUser(userId)) as {
        greetingTopic?: string | null;
        greetingLocale?: string | null;
        greetingUsedAt?: Date | null;
      } | null;
      if (!row?.greetingTopic?.trim()) return null;
      if (row.greetingUsedAt) return null;
      if ((row.greetingLocale ?? locale) !== locale) return null;

      return row.greetingTopic.trim();
    } catch (error: any) {
      this.logger.warn(`Coach could not read the greeting topic: ${error?.message}`);

      return null;
    }
  }

  /** Chào một lần. Best effort: chào hai lần còn đỡ hơn không chào được vì lỗi ghi. */
  async markGreetingUsed(userId: string): Promise<void> {
    try {
      await this.cards.markGreetingUsed(userId, new Date());
    } catch (error: any) {
      this.logger.warn(`Coach could not mark the greeting used: ${error?.message}`);
    }
  }

  /**
   * TRA CỨU — chữ nguyên văn, chỉ khi người ta vừa hỏi thẳng về quá khứ.
   *
   * Trả null ở mọi lối rẽ khác, và đó là điểm chính của thiết kế: khối này tốn
   * hai query nên nó không được chạy ở lượt kể chuyện bình thường. Khi hỏi mà
   * không tìm thấy gì, vẫn trả null — prompt khi đó chỉ có thẻ nhớ, và luật
   * "không có thì nói thật là không nhớ rõ" nằm trong khối thẻ.
   */
  async recallFor(
    userId: string,
    text: string | null | undefined,
  ): Promise<string | null> {
    if (!looksLikeRecallQuestion(text)) return null;

    const keywords = recallKeywords(text);
    if (!keywords.length) return null;

    try {
      const [lines, episodes] = await Promise.all([
        this.messages.searchRecentForUser(
          userId,
          keywords,
          MEMORY_RECALL_SCAN_LINES,
          MEMORY_RECALL_MAX_LINES,
        ) as Promise<Array<{ role: string; content: string }>>,
        this.episodes.searchForUser(
          userId,
          keywords,
          MEMORY_CARD_EPISODES_LIMIT,
        ) as Promise<
          Array<{ situation: string; emotion?: string | null; insight?: string | null }>
        >,
      ]);

      const rendered = [
        ...episodes.map(
          (ep) =>
            `- a moment they told you about: ${ep.situation}${ep.emotion ? ` — ${ep.emotion}` : ''}${ep.insight ? ` — they concluded: ${ep.insight}` : ''}`,
        ),
        ...lines.map(
          (line) =>
            `- ${line.role === 'coach' ? 'you said' : 'they said'}: ${line.content}`,
        ),
      ];

      return rendered.length ? rendered.join('\n') : null;
    } catch (error: any) {
      this.logger.warn(`Coach recall lookup failed: ${error?.message}`);

      return null;
    }
  }

  /**
   * Cho những dòng yếu nhất nghỉ khi một người đã vượt `MEMORY_LIVE_CAP`.
   *
   * Không xoá — "không được chỉ lưu summary rồi xoá raw" là luật của tầng này,
   * và một dòng `inactive` vẫn kiểm toán được. Xếp bằng đúng hàm xếp của thẻ,
   * nên thứ bị cho nghỉ luôn là thứ đã không còn chen nổi vào thẻ.
   */
  private async retireOverCap(userId: string): Promise<void> {
    try {
      const count = await this.memories.countLiveForUser(userId);
      if (count <= MEMORY_LIVE_CAP) return;

      const live = (await this.memories.findRecentLiveForUser(
        userId,
        count,
      )) as Array<ICoachMemory & { _id: unknown }>;
      const ranked = rankByFreshness(live);
      const doomed = ranked.slice(MEMORY_LIVE_CAP).map((row) => row._id);

      await this.memories.retire(doomed);
      this.logger.log(
        `Coach retired ${doomed.length} memories over the cap for user ${userId}`,
      );
    } catch (error: any) {
      this.logger.warn(`Coach could not retire memories: ${error?.message}`);
    }
  }

  /**
   * ĐUÔI của phiên trước, nguyên văn, cũ trước mới sau.
   *
   * Đọc log thô `coach_messages` chứ không đọc thẻ: thẻ là bản cô đọng và đã bị
   * rào "never as fact", nên nó không trả lời được câu "tôi vừa nói ở trên".
   * Bỏ phiên hiện tại để không lặp hai lần — lời của phiên này đã nằm trong
   * `session.turns`.
   *
   * `limit` giờ là `PRIOR_TAIL_LINES` (6) chứ không phải 30: phần xa hơn đã
   * được cô đọng vào thẻ, và 30 dòng raw là cách lớn dần theo lịch sử.
   */
  async priorLinesFor(
    userId: string,
    sessionId: string,
    limit: number,
  ): Promise<Array<{ role: 'user' | 'coach'; text: string }>> {
    try {
      const rows = (await this.messages.findRecentForUserExcludingSession(
        userId,
        sessionId,
        limit,
      )) as Array<{ role: 'user' | 'coach'; content: string }>;

      return rows
        .reverse()
        .map((r) => ({ role: r.role, text: r.content }))
        .filter((r) => r.text?.trim());
    } catch (error: any) {
      this.logger.warn(`Coach could not read prior lines: ${error?.message}`);

      return [];
    }
  }
}
