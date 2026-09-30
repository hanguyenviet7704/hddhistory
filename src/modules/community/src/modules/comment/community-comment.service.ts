import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';

import {
  CommunityAuthorType,
  CommunityPostType,
  CommunityContentStatus,
  CommunityNotificationType,
  CommunityReactionKind,
  CommunityReportStatus,
  CommunityTargetType,
} from '../../enum/community.enum';
import {
  assertWithinWriteLimit,
  COMMUNITY_AUTO_HIDDEN_REASON,
  COMMUNITY_AUTO_MODERATOR_ID,
  COMMUNITY_COMMENT_LIMIT,
} from '../../helper/community-limit.helper';
import { threadFollowUpRecipients } from '../../helper/community-thread-audience.helper';
import { CommunityAuthorService } from '../../service/community-author.service';
import { CommunityNotificationService } from '../notification/community-notification.service';
import { CommunityPostRepository } from '../post/repository/community-post.repository';
import { CommunityReactionService } from '../reaction/community-reaction.service';
import { CommunityReportRepository } from '../report/repository/community-report.repository';
import { CommunitySanctionService } from '../sanction/community-sanction.service';
import { CreateCommunityCommentDto } from './dto/create-community-comment.dto';
import { CreateOfficialCommentDto } from './dto/create-official-comment.dto';
import { GetListCommunityCommentDto } from './dto/get-list-community-comment.dto';
import { ModerateCommunityCommentDto } from './dto/moderate-community-comment.dto';
import {
  CASCADE_HIDDEN_REASON,
  CommunityCommentRepository,
} from './repository/community-comment.repository';
import { CommunityComment } from './schema/community-comment.schema';

@Injectable()
export class CommunityCommentService {
  private readonly logger = new Logger(CommunityCommentService.name);

  constructor(
    private readonly commentRepository: CommunityCommentRepository,
    private readonly postRepository: CommunityPostRepository,
    private readonly reportRepository: CommunityReportRepository,
    private readonly reactionService: CommunityReactionService,
    private readonly sanctionService: CommunitySanctionService,
    private readonly authorService: CommunityAuthorService,
    private readonly notificationService: CommunityNotificationService,
  ) {}

  /**
   * One post's thread: a page of top-level comments with their replies inline.
   *
   * Replies for the whole page come back in a single query rather than one per
   * parent. Newest-first at the top level, oldest-first inside a reply chain —
   * the order the design shows, and the order a conversation reads in.
   */
  async thread(
    postId: string,
    userId: string,
    dto: GetListCommunityCommentDto,
  ) {
    const post = await this.postRepository.findVisibleById(postId);
    if (!post) throw new NotFoundException('Post not found');

    const excludeIds = await this.reactionService.hiddenIds(
      userId,
      CommunityTargetType.COMMENT,
    );

    const parents = await this.commentRepository.topLevelPage({
      postId,
      excludeIds,
      page: dto.page,
      take: dto.take,
    });

    const replies = await this.commentRepository.repliesForParents(
      parents.items.map((comment) => String(comment._id)),
      excludeIds,
    );

    const all = [...parents.items, ...replies];
    const [authors, flags] = await Promise.all([
      this.authorService.resolve(all.map((comment) => comment.authorId)),
      this.reactionService.flagsFor({
        userId,
        targetType: CommunityTargetType.COMMENT,
        targetIds: all.map((comment) => String(comment._id)),
        kinds: [CommunityReactionKind.LIKE],
      }),
    ]);

    // Reply authors are also the "@name" targets, so the same map answers both.
    const liked = flags.get(CommunityReactionKind.LIKE) ?? new Set<string>();
    const repliesByParent = new Map<string, CommunityComment[]>();
    for (const reply of replies) {
      const key = String(reply.parentId);
      const bucket = repliesByParent.get(key) ?? [];
      bucket.push(reply);
      repliesByParent.set(key, bucket);
    }

    const toView = (comment: CommunityComment) => {
      const id = String(comment._id);
      return {
        id,
        author: this.authorService.pick(
          authors,
          comment.authorId,
          comment.authorType,
        ),
        body: comment.body,
        likeCount: comment.likeCount,
        replyCount: comment.replyCount,
        isLiked: liked.has(id),
        isMine: comment.authorId === userId,
        replyToName: comment.replyToUserId
          ? (authors.get(comment.replyToUserId)?.name ?? null)
          : null,
        createdAt: comment.createdAt,
      };
    };

    return {
      items: parents.items.map((parent) => ({
        ...toView(parent),
        replies: (repliesByParent.get(String(parent._id)) ?? []).map(toView),
      })),
      currentPage: parents.currentPage,
      totalPages: parents.totalPages,
      itemsPerPage: parents.itemsPerPage,
    };
  }

  async create(
    postId: string,
    userId: string,
    dto: CreateCommunityCommentDto,
    user?: IUserMeta,
  ) {
    await this.sanctionService.assertCanWrite(userId);
    await this.assertWithinRate(userId, dto.body);

    const post = await this.postRepository.findVisibleById(postId);
    if (!post) throw new NotFoundException('Post not found');
    if (post.commentsLocked) {
      throw new ForbiddenException('Comments are locked on this post');
    }

    let parent: CommunityComment | null = null;
    if (dto.parentId) {
      parent = await this.commentRepository.findVisibleById(dto.parentId);
      if (!parent || String(parent.postId) !== postId) {
        throw new BadRequestException('Parent comment does not belong to this post');
      }
      // The thread is exactly two levels deep: replying to a reply attaches to
      // the same top-level comment, with replyToUserId carrying the "@name".
      if (parent.parentId) {
        throw new BadRequestException(
          'Replies are limited to two levels — pass the top-level comment id',
        );
      }
    }

    const comment = await this.commentRepository.create(
      {
        postId,
        parentId: dto.parentId ?? null,
        replyToUserId: dto.replyToUserId,
        authorId: userId,
        authorType: CommunityAuthorType.USER,
        // Trimmed on the way in: the duplicate check below compares bodies word
        // for word, and trailing whitespace is the cheapest way around it.
        body: dto.body?.trim() ?? '',
      } as Partial<CommunityComment>,
      user,
    );

    await this.postRepository.bumpCounter(postId, 'commentCount', 1, true);
    if (parent) {
      await this.commentRepository.bumpCounter(
        String(parent._id),
        'replyCount',
        1,
      );
    }

    await this.followOwnThread(userId, postId, post.type);

    await this.notifyForNewComment({
      post,
      parent,
      comment,
      actorId: userId,
      replyToUserId: dto.replyToUserId,
    });

    return this.thread(postId, userId, { page: 1, take: 10 } as GetListCommunityCommentDto);
  }

  async removeOwn(id: string, userId: string) {
    const comment = await this.commentRepository.findById(id);
    if (!comment) throw new NotFoundException('Comment not found');
    if (comment.authorId !== userId) {
      throw new ForbiddenException('Not your comment');
    }

    await this.commentRepository.updateOne(
      { _id: id },
      { status: CommunityContentStatus.DELETED },
    );
    await this.afterCommentRemoved(comment);

    return { deleted: true };
  }

  // ---------------------------------------------------------------- admin

  /**
   * The team answers a thread, from the panel.
   *
   * Deliberately NOT the reader path with a flag: it skips the mute check and
   * the flood ceiling, because both exist to hold individual accounts back and
   * neither should be able to gag the team — a moderator working through a busy
   * morning would otherwise trip a limit meant for spammers.
   *
   * The post's author hears OFFICIAL_REPLY rather than COMMENT_ON_POST. That
   * copy has been sitting in the notification table since the feature was
   * designed and nothing ever sent it: "Đội ngũ HDDhistory đã trả lời" is a different
   * event from "somebody commented", and it is the one people actually open.
   */
  async createOfficial(
    postId: string,
    dto: CreateOfficialCommentDto,
    moderatorId: string,
    user?: IUserMeta,
  ) {
    const post = await this.postRepository.findVisibleById(postId);
    if (!post) throw new NotFoundException('Post not found');

    let parent: CommunityComment | null = null;
    if (dto.parentId) {
      parent = await this.commentRepository.findVisibleById(dto.parentId);
      if (!parent || String(parent.postId) !== postId) {
        throw new BadRequestException(
          'Parent comment does not belong to this post',
        );
      }
      // Two levels, same as the reader path: answering a reply attaches to its
      // top-level comment instead of nesting a third time.
      if (parent.parentId) {
        throw new BadRequestException(
          'Replies are limited to two levels — pass the top-level comment id',
        );
      }
    }

    const comment = await this.commentRepository.create(
      {
        postId,
        parentId: dto.parentId ?? null,
        authorId: moderatorId,
        authorType: CommunityAuthorType.OFFICIAL,
        body: dto.body.trim(),
      } as Partial<CommunityComment>,
      user,
    );

    await this.postRepository.bumpCounter(postId, 'commentCount', 1, true);
    if (parent) {
      await this.commentRepository.bumpCounter(
        String(parent._id),
        'replyCount',
        1,
      );
    }

    await this.notifyForNewComment({
      post,
      parent,
      comment,
      actorId: moderatorId,
      isOfficial: true,
    });

    return this.findAllForAdmin({ postId, page: 1, take: 50 } as GetListCommunityCommentDto);
  }

  async findAllForAdmin(dto: GetListCommunityCommentDto) {
    const listed = await this.commentRepository.adminPage(dto);
    const authors = await this.authorService.resolve(
      listed.items.map((comment) => comment.authorId),
    );

    return {
      ...listed,
      items: listed.items.map((comment) => ({
        id: String(comment._id),
        postId: comment.postId,
        parentId: comment.parentId ?? null,
        status: comment.status,
        body: comment.body,
        author: this.authorService.pick(
          authors,
          comment.authorId,
          comment.authorType,
        ),
        likeCount: comment.likeCount,
        replyCount: comment.replyCount,
        reportCount: comment.reportCount,
        // The cascade marker is bookkeeping, not a sentence written for anyone
        // to read — the panel gets a flag instead of the raw token.
        hiddenWithPost: comment.hiddenReason === CASCADE_HIDDEN_REASON,
        hiddenByReports: comment.hiddenReason === COMMUNITY_AUTO_HIDDEN_REASON,
        hiddenReason: [CASCADE_HIDDEN_REASON, COMMUNITY_AUTO_HIDDEN_REASON].includes(
          comment.hiddenReason,
        )
          ? null
          : (comment.hiddenReason ?? null),
        createdAt: comment.createdAt,
      })),
    };
  }

  async moderate(
    id: string,
    dto: ModerateCommunityCommentDto,
    moderatorId: string,
    user?: IUserMeta,
  ) {
    const comment = await this.commentRepository.findById(id);
    if (!comment) throw new NotFoundException('Comment not found');

    if (dto.status && dto.status !== comment.status) {
      await this.commentRepository.updateOne(
        { _id: id },
        {
          status: dto.status,
          hiddenReason: dto.hiddenReason,
          moderatedBy: moderatorId,
          moderatedAt: new Date(),
        } as Partial<CommunityComment>,
        user,
      );

      if (dto.status === CommunityContentStatus.HIDDEN) {
        await Promise.all([
          this.reportRepository.resolveAllForTarget(
            CommunityTargetType.COMMENT,
            id,
            CommunityReportStatus.RESOLVED_HIDDEN,
            moderatorId,
          ),
          this.afterCommentRemoved(comment),
        ]);
      }

      // Putting a comment back has to put the counters back with it. Skipped for
      // one that went down WITH its post: that cascade never decremented them,
      // because the post itself left the feed.
      if (
        dto.status === CommunityContentStatus.VISIBLE &&
        comment.hiddenReason !== CASCADE_HIDDEN_REASON
      ) {
        await this.afterCommentRestored(comment);
      }
    }

    return this.commentRepository.findById(id);
  }

  /**
   * Takes a comment out of its thread because enough different readers reported
   * it.
   *
   * Same reasoning as the post version: the reports stay OPEN so the queue still
   * shows the work, the row is stamped as done by the count rather than by a
   * person, and the author is told nothing until a human has confirmed it.
   * Replies are left alone — a reply is its own author's words, and hiding a
   * comment is not a verdict on the people who answered it.
   */
  async autoHideByReports(id: string) {
    const comment = await this.commentRepository.findById(id);
    if (!comment) return false;
    if (comment.status !== CommunityContentStatus.VISIBLE) return false;
    if (comment.authorType === CommunityAuthorType.OFFICIAL) return false;

    await this.commentRepository.updateOne({ _id: id }, {
      status: CommunityContentStatus.HIDDEN,
      hiddenReason: COMMUNITY_AUTO_HIDDEN_REASON,
      moderatedBy: COMMUNITY_AUTO_MODERATOR_ID,
      moderatedAt: new Date(),
    } as Partial<CommunityComment>);

    await this.afterCommentRemoved(comment);

    return true;
  }

  // ---------------------------------------------------------------- internals

  // The mirror of afterCommentRemoved, for a comment put back.
  private async afterCommentRestored(comment: CommunityComment) {
    await this.postRepository.bumpCounter(
      String(comment.postId),
      'commentCount',
      1,
    );
    if (comment.parentId) {
      await this.commentRepository.bumpCounter(
        String(comment.parentId),
        'replyCount',
        1,
      );
    }
  }

  // Counters follow the comment out: the post's comment count and, for a reply,
  // its parent's reply count.
  private async afterCommentRemoved(comment: CommunityComment) {
    await this.postRepository.bumpCounter(
      String(comment.postId),
      'commentCount',
      -1,
    );
    if (comment.parentId) {
      await this.commentRepository.bumpCounter(
        String(comment.parentId),
        'replyCount',
        -1,
      );
    }
  }

  /**
   * Who hears about a new comment.
   *
   * At most one notification per person per comment: the post author, the
   * parent-comment author, and the person being answered by name can easily be
   * the same human, and three pushes for one reply is how a badge stops meaning
   * anything. notify() itself drops the actor, so nobody is told about their own
   * comment.
   */
  private async notifyForNewComment(params: {
    post: {
      _id: unknown;
      authorId: string;
      authorType: CommunityAuthorType;
      type?: CommunityPostType;
    };
    parent: CommunityComment | null;
    comment: CommunityComment;
    actorId: string;
    replyToUserId?: string;
    isOfficial?: boolean;
  }) {
    const postId = String(params.post._id);
    const commentId = String(params.comment._id);
    const notified = new Set<string>([params.actorId]);

    // The name in the push has to be the one on the account NOW.
    //
    // It used to come from `user.name` on the decoded JWT, which is a snapshot
    // taken when the token was minted: somebody who joined as a guest and then
    // set their name still reached everyone as "Guest" until their token
    // refreshed, while the same person's LIKE — resolved from the users
    // collection — arrived under their real name. Two different names for two
    // taps in the same thread. The team's own replies carry no name: their copy
    // says "Đội ngũ HDDhistory đã trả lời" and never interpolates one.
    const actorName = params.isOfficial
      ? ''
      : ((await this.authorService.resolve([params.actorId])).get(
          params.actorId,
        )?.name ?? '');
    // Stored on the row, not just used for the push text built right here —
    // the in-app notification LIST re-derives the actor identity on every
    // visit, and without this it has no way left to tell an official reply
    // from an ordinary one (owner on-device 2026-09-10).
    const actorType = params.isOfficial
      ? CommunityAuthorType.OFFICIAL
      : CommunityAuthorType.USER;

    const send = (userId: string, type: CommunityNotificationType) => {
      if (!userId || notified.has(userId)) return Promise.resolve();
      notified.add(userId);
      return this.notificationService.notify({
        userId,
        type,
        actorId: params.actorId,
        actorName,
        actorType,
        postId,
        commentId,
      });
    };

    // The person being answered by name comes first — that is the reply they
    // are actually waiting on.
    if (params.replyToUserId) {
      await send(
        params.replyToUserId,
        CommunityNotificationType.REPLY_TO_COMMENT,
      );
    }
    if (params.parent) {
      await send(
        params.parent.authorId,
        CommunityNotificationType.REPLY_TO_COMMENT,
      );
    }
    // A team post has no human author to notify. An ANONYMOUS one does — the
    // row still holds the real account, and the writer wants to hear the
    // answers even though readers cannot see their name.
    if (params.post.authorType !== CommunityAuthorType.OFFICIAL) {
      await send(
        params.post.authorId,
        params.isOfficial
          ? CommunityNotificationType.OFFICIAL_REPLY
          : CommunityNotificationType.COMMENT_ON_POST,
      );
    }

    // Everyone who put the bell on this thread, plus — on an ordinary post —
    // everyone who has ever written in it. Minus whoever already heard about
    // this exact comment above, and minus anyone who switched the thread off.
    //
    // The commenter half is what reaches people who answered BEFORE
    // auto-follow started writing a SAVE row for them: nothing was ever
    // recorded for those accounts, so the follower query alone would miss them
    // for good and only a backfill could have caught up.
    //
    // The weekly question is left out of that half on purpose. Its answerers
    // hear from `notifyWeeklyAnswer` below, which collapses a week of forty
    // answers into one "X và N người khác" row; pulling them in here would give
    // them a row each, which is the noise this change exists to cut.
    const isWeekly = params.post.type === CommunityPostType.WEEKLY_QUESTION;
    const [followerIds, commenterIds, mutedUserIds] = await Promise.all([
      this.reactionService.followerIdsOfPost(postId, [...notified]),
      isWeekly
        ? ([] as string[])
        : this.commentRepository.distinctAuthorIdsForPost(postId),
      this.reactionService.mutedUserIdsOfPost(postId),
    ]);

    const followUpIds = threadFollowUpRecipients({
      followerIds,
      commenterIds,
      alreadyNotified: notified,
      mutedUserIds,
    });

    if (followUpIds.length) {
      await this.notificationService.notifyThreadFollowers({
        postId,
        commentId,
        actorId: params.actorId,
        actorName,
        actorType,
        followerIds: followUpIds,
      });
      followUpIds.forEach((userId) => notified.add(userId));
    }

    // The weekly question has no human author, so everything above reaches
    // only the bell-followers: answer the week's question and you would never
    // hear that anyone else had. The other answerers are the people it
    // concerns, and their row collapses to one line per question.
    if (isWeekly) {
      const answererIds = (
        await this.commentRepository.distinctAuthorIdsForPost(postId)
      ).filter((userId) => !notified.has(userId));

      if (answererIds.length) {
        await this.notificationService.notifyWeeklyAnswer({
          postId,
          actorId: params.actorId,
          actorName,
          answererIds,
        });
      }
    }
  }

  /**
   * Answering a thread puts the bell on it.
   *
   * Skipped on the weekly question, and that exclusion carries weight: its
   * answerers are told by `notifyWeeklyAnswer`, which collapses the week into
   * a single "X và N người khác" row. Make them ordinary followers and they
   * would get one row per answer instead.
   *
   * Swallowed on failure. This is a follow the reader never asked for out
   * loud; it must not be the reason the comment they DID write fails to post.
   */
  private async followOwnThread(
    userId: string,
    postId: string,
    postType?: CommunityPostType,
  ) {
    if (postType === CommunityPostType.WEEKLY_QUESTION) return;

    try {
      await this.reactionService.followThreadOnComment(userId, postId);
    } catch (error) {
      this.logger.warn(
        `Auto-follow failed for user ${userId} on post ${postId}: ${error}`,
      );
    }
  }

  /**
   * The commenting ceiling, and a refusal to say the same thing twice.
   *
   * Looser than the posting one — a reader in a good thread writes a lot — but
   * the duplicate window is what actually matters here: the shape spam takes in
   * comments is one line copied under every post on the feed.
   */
  private async assertWithinRate(userId: string, body?: string) {
    const limit = COMMUNITY_COMMENT_LIMIT;
    const now = Date.now();
    const text = body?.trim();

    const [stats, isDuplicate] = await Promise.all([
      this.commentRepository.recentWritesByAuthor(
        userId,
        new Date(now - limit.windowMs),
        limit.max,
      ),
      text && text.length >= limit.duplicateMinLength
        ? this.commentRepository.hasRecentBody(
            userId,
            new Date(now - limit.duplicateMs),
            text,
          )
        : Promise.resolve(false),
    ]);

    assertWithinWriteLimit(stats, limit, isDuplicate);
  }
}
