import Link from 'next/link';

import { CourseGrid } from '@/components/course-card';
import { Notice } from '@/components/section';
import { request, type PageBreak } from '@/lib/api';
import { text, type Course } from '@/lib/content';
import { getSkillsetList } from '@/lib/learning';

export default async function SkillsetPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  // API không có endpoint lấy một kỹ năng theo id, nên tìm trong danh sách —
  // danh sách chỉ vài chục bản ghi nên rẻ hơn là thêm một route mới ở server.
  const [skillsets, courses] = await Promise.all([
    getSkillsetList().then((page) => page.items, () => []),
    // `skillsetIds` (số nhiều, kiểu mảng) mới là tham số API nhận — tôi đã
    // thử `skillsetId` số ít và nó bị BỎ QUA lặng lẽ, trả về toàn bộ khoá học
    // thay vì báo lỗi. Xem `GetListCourseDto` phía API.
    request<PageBreak<Course>>(
      `/api/v1/courses?skillsetIds=${encodeURIComponent(id)}&page=1&take=30&orderBy=createdAt&order=desc`,
    ).then((page) => page.items, () => null),
  ]);

  const skillset = skillsets.find((item) => item._id === id);

  return (
    <div className="pt-5">
      <Link
        href="/kham-pha"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Khám phá
      </Link>

      <h1 className="mt-3 text-2xl font-bold tracking-tight text-brand-900">
        {text(skillset?.title) || 'Kỹ năng'}
      </h1>
      {text(skillset?.description) ? (
        <p className="mt-2 text-ink-muted">{text(skillset?.description)}</p>
      ) : null}

      <div className="mt-5">
        {courses === null ? (
          <Notice>Không tải được khoá học của kỹ năng này.</Notice>
        ) : courses.length === 0 ? (
          <Notice>Kỹ năng này chưa có khoá học nào.</Notice>
        ) : (
          <CourseGrid courses={courses} />
        )}
      </div>
    </div>
  );
}
