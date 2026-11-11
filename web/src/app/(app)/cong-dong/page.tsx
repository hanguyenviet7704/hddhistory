import Link from 'next/link';

import { MutedBanner } from '@/components/community/author';
import { FeedList } from '@/components/community/feed-list';
import {
  ComposeLink,
  NotificationBell,
  WeeklyCard,
} from '@/components/community/header';
import { PostCard } from '@/components/community/post-card';
import { RoomSuggestions } from '@/components/community/room-suggestions';
import { TopicRow } from '@/components/community/topic-row';
import { Notice, SectionHeader } from '@/components/section';
import { describeError } from '@/lib/action-result';
import {
  DEFAULT_CHAT_ROOM,
  getChatRoom,
  getCommunityFeed,
  getMemberStatus,
  getRoomSuggestions,
  getTopics,
  getUnreadCount,
  type FeedSort,
  type MemberStatus,
  type RoomSuggestion,
  type TopicList,
} from '@/lib/community';

type Tab = 'tat-ca' | 'theo-doi' | 'phong';

/** Gói một lời gọi để một dải hỏng không làm trắng cả trang. */
function settle<T>(promise: Promise<T>): Promise<T | Error> {
  return promise.catch((error: unknown) =>
    error instanceof Error ? error : new Error(String(error)),
  );
}

export default async function CommunityPage({
  searchParams,
}: {
  searchParams: Promise<{ tab?: string; 'sap-xep'?: string; phong?: string }>;
}) {
  const params = await searchParams;
  const tab: Tab =
    params.tab === 'theo-doi' || params.tab === 'phong' ? params.tab : 'tat-ca';
  const sort: FeedSort = params['sap-xep'] === 'soi-noi' ? 'ACTIVE' : 'RECENT';
  const topicId =
    tab === 'tat-ca' && /^[a-f0-9]{24}$/i.test(params.phong ?? '')
      ? params.phong
      : undefined;

  const isFeed = tab !== 'phong';
  const [feed, topics, status, unread, room, suggestions] = await Promise.all([
    isFeed
      ? settle(
          getCommunityFeed({
            page: 1,
            take: 10,
            followedOnly: tab === 'theo-doi',
            sort,
            topicId,
          }),
        )
      : null,
    settle(getTopics()),
    // Hỏng thì coi như được đăng: API vẫn chặn khi gửi, tệ nhất là một lỗi lúc
    // bấm Đăng — tốt hơn khoá người đọc mà không có lý do (như app).
    getMemberStatus().catch((): MemberStatus => ({ canPost: true })),
    getUnreadCount().catch(() => 0),
    getChatRoom(DEFAULT_CHAT_ROOM).catch(() => null),
    tab === 'phong' ? getRoomSuggestions().catch(() => []) : [],
  ]);

  const topicList = topics instanceof Error ? null : topics;
  const allTopics = topicList ? [...topicList.following, ...topicList.all] : [];

  const tabHref = (next: Tab) => (next === 'tat-ca' ? '/cong-dong' : `/cong-dong?tab=${next}`);
  const feedHref = (next: { sort?: FeedSort; topic?: string | null }) => {
    const search = new URLSearchParams();
    if (tab !== 'tat-ca') search.set('tab', tab);
    const nextSort = next.sort ?? sort;
    if (nextSort === 'ACTIVE') search.set('sap-xep', 'soi-noi');
    const nextTopic = next.topic === undefined ? topicId : next.topic;
    if (nextTopic) search.set('phong', nextTopic);
    const query = search.toString();
    return query ? `/cong-dong?${query}` : '/cong-dong';
  };

  return (
    <div className="pt-5">
      <div className="mb-4 flex items-center gap-2">
        <h1 className="mr-auto text-2xl font-bold tracking-tight text-brand-900">
          Cộng đồng
        </h1>
        <NotificationBell unread={unread} />
        <ComposeLink canPost={status.canPost} />
      </div>

      {!status.canPost ? (
        <div className="mb-4">
          <MutedBanner reason={status.reason} mutedUntil={status.mutedUntil} />
        </div>
      ) : null}

      {room ? (
        <Link
          href={`/cong-dong/tro-chuyen/${encodeURIComponent(room.slug || DEFAULT_CHAT_ROOM)}`}
          className="mb-4 flex items-center gap-3 rounded-xl border border-hairline bg-surface p-3 transition hover:bg-brand-50"
        >
          <span aria-hidden className="flex size-10 items-center justify-center rounded-full bg-brand-900 text-sm font-bold text-brand-100">
            {(room.name || 'H').charAt(0)}
          </span>
          <span className="min-w-0 flex-1">
            <span className="block font-semibold text-brand-900">
              {room.name || 'Hội bàn tròn'}
            </span>
            <span className="block text-xs text-ink-faint">
              {room.onlineCount ?? 0} đang online · Giao lưu cùng cộng đồng
            </span>
          </span>
          {room.unreadCount ? (
            <span className="rounded-full bg-red-700 px-2 py-0.5 text-xs font-bold text-white">
              {room.unreadCount > 99 ? '99+' : room.unreadCount}
              <span className="sr-only"> tin chưa đọc</span>
            </span>
          ) : null}
        </Link>
      ) : null}

      <nav aria-label="Mục cộng đồng" className="mb-4 flex gap-1 rounded-xl bg-surface p-1">
        {(
          [
            ['tat-ca', 'Tất cả'],
            ['theo-doi', 'Đang theo dõi'],
            ['phong', 'Phòng'],
          ] as const
        ).map(([value, label]) => (
          <Link
            key={value}
            href={tabHref(value)}
            aria-current={tab === value ? 'page' : undefined}
            className={`flex-1 rounded-lg px-3 py-2 text-center text-sm font-semibold transition ${
              tab === value
                ? 'bg-brand-100 text-brand-900'
                : 'text-ink-faint hover:text-brand-700'
            }`}
          >
            {label}
          </Link>
        ))}
      </nav>

      {tab === 'phong' ? (
        <TopicsTab
          topics={topicList}
          failure={topics instanceof Error ? describeError(topics) : null}
          suggestions={suggestions ?? []}
          canPost={status.canPost}
        />
      ) : feed instanceof Error || !feed ? (
        <Notice>Không tải được bảng tin. {feed ? describeError(feed) : ''}</Notice>
      ) : (
        <>
          {feed.weekly && !topicId ? (
            <div className="mb-4">
              <WeeklyCard weekly={feed.weekly} />
            </div>
          ) : null}

          <div className="mb-3 flex flex-wrap items-center gap-2" aria-label="Sắp xếp">
            {(
              [
                ['RECENT', 'Mới nhất'],
                ['ACTIVE', 'Sôi nổi'],
              ] as const
            ).map(([value, label]) => (
              <Chip key={value} href={feedHref({ sort: value })} active={sort === value}>
                {label}
              </Chip>
            ))}
          </div>

          {tab === 'tat-ca' && allTopics.length > 0 ? (
            <div
              className="mb-4 flex gap-2 overflow-x-auto pb-1"
              role="group"
              aria-label="Lọc theo phòng"
            >
              <Chip href={feedHref({ topic: null })} active={!topicId}>
                Tất cả phòng
              </Chip>
              {allTopics.map((topic) => (
                <Chip
                  key={topic.id}
                  href={feedHref({ topic: topic.id })}
                  active={topicId === topic.id}
                >
                  {topic.name}
                </Chip>
              ))}
            </div>
          ) : null}

          {feed.pinned.length === 0 && feed.items.length === 0 ? (
            tab === 'theo-doi' ? (
              <EmptyState
                title="Chưa theo dõi thread nào"
                body="Bấm chuông trên một bài viết để nhận thông báo khi có bình luận mới."
                action={{ href: '/cong-dong', label: 'Xem tất cả bài' }}
              />
            ) : topicId ? (
              <EmptyState
                title="Phòng này chưa có bài"
                body="Bài của bạn có thể là bài đầu tiên."
              />
            ) : (
              <EmptyState
                title="Chưa có gì ở đây"
                body="Bạn viết bài đầu tiên nhé. Điều gì đang ở trong đầu bạn?"
              />
            )
          ) : (
            <>
              {feed.pinned.length > 0 ? (
                <ul className="mb-3 space-y-3" aria-label="Bài đã ghim">
                  {feed.pinned.map((post) => (
                    <PostCard key={post.id} post={post} />
                  ))}
                </ul>
              ) : null}
              <FeedList
                key={`${tab}|${sort}|${topicId ?? ''}`}
                initial={feed.items}
                currentPage={feed.currentPage}
                totalPages={feed.totalPages}
                anchorAt={feed.anchorAt}
                query={{ topicId, followedOnly: tab === 'theo-doi', sort }}
              />
            </>
          )}
        </>
      )}
    </div>
  );
}

function Chip({
  href,
  active,
  children,
}: {
  href: string;
  active: boolean;
  children: React.ReactNode;
}) {
  return (
    <Link
      href={href}
      aria-current={active ? 'true' : undefined}
      className={`shrink-0 rounded-full px-3 py-1.5 text-xs font-semibold whitespace-nowrap transition ${
        active
          ? 'bg-brand-900 text-brand-50'
          : 'border border-hairline bg-surface text-ink-muted hover:border-brand-200'
      }`}
    >
      {children}
    </Link>
  );
}

function EmptyState({
  title,
  body,
  action,
}: {
  title: string;
  body: string;
  action?: { href: string; label: string };
}) {
  return (
    <div className="rounded-xl border border-hairline bg-surface p-6 text-center">
      <p className="font-semibold text-brand-900">{title}</p>
      <p className="mt-1 text-sm text-ink-muted">{body}</p>
      {action ? (
        <Link
          href={action.href}
          className="mt-3 inline-block text-sm font-semibold text-brand-700 hover:underline"
        >
          {action.label}
        </Link>
      ) : null}
    </div>
  );
}

function TopicsTab({
  topics,
  failure,
  suggestions,
  canPost,
}: {
  topics: TopicList | null;
  failure: string | null;
  suggestions: RoomSuggestion[];
  canPost: boolean;
}) {
  return (
    <>
      {failure || !topics ? (
        <Notice>Không tải được danh sách phòng. {failure}</Notice>
      ) : topics.following.length === 0 && topics.all.length === 0 ? (
        <EmptyState
          title="Chưa có phòng nào"
          body="Đội ngũ HDDhistory đang chuẩn bị. Ghé lại sau nhé."
        />
      ) : (
        <>
          {topics.following.length > 0 ? (
            <>
              <SectionHeader title="Yêu thích" />
              <ul className="space-y-2">
                {topics.following.map((topic) => (
                  <TopicRow key={topic.id} topic={topic} />
                ))}
              </ul>
            </>
          ) : null}
          {topics.all.length > 0 ? (
            <>
              <SectionHeader title="Khám phá phòng" />
              <ul className="space-y-2">
                {topics.all.map((topic) => (
                  <TopicRow key={topic.id} topic={topic} />
                ))}
              </ul>
            </>
          ) : null}
        </>
      )}
      <RoomSuggestions suggestions={suggestions} canPost={canPost} />
    </>
  );
}
