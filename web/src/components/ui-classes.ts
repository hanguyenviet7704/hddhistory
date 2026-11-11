/**
 * Chuỗi class của nút và ô nhập dùng chung. Giữ đúng hình dạng của form đăng
 * nhập để mọi màn hình nhập liệu trên web trông như một bộ.
 *
 * Nằm ở module thường, KHÔNG phải `ui.tsx`: file đó là `'use client'`, nên
 * server component nhập hằng từ đó chỉ nhận được một tham chiếu client chứ
 * không phải chuỗi — đọc `buttonClass.primary` sẽ hỏng lúc dựng trang.
 */
export const buttonClass = {
  primary:
    'inline-flex items-center justify-center gap-2 rounded-xl bg-brand px-4 py-2.5 font-semibold text-white transition hover:bg-brand-700 disabled:cursor-not-allowed disabled:opacity-60',
  secondary:
    'inline-flex items-center justify-center gap-2 rounded-xl border border-brand-200 bg-surface px-4 py-2.5 font-semibold text-brand-900 transition hover:bg-brand-50 disabled:cursor-not-allowed disabled:opacity-60',
  ghost:
    'inline-flex items-center justify-center gap-2 rounded-xl px-3 py-2 text-sm font-semibold text-brand-700 transition hover:bg-brand-100 disabled:cursor-not-allowed disabled:opacity-60',
  danger:
    'inline-flex items-center justify-center gap-2 rounded-xl bg-red-700 px-4 py-2.5 font-semibold text-white transition hover:bg-red-800 disabled:cursor-not-allowed disabled:opacity-60',
} as const;

export const inputClass =
  'w-full rounded-xl border border-hairline bg-surface px-4 py-3 outline-none focus:border-brand focus:ring-2 focus:ring-brand/30';
