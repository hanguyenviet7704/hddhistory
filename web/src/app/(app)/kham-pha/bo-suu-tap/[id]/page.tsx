import Link from 'next/link';
import { notFound } from 'next/navigation';

import { CourseGrid } from '@/components/course-card';
import { Notice } from '@/components/section';
import { getExplore, text } from '@/lib/content';

/**
 * Một bộ sưu tập do biên tập viên chọn — `CollectionCoursesRoute` của app.
 *
 * API không có endpoint lấy một bộ sưu tập theo id: app cũng chỉ đọc lại dải
 * `curated` từ `/courses-explore` đã có trong tay. Web làm y vậy — bộ sưu tập
 * nào không còn trong phản hồi (bị gỡ, hết hạn, không nhắm tới người này) thì
 * coi như không tồn tại.
 */
export default async function CollectionPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  const sections = await getExplore().then(
    (data) => data.sections ?? [],
    () => null,
  );
  const collection = sections?.find(
    (section) => section.type === 'curated' && section.id === id,
  );
  if (sections && !collection) notFound();

  return (
    <div className="pt-5">
      <Link
        href="/kham-pha"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Khám phá
      </Link>

      <h1 className="mt-3 text-2xl font-bold tracking-tight text-brand-900">
        {text(collection?.title) || 'Bộ sưu tập'}
      </h1>

      <div className="mt-5">
        {!collection ? (
          <Notice>Không tải được bộ sưu tập này.</Notice>
        ) : (collection.courses ?? []).length === 0 ? (
          <Notice>Bộ sưu tập này chưa có khoá học nào.</Notice>
        ) : (
          <CourseGrid courses={collection.courses ?? []} />
        )}
      </div>
    </div>
  );
}
