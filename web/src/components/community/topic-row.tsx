import Link from 'next/link';

import type { CommunityTopic } from '@/lib/community';

import { TopicFollowButton } from './topic-follow-button';

/** Một phòng trong danh sách — chữ đếm theo `community_topic_row` của app. */
export function TopicRow({ topic }: { topic: CommunityTopic }) {
  const name = topic.name || 'Phòng';
  return (
    <li className="flex items-start gap-3 rounded-xl border border-hairline bg-surface p-4">
      <TopicThumb topic={topic} />
      <div className="min-w-0 flex-1">
        <Link
          href={`/cong-dong/chu-de/${encodeURIComponent(topic.id)}`}
          className="font-semibold text-brand-900 hover:underline"
        >
          {name}
        </Link>
        {topic.description ? (
          <p className="mt-0.5 line-clamp-2 text-sm text-ink-muted">{topic.description}</p>
        ) : null}
        <p className="mt-1 text-xs text-ink-faint">
          {topic.followers ?? 0} thành viên · {topic.discussions ?? 0} lượt thảo luận ·{' '}
          {topic.postsToday ? `${topic.postsToday} hôm nay` : 'Chưa có bài mới hôm nay'}
        </p>
      </div>
      <TopicFollowButton
        topicId={topic.id}
        topicName={name}
        initial={Boolean(topic.isFollowing)}
      />
    </li>
  );
}

export function TopicThumb({
  topic,
  size = 'md',
}: {
  topic: { name?: string; imageUrl?: string | null };
  size?: 'md' | 'lg';
}) {
  const box = size === 'lg' ? 'size-14 text-xl' : 'size-10 text-base';
  if (topic.imageUrl) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img src={topic.imageUrl} alt="" className={`${box} shrink-0 rounded-xl object-cover`} />
    );
  }
  return (
    <span
      aria-hidden
      className={`${box} flex shrink-0 items-center justify-center rounded-xl bg-brand-100 font-bold text-brand-900`}
    >
      {(topic.name ?? '?').charAt(0).toUpperCase()}
    </span>
  );
}
