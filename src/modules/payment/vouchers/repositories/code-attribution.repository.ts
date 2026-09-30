import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, MoreThanOrEqual, Repository } from 'typeorm';

import { AbstractRepository } from '@base/database/mysql/abstract.repository';

import { CodeAttribution } from '../entitys/code-attribution.entity';

/**
 * How long an applied code stays claimable by a purchase. Long enough to cover
 * a store flow that stalls (Ask-to-Buy waits on a parent, a card needs
 * re-authorising), short enough that a code typed last month cannot take
 * credit for an unrelated purchase today.
 */
export const CODE_ATTRIBUTION_WINDOW_DAYS = 7;

@Injectable()
export class CodeAttributionRepository extends AbstractRepository<CodeAttribution> {
  constructor(
    @InjectRepository(CodeAttribution) repository: Repository<CodeAttribution>,
  ) {
    super(repository);
  }

  async record(userId: string, code: string): Promise<void> {
    await this.repository.insert({ userId, code });
  }

  /**
   * Newest code this user applied that no purchase has taken yet and that is
   * still inside the window, or null.
   */
  async findClaimable(
    userId: string,
    now: Date,
    windowDays = CODE_ATTRIBUTION_WINDOW_DAYS,
  ): Promise<CodeAttribution | null> {
    const since = new Date(now.getTime() - windowDays * 24 * 60 * 60 * 1000);
    return this.repository.findOne({
      where: {
        userId,
        consumedAt: IsNull(),
        createdAt: MoreThanOrEqual(since),
      },
      order: { createdAt: 'DESC' },
    });
  }

  async markConsumed(
    id: string,
    purchaseId: string | undefined,
    now: Date,
  ): Promise<void> {
    await this.repository.update(
      { id },
      { consumedAt: now, consumedByPurchaseId: purchaseId },
    );
  }
}
