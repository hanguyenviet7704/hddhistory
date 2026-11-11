/**
 * Kiểu nút cho `<a>`/`<Link>` trong server component.
 *
 * Không nhập `buttonClass` từ `ui.tsx` được: file đó là `'use client'`, và ở
 * phía máy chủ mọi export của nó chỉ là tham chiếu client — chấm vào
 * `buttonClass.secondary` là lỗi lúc dựng trang. Giữ đúng chuỗi của `ui.tsx`.
 */
export const linkButton = {
  primary:
    'inline-flex items-center justify-center gap-2 rounded-xl bg-brand px-4 py-2.5 font-semibold text-white transition hover:bg-brand-700',
  secondary:
    'inline-flex items-center justify-center gap-2 rounded-xl border border-brand-200 bg-surface px-4 py-2.5 font-semibold text-brand-900 transition hover:bg-brand-50',
  ghost:
    'inline-flex items-center justify-center gap-2 rounded-xl px-3 py-2 text-sm font-semibold text-brand-700 transition hover:bg-brand-100',
} as const;

/** Thẻ dạng hàng có mũi tên, dùng cho danh sách mục ở hồ sơ/tiến độ. */
export const rowCard =
  'flex items-center gap-3 rounded-xl border border-hairline bg-surface p-4 transition hover:border-brand-200';
