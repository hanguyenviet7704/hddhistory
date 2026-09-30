'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

/**
 * Thanh điều hướng, cùng bốn tab với app sau khi gỡ tính năng Thói quen:
 * Trang chủ · Khám phá · Thư viện · Cộng đồng. Tra cứu là lối vào thứ năm,
 * nằm ở đầu trang chứ không chiếm một ô tab — giống thẻ trên tab Thư viện
 * của app.
 */
const TABS = [
  { href: '/', label: 'Trang chủ' },
  { href: '/kham-pha', label: 'Khám phá' },
  { href: '/thu-vien', label: 'Thư viện' },
  { href: '/cong-dong', label: 'Cộng đồng' },
] as const;

export function AppNav() {
  const pathname = usePathname();

  return (
    <nav
      aria-label="Điều hướng chính"
      className="sticky bottom-0 z-10 border-t border-brand-100 bg-brand-50/95 backdrop-blur md:static md:border-t-0 md:border-b md:bg-transparent"
    >
      <ul className="mx-auto flex max-w-3xl">
        {TABS.map((tab) => {
          // So sánh chính xác cho "/" vì mọi đường dẫn đều bắt đầu bằng nó.
          const active =
            tab.href === '/'
              ? pathname === '/'
              : pathname.startsWith(tab.href);
          return (
            <li key={tab.href} className="flex-1">
              <Link
                href={tab.href}
                aria-current={active ? 'page' : undefined}
                className={`block px-2 py-3 text-center text-sm font-semibold transition ${
                  active
                    ? 'text-brand-900 md:border-b-2 md:border-brand'
                    : 'text-ink-faint hover:text-brand-700'
                }`}
              >
                {tab.label}
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
