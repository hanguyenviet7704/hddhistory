import Link from 'next/link';

/** Tiêu đề một dải nội dung, kèm liên kết "xem tất cả" tuỳ chọn. */
export function SectionHeader({
  title,
  href,
  linkLabel = 'Xem tất cả',
}: {
  title: string;
  href?: string;
  linkLabel?: string;
}) {
  return (
    <div className="mt-7 mb-2 flex items-baseline justify-between gap-3">
      <h2 className="text-sm font-bold tracking-wide text-brand-900 uppercase">
        {title}
      </h2>
      {href ? (
        <Link
          href={href}
          className="shrink-0 text-sm font-semibold text-brand-700 hover:underline"
        >
          {linkLabel}
        </Link>
      ) : null}
    </div>
  );
}

/** Khung thông báo dùng chung cho trạng thái rỗng và trạng thái lỗi. */
export function Notice({ children }: { children: React.ReactNode }) {
  return (
    <p className="rounded-xl border border-hairline bg-surface p-4 text-sm text-ink-muted">
      {children}
    </p>
  );
}
