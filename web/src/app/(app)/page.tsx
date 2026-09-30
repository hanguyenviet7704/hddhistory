import Link from 'next/link';

import { CourseGrid } from '@/components/course-card';
import { Notice, SectionHeader } from '@/components/section';
import { ApiError } from '@/lib/api';
import {
  getMyCourses,
  getRandomQuote,
  getSuggestedCourses,
  text,
  type Course,
  type Quote,
} from '@/lib/content';
import { getSessionUser } from '@/lib/session';

export default async function HomePage() {
  const user = await getSessionUser();

  // Bốn lời gọi độc lập — chạy song song, và mỗi cái tự chịu lỗi của mình để
  // một dải hỏng không làm trắng cả trang chủ.
  const [myCourses, suggested, quote] = await Promise.all([
    getMyCourses().then(
      (page) => page.items,
      (error) => error as ApiError,
    ),
    getSuggestedCourses().then(
      (items) => items,
      (error) => error as ApiError,
    ),
    getRandomQuote().then(
      (q) => q,
      () => null,
    ),
  ]);

  const failure = [myCourses, suggested].find(
    (value): value is ApiError => value instanceof Error,
  );

  return (
    <div className="pt-5">
      <h1 className="text-2xl font-bold tracking-tight text-brand-900">
        Xin chào{user?.name ? `, ${user.name}` : ''}!
      </h1>

      <QuoteLine quote={quote} />

      <Link
        href="/tra-cuu"
        className="mt-4 flex items-center gap-3 rounded-xl border border-brand-200 bg-brand-100/50 p-4 transition hover:bg-brand-100"
      >
        <span className="flex-1">
          <span className="block font-semibold text-brand-900">
            Tra cứu lịch sử
          </span>
          <span className="block text-sm text-ink-muted">
            Hỏi đồ thị tri thức về một nhân vật, sự kiện hay triều đại
          </span>
        </span>
        <span aria-hidden className="text-brand-700">
          →
        </span>
      </Link>

      {failure ? (
        <div className="mt-6">
          <Notice>Không tải được nội dung. {failure.message}</Notice>
        </div>
      ) : null}

      <CourseSection
        title="Tiếp tục học"
        href="/thu-vien"
        courses={myCourses}
        empty="Bạn chưa bắt đầu khoá học nào."
      />
      <CourseSection
        title="Gợi ý cho bạn"
        href="/kham-pha"
        courses={suggested}
        empty="Chưa có gợi ý nào."
      />
    </div>
  );
}

function QuoteLine({ quote }: { quote: Quote | null }) {
  const content = text(quote?.content);
  if (!content) return null;
  return (
    <blockquote className="mt-3 border-l-2 border-brand-200 pl-3 text-sm text-ink-muted italic">
      “{content}”
      {quote?.author ? (
        <footer className="mt-0.5 text-xs not-italic">— {quote.author}</footer>
      ) : null}
    </blockquote>
  );
}

function CourseSection({
  title,
  href,
  courses,
  empty,
}: {
  title: string;
  href: string;
  courses: Course[] | ApiError;
  empty: string;
}) {
  if (courses instanceof Error) return null;
  return (
    <section>
      <SectionHeader title={title} href={href} />
      {courses.length === 0 ? (
        <Notice>{empty}</Notice>
      ) : (
        <CourseGrid courses={courses} />
      )}
    </section>
  );
}
