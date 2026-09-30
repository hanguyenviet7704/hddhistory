import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';

import { CreateCommunityTopicDto } from './dto/create-community-topic.dto';
import { GetListCommunityTopicDto } from './dto/get-list-community-topic.dto';
import { UpdateCommunityTopicDto } from './dto/update-community-topic.dto';
import { CommunityTopicRepository } from './repository/community-topic.repository';
import { CommunityTopic } from './schema/community-topic.schema';
import { startOfLocalDayUtc } from '../../helper/community-day.helper';
import { pickTranslation } from '../../helper/community-translation.helper';
import {
  CommunityLocale,
  ICommunityTopicLocaleStats,
} from '../../interface/community.interface';
import { CommunityPostRepository } from '../post/repository/community-post.repository';
import { CommunityTopicFollowRepository } from '../reaction/repository/community-topic-follow.repository';

const EMPTY_STATS: ICommunityTopicLocaleStats = {
  followers: 0,
  postsThisWeek: 0,
};

@Injectable()
export class CommunityTopicService {
  constructor(
    private readonly topicRepository: CommunityTopicRepository,
    private readonly followRepository: CommunityTopicFollowRepository,
    private readonly postRepository: CommunityPostRepository,
  ) {}

  /**
   * The topics screen: what the reader follows, then everything else.
   *
   * Counters are read out of the locale bucket rather than summed across all
   * five, because the feed behind each topic is locale-filtered too — a shared
   * total next to an empty feed would be a lie.
   */
  async listForReader(userId: string, locale: string, tzOffset = 0) {
    const since = startOfLocalDayUtc(new Date(), tzOffset);
    const [topics, followedIds, todayCounts, discussionCounts] =
      await Promise.all([
        this.topicRepository.findActive(),
        this.followRepository.followedTopicIds(userId),
        this.postRepository.countPostsPerTopicSince(locale, since),
        this.postRepository.countDiscussionsPerTopic(locale),
      ]);

    const followed = new Set(followedIds);
    const view = topics.map((topic) =>
      this.toReaderView(topic, locale, followed, todayCounts, discussionCounts),
    );

    return {
      following: view.filter((topic) => topic.isFollowing),
      all: view.filter((topic) => !topic.isFollowing),
    };
  }

  async findOneForReader(
    id: string,
    userId: string,
    locale: string,
    tzOffset = 0,
  ) {
    const topic = await this.topicRepository.findById(id);
    if (!topic) throw new NotFoundException('Topic not found');

    const [followedIds, postsToday, discussions] = await Promise.all([
      this.followRepository.followedTopicIds(userId),
      // The single-topic counters, not the grouped ones: this reads one room,
      // and grouping the whole collection to answer for one of them is waste.
      this.postRepository.countPostsInTopicSince(
        id,
        locale,
        startOfLocalDayUtc(new Date(), tzOffset),
      ),
      this.postRepository.countDiscussionsInTopic(id, locale),
    ]);

    return this.toReaderView(
      topic,
      locale,
      new Set(followedIds),
      { [id]: postsToday },
      { [id]: discussions },
    );
  }

  async follow(topicId: string, userId: string, locale: string) {
    const topic = await this.topicRepository.findById(topicId);
    if (!topic) throw new NotFoundException('Topic not found');

    // Only move the counter when a row was actually inserted, so tapping
    // "theo dõi" twice cannot inflate the follower count.
    const created = await this.followRepository.follow(topicId, userId, locale);
    if (created) {
      await this.topicRepository.bumpStat(topicId, locale, 'followers', 1);
    }

    return { isFollowing: true };
  }

  async unfollow(topicId: string, userId: string, locale: string) {
    const removed = await this.followRepository.unfollow(topicId, userId);
    if (removed) {
      await this.topicRepository.bumpStat(topicId, locale, 'followers', -1);
    }

    return { isFollowing: false };
  }

  async followedTopicIds(userId: string) {
    return this.followRepository.followedTopicIds(userId);
  }

  // ---------------------------------------------------------------- admin

  findAll(dto: GetListCommunityTopicDto) {
    return this.topicRepository.findOption(dto);
  }

  async findOne(id: string) {
    const topic = await this.topicRepository.findById(id);
    if (!topic) throw new NotFoundException('Topic not found');
    return topic;
  }

  async create(dto: CreateCommunityTopicDto, user?: IUserMeta) {
    const existing = await this.topicRepository.findOne({ slug: dto.slug });
    if (existing) {
      throw new BadRequestException(`Slug "${dto.slug}" is already taken`);
    }

    return this.topicRepository.create(dto as Partial<CommunityTopic>, user);
  }

  async update(id: string, dto: UpdateCommunityTopicDto, user?: IUserMeta) {
    await this.findOne(id);

    if (dto.slug) {
      const clash = await this.topicRepository.findOne({ slug: dto.slug });
      if (clash && String(clash._id) !== id) {
        throw new BadRequestException(`Slug "${dto.slug}" is already taken`);
      }
    }

    await this.topicRepository.updateOne(
      { _id: id },
      dto as Partial<CommunityTopic>,
      user,
    );
    return this.findOne(id);
  }

  /**
   * Topics are deactivated, never deleted.
   *
   * Posts keep a topicId, and hard-deleting the topic would leave every post
   * in it pointing at nothing — the feed would render chips with no label.
   */
  async deactivate(id: string, user?: IUserMeta) {
    await this.findOne(id);
    await this.topicRepository.updateOne({ _id: id }, { isActive: false }, user);
    return this.findOne(id);
  }

  bumpPostCount(topicId: string, locale: string, delta: number) {
    return this.topicRepository.bumpStat(
      topicId,
      locale,
      'postsThisWeek',
      delta,
    );
  }

  resetWeeklyPostCounts() {
    return this.topicRepository.resetWeeklyPostCounts();
  }

  /**
   * [todayCounts] is keyed by topic id and absent-means-zero, because the
   * aggregation that builds it only returns rooms that had a post today.
   */
  private toReaderView(
    topic: CommunityTopic,
    locale: string,
    followed: Set<string>,
    todayCounts: Record<string, number> = {},
    discussionCounts: Record<string, number> = {},
  ) {
    const stats = topic.stats?.[locale as CommunityLocale] ?? EMPTY_STATS;
    const id = String(topic._id);

    return {
      id,
      name: pickTranslation(topic.name, locale),
      description: pickTranslation(topic.description, locale),
      slug: topic.slug,
      imageUrl: topic.imageUrl,
      followers: stats.followers ?? 0,
      postsThisWeek: stats.postsThisWeek ?? 0,
      // Counted live per request, unlike the two stored counters above — see
      // `startOfLocalDayUtc` for why this one follows the reader's calendar.
      postsToday: todayCounts[id] ?? 0,
      /**
       * Tổng lượt thảo luận mọi thời: bài viết cộng bình luận của chúng.
       *
       * Thẻ phòng từng hiện `postsThisWeek` ở chỗ này, và một bộ đếm tuần bị
       * quét định kỳ làm mọi phòng có nội dung cũ hơn bảy ngày đọc ra là "0
       * lượt thảo luận" — phòng trông như chết trong khi nó không chết.
       *
       * Trường MỚI chứ không sửa nghĩa `postsThisWeek`: bản app cũ vẫn đọc
       * trường cũ và cư xử y như trước, còn `topicPostsThisWeek` trên hàng
       * gợi ý thì đúng là muốn nói "tuần này" thật.
       */
      discussions: discussionCounts[id] ?? 0,
      isFollowing: followed.has(id),
    };
  }
}
