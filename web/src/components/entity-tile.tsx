import Link from 'next/link';

import { TYPE_COLORS, TYPE_LABELS, type KgEntityType } from '@/lib/kg';

/**
 * Chấm tròn màu theo loại thực thể.
 *
 * App dùng icon Material cho việc này; web không kéo cả bộ icon về chỉ vì bốn
 * hình, nên dùng chấm màu — vẫn phân biệt được bốn loại mà không thêm phụ thuộc.
 * Màu KHÔNG đứng một mình: nhãn loại luôn hiện cạnh nó, nên người không phân
 * biệt được màu vẫn đọc ra.
 */
export function TypeDot({ type }: { type: KgEntityType }) {
  return (
    <span
      aria-hidden
      className="mt-1.5 inline-block size-2.5 shrink-0 rounded-full"
      style={{ backgroundColor: TYPE_COLORS[type] }}
    />
  );
}

export function TypeBadge({ type }: { type: KgEntityType }) {
  return (
    <span
      className="rounded-full px-2 py-0.5 text-xs font-semibold"
      style={{
        color: TYPE_COLORS[type],
        backgroundColor: `${TYPE_COLORS[type]}1f`,
      }}
    >
      {TYPE_LABELS[type]}
    </span>
  );
}

export function EntityTile({
  id,
  type,
  name,
  description,
  trailing,
}: {
  id: string;
  type: KgEntityType;
  name: string;
  description?: string;
  trailing?: React.ReactNode;
}) {
  return (
    <li>
      <Link
        href={`/thuc-the/${encodeURIComponent(id)}`}
        className="flex gap-3 rounded-xl px-3 py-3 transition hover:bg-brand-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand"
      >
        <TypeDot type={type} />
        <span className="min-w-0 flex-1">
          <span className="flex flex-wrap items-baseline gap-x-2">
            <span className="font-semibold text-ink">{name}</span>
            <span className="text-xs text-ink-faint">{TYPE_LABELS[type]}</span>
          </span>
          {description ? (
            <span className="mt-0.5 block text-sm text-ink-muted">
              {description}
            </span>
          ) : null}
        </span>
        {trailing}
      </Link>
    </li>
  );
}
