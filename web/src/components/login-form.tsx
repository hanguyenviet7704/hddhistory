'use client';

import Link from 'next/link';
import { useActionState } from 'react';

import { SubmitButton, inputClass } from '@/components/ui';
import { login } from '@/lib/auth-actions';

export function LoginForm({ defaultEmail = '' }: { defaultEmail?: string }) {
  const [state, formAction] = useActionState(login, null);

  return (
    <div>
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
            defaultValue={defaultEmail}
            required
            className={inputClass}
          />
        </div>
        <div>
          <div className="mb-1 flex items-baseline justify-between gap-3">
            <label htmlFor="password" className="block text-sm text-ink-muted">
              Mật khẩu
            </label>
            <Link
              href="/quen-mat-khau"
              className="text-sm font-semibold text-brand-700 hover:underline"
            >
              Quên mật khẩu?
            </Link>
          </div>
          <input
            id="password"
            name="password"
            type="password"
            autoComplete="current-password"
            required
            className={inputClass}
          />
        </div>

        {state?.error ? (
          <p role="alert" className="text-sm font-medium text-red-700">
            {state.error}
          </p>
        ) : null}

        <SubmitButton pendingLabel="Đang đăng nhập…" className="w-full py-3">
          Đăng nhập
        </SubmitButton>
      </form>

      <p className="mt-6 text-center text-sm text-ink-muted">
        Thành viên mới?{' '}
        <Link
          href="/dang-ky"
          className="font-semibold text-brand-700 hover:underline"
        >
          Tạo tài khoản
        </Link>
      </p>
    </div>
  );
}
