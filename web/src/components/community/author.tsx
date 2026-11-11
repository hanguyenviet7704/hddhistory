/**
 * Ảnh đại diện + tên tác giả + thời gian — đầu mỗi bài, bình luận, tin nhắn.
 *
 * Không dùng hook nên dùng được ở cả server component lẫn client component.
 */
import type { CommunityAuthor } from '@/lib/community';

import { authorInitial, authorName, relativeTime } from './format';

export function Avatar({
  author,
  size = 'md',
}: {
  author: CommunityAuthor | null | undefined;
  size?: 'sm' | 'md';
}) {
  const box = size === 'sm' ? 'size-7 text-xs' : 'size-9 text-sm';
  const official = author?.authorType === 'OFFICIAL';
  if (author?.avatar && author.authorType !== 'ANONYMOUS') {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={author.avatar}
        alt=""
        className={`${box} shrink-0 rounded-full object-cover`}
      />
    );
  }
  return (
    <span
      aria-hidden
      className={`${box} flex shrink-0 items-center justify-center rounded-full font-bold ${
        official ? 'bg-brand-900 text-brand-100' : 'bg-brand-100 text-brand-900'
      }`}
    >
      {official ? 'H' : authorInitial(author)}
    </span>
  );
}

export function OfficialBadge() {
  return (
    <span className="rounded-full bg-brand-900 px-1.5 py-0.5 text-[10px] font-bold tracking-wide text-brand-100 uppercase">
      Đội ngũ
    </span>
  );
}

export function AuthorLine({
  author,
  createdAt,
  extra,
  size = 'md',
}: {
  author: CommunityAuthor | null | undefined;
  createdAt?: string;
  extra?: React.ReactNode;
  size?: 'sm' | 'md';
}) {
  return (
    <div className="flex min-w-0 items-center gap-2.5">
      <Avatar author={author} size={size} />
      <div className="min-w-0">
        <p className="flex flex-wrap items-center gap-1.5 text-sm font-semibold text-brand-900">
          <span className="truncate">{authorName(author)}</span>
          {author?.authorType === 'OFFICIAL' ? <OfficialBadge /> : null}
          {extra}
        </p>
        {createdAt ? (
          <time
            dateTime={createdAt}
            // Thời gian tương đối tính theo đồng hồ lúc vẽ; máy chủ và trình
            // duyệt lệch nhau vài giây là đủ đổi "Vừa xong" thành "1 phút trước".
            suppressHydrationWarning
            className="block text-xs text-ink-faint"
          >
            {relativeTime(createdAt)}
          </time>
        ) : null}
      </div>
    </div>
  );
}

/** Lý do không đăng được — hiện thay cho nút viết, như `CommunityMutedBanner`. */
export function MutedBanner({
  reason,
  mutedUntil,
}: {
  reason?: string | null;
  mutedUntil?: string | null;
}) {
  const until = mutedUntil
    ? new Date(mutedUntil).toLocaleDateString('vi-VN', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        timeZone: 'Asia/Ho_Chi_Minh',
      })
    : null;
  return (
    <div
      role="status"
      className="rounded-xl border border-red-200 bg-red-50 p-4 text-sm"
    >
      <p className="font-bold text-ink">Hiện bạn chưa thể đăng bài</p>
      <p className="mt-1 text-ink-muted">
        {reason?.trim() ||
          'Quyền đăng của bạn đang tạm khoá do vi phạm nội quy cộng đồng.'}
      </p>
      {until ? (
        <p className="mt-1 font-bold text-red-700">Đến {until}</p>
      ) : null}
    </div>
  );
}
