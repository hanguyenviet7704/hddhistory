import { redirect } from 'next/navigation';

import { AuthShell } from '@/components/account/auth-shell';
import { LoginForm } from '@/components/login-form';
import { getSessionUser } from '@/lib/session';

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ email?: string | string[] }>;
}) {
  // Đã đăng nhập thì không có lý do gì đứng ở đây.
  if (await getSessionUser()) redirect('/');
  // Đăng ký tạo được tài khoản nhưng hụt bước đăng nhập thì quay về đây với
  // email điền sẵn.
  const { email } = await searchParams;

  return (
    <AuthShell>
      <LoginForm defaultEmail={typeof email === 'string' ? email : ''} />
    </AuthShell>
  );
}
