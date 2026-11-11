import { Injectable, Logger } from '@nestjs/common';

import { CoachBoostKind } from './enum/boost.enum';
import { ICoachBoostHistory } from './interface/boost.interface';
import { CoachBoostHistoryRepository } from './repository/coach-boost-history.repository';
import {
  COACH_BOOST_ACTION_CEILING,
  COACH_BOOST_MUTE_DAYS,
  COACH_BOOST_SKIP_LIMIT,
  RATING_ELIGIBLE_SESSIONS,
} from '../../shared/coach.constant';

/**
 * The add-ons' own rules — "quan trọng hơn từng luật riêng".
 *
 * Two things live here. Each add-on's own gate (how often, how many skips
 * before it goes quiet), and the CEILING across them: at most two add-ons that
 * cost the reader a tap per sheet-open. Without the ceiling an unlucky session
 * becomes mood → task → mood → rating → card: five interruptions for one story.
 *
 * The priority when the ceiling bites is fixed by the doc — mood cuối phiên →
 * mood đầu ngày → đánh giá Coach — because mood feeds the metric that would tell
 * us to stop building this feature at all, so it never gets pushed out.
 */
@Injectable()
export class CoachBoostService {
  private readonly logger = new Logger(CoachBoostService.name);

  /** Highest priority first — the order the ceiling spends its two slots in. */
  private static readonly PRIORITY: readonly CoachBoostKind[] = [
    CoachBoostKind.MOOD_END,
    CoachBoostKind.MOOD_START,
    CoachBoostKind.RATING,
  ];

  constructor(private readonly repository: CoachBoostHistoryRepository) {}

  /**
   * May this add-on appear now?
   *
   * `alreadyAsked` is what this sheet-open has already spent — the caller knows
   * that, the table does not. A card costs no tap, so it never counts.
   */
  async allows(params: {
    userId: string;
    kind: CoachBoostKind;
    refId?: string | null;
    /** Add-ons that have already asked for a tap in THIS sheet-open. */
    alreadyAsked: CoachBoostKind[];
    /** Bypass the frequency gate — "bật ngay bất kể tần suất". */
    urgent?: boolean;
  }): Promise<boolean> {
    const { userId, kind, refId = null, alreadyAsked, urgent = false } = params;

    const row = (await this.repository
      .findOneFor(userId, kind, refId)
      .catch(() => null)) as ICoachBoostHistory | null;

    // Muted by its own fatigue rule. Even an urgent ask respects this: a reader
    // who declined three times has answered the question.
    if (row?.mutedUntil && row.mutedUntil.getTime() > Date.now()) return false;

    if (kind === CoachBoostKind.COURSE_CARD) return true;

    // The ceiling — the card is exempt because it costs no tap.
    if (!urgent) {
      const spent = alreadyAsked.filter(
        (asked) => asked !== CoachBoostKind.COURSE_CARD,
      ).length;
      if (spent >= COACH_BOOST_ACTION_CEILING) return false;

      // Whoever outranks this one and is still to come takes the slot first.
      const rank = CoachBoostService.PRIORITY.indexOf(kind);
      if (rank > 0 && spent >= COACH_BOOST_ACTION_CEILING - 1) {
        // Only one slot left: keep it for the higher-priority add-ons.
        return false;
      }
    }

    // The rating's cadence: one in every few eligible sessions, unless urgent.
    if (kind === CoachBoostKind.RATING && !urgent) {
      const seen = row?.eligibleSince ?? 0;
      if (row?.lastShownAt && seen < RATING_ELIGIBLE_SESSIONS) return false;
    }

    return true;
  }

  /** Note that it appeared. Resets the eligible-session counter. */
  async shown(userId: string, kind: CoachBoostKind, refId: string | null = null) {
    return this.repository
      .record(userId, kind, refId, { lastShownAt: new Date(), eligibleSince: 0 })
      .catch((error: any) => {
        this.logger.warn(`Could not record a shown add-on: ${error?.message}`);

        return null;
      });
  }

  /** Note that the reader answered it — the skip run goes back to zero. */
  async answered(userId: string, kind: CoachBoostKind, refId: string | null = null) {
    return this.repository
      .record(userId, kind, refId, { skipStreak: 0, mutedUntil: null })
      .catch(() => null);
  }

  /**
   * Note that the reader skipped it.
   *
   * The third consecutive skip mutes it. The rating mutes FOREVER ("bỏ qua 3
   * lần → ẩn hẳn, không hiện lại"); the rest come back after a week.
   */
  async skipped(userId: string, kind: CoachBoostKind, refId: string | null = null) {
    const row = (await this.repository
      .findOneFor(userId, kind, refId)
      .catch(() => null)) as ICoachBoostHistory | null;

    const streak = (row?.skipStreak ?? 0) + 1;
    const muted =
      streak < COACH_BOOST_SKIP_LIMIT
        ? null
        : kind === CoachBoostKind.RATING
          ? new Date(8640000000000000)
          : new Date(Date.now() + COACH_BOOST_MUTE_DAYS * 24 * 60 * 60 * 1000);

    return this.repository
      .record(userId, kind, refId, { skipStreak: streak, mutedUntil: muted })
      .catch(() => null);
  }

  /** One more session that COULD have shown it — the rating's 1-in-3 counter. */
  async countedEligible(userId: string, kind: CoachBoostKind) {
    return this.repository.bumpEligible(userId, kind).catch(() => null);
  }
}
