import Link from 'next/link';

import { CourseGrid } from '@/components/course-card';
import { ClearHistoryButton } from '@/components/learning/clear-history-button';
import { Notice } from '@/components/section';
import { getMyCourses, getRecentlyViewed, type Course } from '@/lib/content';

/**
 * Lịch sử học — `LibraryHistoryRoute` của app: mọi khoá đã bắt đầu, lọc Đang
 * học / Đã hoàn thành (hai cách nhìn trên CÙNG một danh sách). Thêm dải "Xem
 * gần đây" — app để nó trong màn tìm kiếm, web gom về đây cho dễ tìm lại.
 */
export default async function LibraryHistoryPage({
  searchParams,
}: {
  searchParams: Promise<{ loc?: string }>;
}) {
  const { loc } = await searchParams;
  const finished = loc === 'da-xong';

  const [mine, recent] = await Promise.all([
    getMyCourses(1, 100).then(
      (p) => p.items,
      () => null,
    ),
    getRecentlyViewed().catch(() => null),
  ]);

  // Cùng luật với app: xong khi mọi bài đều xong; khoá chưa có bài nào
  // (sắp ra mắt) luôn tính là đang học.
  const isFinished = (c: Course) =>
    (c.numberOfLesson ?? 0) > 0 &&
    (c.numberOfLessonPassed ?? 0) >= (c.numberOfLesson ?? 0);
  const visible = mine?.filter((c) =>
    finished ? isFinished(c) : !isFinished(c),
  );

  return (
    <div className="pt-5">
      <Link
        href="/thu-vien"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Thư viện
      </Link>
      <h1 className="mt-3 text-2xl font-bold tracking-tight text-brand-900">
        Lịch sử học
      </h1>

      <nav aria-label="Lọc lịch sử học" className="mt-4">
        <ul className="flex gap-2">
          {[
            {
              href: '/thu-vien/lich-su',
              label: 'Đang học',
              selected: !finished,
            },
            {
              href: '/thu-vien/lich-su?loc=da-xong',
              label: 'Đã hoàn thành',
              selected: finished,
            },
          ].map((tab) => (
            <li key={tab.href}>
              <Link
                href={tab.href}
                aria-current={tab.selected ? 'page' : undefined}
                className={`inline-block rounded-full px-3 py-1.5 text-sm font-semibold transition ${
                  tab.selected
                    ? 'bg-brand text-white'
                    : 'bg-surface-alt text-ink hover:bg-brand-100'
                }`}
              >
                {tab.label}
              </Link>
            </li>
          ))}
        </ul>
      </nav>

      <div className="mt-5">
        {visible === undefined ? (
          <Notice>Không tải được thư viện của bạn.</Notice>
        ) : visible.length === 0 ? (
          <Notice>
            {finished
              ? 'Bạn chưa hoàn thành khoá học nào.'
              : 'Hiện chưa có khoá học nào đang học.'}
          </Notice>
        ) : (
          <CourseGrid courses={visible} />
        )}
      </div>

      {recent && recent.length > 0 ? (
        <section>
          <div className="mt-7 mb-2 flex items-center justify-between gap-3">
            <h2 className="text-sm font-bold tracking-wide text-brand-900 uppercase">
              Xem gần đây
            </h2>
            <ClearHistoryButton kind="recent" label="Xoá tất cả" />
          </div>
          <CourseGrid courses={recent} />
        </section>
      ) : null}
    </div>
  );
}
