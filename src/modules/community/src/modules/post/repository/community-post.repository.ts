import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { OrderType } from '@utils/type/orderByType';

import {
  CommunityContentStatus,
  CommunityFeedSort,
  CommunityPostType,
} from '../../../enum/community.enum';
import { communityTake } from '../../../helper/community-limit.helper';
import { GetListCommunityPostDto } from '../dto/get-list-community-post.dto';
import { IFeedQuery } from '../interface/community-post.interface';
import { CommunityPost } from '../schema/community-post.schema';

@Injectable()
export class CommunityPostRepository extends AbstractRepository<CommunityPost> {
  protected readonly logger = new Logger(CommunityPostRepository.name);

  constructor(
    @InjectModel(CommunityPost.name) model: Model<CommunityPost>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  // Shared shape of every reader-facing query: visible ordinary posts in the
  // reader's own language, minus anything they hid for themselves.
  private feedWhere(query: IFeedQuery): FilterQuery<CommunityPost> {
    const where: FilterQuery<CommunityPost> = {
      type: CommunityPostType.POST,
      status: CommunityContentStatus.VISIBLE,
      locale: query.locale,
    };

    if (query.topicId) {
      where.topicId = query.topicId;
    } else if (query.topicIds) {
      // Following-only feed. An empty follow list must return nothing rather
      // than silently falling back to everything.
      where.topicId = { $in: query.topicIds };
    }

    // The "Đang theo dõi" tab: only the threads this reader put the bell on.
    // An empty list must return nothing — falling through to the whole feed
    // would read as "you follow everything".
    if (query.includeIds) {
      where._id = query.excludeIds?.length
        ? { $in: query.includeIds, $nin: query.excludeIds }
        : { $in: query.includeIds };
    } else if (query.excludeIds?.length) {
      where._id = { $nin: query.excludeIds };
    }

    // Page 1 stamps a server timestamp that later pages carry back, so a post
    // written between page 1 and page 2 cannot push a row into both.
    if (query.anchorAt) {
      where.createdAt = { $lte: query.anchorAt };
    }

    return where;
  }

  async feedPage(query: IFeedQuery) {
    return this.paginateQuery<CommunityPost>({
      // Pinned posts are returned by findPinned and shown above the list, so
      // excluding them here keeps them off page 2 as ordinary rows.
      where: { ...this.feedWhere(query), isPinned: { $ne: true } },
      page: query.page,
      // Clamped: nothing stops a client asking for a page of 100000, and this
      // is the query that would read the whole forum out of Mongo.
      take: communityTake(query.take),
      // "Sôi nổi" sorts by the last comment rather than the post's own age, so
      // an older thread that is still being answered stays near the top.
      orderBy:
        query.sort === CommunityFeedSort.ACTIVE ? 'lastActivityAt' : 'createdAt',
      order: OrderType.DESC,
    });
  }

  async findPinned(query: IFeedQuery): Promise<CommunityPost[]> {
    return this.model
      .find({ ...this.feedWhere(query), isPinned: true })
      .sort({ pinnedAt: -1, createdAt: -1 })
      .limit(3)
      .lean() as unknown as CommunityPost[];
  }

  // The weekly question currently open. Not locale-filtered: the team writes it
  // in all five languages and every reader sees it in their own.
  async findOpenWeekly(now: Date): Promise<CommunityPost | null> {
    return this.model
      .findOne({
        type: CommunityPostType.WEEKLY_QUESTION,
        status: CommunityContentStatus.VISIBLE,
        'weekly.startsAt': { $lte: now },
        'weekly.endsAt': { $gte: now },
      })
      .sort({ 'weekly.startsAt': -1 })
      .lean() as unknown as CommunityPost | null;
  }

  /**
   * Admin moderation table.
   *
   * Unlike the reader feed this can see HIDDEN and DELETED rows — that is the
   * whole point of it — and searches the body text, which the reader feed never
   * needs to do.
   */
  async adminPage(dto: GetListCommunityPostDto) {
    const where: FilterQuery<CommunityPost> = {};

    if (dto.status) where.status = dto.status;
    if (dto.type) where.type = dto.type;
    if (dto.topicId) where.topicId = dto.topicId;
    if (dto.locale) where.locale = dto.locale;
    if (dto.authorId) where.authorId = dto.authorId;

    if (dto.search?.trim()) {
      const escaped = dto.search.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      where.body = { $regex: escaped, $options: 'i' };
    }

    const orderBy = dto.orderBy || 'createdAt';
    const order = dto.order === OrderType.ASC ? 1 : -1;

    return this.paginateQuery<CommunityPost>({
      where,
      page: dto.page,
      take: dto.take,
      // Pinned first, then the chosen order. A pin is a decision about what sits
      // at the top of the feed, so the panel that made it has to show the same
      // thing — hunting for the post you just pinned, three pages down, is how
      // you end up pinning a second one.
      sort: { isPinned: -1, [orderBy]: order },
    });
  }

  async findVisibleById(id: string): Promise<CommunityPost | null> {
    return this.model
      .findOne({ _id: id, status: CommunityContentStatus.VISIBLE })
      .lean() as unknown as CommunityPost | null;
  }

  async findByIds(ids: string[]): Promise<CommunityPost[]> {
    if (!ids.length) return [];
    return this.model
      .find({ _id: { $in: ids }, status: CommunityContentStatus.VISIBLE })
      .lean() as unknown as CommunityPost[];
  }

  /**
   * Any status, including HIDDEN and DELETED.
   *
   * The moderation queue has to render what was reported even after it was
   * taken down — otherwise a resolved report is a row with nothing in it.
   */
  async findAnyByIds(ids: string[]): Promise<CommunityPost[]> {
    if (!ids.length) return [];
    return this.model
      .find({ _id: { $in: ids } })
      .lean() as unknown as CommunityPost[];
  }

  async bumpCounter(
    postId: string,
    field: 'likeCount' | 'commentCount' | 'saveCount' | 'reportCount',
    delta: number,
    touchActivity = false,
  ) {
    const update: Record<string, unknown> = { $inc: { [field]: delta } };
    if (touchActivity) {
      update.$set = { lastActivityAt: new Date() };
    }
    return this.model.updateOne({ _id: postId }, update);
  }

  /**
   * How many visible posts landed in each topic since [since], keyed by
   * topicId. Topics with none are simply absent from the map.
   *
   * One aggregation for the whole list, rather than the per-topic
   * [countPostsInTopicSince] next door in a loop: the rooms screen renders
   * every topic at once, so that would be one round trip per room on a screen
   * that already waits on two other queries. Matches the same visible-ordinary-
   * post shape [feedWhere] uses, so the number cannot count a row the reader
   * would never see, and runs on the `{ topicId, status, locale, createdAt }`
   * index.
   */
  async countPostsPerTopicSince(
    locale: string,
    since: Date,
  ): Promise<Record<string, number>> {
    const rows = await this.model.aggregate<{ _id: string; count: number }>([
      {
        $match: {
          locale,
          type: CommunityPostType.POST,
          status: CommunityContentStatus.VISIBLE,
          createdAt: { $gte: since },
        },
      },
      { $group: { _id: '$topicId', count: { $sum: 1 } } },
    ]);

    return rows.reduce<Record<string, number>>((counts, row) => {
      // A post with no topic groups under a null key — it belongs to no room,
      // so no room's number may claim it.
      const topicId = row._id ? String(row._id) : '';
      if (topicId) counts[topicId] = row.count;
      return counts;
    }, {});
  }

  async countPostsInTopicSince(topicId: string, locale: string, since: Date) {
    return this.model.countDocuments({
      topicId,
      locale,
      type: CommunityPostType.POST,
      status: CommunityContentStatus.VISIBLE,
      createdAt: { $gte: since },
    });
  }

  /**
   * Tổng lượt thảo luận MỌI THỜI, theo phòng: bài viết cộng bình luận của chúng.
   *
   * Con số trên thẻ phòng trước đây là `postsThisWeek` — một bộ đếm tuần bị
   * quét sạch định kỳ (`resetWeeklyPostCounts`). Hệ quả: một phòng có bài và
   * có bình luận vẫn hiện "0 lượt thảo luận" chỉ vì chúng được viết tuần
   * trước, đọc ra là phòng chết trong khi nó không chết.
   *
   * Cộng từ `commentCount` sẵn có trên mỗi bài chứ không đụng tới bảng bình
   * luận: một phép gộp trên một collection, và quan trọng hơn — KHÔNG cần cột
   * mới nào, nên nội dung đã có từ trước đếm đúng ngay mà không phải backfill.
   *
   * Cùng bộ lọc với phép đếm theo ngày bên dưới: chỉ bài `POST` còn hiện, và
   * chỉ trong bucket ngôn ngữ đang đọc — feed sau mỗi phòng cũng lọc theo
   * ngôn ngữ, nên một tổng gộp cả năm thứ tiếng đặt cạnh một feed rỗng là nói
   * dối.
   */
  async countDiscussionsPerTopic(
    locale: string,
  ): Promise<Record<string, number>> {
    const rows = await this.model.aggregate<{ _id: string; count: number }>([
      {
        $match: {
          locale,
          type: CommunityPostType.POST,
          status: CommunityContentStatus.VISIBLE,
        },
      },
      {
        $group: {
          _id: '$topicId',
          // Bản thân bài là một lượt, cộng thêm bình luận của nó.
          count: { $sum: { $add: [1, { $ifNull: ['$commentCount', 0] }] } },
        },
      },
    ]);

    return rows.reduce<Record<string, number>>((counts, row) => {
      const topicId = row._id ? String(row._id) : '';
      if (topicId) counts[topicId] = row.count;
      return counts;
    }, {});
  }

  /**
   * Cùng phép đếm trên, nhưng cho MỘT phòng — màn chi tiết chỉ đọc một.
   *
   * `topicId` so khớp dạng CHUỖI, y như [countPostsInTopicSince] và mọi truy
   * vấn khác trong tệp này: schema khai `topicId?: string`, nên bọc nó vào
   * `new Types.ObjectId(...)` thì không khớp bản ghi nào và phòng nào cũng trả
   * về 0 — card phòng (đếm gộp, khớp chuỗi) hiện 10 lượt trong khi mở phòng ra
   * lại hiện 0.
   */
  async countDiscussionsInTopic(
    topicId: string,
    locale: string,
  ): Promise<number> {
    const [row] = await this.model.aggregate<{ count: number }>([
      {
        $match: {
          topicId,
          locale,
          type: CommunityPostType.POST,
          status: CommunityContentStatus.VISIBLE,
        },
      },
      {
        $group: {
          _id: null,
          count: { $sum: { $add: [1, { $ifNull: ['$commentCount', 0] }] } },
        },
      },
    ]);

    return row?.count ?? 0;
  }

  /**
   * What this author has written since [since]: how many rows, and when the
   * oldest of them landed — the two numbers the write ceiling is checked
   * against.
   *
   * Stops counting at [cap]: past the ceiling the exact number is not
   * interesting, only that it was passed. Every status counts, hidden and
   * deleted included, so deleting one is not a way to buy another.
   */
  async recentWritesByAuthor(authorId: string, since: Date, cap: number) {
    const rows = await this.model
      .find({ authorId, createdAt: { $gte: since } })
      .select('createdAt')
      .sort({ createdAt: 1 })
      .limit(cap)
      .lean();

    return {
      count: rows.length,
      oldestAt: rows[0]?.createdAt ?? null,
    };
  }

  /**
   * Whether this author has already written exactly this, word for word, since
   * [since] — the cheap half of spam detection, and the half that catches the
   * same message pasted into a room twenty times.
   */
  async hasRecentBody(authorId: string, since: Date, body: string) {
    const existing = await this.model.exists({
      authorId,
      createdAt: { $gte: since },
      body,
    });

    return !!existing;
  }
}
