import Link from 'next/link';
import { notFound } from 'next/navigation';

import { MutedBanner } from '@/components/community/author';
import { FeedList } from '@/components/community/feed-list';
import { ComposeLink } from '@/components/community/header';
import { PostCard } from '@/components/community/post-card';
import { TopicFollowButton } from '@/components/community/topic-follow-button';
import { TopicThumb } from '@/components/community/topic-row';
import { Notice } from '@/components/section';
import { describeError } from '@/lib/action-result';
import { ApiError } from '@/lib/api';
import {
  getCommunityFeed,
  getMemberStatus,
  getTopic,
  type FeedSort,
  type MemberStatus,
} from '@/lib/community';

export default async function CommunityTopicPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ 'sap-xep'?: string }>;
}) {
  const [{ id }, query] = await Promise.all([params, searchParams]);
  // Id hỏng làm API ném 500 (CastError) chứ không 404.
  if (!/^[a-f0-9]{24}$/i.test(id)) notFound();
  const sort: FeedSort = query['sap-xep'] === 'soi-noi' ? 'ACTIVE' : 'RECENT';

  const [topic, feed, status] = await Promise.all([
    getTopic(id).catch((error: unknown) => {
      if (error instanceof ApiError && error.status === 404) notFound();
      throw error;
    }),
    getCommunityFeed({ page: 1, take: 10, topicId: id, sort }).catch(
      (error: unknown) => (error instanceof Error ? error : new Error(String(error))),
    ),
    getMemberStatus().catch((): MemberStatus => ({ canPost: true })),
  ]);

  const name = topic.name || 'Phòng';
  const base = `/cong-dong/chu-de/${encodeURIComponent(id)}`;

  return (
    <div className="pt-5">
      <Link
        href="/cong-dong?tab=phong"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Phòng
      </Link>

      <header className="mt-3 rounded-xl border border-hairline bg-surface p-4">
        <div className="flex items-start gap-3">
          <TopicThumb topic={topic} size="lg" />
          <div className="min-w-0 flex-1">
            <h1 className="text-xl font-bold tracking-tight text-brand-900">{name}</h1>
            <p className="mt-0.5 text-xs text-ink-faint">
              {topic.followers ?? 0} thành viên · {topic.discussions ?? 0} lượt thảo luận ·{' '}
              {topic.postsToday ? `${topic.postsToday} hôm nay` : 'Chưa có bài mới hôm nay'}
            </p>
          </div>
          <TopicFollowButton
            topicId={topic.id}
            topicName={name}
            initial={Boolean(topic.isFollowing)}
          />
        </div>
        {topic.description ? (
          <p className="mt-3 text-sm text-ink-muted">{topic.description}</p>
        ) : null}
        <div className="mt-3 flex justify-end">
          <ComposeLink canPost={status.canPost} topicId={topic.id} />
        </div>
      </header>

      {!status.canPost ? (
        <div className="mt-3">
          <MutedBanner reason={status.reason} mutedUntil={status.mutedUntil} />
        </div>
      ) : null}

      <div className="mt-4 mb-3 flex gap-2" aria-label="Sắp xếp">
        {(
          [
            ['RECENT', 'Mới nhất', base],
            ['ACTIVE', 'Sôi nổi', `${base}?sap-xep=soi-noi`],
          ] as const
        ).map(([value, label, href]) => (
          <Link
            key={value}
            href={href}
            aria-current={sort === value ? 'true' : undefined}
            className={`rounded-full px-3 py-1.5 text-xs font-semibold transition ${
              sort === value
                ? 'bg-brand-900 text-brand-50'
                : 'border border-hairline bg-surface text-ink-muted hover:border-brand-200'
            }`}
          >
            {label}
          </Link>
        ))}
      </div>

      {feed instanceof Error ? (
        <Notice>Không tải được bài trong phòng. {describeError(feed)}</Notice>
      ) : feed.pinned.length === 0 && feed.items.length === 0 ? (
        <div className="rounded-xl border border-hairline bg-surface p-6 text-center">
          <p className="font-semibold text-brand-900">Phòng này chưa có bài</p>
          <p className="mt-1 text-sm text-ink-muted">Bài của bạn có thể là bài đầu tiên.</p>
        </div>
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
            key={`${id}|${sort}`}
            initial={feed.items}
            currentPage={feed.currentPage}
            totalPages={feed.totalPages}
            anchorAt={feed.anchorAt}
            query={{ topicId: id, sort }}
          />
        </>
      )}
    </div>
  );
}
