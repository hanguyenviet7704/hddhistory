'use client';

import { useActionState } from 'react';
import { useFormStatus } from 'react-dom';

import { login } from '@/lib/auth-actions';

function SubmitButton() {
  // useFormStatus phải nằm trong một component CON của <form>, không phải cùng
  // component chứa form — nếu không nó luôn trả pending = false.
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      disabled={pending}
      className="w-full rounded-xl bg-brand py-3 font-semibold text-white transition hover:bg-brand-700 disabled:opacity-60"
    >
      {pending ? 'Đang đăng nhập…' : 'Đăng nhập'}
    </button>
  );
}

export function LoginForm() {
  const [state, formAction] = useActionState(login, null);

  return (
    <form action={formAction} className="space-y-3">
      <div>
        <label htmlFor="email" className="mb-1 block text-sm text-ink-muted">
          Email
        </label>
        <input
          id="email"
          name="email"
          type="email"
          autoComplete="email"
          required
          className="w-full rounded-xl border border-hairline bg-surface px-4 py-3 outline-none focus:border-brand focus:ring-2 focus:ring-brand/30"
        />
      </div>
      <div>
        <label htmlFor="password" className="mb-1 block text-sm text-ink-muted">
          Mật khẩu
        </label>
        <input
          id="password"
          name="password"
          type="password"
          autoComplete="current-password"
          required
          className="w-full rounded-xl border border-hairline bg-surface px-4 py-3 outline-none focus:border-brand focus:ring-2 focus:ring-brand/30"
        />
      </div>

      {state?.error ? (
        <p role="alert" className="text-sm font-medium text-red-700">
          {state.error}
        </p>
      ) : null}

      <SubmitButton />
    </form>
  );
}
