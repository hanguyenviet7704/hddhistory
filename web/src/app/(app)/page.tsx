import Link from 'next/link';

import { CourseGrid } from '@/components/course-card';
import { HomeBannerCarousel } from '@/components/learning/home-banner';
import { HomePopupDialog } from '@/components/learning/home-popup';
import { StreakStrip } from '@/components/learning/streak-strip';
import { Notice, SectionHeader } from '@/components/section';
import { ApiError } from '@/lib/api';
import {
  getHomeBanner,
  getHomePopup,
  getMyCourses,
  getRandomQuote,
  getSuggestedCourses,
  text,
  type BannerSlide,
  type Course,
  type HomeBanner,
  type Quote,
} from '@/lib/content';
import { getDailyWarmUpCount, getSpacedReviewDueCount } from '@/lib/learning';
import { getStreak } from '@/lib/progress';
import { getSessionUser } from '@/lib/session';

export default async function HomePage() {
  const user = await getSessionUser();

  // Mọi lời gọi độc lập — chạy song song, và mỗi cái tự chịu lỗi của mình để
  // một dải hỏng không làm trắng cả trang chủ.
  const [
    myCourses,
    suggested,
    quote,
    streak,
    banner,
    popup,
    reviewDue,
    warmUpCount,
  ] = await Promise.all([
    getMyCourses().then(
      (page) => page.items,
      (error) => error as ApiError,
    ),
    getSuggestedCourses().then(
      (items) => items,
      (error) => error as ApiError,
    ),
    getRandomQuote().catch(() => null),
    getStreak().catch(() => null),
    getHomeBanner().catch(() => null),
    getHomePopup().catch(() => null),
    getSpacedReviewDueCount().catch(() => null),
    getDailyWarmUpCount().catch(() => null),
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

      {streak ? (
        <div className="mt-4">
          <StreakStrip streak={streak} />
        </div>
      ) : null}

      <HomeBannerCarousel slides={bannerSlides(banner)} />
      {popup?.visible && popup.imageUrl && popup.campaignKey ? (
        <HomePopupDialog popup={popup} />
      ) : null}

      <SectionHeader title="Hôm nay" />
      <ul className="grid gap-3 sm:grid-cols-2">
        <EntryCard
          href="/khoi-dong"
          title="Khởi động hằng ngày"
          // Chưa có câu nào nghĩa là người dùng chưa học gì để ôn lại: nói
          // thẳng điều đó thay vì mời vào một màn trống.
          subtitle={
            warmUpCount === null
              ? 'Vài câu hỏi nhanh từ những gì bạn đã học'
              : warmUpCount > 0
                ? `${warmUpCount} câu hỏi nhanh · củng cố bài trước khi quên`
                : 'Học một bài để mở phần khởi động ngày mai'
          }
          muted={warmUpCount === 0}
        />
        <EntryCard
          href="/on-tap"
          title="Ôn tập hôm nay"
          subtitle={
            reviewDue === null
              ? 'Ôn lại phần kiến thức sắp quên'
              : reviewDue > 0
                ? `${reviewDue} phần kiến thức sắp quên · khoảng 3 phút`
                : 'Chưa có phần nào đến hạn ôn'
          }
          badge={reviewDue && reviewDue > 0 ? reviewDue : undefined}
          muted={reviewDue === 0}
        />
        <EntryCard
          href="/tro-ly"
          title="Trợ lý AI"
          subtitle="Hỏi đáp và trò chuyện về những gì bạn đang học"
        />
        <EntryCard
          href="/nhap-bai"
          title="Tạo bài học từ PDF/YouTube"
          subtitle="Biến tài liệu của bạn thành một bài học"
        />
        <EntryCard
          href="/tra-cuu"
          title="Tra cứu lịch sử"
          subtitle="Hỏi đồ thị tri thức về một nhân vật, sự kiện hay triều đại"
        />
      </ul>

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

/**
 * Slide của banner. Chỉ đọc `slides`: `imageUrl`/`linkUrl` ở gốc là bản sao
 * slide 1 server giữ cho app 1.5.0, đọc cả hai là hiện slide đầu hai lần.
 */
function bannerSlides(banner: HomeBanner | null): BannerSlide[] {
  if (!banner?.visible) return [];
  return (banner.slides ?? []).filter(
    (slide) => slide.imageUrl && slide.campaignKey,
  );
}

function EntryCard({
  href,
  title,
  subtitle,
  badge,
  muted = false,
}: {
  href: string;
  title: string;
  subtitle: string;
  badge?: number;
  muted?: boolean;
}) {
  return (
    <li>
      <Link
        href={href}
        className={`flex h-full items-center gap-3 rounded-xl border p-4 transition focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand ${
          muted
            ? 'border-hairline bg-surface hover:bg-brand-50'
            : 'border-brand-200 bg-brand-100/50 hover:bg-brand-100'
        }`}
      >
        <span className="min-w-0 flex-1">
          <span className="block font-semibold text-brand-900">{title}</span>
          <span className="mt-0.5 block text-sm text-ink-muted">
            {subtitle}
          </span>
        </span>
        {badge ? (
          <span className="flex min-w-7 items-center justify-center rounded-full bg-brand px-2 py-0.5 text-xs font-bold text-white">
            {badge}
            <span className="sr-only"> phần đến hạn</span>
          </span>
        ) : (
          <span aria-hidden className="text-brand-700">
            →
          </span>
        )}
      </Link>
    </li>
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
