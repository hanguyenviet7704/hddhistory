/**
 * Ảnh đại diện, hoặc chữ cái đầu của tên khi chưa có ảnh — giống `_ProfileAvatar`
 * của app. Không có `'use client'` để dùng được ở cả server lẫn client component.
 */
export function Avatar({
  src,
  name,
  size = 64,
}: {
  src?: string | null;
  name?: string;
  size?: number;
}) {
  const initial = (name?.trim()[0] ?? '?').toUpperCase();
  const style = { width: size, height: size };

  if (src) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={src}
        alt=""
        width={size}
        height={size}
        style={style}
        className="shrink-0 rounded-full border border-hairline bg-surface-alt object-cover"
      />
    );
  }
  return (
    <span
      aria-hidden
      style={{ ...style, fontSize: size * 0.4 }}
      className="flex shrink-0 items-center justify-center rounded-full bg-brand-100 font-bold text-brand-900"
    >
      {initial}
    </span>
  );
}
