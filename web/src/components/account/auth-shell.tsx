import Image from 'next/image';

/**
 * Khung chung của các trang ngoài phiên đăng nhập (đăng nhập, đăng ký, quên mật
 * khẩu): logo + tên ở trên, nội dung ở giữa, rộng vừa một cột trên điện thoại.
 */
export function AuthShell({
  subtitle = 'Học lịch sử Việt Nam theo đồ thị tri thức',
  children,
}: {
  subtitle?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="mx-auto flex min-h-dvh max-w-sm flex-col justify-center px-5 py-10">
      <div className="mb-8 flex flex-col items-center text-center">
        <Image src="/logo-trong-dong.svg" alt="" width={88} height={88} priority />
        <h1 className="mt-4 text-2xl font-bold tracking-tight text-brand-900">
          HDD<span className="text-brand">history</span>
        </h1>
        <p className="mt-1 text-sm text-ink-muted">{subtitle}</p>
      </div>
      {children}
    </div>
  );
}
