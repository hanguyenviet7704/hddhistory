import Image from 'next/image';
import { redirect } from 'next/navigation';

import { LoginForm } from '@/components/login-form';
import { getSessionUser } from '@/lib/session';

export default async function LoginPage() {
  // Đã đăng nhập thì không có lý do gì đứng ở đây.
  if (await getSessionUser()) redirect('/');

  return (
    <div className="mx-auto flex min-h-dvh max-w-sm flex-col justify-center px-5">
      <div className="mb-8 flex flex-col items-center text-center">
        <Image
          src="/logo-trong-dong.svg"
          alt=""
          width={88}
          height={88}
          priority
        />
        <h1 className="mt-4 text-2xl font-bold tracking-tight text-brand-900">
          HDD<span className="text-brand">history</span>
        </h1>
        <p className="mt-1 text-sm text-ink-muted">
          Học lịch sử Việt Nam theo đồ thị tri thức
        </p>
      </div>

      <LoginForm />
    </div>
  );
}
