'use client';

import { useState, useTransition } from 'react';

import { buttonClass, FormMessage } from '@/components/ui';
import { loadFeedPage } from '@/lib/actions/community';
import type { CommunityPost, FeedSort } from '@/lib/community';

import { PostCard } from './post-card';

/**
 * Danh sách bài + "Xem thêm".
 *
 * Trang sau tải bằng server action rồi nối vào cuối, không bằng `?page=N`:
 * bảng tin có mốc `anchorAt` do trang 1 đóng dấu, và trang 2 phải gửi lại đúng
 * mốc đó — nếu không, một bài đăng chen vào giữa lúc đọc sẽ đẩy một bài của
 * trang 1 xuống trang 2 và người đọc thấy nó hai lần.
 *
 * Trang cha đặt `key` theo bộ lọc, nên đổi tab/sắp xếp là một danh sách mới.
 */
export function FeedList({
  initial,
  currentPage,
  totalPages,
  anchorAt,
  query,
}: {
  initial: CommunityPost[];
  currentPage: number;
  totalPages: number;
  anchorAt?: string;
  query: { topicId?: string; followedOnly?: boolean; sort?: FeedSort };
}) {
  const [posts, setPosts] = useState(initial);
  const [page, setPage] = useState(currentPage || 1);
  const [pages, setPages] = useState(totalPages || 1);
  const [error, setError] = useState<string>();
  const [pending, startTransition] = useTransition();

  function loadMore() {
    setError(undefined);
    startTransition(async () => {
      const result = await loadFeedPage({ ...query, page: page + 1, anchorAt });
      if (!result.ok) {
        setError(result.error);
        return;
      }
      // Gộp theo id: một bài được ghim hay vừa bị đẩy lên vẫn chỉ hiện một lần.
      setPosts((current) => {
        const seen = new Set(current.map((post) => post.id));
        return [...current, ...result.data.items.filter((post) => !seen.has(post.id))];
      });
      setPage(result.data.currentPage || page + 1);
      setPages(result.data.totalPages || pages);
    });
  }

  return (
    <>
      <ul className="space-y-3">
        {posts.map((post) => (
          <PostCard key={post.id} post={post} />
        ))}
      </ul>
      {page < pages ? (
        <div className="mt-4 flex flex-col items-center gap-2">
          <button
            type="button"
            onClick={loadMore}
            disabled={pending}
            className={buttonClass.secondary}
          >
            {pending ? 'Đang tải…' : 'Xem thêm'}
          </button>
          <FormMessage error={error} />
        </div>
      ) : null}
    </>
  );
}
