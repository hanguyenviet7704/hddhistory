import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { CommunityReactionDto } from './dto/community-reaction.dto';
import { HideCommunityItemDto } from './dto/hide-community-item.dto';
import { CommunityHiddenItemRepository } from './repository/community-hidden-item.repository';
import { CommunityReactionRepository } from './repository/community-reaction.repository';
import { CommunityThreadMuteRepository } from './repository/community-thread-mute.repository';
import {
  CommunityAuthorType,
  CommunityReactionKind,
  CommunityTargetType,
} from '../../enum/community.enum';
import { CommunityAuthorService } from '../../service/community-author.service';
import { CommunityCommentRepository } from '../comment/repository/community-comment.repository';
import { CommunityNotificationService } from '../notification/community-notification.service';
import { CommunityPostRepository } from '../post/repository/community-post.repository';

// The bell on a post card. SAVE has no other target today — saving a comment
// is rejected in `assertTarget` — but spelling both halves out keeps a third
// target type added later from silently muting the wrong collection.
const isThreadFollow = (dto: CommunityReactionDto) =>
  dto.kind === CommunityReactionKind.SAVE &&
  dto.targetType === CommunityTargetType.POST;

@Injectable()
export class CommunityReactionService {
  constructor(
    private readonly reactionRepository: CommunityReactionRepository,
    private readonly threadMuteRepository: CommunityThreadMuteRepository,
    private readonly hiddenItemRepository: CommunityHiddenItemRepository,
    private readonly postRepository: CommunityPostRepository,
    private readonly commentRepository: CommunityCommentRepository,
    private readonly notificationService: CommunityNotificationService,
    private readonly authorService: CommunityAuthorService,
  ) {}

  async react(userId: string, dto: CommunityReactionDto) {
    await this.assertTarget(dto);

    const created = await this.reactionRepository.add({ ...dto, userId });
    // Only a real insert moves the counter: the unique index turns a double tap
    // into a no-op, and the count has to follow that.
    if (created) {
      await this.bump(dto, 1);
      await this.notifyLikeIfNeeded(userId, dto);
    }

    // Tapping the bell ON is the reader taking the thread back, so whatever
    // they meant by switching it off no longer applies. Outside the `created`
    // branch on purpose: the mute has to go even when the SAVE row happened to
    // be there already.
    if (isThreadFollow(dto)) {
      await this.threadMuteRepository.unmute(userId, dto.targetId);
    }

    return { active: true };
  }

  /**
   * Tell a post's author that someone liked it.
   *
   * Only on a real insert, so unlike-then-like-again cannot add a second head
   * to the "và N người khác" count. Failure is swallowed: a notification is
   * never worth failing the like the reader just tapped.
   */
  private async notifyLikeIfNeeded(
    userId: string,
    dto: CommunityReactionDto,
  ) {
    if (
      dto.kind !== CommunityReactionKind.LIKE ||
      dto.targetType !== CommunityTargetType.POST
    ) {
      return;
    }

    const post = await this.postRepository.findById(dto.targetId);
    if (!post?.authorId) return;
    // A team post has no human author waiting to hear about it, and `authorId`
    // there is whichever moderator pressed publish — the same exclusion the
    // comment fan-out makes.
    if (post.authorType === CommunityAuthorType.OFFICIAL) return;

    // The push copy is "{name} đã thích bài viết của bạn", so the name has to
    // come along; the in-app row only ever needed the id.
    const authors = await this.authorService.resolve([userId]);

    await this.notificationService.notifyLike({
      userId: post.authorId,
      actorId: userId,
      actorName: authors.get(userId)?.name ?? '',
      postId: dto.targetId,
    });
  }

  async unreact(userId: string, dto: CommunityReactionDto) {
    const removed = await this.reactionRepository.remove({ ...dto, userId });
    if (removed) await this.bump(dto, -1);

    // Recorded even when nothing was removed, because deleting the reaction is
    // no longer enough to mean "leave me out of this thread": commenting
    // auto-follows, and the new-comment fan-out reaches everyone who has ever
    // written here whether they hold a SAVE row or not. Both read this.
    if (isThreadFollow(dto)) {
      await this.threadMuteRepository.mute(userId, dto.targetId);
    }

    return { active: false };
  }

  /**
   * "Ẩn nội dung này" — a preference held by one reader.
   *
   * Deliberately not moderation: the item stays up for everyone else and never
   * enters the report queue. Hiding is how a reader curates their own feed;
   * reporting is how they ask us to look at it.
   */
  async hide(userId: string, dto: HideCommunityItemDto) {
    await this.hiddenItemRepository.hide(userId, dto.targetType, dto.targetId);
    return { hidden: true };
  }

  hiddenIds(userId: string, targetType: CommunityTargetType) {
    return this.hiddenItemRepository.hiddenIds(userId, targetType);
  }

  // Which of these did the reader like / save — one query per kind, ids only.
  async flagsFor(params: {
    userId: string;
    targetType: CommunityTargetType;
    targetIds: string[];
    kinds: CommunityReactionKind[];
  }) {
    const entries = await Promise.all(
      params.kinds.map(async (kind) => {
        const ids = await this.reactionRepository.targetIdsFor({
          userId: params.userId,
          kind,
          targetType: params.targetType,
          targetIds: params.targetIds,
        });
        return [kind, ids] as const;
      }),
    );

    return new Map(entries);
  }

  followedPostIds(userId: string) {
    return this.reactionRepository.followedPostIds(userId);
  }

  followerIdsOfPost(postId: string, excludeUserIds: string[] = []) {
    return this.reactionRepository.followerIdsOfPost(postId, excludeUserIds);
  }

  /**
   * Commenting is following: the reader has joined the thread, so the bell
   * comes on and the post shows up in their "Đang theo dõi" tab.
   *
   * Silent when they switched this thread off by hand — that tap is the one
   * thing auto-follow must not undo. Only a real insert moves `saveCount`, so
   * a reader's second comment does not count them as a second follower.
   */
  async followThreadOnComment(userId: string, postId: string) {
    if (await this.threadMuteRepository.isMuted(userId, postId)) return;

    const created = await this.reactionRepository.add({
      targetType: CommunityTargetType.POST,
      targetId: postId,
      userId,
      kind: CommunityReactionKind.SAVE,
    });

    if (created) await this.postRepository.bumpCounter(postId, 'saveCount', 1);
  }

  mutedUserIdsOfPost(postId: string) {
    return this.threadMuteRepository.mutedUserIdsForPost(postId);
  }

  savedPostsPage(userId: string, page?: number, take?: number) {
    return this.reactionRepository.savedPostsPage(userId, page, take);
  }

  private async assertTarget(dto: CommunityReactionDto) {
    if (
      dto.targetType === CommunityTargetType.COMMENT &&
      dto.kind === CommunityReactionKind.SAVE
    ) {
      // The design only offers the bookmark on a post card.
      throw new BadRequestException('Comments cannot be saved');
    }

    // Explicit, not "anything that is not a POST is a COMMENT": a third target
    // type added later would otherwise silently look itself up in — and bump
    // the counter of — the comments collection.
    if (dto.targetType === CommunityTargetType.CHAT_MESSAGE) {
      throw new BadRequestException(
        'Chat reactions go through the chat endpoint',
      );
    }

    const exists =
      dto.targetType === CommunityTargetType.POST
        ? await this.postRepository.findVisibleById(dto.targetId)
        : await this.commentRepository.findVisibleById(dto.targetId);

    if (!exists) throw new NotFoundException('Target not found');
  }

  private bump(dto: CommunityReactionDto, delta: number) {
    if (dto.targetType === CommunityTargetType.POST) {
      const field =
        dto.kind === CommunityReactionKind.LIKE ? 'likeCount' : 'saveCount';
      return this.postRepository.bumpCounter(dto.targetId, field, delta);
    }

    return this.commentRepository.bumpCounter(dto.targetId, 'likeCount', delta);
  }
}
