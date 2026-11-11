import Link from 'next/link';

import { CourseGrid } from '@/components/course-card';
import { formatWeekRange } from '@/components/progress/format';
import { SavedCardList } from '@/components/learning/saved-card-list';
import { Notice, SectionHeader } from '@/components/section';
import { buttonClass } from '@/components/ui-classes';
import { getMyCourses, getSavedCourses } from '@/lib/content';
import { getSavedCardPage } from '@/lib/learning';
import { getWeekRecapArchive, type WeekRecapSummary } from '@/lib/progress';

/**
 * Tab Thư viện — cùng bố cục với `LibraryPage` của app: dải "Đang học" (kèm
 * lối sang Lịch sử học), rồi các kệ Bài tôi tạo · Đã lưu · Thẻ đã lưu · Sổ tay
 * tuần. Kệ trống thì ẩn đi như app, để người mới thấy một trang ngắn thay vì
 * bốn ô "chưa có gì".
 */
export default async function LibraryPage() {
  const [mine, saved, cards, recaps] = await Promise.all([
    getMyCourses(1, 30).then(
      (p) => p.items,
      () => null,
    ),
    getSavedCourses(1, 4).then(
      (p) => p.items,
      () => null,
    ),
    getSavedCardPage(1, 4).then(
      (p) => p.items,
      () => null,
    ),
    getWeekRecapArchive(1).then(
      (p) => p.items,
      () => null,
    ),
  ]);

  // "Đang học" của app = khoá còn bài chưa xong; khoá đã xong nằm ở Lịch sử.
  const inProgress = mine?.filter(
    (c) =>
      !c.numberOfLesson || (c.numberOfLessonPassed ?? 0) < c.numberOfLesson,
  );

  return (
    <div className="pt-5">
      <h1 className="text-2xl font-bold tracking-tight text-brand-900">
        Thư viện của tôi
      </h1>

      <SectionHeader
        title="Đang học"
        href="/thu-vien/lich-su"
        linkLabel="Lịch sử học"
      />
      {inProgress === undefined ? (
        <Notice>Không tải được thư viện của bạn.</Notice>
      ) : inProgress.length === 0 ? (
        <div className="rounded-xl border border-hairline bg-surface p-4">
          <p className="font-semibold text-ink">Chưa có bài nào đang học</p>
          <p className="mt-1 text-sm text-ink-muted">
            Bắt đầu một khoá học, nó sẽ chờ bạn ở đây.
          </p>
          <Link href="/kham-pha" className={`${buttonClass.secondary} mt-3`}>
            Khám phá khoá học
          </Link>
        </div>
      ) : (
        <CourseGrid courses={inProgress.slice(0, 6)} />
      )}

      <Link
        href="/bai-cua-toi"
        className="mt-6 flex items-center gap-3 rounded-xl border border-brand-200 bg-brand-100/50 p-4 transition hover:bg-brand-100 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand"
      >
        <span className="flex-1">
          <span className="block font-semibold text-brand-900">
            Bài tôi tạo
          </span>
          <span className="block text-sm text-ink-muted">
            Những bài học bạn tự tạo từ PDF hoặc YouTube
          </span>
        </span>
        <span aria-hidden className="text-brand-700">
          →
        </span>
      </Link>

      {saved && saved.length > 0 ? (
        <section>
          <SectionHeader title="Đã lưu" href="/thu-vien/da-luu" />
          <CourseGrid courses={saved} />
        </section>
      ) : null}

      {cards && cards.length > 0 ? (
        <section>
          <SectionHeader title="Thẻ đã lưu" href="/thu-vien/the-da-luu" />
          <SavedCardList cards={cards} />
        </section>
      ) : null}

      {recaps && recaps.length > 0 ? (
        <section>
          <SectionHeader title="Sổ tay tuần" href="/tien-do/tuan" />
          <ul className="space-y-2">
            {recaps.map((recap, index) => (
              <WeekRecapRow key={recap.id ?? index} recap={recap} />
            ))}
          </ul>
        </section>
      ) : null}

      {saved?.length === 0 && cards?.length === 0 ? (
        <p className="mt-6 text-sm text-ink-faint">
          Chạm “Lưu khoá học” trên một khoá, hoặc “Lưu thẻ” ở cuối một phần học,
          để giữ chúng ở đây.
        </p>
      ) : null}
    </div>
  );
}

/** Một tuần trong sổ tay — mở tấm "Hành trình tuần qua" của trang Tiến độ. */
function WeekRecapRow({ recap }: { recap: WeekRecapSummary }) {
  return (
    <li>
      <Link
        href={`/tien-do/tuan/${encodeURIComponent(recap.id)}`}
        className="block rounded-xl border border-hairline bg-surface p-3 transition hover:border-brand-200"
      >
        <span className="block font-semibold text-ink">
          Tuần {recap.weekNumber}
        </span>
        <span className="mt-0.5 block text-sm text-ink-muted">
          {formatWeekRange(recap.weekStart, recap.weekEnd)}
        </span>
      </Link>
    </li>
  );
}
