import Link from 'next/link';

import { CourseGrid } from '@/components/course-card';
import { ClearHistoryButton } from '@/components/learning/clear-history-button';
import { SearchField } from '@/components/search-field';
import { Notice, SectionHeader } from '@/components/section';
import { recordSearch } from '@/lib/actions/learning';
import { ApiError } from '@/lib/api';
import {
  getCourses,
  getExplore,
  getRecentlyViewed,
  getSearchHistory,
  text,
  type Course,
  type ExploreSection,
} from '@/lib/content';
import { getCategoryList, type Category } from '@/lib/learning';

export default async function ExplorePage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q = '' } = await searchParams;
  const query = q.trim();

  return (
    <div className="pt-5">
      <h1 className="mb-4 text-2xl font-bold tracking-tight text-brand-900">
        Khám phá
      </h1>

      <SearchField
        initialQuery={q}
        basePath="/kham-pha"
        label="Tìm kiếm khoá học"
        placeholder="Nhập tiêu đề, từ khoá,..."
        onSubmitQuery={recordSearch}
      />

      {query ? <SearchResults query={query} /> : <ExploreHome />}
    </div>
  );
}

async function SearchResults({ query }: { query: string }) {
  let courses: Course[] = [];
  let failure: string | null = null;
  try {
    courses = (await getCourses(1, 50, query)).items;
  } catch (error) {
    failure = error instanceof ApiError ? error.message : String(error);
  }

  return (
    <div className="mt-5">
      {failure ? (
        <Notice>Không tải được danh sách khoá học. {failure}</Notice>
      ) : courses.length === 0 ? (
        <Notice>
          Không tìm thấy kết quả cho “{query}”. Thử từ khoá hoặc tiêu đề khác.
        </Notice>
      ) : (
        <CourseGrid courses={courses} />
      )}
    </div>
  );
}

async function ExploreHome() {
  // Các dải độc lập, mỗi dải tự rút lui khi hỏng. Thứ tự dải lấy từ server.
  const [explore, categories, history, recent, all] = await Promise.all([
    getExplore().then(
      (data) => data.sections ?? [],
      () => null,
    ),
    getCategoryList().then(
      (page) => page.items,
      () => [] as Category[],
    ),
    getSearchHistory().catch(() => []),
    getRecentlyViewed().catch(() => [] as Course[]),
    getCourses(1, 30).then(
      (page) => page.items,
      () => null,
    ),
  ]);

  // Không có dải nào từ server thì vẫn giữ chỗ cho dải chủ đề, để danh mục
  // không biến mất chỉ vì `/courses-explore` hỏng.
  const sections: ExploreSection[] = explore?.length
    ? explore
    : [{ type: 'topicChips' }];

  return (
    <>
      {history.length > 0 ? (
        <section>
          <div className="mt-5 flex items-center justify-between gap-3">
            <h2 className="text-sm font-bold tracking-wide text-brand-900 uppercase">
              Tìm kiếm gần đây
            </h2>
            <ClearHistoryButton kind="search" label="Xoá tất cả" />
          </div>
          <ul className="mt-2 flex flex-wrap gap-2">
            {history.slice(0, 10).map((entry) => (
              <li key={entry.query}>
                <Link
                  href={`/kham-pha?q=${encodeURIComponent(entry.query)}`}
                  className="inline-block rounded-full border border-hairline bg-surface px-3 py-1.5 text-sm text-ink transition hover:bg-brand-100"
                >
                  {entry.query}
                </Link>
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      {recent.length > 0 ? (
        <section>
          <div className="mt-7 mb-2 flex items-center justify-between gap-3">
            <h2 className="text-sm font-bold tracking-wide text-brand-900 uppercase">
              Xem gần đây
            </h2>
            <ClearHistoryButton kind="recent" label="Xoá tất cả" />
          </div>
          <CourseGrid courses={recent.slice(0, 4)} />
        </section>
      ) : null}

      {sections.map((section, index) => (
        <ExploreStrip
          key={section.id ?? `${section.type}-${index}`}
          section={section}
          categories={categories}
        />
      ))}

      <SectionHeader title="Tất cả khoá học" />
      {all === null ? (
        <Notice>Không tải được danh sách khoá học.</Notice>
      ) : all.length === 0 ? (
        <Notice>Chưa có khoá học nào.</Notice>
      ) : (
        <CourseGrid courses={all} />
      )}
    </>
  );
}

function ExploreStrip({
  section,
  categories,
}: {
  section: ExploreSection;
  categories: Category[];
}) {
  const courses = section.courses ?? [];

  switch (section.type) {
    case 'topicChips':
      if (categories.length === 0) return null;
      return (
        <section>
          <SectionHeader title="Tìm kiếm theo chủ đề" />
          <ul className="flex flex-wrap gap-2">
            {categories.map((category) => (
              <li key={category._id}>
                <Link
                  href={`/chu-de/${encodeURIComponent(category._id)}`}
                  className="inline-block rounded-full bg-surface-alt px-3 py-1.5 text-sm text-ink transition hover:bg-brand-100"
                >
                  {text(category.title) || 'Chủ đề'}
                </Link>
              </li>
            ))}
          </ul>
        </section>
      );

    case 'weeklyTop':
      if (courses.length === 0) return null;
      return (
        <section>
          <SectionHeader title="Tuần qua · Được học nhiều nhất" />
          <CourseGrid courses={courses} />
        </section>
      );

    case 'becauseYou':
      if (courses.length === 0) return null;
      return (
        <section>
          <SectionHeader
            title={`Vì bạn đã học ${text(section.sourceCourse?.title)}`.trim()}
          />
          <CourseGrid courses={courses} />
        </section>
      );

    case 'curated':
      if (courses.length === 0 || !section.id) return null;
      return (
        <section>
          <SectionHeader
            title={text(section.title) || 'Bộ sưu tập'}
            href={`/kham-pha/bo-suu-tap/${encodeURIComponent(section.id)}`}
          />
          <CourseGrid courses={courses.slice(0, 4)} />
        </section>
      );

    default:
      // Kiểu dải mới mà web chưa biết: bỏ qua thay vì vẽ sai.
      return null;
  }
}
