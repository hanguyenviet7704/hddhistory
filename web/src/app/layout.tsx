import type { Metadata } from 'next';
import localFont from 'next/font/local';

import './globals.css';

// Phông lấy từ chính app (assets/fonts/Poppins). Nạp cục bộ thay vì qua
// next/font/google: trang phải dựng được cả khi máy không ra mạng, và bản cục
// bộ chắc chắn khớp với bản app đang dùng.
const poppins = localFont({
  src: [
    { path: './fonts/Poppins-Regular.ttf', weight: '400', style: 'normal' },
    { path: './fonts/Poppins-SemiBold.ttf', weight: '600', style: 'normal' },
    { path: './fonts/Poppins-Bold.ttf', weight: '700', style: 'normal' },
  ],
  variable: '--font-poppins',
  display: 'swap',
});

export const metadata: Metadata = {
  title: 'HDDhistory — Học lịch sử Việt Nam',
  description:
    'Học lịch sử Việt Nam theo đồ thị tri thức: khoá học, bài học, và tra cứu nhân vật, sự kiện, triều đại.',
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="vi" className={poppins.variable}>
      <body className="min-h-dvh font-sans antialiased">{children}</body>
    </html>
  );
}
