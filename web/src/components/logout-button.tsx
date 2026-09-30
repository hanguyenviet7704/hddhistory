import { logout } from '@/lib/auth-actions';

/**
 * Đăng xuất bằng form + server action, không phải onClick: nút vẫn chạy khi
 * JavaScript chưa tải xong, và không cần biến cả trang hồ sơ thành client
 * component chỉ vì một cái nút.
 */
export function LogoutButton() {
  return (
    <form action={logout}>
      <button
        type="submit"
        className="rounded-xl border border-hairline bg-surface px-4 py-2.5 text-sm font-semibold text-ink-muted transition hover:border-brand-200 hover:text-brand-900"
      >
        Đăng xuất
      </button>
    </form>
  );
}
