'use client';

import { useActionState } from 'react';

import { Field, FormMessage, SubmitButton } from '@/components/ui';
import { updateName } from '@/lib/actions/account';

export function NameForm({ name, email }: { name: string; email: string }) {
  const [state, formAction] = useActionState(updateName, null);
  // Sau khi lưu, React đặt lại form về defaultValue — nên defaultValue phải là
  // tên vừa lưu, không phải tên lúc mở trang.
  const current = state?.ok ? state.data : name;

  return (
    <form action={formAction} className="space-y-3">
      <Field
        label="Họ tên"
        name="name"
        autoComplete="name"
        defaultValue={current}
        maxLength={80}
        required
      />
      <div>
        <label htmlFor="email" className="mb-1 block text-sm text-ink-muted">
          Email
        </label>
        <input
          id="email"
          value={email}
          readOnly
          className="w-full rounded-xl border border-hairline bg-surface-alt px-4 py-3 text-ink-muted outline-none"
        />
        <p className="mt-1 text-xs text-ink-faint">Email không đổi được.</p>
      </div>
      <FormMessage
        error={state?.ok === false ? state.error : undefined}
        success={state?.ok ? 'Đã lưu.' : undefined}
      />
      <SubmitButton pendingLabel="Đang lưu…">Lưu</SubmitButton>
    </form>
  );
}
