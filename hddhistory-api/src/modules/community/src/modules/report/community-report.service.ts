import { Injectable, Logger, NotFoundException } from '@nestjs/common';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';

import { CreateCommunityReportDto } from './dto/create-community-report.dto';
import { ResolveCommunityReportDto } from './dto/resolve-community-report.dto';
import {
  CommunityContentStatus,
  CommunityReportStatus,
  CommunityTargetType,
} from '../../enum/community.enum';
import {
  COMMUNITY_AUTO_HIDDEN_REASON,
  COMMUNITY_AUTO_HIDE_REPORTS,
} from '../../helper/community-limit.helper';
import { CommunityAuthorService } from '../../service/community-author.service';
import { CommunityChatService } from '../chat/community-chat.service';
import { CommunityChatMessageRepository } from '../chat/repository/community-chat-message.repository';
import { CommunityCommentService } from '../comment/community-comment.service';
import { CommunityCommentRepository } from '../comment/repository/community-comment.repository';
import { CommunityPostService } from '../post/community-post.service';
import { GetListCommunityReportDto } from './dto/get-list-community-report.dto';
import { CommunityReportRepository } from './repository/community-report.repository';
import { CommunityPostRepository } from '../post/repository/community-post.repository';

@Injectable()
export class CommunityReportService {
  private readonly logger = new Logger(CommunityReportService.name);

  constructor(
    private readonly reportRepository: CommunityReportRepository,
    private readonly postRepository: CommunityPostRepository,
    private readonly commentRepository: CommunityCommentRepository,
    private readonly chatMessageRepository: CommunityChatMessageRepository,
    private readonly postService: CommunityPostService,
    private readonly commentService: CommunityCommentService,
    private readonly chatService: CommunityChatService,
    private readonly authorService: CommunityAuthorService,
  ) {}

  /**
   * A reader reports a post or comment.
   *
   * One report changes nothing visible — this is a post-moderated community, so
   * the item stays up and the count is what sorts the queue. Enough DIFFERENT
   * readers reporting the same thing does take it out of the feed, provisionally
   * and with the reports left open: see [autoHideIfEnoughReports].
   */
  async create(reporterId: string, dto: CreateCommunityReportDto) {
    await this.assertTargetExists(dto.targetType, dto.targetId);

    const created = await this.reportRepository.report({
      targetType: dto.targetType,
      targetId: dto.targetId,
      reporterId,
      reason: dto.reason,
      note: dto.note,
    });

    // Second report from the same reader is a no-op, so the count stays honest.
    if (created) {
      // Spelled out per type rather than "post, else comment". That `else` was
      // how a chat report landed on the COMMENTS collection: it bumped a
      // reportCount on whatever comment happened to share the id, or nothing at
      // all, and the reported line itself stayed at zero.
      switch (dto.targetType) {
        case CommunityTargetType.POST:
          await this.postRepository.bumpCounter(dto.targetId, 'reportCount', 1);
          break;
        case CommunityTargetType.CHAT_MESSAGE:
          await this.chatMessageRepository.bumpCounter(
            dto.targetId,
            'reportCount',
            1,
          );
          break;
        default:
          await this.commentRepository.bumpCounter(
            dto.targetId,
            'reportCount',
            1,
          );
      }

      await this.autoHideIfEnoughReports(dto.targetType, dto.targetId);
    }

    return { reported: true };
  }

  /**
   * Pulls an item out of the feed once [COMMUNITY_AUTO_HIDE_REPORTS] different
   * readers have reported it.
   *
   * The queue is not emptied by this: the reports stay PENDING and the item is
   * stamped as hidden-by-count, so a moderator still confirms or reverses it.
   * Waiting for a person is the right default for a disagreement and the wrong
   * one for spam, and this is how the two get different response times without
   * handing the verdict to whoever taps first.
   *
   * Read after the bump, so the count includes the report that just landed.
   */
  private async autoHideIfEnoughReports(
    targetType: CommunityTargetType,
    targetId: string,
  ) {
    const target = await this.findTarget(targetType, targetId);

    if (!target) return;
    if ((target.reportCount ?? 0) < COMMUNITY_AUTO_HIDE_REPORTS) return;

    const hidden = await this.hideTarget(targetType, targetId);

    if (hidden) {
      // Worth a log line: this is the one moderation action with nobody's name
      // on it, so the trail is the only way to know it happened.
      this.logger.warn(
        `Auto-hid ${targetType} ${targetId} after ${target.reportCount} reports`,
      );
    }
  }

  // ---------------------------------------------------------------- admin

  /**
   * The moderation queue.
   *
   * Each row carries the reported text and its author, because a queue of ids
   * is a queue nobody can act on without opening ten tabs.
   */
  async findAll(dto: GetListCommunityReportDto) {
    const listed = await this.reportRepository.findOption({
      ...dto,
      status: dto.status ?? CommunityReportStatus.PENDING,
    });

    const postIds = listed.items
      .filter((row) => row.targetType === CommunityTargetType.POST)
      .map((row) => row.targetId);
    const commentIds = listed.items
      .filter((row) => row.targetType === CommunityTargetType.COMMENT)
      .map((row) => row.targetId);
    const chatIds = listed.items
      .filter((row) => row.targetType === CommunityTargetType.CHAT_MESSAGE)
      .map((row) => row.targetId);

    const [posts, comments, chatMessages] = await Promise.all([
      this.postRepository.findAnyByIds(postIds),
      this.commentRepository.findAnyByIds(commentIds),
      this.chatMessageRepository.findAnyByIds(chatIds),
    ]);

    const authorIds = [
      ...posts.map((post) => post.authorId),
      ...comments.map((comment) => comment.authorId),
      ...chatMessages.map((message) => message.authorId),
      ...listed.items.map((row) => row.reporterId),
    ];
    const authors = await this.authorService.resolve(authorIds);

    const postById = new Map(posts.map((post) => [String(post._id), post]));
    const commentById = new Map(
      comments.map((comment) => [String(comment._id), comment]),
    );
    const chatById = new Map(
      chatMessages.map((message) => [String(message._id), message]),
    );

    return {
      ...listed,
      items: listed.items.map((row) => {
        const target =
          row.targetType === CommunityTargetType.POST
            ? postById.get(row.targetId)
            : row.targetType === CommunityTargetType.CHAT_MESSAGE
              ? chatById.get(row.targetId)
              : commentById.get(row.targetId);

        return {
          id: String(row._id),
          targetType: row.targetType,
          targetId: row.targetId,
          reason: row.reason,
          note: row.note ?? null,
          status: row.status,
          reporter: this.authorService.pick(authors, row.reporterId),
          // Null when the author had already deleted it — the report is still
          // worth showing as history, just with nothing left to act on.
          target: target
            ? {
                body: target.body,
                status: target.status,
                // Whether the count hid it or a person did. The panel labels its
                // "keep" button off this: on an auto-hide, keeping it puts the
                // item back, which is a different promise from closing a report
                // on something that never left the feed.
                hiddenByReports:
                  target.hiddenReason === COMMUNITY_AUTO_HIDDEN_REASON,
                author: this.authorService.pick(
                  authors,
                  target.authorId,
                  target.authorType,
                ),
                reportCount: target.reportCount,
              }
            : null,
          createdAt: row.createdAt,
        };
      }),
    };
  }

  /**
   * Close a report, optionally taking the content down with it.
   *
   * Hiding goes through the post/comment service rather than writing status
   * here, so the rest of it still happens: the thread is hidden, the author is
   * told why, counters move, and every other pending report on the same item is
   * closed with the same verdict.
   */
  async resolve(
    id: string,
    dto: ResolveCommunityReportDto,
    moderatorId: string,
    user?: IUserMeta,
  ) {
    const report = await this.reportRepository.findById(id);
    if (!report) throw new NotFoundException('Report not found');

    if (dto.status === CommunityReportStatus.RESOLVED_HIDDEN) {
      if (report.targetType === CommunityTargetType.POST) {
        await this.postService.moderate(
          report.targetId,
          {
            status: CommunityContentStatus.HIDDEN,
            hiddenReason: report.reason,
          },
          moderatorId,
          user,
        );
      } else {
        await this.commentService.moderate(
          report.targetId,
          {
            status: CommunityContentStatus.HIDDEN,
            hiddenReason: report.reason,
          },
          moderatorId,
          user,
        );
      }
      // moderate() already closed every pending report on the target.
      return this.reportRepository.findById(id);
    }

    // "Keep" has to be able to undo an automatic hide. The count that hid it may
    // have been a brigade, and closing the reports while leaving the item hidden
    // would leave the queue's verdict and the feed disagreeing permanently.
    await this.restoreIfAutoHidden(report, moderatorId, user);

    await this.reportRepository.resolveAllForTarget(
      report.targetType,
      report.targetId,
      CommunityReportStatus.RESOLVED_KEPT,
      moderatorId,
    );

    return this.reportRepository.findById(id);
  }

  /**
   * Puts back an item that only the report count had taken down.
   *
   * A moderator's own hide is left exactly where it is: they read the thing and
   * decided, and a later "keep" on one report is not a reversal of that.
   */
  private async restoreIfAutoHidden(
    report: { targetType: CommunityTargetType; targetId: string },
    moderatorId: string,
    user?: IUserMeta,
  ) {
    const target =
      report.targetType === CommunityTargetType.POST
        ? await this.postRepository.findById(report.targetId)
        : await this.commentRepository.findById(report.targetId);

    if (!target) return;
    if (target.status !== CommunityContentStatus.HIDDEN) return;
    if (target.hiddenReason !== COMMUNITY_AUTO_HIDDEN_REASON) return;

    const restore = { status: CommunityContentStatus.VISIBLE };

    if (report.targetType === CommunityTargetType.POST) {
      await this.postService.moderate(
        report.targetId,
        restore,
        moderatorId,
        user,
      );
      return;
    }

    await this.commentService.moderate(
      report.targetId,
      restore,
      moderatorId,
      user,
    );
  }

  private async assertTargetExists(
    targetType: CommunityTargetType,
    targetId: string,
  ) {
    const exists =
      targetType === CommunityTargetType.POST
        ? await this.postRepository.findVisibleById(targetId)
        : targetType === CommunityTargetType.CHAT_MESSAGE
          ? await this.chatMessageRepository.findVisibleById(targetId)
          : await this.commentRepository.findVisibleById(targetId);

    if (!exists) throw new NotFoundException('Target not found');
  }

  private findTarget(targetType: CommunityTargetType, targetId: string) {
    switch (targetType) {
      case CommunityTargetType.POST:
        return this.postRepository.findById(targetId);
      case CommunityTargetType.CHAT_MESSAGE:
        return this.chatMessageRepository.findAnyById(targetId);
      default:
        return this.commentRepository.findById(targetId);
    }
  }

  private hideTarget(targetType: CommunityTargetType, targetId: string) {
    switch (targetType) {
      case CommunityTargetType.POST:
        return this.postService.autoHideByReports(targetId);
      case CommunityTargetType.CHAT_MESSAGE:
        return this.chatService.autoHideByReports(targetId);
      default:
        return this.commentService.autoHideByReports(targetId);
    }
  }
}
