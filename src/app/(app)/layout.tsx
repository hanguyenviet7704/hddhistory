import Image from 'next/image';
import Link from 'next/link';
import { redirect } from 'next/navigation';

import { AppNav } from '@/components/app-nav';
import { ApiError, request } from '@/lib/api';
import { getSessionUser } from '@/lib/session';

interface Me {
  _id?: string;
  name?: string;
  email?: string;
}

export default async function AppLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  // Chặn ở layout chứ không ở proxy/middleware: mọi trang trong nhóm này đều
  // là server component và đều cần người dùng, nên chặn một chỗ là đủ.
  const session = await getSessionUser();
  if (!session) redirect('/dang-nhap');

  // Hỏi API xem token còn dùng được không, MỘT lần cho cả trang.
  //
  // Không thừa: cookie còn không có nghĩa là token còn giá trị — đổi máy chủ
  // API, đăng xuất từ thiết bị khác, hay token hết hạn đều làm mọi lời gọi
  // phía dưới trả 401, và từng trang sẽ hiện "không tải được nội dung" thay
  // vì đưa người dùng về đăng nhập. Đây là chỗ duy nhất biết phân biệt hai
  // chuyện đó.
  let me: Me | null = null;
  try {
    me = await request<Me>('/api/v1/users/me', { revalidate: 0 });
  } catch (error) {
    if (error instanceof ApiError && (error.status === 401 || error.status === 403)) {
      redirect('/dang-xuat');
    }
    // Lỗi mạng hay 5xx thì vẫn dựng khung bằng tên trong cookie: mất API
    // không phải là lý do đá người dùng ra khỏi phiên đăng nhập.
  }

  const name = me?.name || session.name;

  return (
    <div className="flex min-h-dvh flex-col">
      <header className="bg-brand-900">
        <div className="mx-auto flex max-w-3xl items-center gap-3 px-4 py-3">
          <Link href="/" className="flex items-center gap-2.5">
            <Image
              src="/logo-trong-dong.svg"
              alt=""
              width={32}
              height={32}
              priority
            />
            <span className="font-bold tracking-tight text-brand-50">
              HDD<span className="text-brand-300">history</span>
            </span>
          </Link>
          <Link
            href="/ho-so"
            className="ml-auto text-sm font-semibold text-brand-100 hover:text-white"
          >
            {name || 'Hồ sơ'}
          </Link>
        </div>
      </header>

      <AppNav />

      <main className="mx-auto w-full max-w-3xl flex-1 px-4 pb-10">
        {children}
      </main>
    </div>
  );
}
