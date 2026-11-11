'use client';

import { useActionState, useState, useTransition } from 'react';

import { buttonClass, FormMessage, SubmitButton } from '@/components/ui';
import { deleteUserLesson, requestMoreContent } from '@/lib/actions/user-lessons';

/**
 * "Bạn có muốn yêu cầu thêm nội dung không?" — chỉ hiện khi đã đọc hết bài
 * (API trả 400 nếu chưa xong). "Không, đủ rồi!" chỉ ẩn bảng, không gửi gì.
 */
export function AdditionalContentPanel({
  lessonId,
  answered,
}: {
  lessonId: string;
  answered: boolean;
}) {
  const [dismissed, setDismissed] = useState(false);
  const [done, setDone] = useState(answered);
  const [error, setError] = useState<string | undefined>();
  const [pending, startTransition] = useTransition();

  if (dismissed) return null;

  return (
    <section className="mt-6 rounded-xl border border-hairline bg-surface p-4">
      <p className="font-semibold text-ink">
        Bạn có muốn yêu cầu thêm nội dung không?
      </p>
      <div className="mt-3 grid grid-cols-2 gap-2">
        <button
          type="button"
          disabled={done || pending}
          onClick={() => setDismissed(true)}
          className={buttonClass.secondary}
        >
          Không, đủ rồi!
        </button>
        <button
          type="button"
          disabled={done || pending}
          aria-pressed={done}
          onClick={() =>
            startTransition(async () => {
              const result = await requestMoreContent(lessonId);
              if (result.ok) setDone(true);
              else setError('Chưa gửi được yêu cầu. Vui lòng thử lại.');
            })
          }
          className={done ? `${buttonClass.secondary} border-brand bg-brand-50` : buttonClass.primary}
        >
          Có, thêm nữa!
        </button>
      </div>
      <div className="mt-2">
        <FormMessage
          error={error}
          success={done ? 'Đã ghi nhận yêu cầu của bạn.' : undefined}
        />
      </div>
    </section>
  );
}

/**
 * Xoá bài — API cho phép, dù app hiện giấu nút này (quyết định sản phẩm
 * 2026-08-12, kệ chỉ đọc). Web giữ lại theo yêu cầu, sau một bước xác nhận vì
 * không khôi phục được.
 */
export function DeleteLessonButton({ lessonId }: { lessonId: string }) {
  const [confirming, setConfirming] = useState(false);
  const [state, formAction] = useActionState(deleteUserLesson, null);

  if (!confirming) {
    return (
      <button
        type="button"
        onClick={() => setConfirming(true)}
        className="text-sm font-semibold text-red-700 hover:underline"
      >
        Xoá bài này
      </button>
    );
  }

  return (
    <form
      action={formAction}
      className="rounded-xl border border-red-200 bg-surface p-4"
      role="alertdialog"
      aria-labelledby="delete-lesson-title"
    >
      <input type="hidden" name="lessonId" value={lessonId} />
      <p id="delete-lesson-title" className="font-semibold text-ink">
        Xoá bài này?
      </p>
      <p className="mt-1 text-sm text-ink-muted">Không khôi phục lại được.</p>
      <div className="mt-3 flex gap-2">
        <SubmitButton variant="danger" pendingLabel="Đang xoá…">
          Xoá
        </SubmitButton>
        <button
          type="button"
          onClick={() => setConfirming(false)}
          className={buttonClass.secondary}
        >
          Huỷ
        </button>
      </div>
      <div className="mt-2">
        <FormMessage error={state?.error} />
      </div>
    </form>
  );
}
