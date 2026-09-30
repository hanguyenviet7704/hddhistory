import { Injectable, Logger } from '@nestjs/common';

import { FirebaseService } from '@base/config/firebase';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import { communityPushCopy } from './community-notification.copy';
import { MarkCommunityNotificationReadDto } from './dto/mark-community-notification-read.dto';
import { CommunityNotificationRepository } from './repository/community-notification.repository';
import { CommunityNotification } from './schema/community-notification.schema';
import {
  CommunityAuthorType,
  CommunityNotificationType,
} from '../../enum/community.enum';
import { CommunityAuthorService } from '../../service/community-author.service';

interface INotifyParams {
  userId: string;
  type: CommunityNotificationType;
  actorId?: string;
  actorName?: string;
  /**
   * Was `actorId` speaking as the team ("trả lời với tư cách HDDhistory")? Stored
   * on the row so a LATER read of the in-app list still knows — the push text
   * built right here from `actorName` is not enough, because it is never
   * re-derived: it is `list()` that has to pick between the real account and
   * `official()` for every row, and it can only do that by reading this back.
   */
  actorType?: CommunityAuthorType;
  postId?: string;
  commentId?: string;
  roomId?: string;
  roomSlug?: string;
  roomTitle?: string;
  reason?: string;
}

@Injectable()
export class CommunityNotificationService {
  private readonly logger = new Logger(CommunityNotificationService.name);

  constructor(
    private readonly notificationRepository: CommunityNotificationRepository,
    private readonly userRepository: UserRepository,
    private readonly authorService: CommunityAuthorService,
    private readonly firebaseService: FirebaseService,
  ) {}

  /**
   * Record the event and push it.
   *
   * Never notifies someone about their own action — the common case is
   * commenting on your own post, and a badge for that would train readers to
   * ignore the badge. Push failure is logged, not thrown: a lost notification
   * must not fail the comment that caused it.
   */
  async notify(params: INotifyParams) {
    if (!params.userId || params.userId === params.actorId) return;

    await this.notificationRepository.create({
      userId: params.userId,
      type: params.type,
      actorId: params.actorId,
      actorType: params.actorType,
      postId: params.postId,
      commentId: params.commentId,
      roomId: params.roomId,
      roomSlug: params.roomSlug,
    } as Partial<CommunityNotification>);

    try {
      await this.push(params);
    } catch (error) {
      this.logger.warn(
        `Community push failed for user ${params.userId}: ${error}`,
      );
    }
  }

  /**
   * Tell everyone who follows a thread that it has a new comment.
   *
   * Fanned out one by one rather than in a batch write because each recipient
   * also gets a push, and a push that fails for one device must not stop the
   * rest. Nobody is notified twice: the author and the commenter are excluded
   * before we get here.
   */
  async notifyThreadFollowers(params: {
    postId: string;
    commentId: string;
    actorId: string;
    actorName?: string;
    actorType?: CommunityAuthorType;
    followerIds: string[];
  }) {
    await Promise.all(
      params.followerIds.map((userId) =>
        this.notify({
          userId,
          type: CommunityNotificationType.COMMENT_ON_FOLLOWED_POST,
          actorId: params.actorId,
          actorName: params.actorName,
          actorType: params.actorType,
          postId: params.postId,
          commentId: params.commentId,
        }),
      ),
    );
  }

  /**
   * Somebody else answered the weekly question — told to the people who
   * answered it too.
   *
   * The question is posted by the team, so `notifyForNewComment` has no author
   * to tell: unless a reader had pressed the bell, answering the week's
   * question and never hearing another word was the whole experience. The
   * people who obviously care are the ones who already answered.
   *
   * Collapsed and batched exactly like `notifyLike`, and for the same reason:
   * one row per question ("X và N người khác"), and a push only when it is
   * news — the first new answer, then the first after they have read the last
   * lot. A week with forty answers is not forty notifications.
   */
  async notifyWeeklyAnswer(params: {
    postId: string;
    actorId: string;
    actorName?: string;
    /** Everyone who has answered this question; the actor is filtered here. */
    answererIds: string[];
  }) {
    const recipients = [...new Set(params.answererIds)].filter(
      (userId) => userId && userId !== params.actorId,
    );

    await Promise.all(
      recipients.map(async (userId) => {
        const previous = await this.notificationRepository.upsertLike({
          userId,
          postId: params.postId,
          actorId: params.actorId,
          type: CommunityNotificationType.ANSWER_ON_WEEKLY,
        });

        if (previous && !previous.isRead) return;

        try {
          await this.push({
            userId,
            type: CommunityNotificationType.ANSWER_ON_WEEKLY,
            actorId: params.actorId,
            actorName: params.actorName,
            postId: params.postId,
          });
        } catch (error) {
          this.logger.warn(
            `Community weekly push failed for user ${userId}: ${error}`,
          );
        }
      }),
    );
  }

  /**
   * Someone liked a post.
   *
   * Collapsed into one row per post — see the repository — so the list stays
   * readable. No push: a like is not worth waking a phone for, and a popular
   * post would otherwise buzz once per liker.
   */
  /**
   * Someone liked a post — one row per post, and a push only when it is news.
   *
   * The row was collapsed from the start ("X và N người khác"), but nothing ever
   * pushed it, so a like reached the author only if they happened to open the
   * bell. Pushing every like instead would make one popular post a buzzing
   * phone, so the push follows the BATCH: the first like, and then the first
   * like after they have read the last lot.
   */
  async notifyLike(params: {
    userId: string;
    actorId: string;
    actorName?: string;
    postId: string;
  }) {
    if (!params.userId || params.userId === params.actorId) return;

    const previous = await this.notificationRepository.upsertLike(params);
    const isNews = !previous || previous.isRead;
    if (!isNews) return;

    try {
      await this.push({
        userId: params.userId,
        type: CommunityNotificationType.LIKE_ON_POST,
        actorId: params.actorId,
        actorName: params.actorName,
        postId: params.postId,
      });
    } catch (error) {
      // Same as `notify`: a lost push must not fail the tap that caused it.
      this.logger.warn(
        `Community like push failed for user ${params.userId}: ${error}`,
      );
    }
  }

  private async push(params: INotifyParams) {
    const recipient = await this.userRepository.findById(params.userId);
    if (!recipient) return;

    const tokens = (recipient.devices ?? [])
      .filter((device) => device.pushEnabled !== false && !!device.pushToken)
      .map((device) => device.pushToken as string);
    if (!tokens.length) return;

    const copy = communityPushCopy(params.type, recipient.language, {
      name: params.actorName ?? '',
      reason: params.reason ?? '',
      room: params.roomTitle ?? '',
    });

    // `deeplink` is the key the app's notification router reads, so the tap
    // lands on the thread itself; a payload it does not understand would just
    // open the app on whatever screen was last shown.
    //
    // A SYMBOLIC key from the shared destination catalogue, never a URI: the
    // app switches on this value and falls back to
    // `DeeplinkDestination.tryFromValue`, which compares it against bare keys
    // like `community-post`. A full `hddhistory://…?postId=` string matched nothing,
    // so every tap on a community push was declined by the router and merely
    // brought the app forward — on a cold start, onto Home. `postId` travels as
    // its own data field below and reaches the route as a param.
    const deeplink = params.roomSlug
      ? 'community-chat'
      : params.postId
        ? 'community-post'
        : 'community';

    const result = await this.firebaseService.sendToTokens(
      tokens,
      copy.title,
      copy.body,
      {
        deeplink,
        type: params.type,
        postId: params.postId ?? '',
        commentId: params.commentId ?? '',
        // `room` is the param name `CommunityChatRoute` takes — a slug, not an
        // id, so the app can name the room before it has loaded it.
        room: params.roomSlug ?? '',
      },
    );

    if (result.deadTokens.length) {
      await this.userRepository.pruneDeadPushTokens(result.deadTokens);
    }
  }

  /**
   * The notification list, with the actor resolved.
   *
   * The row stores only an id; the screen draws a name, initials and an avatar.
   * Resolving here — one query for the whole page — keeps that out of the app,
   * which would otherwise have no way to turn an id into a person.
   */
  async list(userId: string, page?: number, take?: number) {
    const [page$, unreadCount] = await Promise.all([
      this.notificationRepository.listPage(userId, page, take),
      this.notificationRepository.countUnread(userId),
    ]);

    const actors = await this.authorService.resolve(
      page$.items.map((row) => row.actorId).filter(Boolean) as string[],
    );

    return {
      ...page$,
      items: page$.items.map((row) => ({
        id: String(row._id),
        type: row.type,
        actorId: row.actorId ?? null,
        // `row.actorType` is what makes an official reply's row still read
        // "HDDhistory" on a later visit to the notification list, instead of
        // defaulting to the real account nobody told this query about (owner
        // on-device 2026-09-10: "phần thông báo lại hiện name của tài khoản
        // thật" — the push at send time already said "HDDhistory"; this list did
        // not, because nothing here knew the actor had been official).
        actor: row.actorId
          ? this.authorService.pick(actors, row.actorId, row.actorType ?? CommunityAuthorType.USER)
          : null,
        // 0 when this is the only person; the app reads it as "and N others".
        otherActorCount: Math.max(0, (row.actorCount ?? 1) - 1),
        postId: row.postId ?? null,
        commentId: row.commentId ?? null,
        roomId: row.roomId ?? null,
        roomSlug: row.roomSlug ?? null,
        isRead: row.isRead,
        createdAt: row.createdAt,
      })),
      unreadCount,
    };
  }

  unreadCount(userId: string) {
    return this.notificationRepository.countUnread(userId);
  }

  async markRead(userId: string, dto: MarkCommunityNotificationReadDto) {
    await this.notificationRepository.markRead(userId, dto.ids);
    return { unreadCount: await this.notificationRepository.countUnread(userId) };
  }
}
