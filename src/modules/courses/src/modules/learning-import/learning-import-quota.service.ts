import { Injectable } from '@nestjs/common';

import { SubscriptionService } from 'src/modules/payment/subscriptions/subscription.service';

import { LEARNING_IMPORT_CONFIG } from './learning-import.config';
import { weekWindow } from './learning-import.util';
import { LearningImportJobRepository } from './repository/learning-import-job.repository';

export interface ImportQuota {
  /**
   * This reader's own allowance: the premium weekly one, or the free tier's
   * single lifetime ticket.
   */
  limit: number;
  used: number;
  remaining: number;
  /**
   * Next Monday 00:00 -- when `used` goes back to zero.
   *
   * NULL for a free reader: their one ticket never comes back, and a date here
   * would have the app promising a refill that does not exist.
   */
  resetsAt: Date | null;
  isPremium: boolean;
  /**
   * What the allowance would be WITH a subscription.
   *
   * Sent to every reader, premium included, because it is the number the upsell
   * line quotes ("Premium gives you 5 every week"). Without it the app would have
   * to hardcode 5 and quietly start lying the day this config changes.
   */
  premiumLimit: number;
}

/**
 * Who may start an import, and how many they have left.
 *
 * Two of the four walls from the design live here (the weekly count and the free
 * tier's smaller one); the other two -- single-flight and per-source size -- sit
 * where they can actually be checked, in the service and the resolvers
 * respectively.
 *
 * Note what is NOT here: a premium GATE. A reader without a subscription is not
 * refused outright, they are given ONE ticket for the lifetime of the account
 * (`freeQuotaLifetime`), so the only question this service answers is how many
 * are left. The two tiers take different code paths because they are counted over
 * different spans -- a week for a subscriber, all of history for a free reader.
 */
@Injectable()
export class LearningImportQuotaService {
  constructor(
    private readonly jobRepository: LearningImportJobRepository,
    private readonly subscriptionService: SubscriptionService,
  ) {}

  /**
   * Whether the user currently holds an active subscription.
   *
   * Always asked server-side. The app knows the answer too and uses it to decide
   * whether to open the paywall, but a client-supplied flag is a request, not a
   * fact -- this is the check that actually gates the spend.
   */
  async isPremium(userId: string): Promise<boolean> {
    const subscription =
      await this.subscriptionService.findActivePremiumForUser(userId);

    return Boolean(subscription);
  }

  async getQuota(userId: string): Promise<ImportQuota> {
    const premiumLimit = LEARNING_IMPORT_CONFIG.quotaPerWeek;
    const isPremium = await this.isPremium(userId);

    // Two different questions, so two different counts. A subscriber's allowance
    // is a weekly window; a free reader's is one ticket for the life of the
    // account, which can only be answered by counting every import they ever ran.
    if (!isPremium) {
      const used = await this.jobRepository.countChargedAllTime(userId);
      const limit = LEARNING_IMPORT_CONFIG.freeQuotaLifetime;

      return {
        limit,
        used,
        remaining: Math.max(0, limit - used),
        resetsAt: null,
        isPremium: false,
        premiumLimit,
      };
    }

    const { from, to } = weekWindow(new Date());
    const used = await this.jobRepository.countChargedInRange(userId, from, to);

    return {
      limit: premiumLimit,
      used,
      // Clamped rather than trusted: someone who imported five this week on
      // Premium and then let it lapse would otherwise show a negative balance.
      remaining: Math.max(0, premiumLimit - used),
      resetsAt: to,
      isPremium: true,
      premiumLimit,
    };
  }
}
