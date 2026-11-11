'use client';

import { useActionState, useState } from 'react';

import { FormMessage, inputClass, SubmitButton } from '@/components/ui';
import { startImport } from '@/lib/actions/learning-import';

import { MAX_PDF_MB } from './import-copy';

type Source = 'youtube' | 'pdf';

/**
 * Form tạo bài: hai nguồn, một nút — bố cục màn "Tự tạo bài học của bạn".
 *
 * Gửi thẳng qua server action (kể cả tệp PDF): trình duyệt không bao giờ gọi
 * API, nên tệp đi trình duyệt → máy chủ Next → R2 qua `/cloudflares/upload`.
 */
export function ImportForm({ disabled }: { disabled: boolean }) {
  const [state, formAction] = useActionState(startImport, null);
  const [source, setSource] = useState<Source>('youtube');
  const [url, setUrl] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [localError, setLocalError] = useState<string | null>(null);

  // React đặt lại ô <input type="file"> (không điều khiển) sau mỗi lần action
  // chạy xong; nếu vẫn giữ `file` cũ thì nút bật mà ô thì trống. Xoá theo, ngay
  // trong lúc render khi thấy kết quả mới — không cần effect.
  const [seenState, setSeenState] = useState(state);
  if (seenState !== state) {
    setSeenState(state);
    setFile(null);
  }

  const tooLarge = file !== null && file.size > MAX_PDF_MB * 1024 * 1024;
  const ready = source === 'youtube' ? url.trim().length > 0 : file !== null && !tooLarge;
  const error = localError ?? state?.error;

  return (
    <form action={formAction} className="mt-5 space-y-4">
      <input type="hidden" name="source" value={source} />

      <div role="radiogroup" aria-label="Nguồn tài liệu" className="grid grid-cols-2 gap-2">
        {(
          [
            ['youtube', 'YouTube', 'Bài giảng hoặc hướng dẫn có phụ đề'],
            ['pdf', 'PDF', 'Giáo trình, bài báo, ghi chép bài giảng'],
          ] as const
        ).map(([value, label, hint]) => {
          const selected = source === value;
          return (
            <button
              key={value}
              type="button"
              role="radio"
              aria-checked={selected}
              onClick={() => {
                setSource(value);
                setLocalError(null);
              }}
              className={`rounded-xl border p-3 text-left transition focus:outline-none focus-visible:ring-2 focus-visible:ring-brand/40 ${
                selected
                  ? 'border-brand bg-brand-50'
                  : 'border-hairline bg-surface hover:bg-brand-50'
              }`}
            >
              <span className="block font-semibold text-brand-900">{label}</span>
              <span className="mt-0.5 block text-xs text-ink-muted">{hint}</span>
            </button>
          );
        })}
      </div>

      {source === 'youtube' ? (
        <div>
          <label htmlFor="import-url" className="mb-1 block text-sm text-ink-muted">
            Dán link YouTube
          </label>
          <input
            id="import-url"
            name="url"
            type="url"
            inputMode="url"
            autoComplete="off"
            placeholder="https://youtube.com/watch?v=..."
            value={url}
            onChange={(event) => {
              setUrl(event.target.value);
              setLocalError(null);
            }}
            aria-invalid={state?.field === 'url' || undefined}
            className={inputClass}
          />
          <p className="mt-1 text-xs text-ink-faint">
            Video dài từ 10 phút đến 3 tiếng và có phụ đề.
          </p>
        </div>
      ) : (
        <div>
          <label htmlFor="import-file" className="mb-1 block text-sm text-ink-muted">
            Chọn một file PDF
          </label>
          <input
            id="import-file"
            name="file"
            type="file"
            accept="application/pdf,.pdf"
            onChange={(event) => {
              const picked = event.target.files?.[0] ?? null;
              setFile(picked);
              setLocalError(
                picked && picked.size > MAX_PDF_MB * 1024 * 1024
                  ? 'Tài liệu quá lớn. Thử tài liệu dưới 300 trang.'
                  : null,
              );
            }}
            aria-invalid={state?.field === 'file' || tooLarge || undefined}
            className="block w-full rounded-xl border border-dashed border-brand-200 bg-surface p-4 text-sm text-ink-muted file:mr-3 file:rounded-lg file:border-0 file:bg-brand-100 file:px-3 file:py-1.5 file:font-semibold file:text-brand-900"
          />
          <p className="mt-1 text-xs text-ink-faint">
            {file
              ? `${file.name} · ${(file.size / (1024 * 1024)).toFixed(1)} MB`
              : `Tối đa ${MAX_PDF_MB} MB`}
          </p>
        </div>
      )}

      <FormMessage error={error ?? undefined} />

      <SubmitButton
        disabled={disabled || !ready}
        pendingLabel={source === 'pdf' ? 'Đang tải tệp lên…' : 'Đang tạo…'}
        className="w-full"
      >
        Tạo bài học
      </SubmitButton>
    </form>
  );
}
