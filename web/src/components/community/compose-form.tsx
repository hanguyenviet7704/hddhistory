'use client';

import { useActionState, useState, useTransition } from 'react';

import { buttonClass, FormMessage, inputClass, SubmitButton } from '@/components/ui';
import {
  createPost,
  uploadCommunityImage,
  type CreatePostState,
} from '@/lib/actions/community';
import type { CommunityTopic } from '@/lib/community';

import { LIMITS } from './format';

/**
 * Server action mặc định nhận tối đa 1 MB mỗi lần gọi — ảnh điện thoại thường
 * vượt xa. Thu nhỏ ngay trên trình duyệt (cạnh dài 1600px, JPEG) để vừa giới
 * hạn đó mà vẫn đủ nét cho một bài viết.
 */
const MAX_UPLOAD_BYTES = 950 * 1024;
const MAX_EDGE = 1600;

async function shrink(file: File): Promise<File> {
  if (file.size <= MAX_UPLOAD_BYTES && file.type !== 'image/heic') return file;
  const bitmap = await createImageBitmap(file);
  const scale = Math.min(1, MAX_EDGE / Math.max(bitmap.width, bitmap.height));
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(bitmap.width * scale);
  canvas.height = Math.round(bitmap.height * scale);
  canvas.getContext('2d')?.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
  bitmap.close();
  for (const quality of [0.85, 0.7, 0.55]) {
    const blob = await new Promise<Blob | null>((resolve) =>
      canvas.toBlob(resolve, 'image/jpeg', quality),
    );
    if (blob && blob.size <= MAX_UPLOAD_BYTES) {
      const name = file.name.replace(/\.[^.]+$/, '') || 'anh';
      return new File([blob], `${name}.jpg`, { type: 'image/jpeg' });
    }
  }
  throw new Error('Ảnh quá lớn, chọn ảnh khác nhé.');
}

export function ComposeForm({
  following,
  others,
  defaultTopicId,
  userName,
}: {
  following: CommunityTopic[];
  others: CommunityTopic[];
  defaultTopicId?: string;
  userName: string;
}) {
  const [state, formAction] = useActionState<CreatePostState | null, FormData>(
    createPost,
    null,
  );
  const [body, setBody] = useState('');
  const [subject, setSubject] = useState('');
  // Mọi ô đều có kiểm soát: React tự reset form sau mỗi lần action chạy, kể
  // cả khi API từ chối — ô không kiểm soát sẽ mất sạch bài đang viết dở.
  const [topicId, setTopicId] = useState(defaultTopicId ?? '');
  const [anonymous, setAnonymous] = useState(false);
  const [images, setImages] = useState<string[]>([]);
  const [imageError, setImageError] = useState<string>();
  const [uploading, startUpload] = useTransition();

  function onPickImages(event: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(event.target.files ?? []);
    // Xoá giá trị để chọn lại đúng tệp đó vẫn kích hoạt onChange.
    event.target.value = '';
    const room = LIMITS.postImages - images.length;
    if (files.length === 0 || room <= 0) return;
    setImageError(
      files.length > room ? `Mỗi bài tối đa ${LIMITS.postImages} ảnh.` : undefined,
    );
    startUpload(async () => {
      for (const original of files.slice(0, room)) {
        let file: File;
        try {
          file = await shrink(original);
        } catch (error) {
          setImageError((error as Error).message);
          continue;
        }
        const data = new FormData();
        data.append('file', file);
        const result = await uploadCommunityImage(data);
        if (!result.ok) {
          setImageError(result.error);
          continue;
        }
        setImages((current) => [...current, result.data.url]);
      }
    });
  }

  const hasTopics = following.length + others.length > 0;

  return (
    <form action={formAction} className="space-y-4">
      {hasTopics ? (
        <div>
          <label htmlFor="topicId" className="mb-1 block text-sm text-ink-muted">
            Chọn phòng để đăng
          </label>
          <select
            id="topicId"
            name="topicId"
            value={topicId}
            onChange={(event) => setTopicId(event.target.value)}
            className={inputClass}
          >
            <option value="">Không chọn phòng</option>
            {following.length > 0 ? (
              <optgroup label="Phòng bạn đã tham gia">
                {following.map((topic) => (
                  <option key={topic.id} value={topic.id}>
                    {topic.name}
                  </option>
                ))}
              </optgroup>
            ) : null}
            {others.length > 0 ? (
              <optgroup label={following.length > 0 ? 'Phòng khác' : 'Phòng'}>
                {others.map((topic) => (
                  <option key={topic.id} value={topic.id}>
                    {topic.name}
                  </option>
                ))}
              </optgroup>
            ) : null}
          </select>
        </div>
      ) : null}

      <div>
        <label htmlFor="subject" className="mb-1 block text-sm text-ink-muted">
          Tiêu đề (không bắt buộc)
        </label>
        <input
          id="subject"
          name="subject"
          value={subject}
          onChange={(event) => setSubject(event.target.value)}
          maxLength={LIMITS.postSubject}
          placeholder="Tiêu đề bài viết"
          className={inputClass}
        />
      </div>

      <div>
        <label htmlFor="body" className="mb-1 block text-sm text-ink-muted">
          Nội dung
        </label>
        <textarea
          id="body"
          name="body"
          required
          value={body}
          onChange={(event) => setBody(event.target.value)}
          maxLength={LIMITS.postBody}
          rows={8}
          placeholder="Kể chuyện của bạn ở đây…"
          className={`${inputClass} resize-y`}
        />
        <p className="mt-1 text-right text-xs text-ink-faint">
          {body.length}/{LIMITS.postBody}
        </p>
      </div>

      <div>
        <p className="mb-1 text-sm text-ink-muted">Ảnh ({images.length}/{LIMITS.postImages})</p>
        {images.length > 0 ? (
          <ul className="mb-2 grid grid-cols-2 gap-2 sm:grid-cols-4">
            {images.map((url, index) => (
              <li key={url} className="relative overflow-hidden rounded-lg border border-hairline">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={url} alt={`Ảnh ${index + 1}`} className="h-24 w-full object-cover" />
                <input type="hidden" name="images" value={url} />
                <button
                  type="button"
                  onClick={() => setImages((current) => current.filter((item) => item !== url))}
                  aria-label={`Bỏ ảnh ${index + 1}`}
                  className="absolute top-1 right-1 rounded-full bg-ink/70 px-2 py-0.5 text-xs font-bold text-white hover:bg-ink"
                >
                  Bỏ
                </button>
              </li>
            ))}
          </ul>
        ) : null}
        {images.length < LIMITS.postImages ? (
          <label className={`${buttonClass.secondary} cursor-pointer px-3 py-2 text-sm focus-within:ring-2 focus-within:ring-brand/30`}>
            {uploading ? 'Đang tải ảnh…' : 'Thêm ảnh'}
            <input
              type="file"
              accept="image/*"
              multiple
              onChange={onPickImages}
              disabled={uploading}
              className="sr-only"
            />
          </label>
        ) : null}
        <div className="mt-1">
          <FormMessage error={imageError} />
        </div>
      </div>

      <label className="flex items-start gap-3 rounded-xl border border-hairline bg-surface p-3">
        <input
          type="checkbox"
          name="isAnonymous"
          checked={anonymous}
          onChange={(event) => setAnonymous(event.target.checked)}
          className="mt-1 accent-brand"
        />
        <span>
          <span className="block text-sm font-semibold text-ink">Ẩn danh</span>
          <span className="block text-xs text-ink-faint">
            {anonymous
              ? 'Bài này sẽ không hiện tên bạn.'
              : `Đăng với tên ${userName || 'của bạn'}. Mọi người trong phòng sẽ thấy bài của bạn.`}
          </span>
        </span>
      </label>

      <FormMessage error={state?.error} />

      <SubmitButton pendingLabel="Đang đăng…" disabled={uploading || !body.trim()}>
        Đăng
      </SubmitButton>
    </form>
  );
}
