import { Notice, SectionHeader } from '@/components/section';
import { ApiError } from '@/lib/api';
import {
  getCommunityFeed,
  type CommunityFeed,
  type CommunityPost,
} from '@/lib/progress';

export default async function CommunityPage() {
  let feed: CommunityFeed | null = null;
  let failure: string | null = null;
  try {
    feed = await getCommunityFeed();
  } catch (error) {
    failure = error instanceof ApiError ? error.message : String(error);
  }

  const pinned = feed?.pinned ?? [];
  const items = feed?.items ?? [];

  return (
    <div className="pt-5">
      <h1 className="mb-4 text-2xl font-bold tracking-tight text-brand-900">
        Cộng đồng
      </h1>

      {feed?.weekly ? (
        <div className="rounded-xl border border-brand-200 bg-brand-100/50 p-4">
          <p className="text-xs font-bold tracking-wide text-brand-700 uppercase">
            Câu hỏi tuần này
          </p>
          <p className="mt-1 font-semibold text-brand-900">
            {feed.weekly.title}
          </p>
          {feed.weekly.note ? (
            <p className="mt-1 text-sm text-ink-muted">{feed.weekly.note}</p>
          ) : null}
        </div>
      ) : null}

      {failure ? (
        <Notice>Không tải được bảng tin. {failure}</Notice>
      ) : pinned.length === 0 && items.length === 0 ? (
        <Notice>Chưa có bài viết nào.</Notice>
      ) : (
        <>
          {pinned.length > 0 ? (
            <>
              <SectionHeader title="Ghim" />
              <ul className="space-y-3">
                {pinned.map((post) => (
                  <PostCard key={post.id} post={post} />
                ))}
              </ul>
            </>
          ) : null}
          {items.length > 0 ? (
            <>
              <SectionHeader title="Mới nhất" />
              <ul className="space-y-3">
                {items.map((post) => (
                  <PostCard key={post.id} post={post} />
                ))}
              </ul>
            </>
          ) : null}
        </>
      )}
    </div>
  );
}

function PostCard({ post }: { post: CommunityPost }) {
  return (
    <li className="rounded-xl border border-hairline bg-surface p-4">
      <p className="text-sm font-semibold text-brand-900">
        {post.author?.name || 'Ẩn danh'}
        {post.topic?.name ? (
          <span className="ml-2 rounded-full bg-brand-50 px-2 py-0.5 text-xs font-medium text-brand-700">
            {post.topic.name}
          </span>
        ) : null}
      </p>
      {post.subject ? (
        <h2 className="mt-1 font-semibold text-ink">{post.subject}</h2>
      ) : null}
      {post.body ? (
        <p className="mt-1 whitespace-pre-line text-sm text-ink-muted">
          {post.body}
        </p>
      ) : null}
      <p className="mt-2 text-xs text-ink-faint">
        {post.likeCount ?? 0} thích · {post.commentCount ?? 0} bình luận
      </p>
    </li>
  );
}
