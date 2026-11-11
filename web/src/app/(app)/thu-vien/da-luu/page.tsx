import Link from 'next/link';

import { CourseGrid } from '@/components/course-card';
import { Notice } from '@/components/section';
import { getSavedCoursesByStatus, type SavedCourseStatus } from '@/lib/content';

/** Ba nhóm của app; server tự xếp khoá vào nhóm theo tiến độ hiện tại. */
const FILTERS: { value?: SavedCourseStatus; label: string; empty: string }[] = [
  {
    label: 'Tất cả',
    empty:
      'Chưa lưu gì cả. Chạm “Lưu khoá học” ở khoá học bất kỳ để giữ nó ở đây.',
  },
  {
    value: 'up_next',
    label: 'Sắp học',
    empty:
      'Chưa lưu gì cả. Chạm “Lưu khoá học” ở khoá học bất kỳ để giữ nó ở đây.',
  },
  {
    value: 'in_progress',
    label: 'Đang học',
    empty: 'Chưa có khoá học nào đã lưu đang học dở.',
  },
  {
    value: 'finished',
    label: 'Đã hoàn thành',
    empty: 'Bạn chưa hoàn thành khoá học nào đã lưu.',
  },
];

export default async function SavedCoursesPage({
  searchParams,
}: {
  searchParams: Promise<{ nhom?: string }>;
}) {
  const { nhom } = await searchParams;
  const active = FILTERS.find((f) => f.value === nhom) ?? FILTERS[0];

  const courses = await getSavedCoursesByStatus(active.value, 1, 100).then(
    (page) => page.items,
    () => null,
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
        Đã lưu
      </h1>

      <nav aria-label="Lọc khoá đã lưu" className="mt-4">
        <ul className="flex flex-wrap gap-2">
          {FILTERS.map((filter) => {
            const selected = filter === active;
            return (
              <li key={filter.label}>
                <Link
                  href={
                    filter.value
                      ? `/thu-vien/da-luu?nhom=${filter.value}`
                      : '/thu-vien/da-luu'
                  }
                  aria-current={selected ? 'page' : undefined}
                  className={`inline-block rounded-full px-3 py-1.5 text-sm font-semibold transition ${
                    selected
                      ? 'bg-brand text-white'
                      : 'bg-surface-alt text-ink hover:bg-brand-100'
                  }`}
                >
                  {filter.label}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>

      <div className="mt-5">
        {courses === null ? (
          <Notice>Không tải được danh sách khoá đã lưu.</Notice>
        ) : courses.length === 0 ? (
          <Notice>{active.empty}</Notice>
        ) : (
          <CourseGrid courses={courses} />
        )}
      </div>
    </div>
  );
}
