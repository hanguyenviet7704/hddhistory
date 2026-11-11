import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import { CommunityNotificationType } from '../../enum/community.enum';
import { CommunityNotificationService } from '../notification/community-notification.service';
import { CreateCommunitySanctionDto } from './dto/create-community-sanction.dto';
import { GetListCommunitySanctionDto } from './dto/get-list-community-sanction.dto';
import { CommunitySanctionRepository } from './repository/community-sanction.repository';
import { CommunitySanction } from './schema/community-sanction.schema';

@Injectable()
export class CommunitySanctionService {
  constructor(
    private readonly sanctionRepository: CommunitySanctionRepository,
    private readonly notificationService: CommunityNotificationService,
    private readonly userRepository: UserRepository,
  ) {}

  /**
   * Throws if the reader is currently muted.
   *
   * Called before every write (post, comment). The message carries the reason
   * and the date the mute lifts, because "you can't post" with no explanation
   * is the version of this that generates support tickets.
   */
  async assertCanWrite(userId: string) {
    const active = await this.sanctionRepository.findActive(userId, new Date());
    if (!active) return;

    // Under `meta`: the global exception filter forwards `message` and `meta`
    // and drops any other key, so these two were never reaching the app.
    throw new ForbiddenException({
      message: 'COMMUNITY_MUTED',
      meta: {
        reason: active.reason,
        mutedUntil: active.mutedUntil ?? null,
      },
    });
  }

  /**
   * What the app asks on entering the community.
   *
   * Lets the composer be disabled with the real explanation up front instead of
   * failing on submit. A mute is now the ONLY reason a reader cannot write:
   * guests write under the name they gave at onboarding, exactly like a member,
   * so `requiresLogin` is answered `false` for everyone.
   *
   * The field stays in the response rather than being dropped. It is what the
   * app keys its sign-in invitation off, and every shipped build reads it —
   * answering `false` is what opens the forum to guests without a release, and
   * keeps reverting this file as the way back.
   */
  async statusFor(user: { id?: string }) {
    // The first-run tour rides on THIS response rather than a call of its own:
    // the app already asks for the status on every entry to the tab, and the
    // tour has to be decided at exactly that moment.
    const tourSeen = await this.hasSeenTour(user.id);

    const active = await this.sanctionRepository.findActive(user.id, new Date());

    return {
      canPost: !active,
      requiresLogin: false,
      reason: active?.reason ?? null,
      mutedUntil: active?.mutedUntil ?? null,
      tourSeen,
    };
  }

  /**
   * Has this reader already been walked through the forum?
   *
   * Unknown reader (no id) counts as SEEN: the tour is a welcome, and showing
   * it to somebody we cannot record it against would show it again on every
   * single entry.
   */
  private async hasSeenTour(userId?: string): Promise<boolean> {
    if (!userId) return true;

    const user = await this.userRepository
      .findById(userId)
      .catch(() => null);

    return Boolean((user as { communityTourSeenAt?: Date | null })?.communityTourSeenAt);
  }

  /** The tour finished or was skipped — never show it to this reader again. */
  async markTourSeen(userId: string) {
    if (!userId) return { tourSeen: true };

    await this.userRepository.markCommunityTourSeen(userId);

    return { tourSeen: true };
  }

  // ---------------------------------------------------------------- admin

  list(dto: GetListCommunitySanctionDto) {
    return this.sanctionRepository.listPage(dto);
  }

  history(userId: string) {
    return this.sanctionRepository.historyFor(userId);
  }

  /**
   * Suspend a reader's posting.
   *
   * They are told, with the reason: the alternative is a composer that stops
   * working with no explanation, which reads as a bug and arrives as a support
   * ticket rather than as the correction it is meant to be.
   */
  async create(
    dto: CreateCommunitySanctionDto,
    moderatorId: string,
    user?: IUserMeta,
  ) {
    const sanction = await this.sanctionRepository.create(
      {
        userId: dto.userId,
        mutedUntil: dto.mutedUntil,
        reason: dto.reason,
        createdByUserId: moderatorId,
      } as Partial<CommunitySanction>,
      user,
    );

    await this.notificationService.notify({
      userId: dto.userId,
      type: CommunityNotificationType.SANCTION_APPLIED,
      reason: dto.reason,
    });

    return sanction;
  }

  async revoke(id: string, moderatorId: string) {
    const sanction = await this.sanctionRepository.findById(id);
    if (!sanction) throw new NotFoundException('Sanction not found');

    await this.sanctionRepository.revoke(id, moderatorId);
    return this.sanctionRepository.findById(id);
  }
}
