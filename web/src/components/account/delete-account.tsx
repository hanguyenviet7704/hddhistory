'use client';

import { useActionState, useState } from 'react';

import { FormMessage, SubmitButton, buttonClass } from '@/components/ui';
import { deleteAccount } from '@/lib/actions/account';

/**
 * Xoá tài khoản, hai bước như hộp thoại của app: bấm lần đầu chỉ mở phần cảnh
 * báo; chỉ nút trong phần cảnh báo mới gửi form (kèm `confirm=yes`).
 */
export function DeleteAccount() {
  const [open, setOpen] = useState(false);
  const [state, formAction] = useActionState(deleteAccount, null);

  if (!open) {
    return (
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="rounded-xl px-4 py-2.5 text-sm font-semibold text-red-700 transition hover:bg-red-50"
      >
        Xóa tài khoản
      </button>
    );
  }

  return (
    <section
      aria-labelledby="delete-account-title"
      className="rounded-xl border border-red-200 bg-red-50 p-4"
    >
      <h2 id="delete-account-title" className="font-semibold text-red-800">
        Tất cả dữ liệu của bạn sẽ bị xóa
      </h2>
      <p className="mt-1 text-sm text-red-800">
        Hồ sơ và toàn bộ tiến độ học sẽ mất vĩnh viễn, không khôi phục được. Hãy
        đảm bảo rằng bạn thực sự chắc chắn.
      </p>
      <form action={formAction} className="mt-3 flex flex-wrap gap-2">
        <input type="hidden" name="confirm" value="yes" />
        <SubmitButton variant="danger" pendingLabel="Đang xóa…">
          Tôi chắc chắn muốn xóa
        </SubmitButton>
        <button
          type="button"
          autoFocus
          onClick={() => setOpen(false)}
          className={buttonClass.secondary}
        >
          Giữ lại tài khoản
        </button>
      </form>
      <div className="mt-2">
        <FormMessage error={state?.ok === false ? state.error : undefined} />
      </div>
    </section>
  );
}
