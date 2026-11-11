'use client';

import { useRef, useState, useTransition } from 'react';

import { Avatar } from '@/components/account/avatar';
import { FormMessage } from '@/components/ui';
import { updateAvatar } from '@/lib/actions/account';

/** Cạnh dài nhất sau khi thu nhỏ — cùng số app dùng khi chọn ảnh. */
const MAX_EDGE = 1024;
const JPEG_QUALITY = 0.88;

/**
 * Thu nhỏ ảnh ngay trong trình duyệt trước khi gửi.
 *
 * Server action chỉ nhận tối đa 1MB mỗi request, còn ảnh chụp điện thoại thường
 * vài MB. App cũng thu nhỏ lúc chọn ảnh (1024px, chất lượng 88) vì API tải lên
 * không tự giới hạn cỡ ảnh — ảnh đại diện chưa bao giờ cần to hơn thế.
 */
async function shrink(file: File): Promise<Blob> {
  const bitmap = await createImageBitmap(file);
  const scale = Math.min(1, MAX_EDGE / Math.max(bitmap.width, bitmap.height));
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(bitmap.width * scale);
  canvas.height = Math.round(bitmap.height * scale);
  const context = canvas.getContext('2d');
  if (!context) throw new Error('canvas');
  context.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
  bitmap.close();
  return new Promise((resolve, reject) =>
    canvas.toBlob(
      (blob) => (blob ? resolve(blob) : reject(new Error('toBlob'))),
      'image/jpeg',
      JPEG_QUALITY,
    ),
  );
}

/** Ảnh tự lưu ngay khi chọn, không chờ nút "Lưu" của phần tên — như app. */
export function AvatarEditor({
  avatar,
  name,
}: {
  avatar?: string;
  name?: string;
}) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [error, setError] = useState<string>();
  const [saved, setSaved] = useState(false);
  const [pending, startTransition] = useTransition();

  function onPick(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    // Xoá giá trị để chọn lại đúng tệp đó lần nữa vẫn kích hoạt onChange.
    event.target.value = '';
    if (!file) return;
    setError(undefined);
    setSaved(false);

    startTransition(async () => {
      let blob: Blob;
      try {
        blob = await shrink(file);
      } catch {
        setError('Không đọc được ảnh này. Chọn ảnh khác.');
        return;
      }
      const localUrl = URL.createObjectURL(blob);
      setPreview(localUrl);

      const formData = new FormData();
      formData.append('file', blob, 'avatar.jpg');
      const result = await updateAvatar(formData);
      // Thành công thì `avatar` mới về cùng lượt render lại của action; bỏ ảnh
      // xem trước để hiện đúng ảnh đã lưu trên CDN.
      setPreview(null);
      URL.revokeObjectURL(localUrl);
      if (result.ok) setSaved(true);
      else setError(result.error);
    });
  }

  return (
    <div className="flex flex-col items-center gap-3">
      <div className={pending ? 'opacity-60' : undefined}>
        <Avatar src={preview ?? avatar} name={name} size={96} />
      </div>
      <input
        ref={inputRef}
        id="avatar-file"
        type="file"
        accept="image/*"
        onChange={onPick}
        className="sr-only"
        tabIndex={-1}
        aria-hidden
      />
      <button
        type="button"
        onClick={() => inputRef.current?.click()}
        disabled={pending}
        className="rounded-xl px-3 py-2 text-sm font-semibold text-brand-700 transition hover:bg-brand-100 disabled:opacity-60"
      >
        {pending ? 'Đang tải ảnh lên…' : 'Đổi ảnh đại diện'}
      </button>
      <FormMessage error={error} success={saved ? 'Đã lưu ảnh đại diện.' : undefined} />
    </div>
  );
}
