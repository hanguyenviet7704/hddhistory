'use client';

import { useState, useTransition } from 'react';

import { setTopicFollow } from '@/lib/actions/community';

/**
 * "+ Theo dõi" / "Đang theo dõi" của một phòng — đổi ngay, sai thì trả lại,
 * như `toggleTopicFollow` của app.
 */
export function TopicFollowButton({
  topicId,
  topicName,
  initial,
}: {
  topicId: string;
  topicName: string;
  initial: boolean;
}) {
  const [following, setFollowing] = useState(initial);
  const [error, setError] = useState<string>();
  const [pending, startTransition] = useTransition();

  function toggle() {
    const next = !following;
    setFollowing(next);
    setError(undefined);
    startTransition(async () => {
      const result = await setTopicFollow(topicId, next);
      if (!result.ok) {
        setFollowing(!next);
        setError(result.error);
      }
    });
  }

  return (
    <span className="inline-flex flex-col items-end gap-1">
      <button
        type="button"
        onClick={toggle}
        disabled={pending}
        aria-pressed={following}
        aria-label={`${following ? 'Bỏ theo dõi' : 'Theo dõi'} phòng ${topicName}`}
        className={`shrink-0 rounded-full px-3 py-1.5 text-xs font-bold transition disabled:opacity-70 ${
          following
            ? 'border border-brand-200 bg-surface text-brand-700 hover:bg-brand-50'
            : 'bg-brand text-white hover:bg-brand-700'
        }`}
      >
        {following ? 'Đang theo dõi' : '+ Theo dõi'}
      </button>
      {error ? (
        <span role="alert" className="text-xs text-red-700">
          {error}
        </span>
      ) : null}
    </span>
  );
}
