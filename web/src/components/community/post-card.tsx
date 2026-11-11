'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState, useTransition } from 'react';

import { FormMessage } from '@/components/ui';
import { deletePost, setReaction } from '@/lib/actions/community';
import type { CommunityPost } from '@/lib/community';

import { AuthorLine } from './author';
import { ItemMenu } from './item-menu';

/**
 * Một bài viết — thẻ trên bảng tin hoặc phần đầu trang chi tiết.
 *
 * Tim và chuông đổi NGAY rồi mới gọi API, sai thì trả lại — giống
 * `toggleReaction` của app: một nút phải chờ một vòng mạng mới đổi màu là nút
 * trông như hỏng.
 */
export function PostCard({
  post,
  variant = 'feed',
}: {
  post: CommunityPost;
  variant?: 'feed' | 'detail';
}) {
  const router = useRouter();
  const [liked, setLiked] = useState(Boolean(post.isLiked));
  const [likeCount, setLikeCount] = useState(post.likeCount ?? 0);
  const [following, setFollowing] = useState(Boolean(post.isSaved));
  const [removed, setRemoved] = useState<'hidden' | 'deleted' | null>(null);
  const [error, setError] = useState<string>();
  const [, startTransition] = useTransition();

  const href = `/cong-dong/bai/${encodeURIComponent(post.id)}`;
  const isDetail = variant === 'detail';

  function toggleLike() {
    const next = !liked;
    setLiked(next);
    setLikeCount((count) => Math.max(0, count + (next ? 1 : -1)));
    setError(undefined);
    startTransition(async () => {
      const result = await setReaction({
        targetType: 'POST',
        targetId: post.id,
        kind: 'LIKE',
        active: next,
      });
      if (!result.ok) {
        setLiked(!next);
        setLikeCount((count) => Math.max(0, count + (next ? -1 : 1)));
        setError(result.error);
      }
    });
  }

  function toggleFollow() {
    const next = !following;
    setFollowing(next);
    setError(undefined);
    startTransition(async () => {
      const result = await setReaction({
        targetType: 'POST',
        targetId: post.id,
        kind: 'SAVE',
        active: next,
      });
      if (!result.ok) {
        setFollowing(!next);
        setError(result.error);
      }
    });
  }

  function onDone(what: 'hidden' | 'deleted') {
    // Ở trang chi tiết, bài vừa ẩn/xoá không còn gì để xem: về bảng tin.
    if (isDetail) {
      router.push('/cong-dong');
      return;
    }
    setRemoved(what);
  }

  if (removed) {
    return (
      <li role="status" className="rounded-xl border border-hairline bg-surface-alt p-4 text-sm text-ink-muted">
        {removed === 'hidden'
          ? 'Đã ẩn. Bạn sẽ không thấy nội dung này nữa.'
          : 'Đã xoá bài của bạn'}
      </li>
    );
  }

  const Root = isDetail ? 'article' : 'li';
  const images = post.images ?? [];

  return (
    <Root
      className={`rounded-xl border bg-surface p-4 ${
        post.isPinned ? 'border-brand-200' : 'border-hairline'
      }`}
    >
      <div className="flex items-start justify-between gap-2">
        <AuthorLine
          author={post.author}
          createdAt={post.createdAt}
          extra={
            post.isPinned ? (
              <span className="text-xs font-semibold text-brand-700">· Đã ghim</span>
            ) : null
          }
        />
        <ItemMenu
          targetType="POST"
          targetId={post.id}
          isMine={Boolean(post.isMine) && post.type !== 'WEEKLY_QUESTION'}
          noun="bài viết"
          onDelete={() => deletePost(post.id)}
          onDone={onDone}
        />
      </div>

      {post.topic?.name ? (
        <Link
          href={`/cong-dong/chu-de/${encodeURIComponent(post.topic.id)}`}
          className="mt-2 inline-block rounded-full bg-brand-50 px-2.5 py-0.5 text-xs font-semibold text-brand-700 hover:bg-brand-100"
        >
          {post.topic.name}
        </Link>
      ) : null}

      {isDetail ? (
        <>
          {post.subject ? (
            <h1 className="mt-2 text-xl font-bold tracking-tight text-brand-900">
              {post.subject}
            </h1>
          ) : null}
          {post.body ? (
            <p className="mt-2 leading-relaxed whitespace-pre-line text-ink">
              {post.body}
            </p>
          ) : null}
        </>
      ) : (
        <Link href={href} className="mt-2 block rounded-lg hover:opacity-90">
          {post.subject ? (
            <h2 className="font-semibold text-ink">{post.subject}</h2>
          ) : null}
          {post.body ? (
            <p className="mt-1 line-clamp-4 text-sm whitespace-pre-line text-ink-muted">
              {post.body}
            </p>
          ) : null}
        </Link>
      )}

      {images.length > 0 ? (
        <div
          className={`mt-3 grid gap-2 ${images.length === 1 ? 'grid-cols-1' : 'grid-cols-2'}`}
        >
          {images.map((url, index) => (
            <a
              key={url + index}
              href={url}
              target="_blank"
              rel="noreferrer"
              className="block overflow-hidden rounded-lg border border-hairline"
            >
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={url}
                alt={`Ảnh ${index + 1} của bài viết`}
                className={`w-full object-cover ${isDetail ? 'max-h-96' : 'h-40'}`}
                loading="lazy"
              />
            </a>
          ))}
        </div>
      ) : null}

      {post.attachedCard ? (
        <div className="mt-3 rounded-lg border border-brand-200 bg-brand-50 p-3">
          {post.attachedCard.courseName ? (
            <p className="text-xs font-semibold text-brand-700">
              {post.attachedCard.courseName}
            </p>
          ) : null}
          <p className="font-semibold text-brand-900">{post.attachedCard.title}</p>
          {post.attachedCard.back ? (
            <p className="mt-1 text-sm whitespace-pre-line text-ink-muted">
              {post.attachedCard.back}
            </p>
          ) : null}
        </div>
      ) : null}

      {post.attachedCourseId ? (
        <Link
          href={`/khoa-hoc/${encodeURIComponent(post.attachedCourseId)}`}
          className="mt-3 flex items-center gap-3 rounded-lg border border-brand-200 bg-brand-50 p-3 hover:bg-brand-100"
        >
          <span className="flex-1">
            <span className="block text-sm font-semibold text-brand-900">
              Lộ trình HDDhistory
            </span>
            <span className="block text-xs text-ink-muted">
              Mở khoá học mà bài viết này nhắc tới.
            </span>
          </span>
          <span className="text-sm font-semibold text-brand-700">Xem khoá học →</span>
        </Link>
      ) : null}

      <div className="mt-3 flex flex-wrap items-center gap-1 border-t border-hairline pt-2 text-sm">
        <button
          type="button"
          onClick={toggleLike}
          aria-pressed={liked}
          aria-label={liked ? 'Bỏ thích bài viết' : 'Thích bài viết'}
          className={`inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1.5 font-semibold transition hover:bg-surface-alt ${
            liked ? 'text-red-700' : 'text-ink-muted'
          }`}
        >
          <HeartIcon filled={liked} />
          <span>{likeCount}</span>
        </button>

        {isDetail ? (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1.5 text-ink-muted">
            <CommentIcon />
            {post.commentCount ?? 0} bình luận
          </span>
        ) : (
          <Link
            href={`${href}#binh-luan`}
            className="inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1.5 font-semibold text-ink-muted hover:bg-surface-alt"
          >
            <CommentIcon />
            {post.commentCount ?? 0}
            <span className="sr-only">bình luận</span>
          </Link>
        )}

        <button
          type="button"
          onClick={toggleFollow}
          aria-pressed={following}
          className={`ml-auto inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1.5 text-xs font-semibold transition hover:bg-surface-alt ${
            following ? 'text-brand-700' : 'text-ink-faint'
          }`}
        >
          <BellIcon filled={following} />
          {following ? 'Đang theo dõi' : 'Theo dõi bài này'}
        </button>
      </div>

      {error ? (
        <div className="mt-2">
          <FormMessage error={error} />
        </div>
      ) : null}
    </Root>
  );
}

export function HeartIcon({ filled }: { filled: boolean }) {
  return (
    <svg viewBox="0 0 24 24" className="size-4" aria-hidden fill={filled ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="2">
      <path d="M12 20.5s-7.5-4.6-7.5-10.2A4.3 4.3 0 0 1 12 7.6a4.3 4.3 0 0 1 7.5 2.7c0 5.6-7.5 10.2-7.5 10.2Z" strokeLinejoin="round" />
    </svg>
  );
}

function CommentIcon() {
  return (
    <svg viewBox="0 0 24 24" className="size-4" aria-hidden fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M4 5h16v11H9l-5 4V5Z" strokeLinejoin="round" />
    </svg>
  );
}

function BellIcon({ filled }: { filled: boolean }) {
  return (
    <svg viewBox="0 0 24 24" className="size-4" aria-hidden fill={filled ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="2">
      <path d="M6 16V11a6 6 0 1 1 12 0v5l1.5 2h-15L6 16Z" strokeLinejoin="round" />
      <path d="M10 20a2 2 0 0 0 4 0" />
    </svg>
  );
}
