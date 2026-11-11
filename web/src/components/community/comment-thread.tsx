'use client';

import { useRef, useState, useTransition } from 'react';

import { buttonClass, FormMessage, inputClass } from '@/components/ui';
import {
  addComment,
  deleteComment,
  loadComments,
  setReaction,
} from '@/lib/actions/community';
import type { CommentPage, CommunityComment } from '@/lib/community';

import { AuthorLine } from './author';
import { authorName, LIMITS } from './format';
import { ItemMenu } from './item-menu';
import { HeartIcon } from './post-card';

interface ReplyTarget {
  /** Luôn là id bình luận GỐC — luồng sâu đúng hai tầng. */
  parentId: string;
  userId?: string;
  name: string;
}

/**
 * Luồng bình luận của một bài (hay câu trả lời của câu hỏi tuần).
 *
 * Danh sách giữ ở client: thêm bình luận thì API trả lại trang 1 mới và thay
 * luôn, xoá/ẩn thì gỡ tại chỗ — như `CommunityPostCubit`.
 */
export function CommentThread({
  postId,
  initial,
  canWrite,
  closedReason,
  placeholder = 'Viết bình luận…',
  emptyTitle = 'Chưa có bình luận',
  emptyBody = 'Nói một câu tử tế, hoặc chỉ cần nói bạn cũng từng như vậy.',
}: {
  postId: string;
  initial: CommentPage | null;
  canWrite: boolean;
  /** Vì sao không viết được: bài khoá bình luận, hay người đọc đang bị khoá. */
  closedReason?: string;
  placeholder?: string;
  emptyTitle?: string;
  emptyBody?: string;
}) {
  const [comments, setComments] = useState<CommunityComment[]>(initial?.items ?? []);
  const [page, setPage] = useState(initial?.currentPage || 1);
  const [pages, setPages] = useState(initial?.totalPages || 1);
  const [loadError, setLoadError] = useState<string | undefined>(
    initial ? undefined : 'Không tải được bình luận.',
  );
  const [body, setBody] = useState('');
  const [replyTo, setReplyTo] = useState<ReplyTarget | null>(null);
  const [error, setError] = useState<string>();
  const [sending, startSending] = useTransition();
  const [loading, startLoading] = useTransition();
  const inputRef = useRef<HTMLTextAreaElement>(null);

  function startReply(target: CommunityComment, parent?: CommunityComment) {
    setReplyTo({
      parentId: (parent ?? target).id,
      userId: target.author?.id || undefined,
      name: authorName(target.author),
    });
    inputRef.current?.focus();
  }

  function submit(event: React.FormEvent) {
    event.preventDefault();
    const text = body.trim();
    if (!text) {
      setError('Viết gì đó trước khi gửi nhé.');
      return;
    }
    setError(undefined);
    startSending(async () => {
      const result = await addComment({
        postId,
        body: text,
        parentId: replyTo?.parentId,
        replyToUserId: replyTo?.userId,
      });
      if (!result.ok) {
        setError(result.error);
        return;
      }
      setComments(result.data.items ?? []);
      setPage(result.data.currentPage || 1);
      setPages(result.data.totalPages || 1);
      setBody('');
      setReplyTo(null);
    });
  }

  function loadMore() {
    setLoadError(undefined);
    startLoading(async () => {
      const result = await loadComments(postId, page + 1);
      if (!result.ok) {
        setLoadError(result.error);
        return;
      }
      setComments((current) => {
        const seen = new Set(current.map((c) => c.id));
        return [...current, ...result.data.items.filter((c) => !seen.has(c.id))];
      });
      setPage(result.data.currentPage || page + 1);
      setPages(result.data.totalPages || pages);
    });
  }

  function remove(id: string) {
    setComments((current) =>
      current
        .filter((comment) => comment.id !== id)
        .map((comment) => ({
          ...comment,
          replies: comment.replies?.filter((reply) => reply.id !== id),
        })),
    );
  }

  return (
    <section id="binh-luan" aria-label="Bình luận" className="mt-6">
      {canWrite ? (
        <form onSubmit={submit} className="rounded-xl border border-hairline bg-surface p-3">
          {replyTo ? (
            <p className="mb-2 flex items-center gap-2 text-xs text-ink-muted">
              <span>
                Đang trả lời <strong className="text-brand-900">{replyTo.name}</strong>
              </span>
              <button
                type="button"
                onClick={() => setReplyTo(null)}
                className="font-semibold text-brand-700 hover:underline"
              >
                Huỷ
              </button>
            </p>
          ) : null}
          <label htmlFor={`comment-${postId}`} className="sr-only">
            {replyTo ? 'Viết trả lời' : placeholder}
          </label>
          <textarea
            id={`comment-${postId}`}
            ref={inputRef}
            value={body}
            onChange={(event) => setBody(event.target.value)}
            placeholder={replyTo ? 'Viết trả lời…' : placeholder}
            maxLength={LIMITS.comment}
            rows={3}
            className={`${inputClass} resize-y`}
          />
          <div className="mt-2 flex items-center gap-3">
            <span className="text-xs text-ink-faint">
              {body.length}/{LIMITS.comment}
            </span>
            <div className="ml-auto">
              <button
                type="submit"
                disabled={sending || !body.trim()}
                className={`${buttonClass.primary} px-4 py-2 text-sm`}
              >
                {sending ? 'Đang gửi…' : 'Gửi'}
              </button>
            </div>
          </div>
          <FormMessage error={error} />
        </form>
      ) : closedReason ? (
        <p className="rounded-xl border border-hairline bg-surface-alt p-3 text-sm text-ink-muted">
          {closedReason}
        </p>
      ) : null}

      {comments.length === 0 && !loadError ? (
        <div className="mt-4 rounded-xl border border-hairline bg-surface p-6 text-center">
          <p className="font-semibold text-brand-900">{emptyTitle}</p>
          <p className="mt-1 text-sm text-ink-muted">{emptyBody}</p>
        </div>
      ) : (
        <ul className="mt-4 space-y-3">
          {comments.map((comment) => (
            <li key={comment.id} className="rounded-xl border border-hairline bg-surface p-3">
              <CommentItem
                comment={comment}
                canReply={canWrite}
                onReply={() => startReply(comment)}
                onRemoved={() => remove(comment.id)}
              />
              {comment.replies && comment.replies.length > 0 ? (
                <ul className="mt-3 space-y-3 border-l-2 border-brand-100 pl-3">
                  {comment.replies.map((reply) => (
                    <li key={reply.id}>
                      <CommentItem
                        comment={reply}
                        canReply={canWrite}
                        onReply={() => startReply(reply, comment)}
                        onRemoved={() => remove(reply.id)}
                      />
                    </li>
                  ))}
                </ul>
              ) : null}
            </li>
          ))}
        </ul>
      )}

      {page < pages ? (
        <div className="mt-3 text-center">
          <button
            type="button"
            onClick={loadMore}
            disabled={loading}
            className={buttonClass.secondary}
          >
            {loading ? 'Đang tải…' : 'Xem thêm bình luận'}
          </button>
        </div>
      ) : null}
      <div className="mt-2">
        <FormMessage error={loadError} />
      </div>
    </section>
  );
}

function CommentItem({
  comment,
  canReply,
  onReply,
  onRemoved,
}: {
  comment: CommunityComment;
  canReply: boolean;
  onReply: () => void;
  onRemoved: () => void;
}) {
  const [liked, setLiked] = useState(Boolean(comment.isLiked));
  const [count, setCount] = useState(comment.likeCount ?? 0);
  const [error, setError] = useState<string>();
  const [, startTransition] = useTransition();

  function toggleLike() {
    const next = !liked;
    setLiked(next);
    setCount((value) => Math.max(0, value + (next ? 1 : -1)));
    setError(undefined);
    startTransition(async () => {
      const result = await setReaction({
        targetType: 'COMMENT',
        targetId: comment.id,
        kind: 'LIKE',
        active: next,
      });
      if (!result.ok) {
        setLiked(!next);
        setCount((value) => Math.max(0, value + (next ? -1 : 1)));
        setError(result.error);
      }
    });
  }

  return (
    <div>
      <div className="flex items-start justify-between gap-2">
        <AuthorLine author={comment.author} createdAt={comment.createdAt} size="sm" />
        <ItemMenu
          targetType="COMMENT"
          targetId={comment.id}
          isMine={Boolean(comment.isMine)}
          noun="bình luận"
          onDelete={() => deleteComment(comment.id)}
          onDone={onRemoved}
        />
      </div>
      <p className="mt-1.5 text-sm whitespace-pre-line text-ink">
        {comment.replyToName ? (
          <span className="font-semibold text-brand-700">@{comment.replyToName} </span>
        ) : null}
        {comment.body}
      </p>
      <div className="mt-1 flex items-center gap-1 text-xs">
        <button
          type="button"
          onClick={toggleLike}
          aria-pressed={liked}
          aria-label={liked ? 'Bỏ thích bình luận' : 'Thích bình luận'}
          className={`inline-flex items-center gap-1 rounded-lg px-2 py-1 font-semibold hover:bg-surface-alt ${
            liked ? 'text-red-700' : 'text-ink-faint'
          }`}
        >
          <HeartIcon filled={liked} />
          {count}
        </button>
        {canReply ? (
          <button
            type="button"
            onClick={onReply}
            className="rounded-lg px-2 py-1 font-semibold text-ink-faint hover:bg-surface-alt hover:text-brand-700"
          >
            Trả lời
          </button>
        ) : null}
      </div>
      <FormMessage error={error} />
    </div>
  );
}
