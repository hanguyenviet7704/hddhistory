import { CourseGrid } from '@/components/course-card';
import { Notice, SectionHeader } from '@/components/section';
import { getMyCourses, getSavedCourses, text, type Course } from '@/lib/content';
import {
  getSavedCards,
  getUserLessons,
  getWeekRecaps,
  type SavedCard,
  type UserLesson,
  type WeekRecap,
} from '@/lib/progress';

export default async function LibraryPage() {
  // Năm dải độc lập; mỗi dải tự chịu lỗi của mình để một cái hỏng không làm
  // trắng cả trang.
  const [mine, saved, cards, lessons, recaps] = await Promise.all([
    getMyCourses(1, 30).then((p) => p.items, () => null),
    getSavedCourses(1, 30).then((p) => p.items, () => null),
    getSavedCards().then((p) => p.items, () => null),
    getUserLessons().then((p) => p.items, () => null),
    getWeekRecaps().then((p) => p.items, () => null),
  ]);

  return (
    <div className="pt-5">
      <h1 className="text-2xl font-bold tracking-tight text-brand-900">
        Thư viện
      </h1>

      <Shelf title="Đang học" empty="Bạn chưa bắt đầu khoá học nào.">
        {mine && mine.length > 0 ? <CourseGrid courses={mine} /> : null}
      </Shelf>
      <Shelf title="Đã lưu" empty="Bạn chưa lưu khoá học nào.">
        {saved && saved.length > 0 ? <CourseGrid courses={saved} /> : null}
      </Shelf>

      <Shelf title="Thẻ đã lưu" empty="Bạn chưa lưu thẻ ghi nhớ nào.">
        {cards && cards.length > 0 ? (
          <ul className="space-y-2">
            {cards.map((card, index) => (
              <SavedCardRow key={card._id ?? index} card={card} />
            ))}
          </ul>
        ) : null}
      </Shelf>

      <Shelf
        title="Bài học của tôi"
        empty="Bạn chưa tạo bài học nào. Tính năng tạo bài từ PDF/YouTube hiện chỉ có trên ứng dụng."
      >
        {lessons && lessons.length > 0 ? (
          <ul className="space-y-2">
            {lessons.map((lesson, index) => (
              <UserLessonRow key={lesson._id ?? index} lesson={lesson} />
            ))}
          </ul>
        ) : null}
      </Shelf>

      <Shelf title="Sổ tay tuần" empty="Chưa có bản tổng kết tuần nào.">
        {recaps && recaps.length > 0 ? (
          <ul className="space-y-2">
            {recaps.map((recap, index) => (
              <WeekRecapRow key={recap._id ?? index} recap={recap} />
            ))}
          </ul>
        ) : null}
      </Shelf>
    </div>
  );
}

/**
 * Một dải của Thư viện. `children` rỗng nghĩa là không có gì để hiện — hoặc vì
 * danh sách trống, hoặc vì lời gọi hỏng; cả hai đều hiện cùng một dòng nhắc
 * thay vì để một khoảng trắng không giải thích gì.
 */
function Shelf({
  title,
  empty,
  children,
}: {
  title: string;
  empty: string;
  children: React.ReactNode;
}) {
  return (
    <section>
      <SectionHeader title={title} />
      {children ?? <Notice>{empty}</Notice>}
    </section>
  );
}

function SavedCardRow({ card }: { card: SavedCard }) {
  return (
    <li className="rounded-xl border border-hairline bg-surface p-3">
      <p className="font-semibold text-ink">{text(card.title) || 'Thẻ'}</p>
      {text(card.content) ? (
        <p className="mt-1 text-sm text-ink-muted">{text(card.content)}</p>
      ) : null}
    </li>
  );
}

function UserLessonRow({ lesson }: { lesson: UserLesson }) {
  return (
    <li className="rounded-xl border border-hairline bg-surface p-3">
      <p className="font-semibold text-ink">{lesson.title || 'Bài học'}</p>
      {lesson.status ? (
        <p className="mt-0.5 text-xs text-ink-faint">{lesson.status}</p>
      ) : null}
    </li>
  );
}

function WeekRecapRow({ recap }: { recap: WeekRecap }) {
  const from = recap.weekStartDate?.slice(0, 10) ?? '';
  const to = recap.weekEndDate?.slice(0, 10) ?? '';
  return (
    <li className="rounded-xl border border-hairline bg-surface p-3">
      <p className="font-semibold text-ink">
        Tuần {from}
        {to ? ` – ${to}` : ''}
      </p>
      <p className="mt-0.5 text-sm text-ink-muted">
        {recap.stats?.lessons ?? 0} bài học · {recap.stats?.minutes ?? 0} phút
      </p>
    </li>
  );
}
