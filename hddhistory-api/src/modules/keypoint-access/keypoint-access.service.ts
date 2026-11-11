import { Injectable } from '@nestjs/common';

import { RequestService } from '@base/service/request.service';
import { UserProgressRepository } from 'src/modules/courses/src/modules/progress/src/modules/user-progress/repository/user-progress.repository';
import { SubscriptionService } from 'src/modules/payment/subscriptions/subscription.service';
import { PaywallConfigService } from 'src/modules/paywall-config/paywall-config.service';

import { isUserLessonKeypointId } from './keypoint-access.util';
import { KeypointQuotaLedgerService } from './keypoint-quota-ledger.service';

/** Why a keypoint reads the way it does — for the app's logs and for support. */
export type KeypointAccessReason =
  | 'quota_disabled'
  /** A lesson the reader generated — their own material is never metered. */
  | 'user_lesson'
  | 'premium'
  /** Finished on an EARLIER day: revision, free and uncapped. */
  | 'already_completed'
  /** Finished TODAY — the keypoint the day's ticket was spent on. */
  | 'todays_free_keypoint'
  /** The day still has room, so this keypoint reads in full; finishing it charges. */
  | 'ticket_available'
  /** Today's keypoints are used up: a real wall until tomorrow. */
  | 'quota_spent';

export interface KeypointAccessView {
  /**
   * Highest card index the reader may reach, or null for no limit.
   *
   * The app hands this straight to `KeypointCardCubit.setPaywallCardCap`, which is
   * the single place every deck movement is bounded. Sending the CAP rather than
   * the inputs is deliberate: the rule depends on the reader's history, so a client
   * that computed it would have to be told the history instead.
   */
  cardCap: number | null;
  reason: KeypointAccessReason;
  /** Null when the quota does not apply to this reader at all. */
  quota: {
    limit: number;
    used: number;
    remaining: number;
    /** The last keypoint the reader FINISHED today, when there is one. */
    claimedKeypointId: string | null;
  } | null;
}

export interface KeypointClaimResult {
  granted: boolean;
  cardCap: number | null;
  reason: KeypointAccessReason;
  /** The last keypoint finished today — who the day is currently spent on. */
  claimedKeypointId: string | null;
}

/**
 * How much of a keypoint a free reader may read today.
 *
 * A ticket is spent by FINISHING a keypoint (product call, 2026-08-21), not by
 * walking past the lock card as it worked before. So the day is counted in
 * keypoints completed: while the reader still has room, every keypoint opens in
 * full and nothing is charged until they actually finish one; once the day's
 * keypoints are done, everything else stops at [KeypointQuotaRules.cardCap] until
 * tomorrow. Re-reading anything already finished — today or last month — is always
 * free.
 *
 * The write side of that rule is not here: `UserProgressService` calls
 * [KeypointQuotaService.recordCompletion] when it marks a keypoint passed, because
 * that endpoint IS the completion. This service only reads the ledger.
 */
@Injectable()
export class KeypointAccessService {
  constructor(
    private readonly ledgerService: KeypointQuotaLedgerService,
    private readonly paywallConfigService: PaywallConfigService,
    private readonly subscriptionService: SubscriptionService,
    private readonly userProgressRepository: UserProgressRepository,
    private readonly requestService: RequestService,
  ) {}

  private get userId(): string {
    return this.requestService.user?.id ?? '';
  }

  /**
   * The quota block, or null when it is off.
   *
   * Fails OPEN: a config that cannot be read leaves the keypoint unlocked, matching
   * the rule the in-lesson paywall already states in code -- a paywall that cannot
   * be evaluated must not be able to lock content away.
   */
  private async resolveQuota(): Promise<{ limit: number; cardCap: number } | null> {
    try {
      const config = await this.paywallConfigService.getMobileConfig();
      const quota = config?.dailyKeypointQuota;
      if (!quota?.enabled) return null;

      const limit = quota.freeKeypointsPerDay ?? 1;
      // `cardCap` is the LAST INDEX the reader may reach, which is two below the
      // admin field: `afterCards: 3` reads "the lock stands at card 3" (1-based, the
      // wording on the admin field itself), so cards 1 and 2 are readable and the
      // last allowed index is 1.
      //
      // `- 1` here let the reader swipe THROUGH the card that was supposed to be
      // walled ("user lướt qua card thứ 3", on device 2026-08-12) -- the arithmetic
      // contradicted the comment right next to it. Note this is NOT the same
      // semantic as `inLessonPaywall.afterCards`, which COUNTS readable cards; the
      // two fields read alike and mean different things.
      const cardCap = Math.max((quota.afterCards ?? 3) - 2, 0);

      return { limit, cardCap };
    } catch (error) {
      this.logUnevaluable('config', error);
      return null;
    }
  }

  /**
   * Whether the reader holds a subscription. Always asked server-side: the app
   * knows too and uses it for its own UI, but a client-supplied flag is a request,
   * not a fact.
   */
  private async isPremium(userId: string): Promise<boolean> {
    try {
      return Boolean(await this.subscriptionService.findActivePremiumForUser(userId));
    } catch (error) {
      // Fails OPEN, like the config read: treating a premium reader as free because
      // their subscription lookup timed out would lock content they paid for.
      this.logUnevaluable('subscription', error);
      return true;
    }
  }

  private logUnevaluable(what: string, error: unknown): void {
    // Deliberately not a throw: see resolveQuota's doc. Logged because a quota
    // silently not applying is otherwise invisible.
    // eslint-disable-next-line no-console
    console.warn(`[keypoint-access] ${what} unevaluable, leaving keypoint open`, error);
  }

  /** How this keypoint should read for this caller, right now. */
  async getAccess(
    keypointId: string,
    offsetMinutes: number,
  ): Promise<KeypointAccessView> {
    // Before anything else, and before any DB read: content the reader made is
    // outside the quota entirely.
    if (isUserLessonKeypointId(keypointId)) {
      return { cardCap: null, reason: 'user_lesson', quota: null };
    }

    const quota = await this.resolveQuota();
    if (!quota) return { cardCap: null, reason: 'quota_disabled', quota: null };

    const userId = this.userId;
    // No user, no history to meter against. Every real build is authenticated.
    if (!userId) return { cardCap: null, reason: 'quota_disabled', quota: null };

    if (await this.isPremium(userId)) {
      return { cardCap: null, reason: 'premium', quota: null };
    }

    // Revision is free: a keypoint already finished on an earlier day costs
    // nothing and is never capped.
    if (await this.hasCompleted(userId, keypointId)) {
      return { cardCap: null, reason: 'already_completed', quota: null };
    }

    const completed = await this.ledgerService.completedToday(userId, offsetMinutes);
    const used = completed.length;
    const quotaView = {
      limit: quota.limit,
      used,
      remaining: Math.max(quota.limit - used, 0),
      claimedKeypointId: completed.at(-1) ?? null,
    };

    // Finished today: returning to it later the same day stays open. (A completion
    // this device has not synced yet lands on the branch below instead, which is
    // also open while the day has room — the reader never sees a wall over work
    // they have already done.)
    if (completed.includes(keypointId)) {
      return { cardCap: null, reason: 'todays_free_keypoint', quota: quotaView };
    }

    // Room left in the day: read it all. Nothing is charged here — the charge
    // happens if and when they finish it, which is what "học hết mới tính một
    // lượt" means.
    if (used < quota.limit) {
      return { cardCap: null, reason: 'ticket_available', quota: quotaView };
    }

    return { cardCap: quota.cardCap, reason: 'quota_spent', quota: quotaView };
  }

  /**
   * "May I move past the lock?" — and nothing more.
   *
   * SPENDS NOTHING since 2026-08-21. It stays because app builds already in the
   * wild call it when a swipe reaches the wall, and their behaviour has to match
   * the new rule: while the day has room they are let through, and the day is
   * charged later by the completion itself. Current builds never reach it, because
   * a reader with room is given `cardCap: null` and has no wall to cross.
   */
  async claim(
    keypointId: string,
    offsetMinutes: number,
  ): Promise<KeypointClaimResult> {
    if (isUserLessonKeypointId(keypointId)) {
      return { granted: true, cardCap: null, reason: 'user_lesson', claimedKeypointId: null };
    }

    const quota = await this.resolveQuota();
    if (!quota) {
      return { granted: true, cardCap: null, reason: 'quota_disabled', claimedKeypointId: null };
    }

    const userId = this.userId;
    if (!userId) {
      return { granted: true, cardCap: null, reason: 'quota_disabled', claimedKeypointId: null };
    }

    if (await this.isPremium(userId)) {
      return { granted: true, cardCap: null, reason: 'premium', claimedKeypointId: null };
    }

    if (await this.hasCompleted(userId, keypointId)) {
      return { granted: true, cardCap: null, reason: 'already_completed', claimedKeypointId: null };
    }

    // A limit of zero is a hard wall -- there is no day to have room in.
    if (quota.limit <= 0) {
      return {
        granted: false,
        cardCap: quota.cardCap,
        reason: 'quota_spent',
        claimedKeypointId: null,
      };
    }

    const completed = await this.ledgerService.completedToday(userId, offsetMinutes);
    const finishedThisOne = completed.includes(keypointId);
    const granted = finishedThisOne || completed.length < quota.limit;

    return {
      granted,
      cardCap: granted ? null : quota.cardCap,
      reason: granted
        ? finishedThisOne
          ? 'todays_free_keypoint'
          : 'ticket_available'
        : 'quota_spent',
      claimedKeypointId: completed.at(-1) ?? null,
    };
  }

  /** Whether this keypoint is already marked passed anywhere in the reader's progress. */
  private async hasCompleted(userId: string, keypointId: string): Promise<boolean> {
    try {
      const passed = await this.userProgressRepository.findPassedKeypointIds(userId);
      return passed.includes(keypointId);
    } catch (error) {
      // Fails OPEN, like every other branch of this gate.
      this.logUnevaluable('progress', error);
      return true;
    }
  }
}
