import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';

import { CreateCommunityPostDto } from './dto/create-community-post.dto';
import { CreateOfficialPostDto } from './dto/create-official-post.dto';
import { GetCommunityFeedDto } from './dto/get-community-feed.dto';
import { GetListCommunityPostDto } from './dto/get-list-community-post.dto';
import { ModerateCommunityPostDto } from './dto/moderate-community-post.dto';
import { UpsertWeeklyQuestionDto } from './dto/upsert-weekly-question.dto';
import { CommunityPostRepository } from './repository/community-post.repository';
import { CommunityPost } from './schema/community-post.schema';
import {
  CommunityAuthorType,
  CommunityContentStatus,
  CommunityNotificationType,
  CommunityPostType,
  CommunityReactionKind,
  CommunityReportStatus,
  CommunityTargetType,
} from '../../enum/community.enum';
import {
  assertWithinWriteLimit,
  COMMUNITY_AUTO_HIDDEN_REASON,
  COMMUNITY_AUTO_MODERATOR_ID,
  COMMUNITY_POST_LIMIT,
} from '../../helper/community-limit.helper';
import { pickTranslation } from '../../helper/community-translation.helper';
import { startOfWeekUtc } from '../../helper/community-week.helper';
import { CommunityAuthorService } from '../../service/community-author.service';
import { CommunityCommentRepository } from '../comment/repository/community-comment.repository';
import { CommunityNotificationService } from '../notification/community-notification.service';
import { CommunityReactionService } from '../reaction/community-reaction.service';
import { CommunityReportRepository } from '../report/repository/community-report.repository';
import { CommunitySanctionService } from '../sanction/community-sanction.service';
import { CommunityTopicService } from '../topic/community-topic.service';
import { CommunityTopicRepository } from '../topic/repository/community-topic.repository';

@Injectable()
export class CommunityPostService {
  constructor(
    private readonly postRepository: CommunityPostRepository,
    private readonly commentRepository: CommunityCommentRepository,
    private readonly topicRepository: CommunityTopicRepository,
    private readonly reportRepository: CommunityReportRepository,
    private readonly topicService: CommunityTopicService,
    private readonly reactionService: CommunityReactionService,
    private readonly sanctionService: CommunitySanctionService,
    private readonly authorService: CommunityAuthorService,
    private readonly notificationService: CommunityNotificationService,
  ) {}

  /**
   * The community feed.
   *
   * Page 1 carries the pinned posts and the open weekly question; later pages
   * return the list alone, so a reader scrolling down does not meet the same
   * house-rules post every ten rows.
   */
  async feed(userId: string, locale: string, dto: GetCommunityFeedDto) {
    const page = dto.page ?? 1;
    const isFirstPage = page <= 1;
    // Page 1 stamps the anchor; later pages send it back so a post written
    // mid-scroll cannot shift a row from page 2 down into page 3 as well.
    const anchorAt = dto.anchorAt ?? new Date();

    const [hiddenIds, followedPostIds] = await Promise.all([
      this.reactionService.hiddenIds(userId, CommunityTargetType.POST),
      // The "Đang theo dõi" tab is per-thread, not per-room: it lists the posts
      // the reader put the bell on, which is what the bell promises.
      dto.followedOnly
        ? this.reactionService.followedPostIds(userId)
        : Promise.resolve(undefined),
    ]);

    const query = {
      locale,
      topicId: dto.topicId,
      includeIds: followedPostIds,
      excludeIds: hiddenIds,
      sort: dto.sort,
      anchorAt,
      page,
      take: dto.take,
    };

    // The house-rules pin and the weekly question belong to the "Tất cả" tab.
    // On the followed tab they would be two rows the reader never asked to
    // follow, sitting above the ones they did.
    const wantsHeader = isFirstPage && !dto.followedOnly;
    const [listed, pinned, weekly] = await Promise.all([
      this.postRepository.feedPage(query),
      wantsHeader ? this.postRepository.findPinned(query) : Promise.resolve([]),
      wantsHeader
        ? this.postRepository.findOpenWeekly(new Date())
        : Promise.resolve(null),
    ]);

    const posts = [...pinned, ...listed.items];
    const views = await this.toViews(posts, userId, locale);
    const pinnedIds = new Set(pinned.map((post) => String(post._id)));

    return {
      anchorAt,
      weekly: weekly ? this.toWeeklyView(weekly, locale) : null,
      pinned: views.filter((view) => pinnedIds.has(view.id)),
      items: views.filter((view) => !pinnedIds.has(view.id)),
      currentPage: listed.currentPage,
      totalPages: listed.totalPages,
      itemsPerPage: listed.itemsPerPage,
    };
  }

  async findOneForReader(id: string, userId: string, locale: string) {
    const post = await this.postRepository.findVisibleById(id);
    if (!post) throw new NotFoundException('Post not found');

    const [view] = await this.toViews([post], userId, locale);
    return view;
  }

  async savedPosts(userId: string, locale: string, page?: number, take?: number) {
    const saved = await this.reactionService.savedPostsPage(userId, page, take);
    const posts = await this.postRepository.findByIds(
      saved.items.map((row) => String(row.targetId)),
    );

    // Keep the order the reader saved them in, newest first: findByIds returns
    // natural collection order, which is not that.
    const byId = new Map(posts.map((post) => [String(post._id), post]));
    const ordered = saved.items
      .map((row) => byId.get(String(row.targetId)))
      .filter(Boolean) as CommunityPost[];

    return {
      items: await this.toViews(ordered, userId, locale),
      currentPage: saved.currentPage,
      totalPages: saved.totalPages,
      itemsPerPage: saved.itemsPerPage,
    };
  }

  async weekly(locale: string) {
    const post = await this.postRepository.findOpenWeekly(new Date());
    return post ? this.toWeeklyView(post, locale) : null;
  }

  async create(
    userId: string,
    locale: string,
    dto: CreateCommunityPostDto,
    user?: IUserMeta,
  ) {
    await this.sanctionService.assertCanWrite(userId);
    await this.assertWithinRate(userId, dto.body);
    await this.assertTopicUsable(dto.topicId);

    const post = await this.postRepository.create(
      {
        type: CommunityPostType.POST,
        // authorId is stored either way: an anonymous post still has to be
        // deletable by its writer, reachable by moderation, and coverable by a
        // posting ban. Only the reader-facing view drops the name.
        authorType: dto.isAnonymous
          ? CommunityAuthorType.ANONYMOUS
          : CommunityAuthorType.USER,
        authorId: userId,
        topicId: dto.topicId,
        locale,
        subject: dto.subject?.trim() ?? '',
        // Trimmed on the way in, so the same story pasted a second time with a
        // stray newline is still recognised as the same story.
        body: dto.body?.trim() ?? '',
        images: dto.images ?? [],
        attachedCourseId: dto.attachedCourseId,
        attachedCard: dto.attachedCard,
        lastActivityAt: new Date(),
      } as Partial<CommunityPost>,
      user,
    );

    if (dto.topicId) {
      await this.topicService.bumpPostCount(dto.topicId, locale, 1);
    }

    const [view] = await this.toViews([post], userId, locale);
    return view;
  }

  /**
   * The posting ceiling: how many threads one account may open in an hour, and
   * a refusal to publish the same story twice.
   *
   * Checked here rather than by a global HTTP throttler because the budget that
   * matters is per ACCOUNT — the forum is all behind AuthGuard, and an IP is
   * neither stable (mobile) nor unique (office NAT). Counted straight off the
   * posts collection, so it costs one indexed query and cannot drift out of
   * sync with what is actually on the feed.
   */
  private async assertWithinRate(userId: string, body?: string) {
    const limit = COMMUNITY_POST_LIMIT;
    const now = Date.now();
    const text = body?.trim();

    const [stats, isDuplicate] = await Promise.all([
      this.postRepository.recentWritesByAuthor(
        userId,
        new Date(now - limit.windowMs),
        limit.max,
      ),
      text && text.length >= limit.duplicateMinLength
        ? this.postRepository.hasRecentBody(
            userId,
            new Date(now - limit.duplicateMs),
            text,
          )
        : Promise.resolve(false),
    ]);

    assertWithinWriteLimit(stats, limit, isDuplicate);
  }

  /**
   * The author removes their own post.
   *
   * Status becomes DELETED rather than the row being dropped: comments,
   * reactions and any report already filed still point at it, and a moderator
   * looking into a report needs to see what was reported.
   */
  async removeOwn(id: string, userId: string) {
    const post = await this.postRepository.findById(id);
    if (!post) throw new NotFoundException('Post not found');
    if (post.authorId !== userId) {
      throw new ForbiddenException('Not your post');
    }

    await this.postRepository.updateOne(
      { _id: id },
      { status: CommunityContentStatus.DELETED },
    );
    await this.adjustWeeklyCountIfNeeded(post, -1);

    return { deleted: true };
  }

  // ---------------------------------------------------------------- admin

  async findAllForAdmin(dto: GetListCommunityPostDto) {
    const listed = await this.postRepository.adminPage(dto);
    const authors = await this.authorService.resolve(
      listed.items.map((post) => post.authorId),
    );
    const topics = await this.topicRepository.findByIds(
      listed.items.map((post) => post.topicId).filter(Boolean) as string[],
    );
    const topicById = new Map(topics.map((t) => [String(t._id), t]));

    return {
      ...listed,
      items: listed.items.map((post) => ({
        id: String(post._id),
        type: post.type,
        status: post.status,
        locale: post.locale,
        subject: post.subject ?? '',
        body: post.body,
        // Weekly questions carry translations and a window instead of a body;
        // the admin editor prefills from these.
        title: post.title,
        note: post.note,
        weekly: post.weekly,
        images: post.images,
        // The panel could see the attached CARD but not the attached COURSE, so
        // a post whose whole point is "mình đang học khoá này" arrived looking
        // like a body with nothing on it.
        attachedCourseId: post.attachedCourseId ?? null,
        attachedCard: post.attachedCard ?? null,
        // `reveal` — the moderation queue has to know WHO wrote an anonymous
        // post, or a ban has nobody to land on. The author object still carries
        // authorType ANONYMOUS so the queue can label it.
        author: this.authorService.pick(
          authors,
          post.authorId,
          post.authorType,
          true,
        ),
        topic: post.topicId
          ? {
              id: post.topicId,
              name: topicById.get(post.topicId)?.name ?? null,
            }
          : null,
        isPinned: post.isPinned,
        commentsLocked: post.commentsLocked,
        likeCount: post.likeCount,
        commentCount: post.commentCount,
        // The bell: how many readers asked to be told when this thread moves.
        // The app's card draws it beside the heart, so the panel showing two of
        // the three counters made the same post look different in the two
        // places it is read.
        saveCount: post.saveCount,
        reportCount: post.reportCount,
        // Both markers are bookkeeping, not sentences written for anyone to
        // read: the panel gets a flag and the raw token stays out of the table.
        hiddenByReports: post.hiddenReason === COMMUNITY_AUTO_HIDDEN_REASON,
        hiddenReason:
          post.hiddenReason === COMMUNITY_AUTO_HIDDEN_REASON
            ? null
            : (post.hiddenReason ?? null),
        createdAt: post.createdAt,
      })),
    };
  }

  /**
   * Moderator action on a post: hide, restore, pin, lock comments.
   *
   * Hiding takes the thread with it and closes every pending report on the
   * post — otherwise the queue keeps offering work that is already done. The
   * author is told, with the reason, because a post that vanishes silently
   * reads as a bug and comes back as a support ticket.
   */
  async moderate(
    id: string,
    dto: ModerateCommunityPostDto,
    moderatorId: string,
    user?: IUserMeta,
  ) {
    const post = await this.postRepository.findById(id);
    if (!post) throw new NotFoundException('Post not found');

    // subject/body/images are a POST's own shape. A weekly question carries
    // `title`/`note` translations instead and has its own edit route
    // (`PATCH admin/weekly/:id`) — no live caller sends these here for one,
    // but a future one silently writing an English `subject` onto a
    // WEEKLY_QUESTION row is exactly the kind of bug this guard is cheap
    // insurance against.
    const editsContent =
      dto.subject !== undefined || dto.body !== undefined || dto.images !== undefined;
    if (editsContent && post.type !== CommunityPostType.POST) {
      throw new BadRequestException(
        'Chỉ sửa được nội dung của bài đăng thường, không phải câu hỏi tuần',
      );
    }

    const update: Partial<CommunityPost> = {};
    const statusChanged = Boolean(dto.status && dto.status !== post.status);

    if (statusChanged) {
      update.status = dto.status;
      if (dto.status === CommunityContentStatus.HIDDEN) {
        update.hiddenReason = dto.hiddenReason;
      }
    }

    if (dto.isPinned !== undefined && dto.isPinned !== post.isPinned) {
      update.isPinned = dto.isPinned;
      update.pinnedAt = dto.isPinned ? new Date() : null;
    }

    if (dto.commentsLocked !== undefined) {
      update.commentsLocked = dto.commentsLocked;
    }

    if (dto.subject !== undefined) update.subject = dto.subject.trim();
    if (dto.body !== undefined) update.body = dto.body.trim();
    if (dto.images !== undefined) update.images = dto.images.map(url => url.trim()).filter(Boolean);

    // `moderatedBy/At` now means "a moderator last touched this" rather than
    // narrowly "last status change" — a content edit is exactly the kind of
    // moderator action that field exists to record, and nothing reads it as
    // status-change-only (grepped every call site before widening this).
    if (statusChanged || editsContent) {
      update.moderatedBy = moderatorId;
      update.moderatedAt = new Date();
    }

    if (Object.keys(update).length) {
      await this.postRepository.updateOne({ _id: id }, update, user);
    }

    // Restoring a post brings back the comments that went down with it — but
    // not the ones a moderator had hidden on their own merits — and puts the
    // topic's weekly count back where it was.
    if (update.status === CommunityContentStatus.VISIBLE) {
      await Promise.all([
        this.commentRepository.restoreCascadedForPost(id, moderatorId),
        this.adjustWeeklyCountIfNeeded(post, 1),
      ]);
    }

    if (update.status === CommunityContentStatus.HIDDEN) {
      await Promise.all([
        this.commentRepository.hideAllForPost(id, moderatorId),
        this.reportRepository.resolveAllForTarget(
          CommunityTargetType.POST,
          id,
          CommunityReportStatus.RESOLVED_HIDDEN,
          moderatorId,
        ),
        this.adjustWeeklyCountIfNeeded(post, -1),
      ]);

      if (post.authorType === CommunityAuthorType.USER) {
        await this.notificationService.notify({
          userId: post.authorId,
          type: CommunityNotificationType.POST_HIDDEN,
          postId: id,
          reason: dto.hiddenReason ?? '',
        });
      }
    }

    return this.postRepository.findById(id);
  }

  /**
   * Takes a post out of the feed because enough different readers reported it.
   *
   * Deliberately NOT `moderate()`: that closes every pending report as
   * RESOLVED_HIDDEN, which would empty the queue of exactly the items a human
   * still has to look at. Here the reports stay open and the post is marked with
   * [COMMUNITY_AUTO_HIDDEN_REASON], so the panel can tell "the count did this,
   * confirm it" from "a moderator decided this".
   *
   * The author is not notified. The hide is provisional and can be wrong — a
   * handful of readers who dislike a post can produce it — and being told your
   * post was hidden and then having it quietly reappear is worse than being told
   * once, after a person has actually read it. The moderator's own hide sends
   * that message.
   *
   * Returns whether it hid anything, so the caller can log it.
   */
  async autoHideByReports(id: string) {
    const post = await this.postRepository.findById(id);
    if (!post) return false;
    if (post.status !== CommunityContentStatus.VISIBLE) return false;

    // The house's own content is out of reach: the pinned rules post and the
    // team's answers are the two things a brigade would most want gone, and a
    // forum whose rules can be reported off the front page has no rules.
    if (post.authorType === CommunityAuthorType.OFFICIAL) return false;
    if (post.isPinned || post.type === CommunityPostType.WEEKLY_QUESTION) {
      return false;
    }

    await this.postRepository.updateOne({ _id: id }, {
      status: CommunityContentStatus.HIDDEN,
      hiddenReason: COMMUNITY_AUTO_HIDDEN_REASON,
      moderatedBy: COMMUNITY_AUTO_MODERATOR_ID,
      moderatedAt: new Date(),
    } as Partial<CommunityPost>);

    await Promise.all([
      this.commentRepository.hideAllForPost(id, COMMUNITY_AUTO_MODERATOR_ID),
      this.adjustWeeklyCountIfNeeded(post, -1),
    ]);

    return true;
  }

  async createOfficial(
    dto: CreateOfficialPostDto,
    moderatorId: string,
    user?: IUserMeta,
  ) {
    await this.assertTopicUsable(dto.topicId);

    const post = await this.postRepository.create(
      {
        type: CommunityPostType.POST,
        authorType: CommunityAuthorType.OFFICIAL,
        authorId: moderatorId,
        topicId: dto.topicId,
        locale: dto.locale,
        subject: dto.subject?.trim() ?? '',
        body: dto.body,
        images: dto.images ?? [],
        attachedCourseId: dto.attachedCourseId,
        attachedCard: dto.attachedCard,
        isPinned: dto.isPinned ?? false,
        pinnedAt: dto.isPinned ? new Date() : undefined,
        lastActivityAt: new Date(),
      } as Partial<CommunityPost>,
      user,
    );

    if (dto.topicId) {
      await this.topicService.bumpPostCount(dto.topicId, dto.locale, 1);
    }

    return post;
  }

  async listWeeklyForAdmin(dto: GetListCommunityPostDto) {
    return this.findAllForAdmin({
      ...dto,
      type: CommunityPostType.WEEKLY_QUESTION,
    });
  }

  async createWeekly(
    dto: UpsertWeeklyQuestionDto,
    moderatorId: string,
    user?: IUserMeta,
  ) {
    this.assertWeeklyWindow(dto);

    return this.postRepository.create(
      {
        type: CommunityPostType.WEEKLY_QUESTION,
        authorType: CommunityAuthorType.OFFICIAL,
        authorId: moderatorId,
        // No locale on purpose: the team writes the question in all five
        // languages, so it is shown to every reader in their own.
        locale: null,
        title: dto.title,
        note: dto.note,
        weekly: {
          weekNumber: dto.weekNumber,
          year: dto.year,
          startsAt: dto.startsAt,
          endsAt: dto.endsAt,
        },
        lastActivityAt: new Date(),
      } as Partial<CommunityPost>,
      user,
    );
  }

  async updateWeekly(
    id: string,
    dto: UpsertWeeklyQuestionDto,
    user?: IUserMeta,
  ) {
    const post = await this.postRepository.findById(id);
    if (!post || post.type !== CommunityPostType.WEEKLY_QUESTION) {
      throw new NotFoundException('Weekly question not found');
    }
    this.assertWeeklyWindow(dto);

    await this.postRepository.updateOne(
      { _id: id },
      {
        title: dto.title,
        note: dto.note,
        weekly: {
          weekNumber: dto.weekNumber,
          year: dto.year,
          startsAt: dto.startsAt,
          endsAt: dto.endsAt,
        },
      } as Partial<CommunityPost>,
      user,
    );

    return this.postRepository.findById(id);
  }

  // ---------------------------------------------------------------- shared

  /**
   * Turn post documents into what the app renders.
   *
   * Three lookups for the whole page regardless of its size: authors, topics,
   * and the reader's own likes/saves. Doing any of them per post is what turns
   * a feed into forty queries.
   */
  private async toViews(
    posts: CommunityPost[],
    userId: string,
    locale: string,
  ) {
    if (!posts.length) return [];

    const ids = posts.map((post) => String(post._id));
    const [authors, topics, flags] = await Promise.all([
      this.authorService.resolve(posts.map((post) => post.authorId)),
      this.topicRepository.findByIds(
        posts.map((post) => post.topicId).filter(Boolean) as string[],
      ),
      this.reactionService.flagsFor({
        userId,
        targetType: CommunityTargetType.POST,
        targetIds: ids,
        kinds: [CommunityReactionKind.LIKE, CommunityReactionKind.SAVE],
      }),
    ]);

    const topicById = new Map(topics.map((topic) => [String(topic._id), topic]));
    const liked = flags.get(CommunityReactionKind.LIKE) ?? new Set<string>();
    const saved = flags.get(CommunityReactionKind.SAVE) ?? new Set<string>();

    return posts.map((post) => {
      const id = String(post._id);
      const topic = post.topicId ? topicById.get(post.topicId) : undefined;

      return {
        id,
        type: post.type,
        author: this.authorService.pick(
          authors,
          post.authorId,
          post.authorType,
        ),
        topic: topic
          ? {
              id: String(topic._id),
              name: pickTranslation(topic.name, locale),
              // The post screen's header draws the room's thumbnail next to its
              // name, and the topic is already loaded here — leaving it off
              // meant the app had a name with nothing to put beside it.
              imageUrl: topic.imageUrl ?? null,
            }
          : null,
        // A weekly question carries its text as translations, not as `body`.
        // Filling body here means every consumer reads it the same way — the
        // detail screen a weekly-answer notification deeplinks into showed a
        // blank post otherwise.
        body:
          post.type === CommunityPostType.WEEKLY_QUESTION
            ? pickTranslation(post.title, locale)
            : post.body,
        subject: post.subject ?? '',
        images: post.images ?? [],
        attachedCourseId: post.attachedCourseId ?? null,
        attachedCard: post.attachedCard ?? null,
        isPinned: post.isPinned,
        commentsLocked: post.commentsLocked,
        likeCount: post.likeCount,
        commentCount: post.commentCount,
        saveCount: post.saveCount,
        isLiked: liked.has(id),
        isSaved: saved.has(id),
        isMine: post.authorId === userId,
        createdAt: post.createdAt,
      };
    });
  }

  private toWeeklyView(post: CommunityPost, locale: string) {
    return {
      id: String(post._id),
      title: pickTranslation(post.title, locale),
      note: pickTranslation(post.note, locale),
      weekNumber: post.weekly?.weekNumber ?? null,
      year: post.weekly?.year ?? null,
      startsAt: post.weekly?.startsAt ?? null,
      endsAt: post.weekly?.endsAt ?? null,
      answerCount: post.commentCount,
    };
  }

  private async assertTopicUsable(topicId?: string) {
    if (!topicId) return;

    const topic = await this.topicRepository.findById(topicId);
    if (!topic || !topic.isActive) {
      throw new BadRequestException('Topic not available');
    }
  }

  /**
   * Move a topic's "N bài tuần này" counter when a post appears or disappears.
   *
   * The counter only tracks the CURRENT week, so a post written in an earlier
   * week must not move it either way — otherwise hiding old content pushes it
   * negative.
   *
   * Called with -1 when a post is hidden or deleted and +1 when a hidden post
   * is restored. It has to be both: with only the decrement, a moderator who
   * hid a post and put it back left the topic reading "0 bài tuần này" next to
   * a topic that visibly has one, and it stayed wrong until the Monday reset.
   */
  private async adjustWeeklyCountIfNeeded(post: CommunityPost, delta: number) {
    if (!post.topicId || !post.locale) return;
    if (post.createdAt < startOfWeekUtc(new Date())) return;

    await this.topicService.bumpPostCount(post.topicId, post.locale, delta);
  }

  private assertWeeklyWindow(dto: UpsertWeeklyQuestionDto) {
    if (dto.endsAt <= dto.startsAt) {
      throw new BadRequestException('endsAt must be after startsAt');
    }
  }
}
