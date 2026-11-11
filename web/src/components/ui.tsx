'use client';

import { useFormStatus } from 'react-dom';

import { buttonClass, inputClass } from './ui-classes';

export { buttonClass, inputClass } from './ui-classes';

/**
 * Nút gửi form, tự khoá khi form đang chạy.
 *
 * `useFormStatus` phải nằm trong component CON của `<form>` — đặt cùng
 * component chứa form thì nó luôn trả `pending = false`.
 */
export function SubmitButton({
  children,
  pendingLabel,
  variant = 'primary',
  className = '',
  disabled,
}: {
  children: React.ReactNode;
  pendingLabel?: string;
  variant?: keyof typeof buttonClass;
  className?: string;
  disabled?: boolean;
}) {
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      disabled={pending || disabled}
      className={`${buttonClass[variant]} ${className}`}
    >
      {pending ? (pendingLabel ?? 'Đang xử lý…') : children}
    </button>
  );
}

export function Field({
  label,
  name,
  hint,
  ...input
}: {
  label: string;
  name: string;
  hint?: string;
} & React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <div>
      <label htmlFor={name} className="mb-1 block text-sm text-ink-muted">
        {label}
      </label>
      <input id={name} name={name} className={inputClass} {...input} />
      {hint ? <p className="mt-1 text-xs text-ink-faint">{hint}</p> : null}
    </div>
  );
}

/** Dòng báo lỗi/thành công dưới form. */
export function FormMessage({
  error,
  success,
}: {
  error?: string;
  success?: string;
}) {
  if (error) {
    return (
      <p role="alert" className="text-sm font-medium text-red-700">
        {error}
      </p>
    );
  }
  if (success) {
    return (
      <p role="status" className="text-sm font-medium text-emerald-700">
        {success}
      </p>
    );
  }
  return null;
}
