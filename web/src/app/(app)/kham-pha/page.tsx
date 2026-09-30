import { CourseGrid } from '@/components/course-card';
import { SearchField } from '@/components/search-field';
import { Notice } from '@/components/section';
import { ApiError } from '@/lib/api';
import { getCourses, text, type Course } from '@/lib/content';
import { getSkillsetList } from '@/lib/learning';
import Link from 'next/link';

export default async function ExplorePage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q = '' } = await searchParams;

  let courses: Course[] = [];
  let failure: string | null = null;
  try {
    courses = (await getCourses(1, 30, q)).items;
  } catch (error) {
    failure = error instanceof ApiError ? error.message : String(error);
  }

  // Dải kỹ năng chỉ hiện khi KHÔNG tìm kiếm: đang lọc mà vẫn bày lối rẽ sang
  // chỗ khác thì chỉ làm loãng kết quả.
  const skillsets = q
    ? []
    : await getSkillsetList().then((page) => page.items, () => []);

  return (
    <div className="pt-5">
      <h1 className="mb-4 text-2xl font-bold tracking-tight text-brand-900">
        Khám phá
      </h1>

      <SearchField
        initialQuery={q}
        basePath="/kham-pha"
        label="Tìm khoá học"
        placeholder="Tìm khoá học…"
      />

      {skillsets.length > 0 ? (
        <ul className="mt-4 flex flex-wrap gap-2">
          {skillsets.map((skillset) => (
            <li key={skillset._id}>
              <Link
                href={`/ky-nang/${encodeURIComponent(skillset._id)}`}
                className="inline-block rounded-full bg-surface-alt px-3 py-1.5 text-sm text-ink transition hover:bg-brand-100"
              >
                {text(skillset.title) || 'Kỹ năng'}
              </Link>
            </li>
          ))}
        </ul>
      ) : null}

      <div className="mt-5">
        {failure ? (
          <Notice>Không tải được danh sách khoá học. {failure}</Notice>
        ) : courses.length === 0 ? (
          <Notice>
            {q
              ? `Không tìm thấy khoá học nào khớp với “${q}”.`
              : 'Chưa có khoá học nào.'}
          </Notice>
        ) : (
          <CourseGrid courses={courses} />
        )}
      </div>
    </div>
  );
}
