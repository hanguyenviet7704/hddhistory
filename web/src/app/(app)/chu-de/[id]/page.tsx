import Link from 'next/link';

import { CourseGrid } from '@/components/course-card';
import { Notice } from '@/components/section';
import { request, type PageBreak } from '@/lib/api';
import { text, type Course } from '@/lib/content';
import { getCategoryList } from '@/lib/learning';

export default async function CategoryPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  // API không có endpoint lấy một chủ đề theo id, nên tìm trong danh sách —
  // danh sách chỉ vài chục bản ghi nên rẻ hơn là thêm một route mới ở server.
  const [categories, courses] = await Promise.all([
    getCategoryList().then((page) => page.items, () => []),
    // `categoryIds` (số nhiều, kiểu mảng) mới là tham số API nhận — tôi đã
    // thử `categoryId` số ít và nó bị BỎ QUA lặng lẽ, trả về toàn bộ khoá học
    // thay vì báo lỗi. Xem `GetListCourseDto` phía API.
    request<PageBreak<Course>>(
      `/api/v1/courses?categoryIds=${encodeURIComponent(id)}&page=1&take=30&orderBy=createdAt&order=desc`,
    ).then((page) => page.items, () => null),
  ]);

  const category = categories.find((item) => item._id === id);

  return (
    <div className="pt-5">
      <Link
        href="/kham-pha"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Khám phá
      </Link>

      <h1 className="mt-3 text-2xl font-bold tracking-tight text-brand-900">
        {text(category?.title) || 'Chủ đề'}
      </h1>
      {text(category?.description) ? (
        <p className="mt-2 text-ink-muted">{text(category?.description)}</p>
      ) : null}

      <div className="mt-5">
        {courses === null ? (
          <Notice>Không tải được khoá học của chủ đề này.</Notice>
        ) : courses.length === 0 ? (
          <Notice>Chủ đề này chưa có khoá học nào.</Notice>
        ) : (
          <CourseGrid courses={courses} />
        )}
      </div>
    </div>
  );
}
