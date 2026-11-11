import Link from 'next/link';

import { MutedBanner } from '@/components/community/author';
import { ComposeForm } from '@/components/community/compose-form';
import {
  getMemberStatus,
  getTopics,
  type MemberStatus,
  type TopicList,
} from '@/lib/community';
import { getSessionUser } from '@/lib/session';

export default async function CommunityComposePage({
  searchParams,
}: {
  searchParams: Promise<{ phong?: string }>;
}) {
  const { phong } = await searchParams;
  const [topics, status, user] = await Promise.all([
    // Phòng là tuỳ chọn: hỏng danh sách thì vẫn đăng được, chỉ không chọn phòng.
    getTopics().catch((): TopicList => ({ following: [], all: [] })),
    getMemberStatus().catch((): MemberStatus => ({ canPost: true })),
    getSessionUser(),
  ]);

  const known = [...topics.following, ...topics.all].some((topic) => topic.id === phong);

  return (
    <div className="pt-5">
      <Link
        href={known ? `/cong-dong/chu-de/${encodeURIComponent(phong!)}` : '/cong-dong'}
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Huỷ
      </Link>
      <h1 className="mt-3 mb-4 text-2xl font-bold tracking-tight text-brand-900">
        Bài viết mới
      </h1>

      {status.canPost ? (
        <ComposeForm
          following={topics.following}
          others={topics.all}
          defaultTopicId={known ? phong : undefined}
          userName={user?.name ?? ''}
        />
      ) : (
        <MutedBanner reason={status.reason} mutedUntil={status.mutedUntil} />
      )}
    </div>
  );
}
