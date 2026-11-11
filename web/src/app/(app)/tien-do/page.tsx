import Link from 'next/link';

import { mondayIndex, formatDayTitle } from '@/components/progress/format';
import { StudyJournalCalendar } from '@/components/progress/study-journal-calendar';
import { WeekRecapCard } from '@/components/progress/week-recap-card';
import { Notice, SectionHeader } from '@/components/section';
import { text } from '@/lib/content';
import {
  getAchievements,
  getCurrentWeekRecap,
  getStreak,
  getStudyJournal,
  getStudyJournalDay,
  localToday,
  type Achievement,
  type Streak,
  type StudyJournalDayDetail,
} from '@/lib/progress';

const WEEKDAYS = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

const MONTH_RE = /^\d{4}-(0[1-9]|1[0-2])$/;
const DATE_RE = /^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/;

export default async function ProgressPage({
  searchParams,
}: {
  searchParams: Promise<{ thang?: string | string[]; ngay?: string | string[] }>;
}) {
  const params = await searchParams;
  const today = localToday();
  // Tham số URL do người dùng gõ được: sai định dạng hay ở tương lai thì coi
  // như không có, đừng để API trả 400 rồi báo "không tải được".
  const rawMonth = typeof params.thang === 'string' ? params.thang : '';
  const month =
    MONTH_RE.test(rawMonth) && rawMonth <= today.slice(0, 7)
      ? rawMonth
      : today.slice(0, 7);
  const rawDay = typeof params.ngay === 'string' ? params.ngay : '';
  const selectedDay =
    DATE_RE.test(rawDay) && rawDay.startsWith(month) && rawDay <= today
      ? rawDay
      : undefined;

  // Các lời gọi độc lập; mỗi phần tự chịu lỗi để một cái hỏng không làm trắng
  // cả trang.
  const [streak, recap, journal, day, achievements] = await Promise.all([
    getStreak().catch(() => null),
    getCurrentWeekRecap().catch(() => null),
    getStudyJournal(month).catch(() => null),
    selectedDay ? getStudyJournalDay(selectedDay).catch(() => null) : undefined,
    getAchievements().catch(() => null),
  ]);

  return (
    <div className="pt-5">
      <h1 className="text-2xl font-bold tracking-tight text-brand-900">
        Tiến độ
      </h1>

      <SectionHeader title="Chuỗi ngày học" />
      {streak === null ? (
        <Notice>Không tải được chuỗi ngày học.</Notice>
      ) : (
        <StreakCard streak={streak} todayIndex={mondayIndex(today)} />
      )}

      <SectionHeader title="Hành trình tuần qua" />
      {recap === null ? (
        <Notice>Không tải được hành trình của bạn.</Notice>
      ) : (
        <WeekRecapCard current={recap} today={today} />
      )}

      <section id="nhat-ky" className="scroll-mt-4">
        <SectionHeader title="Nhật ký học tập" />
        {journal === null ? (
          <Notice>Không tải được nhật ký.</Notice>
        ) : (
          <StudyJournalCalendar
            journal={journal}
            month={month}
            today={today}
            selected={selectedDay}
          />
        )}
        {selectedDay ? <DayDetail date={selectedDay} day={day ?? null} /> : null}
      </section>

      <SectionHeader title="Thành tích theo chủ đề" />
      {achievements === null ? (
        <Notice>Không tải được thành tích.</Notice>
      ) : achievements.length === 0 ? (
        <Notice>Chưa có thành tích nào — hãy bắt đầu một khoá học.</Notice>
      ) : (
        <ul className="space-y-2">
          {achievements.map((item, index) => (
            <AchievementRow key={item.categoryId ?? index} item={item} />
          ))}
        </ul>
      )}
    </div>
  );
}

function StreakCard({ streak, todayIndex }: { streak: Streak; todayIndex: number }) {
  const checkedIn = streak.weekStudy?.[todayIndex] ?? false;
  return (
    <div className="rounded-xl border border-hairline bg-surface p-4">
      <div className="flex gap-6">
        <div>
          <p className="text-2xl font-bold text-brand">{streak.currentStreak}</p>
          <p className="text-xs text-ink-faint">ngày liên tiếp</p>
        </div>
        <div>
          <p className="text-2xl font-bold text-ink">{streak.bestStreak}</p>
          <p className="text-xs text-ink-faint">chuỗi dài nhất</p>
        </div>
        <div>
          <p className="text-2xl font-bold text-ink">
            {Math.round((streak.studyTime ?? 0) / 60)}
          </p>
          <p className="text-xs text-ink-faint">phút tuần này</p>
        </div>
      </div>

      <ul className="mt-4 flex gap-2" aria-label="Tuần này">
        {WEEKDAYS.map((day, index) => {
          const studied = streak.weekStudy?.[index] ?? false;
          return (
            <li key={day} className="flex-1 text-center">
              <span
                className={`mx-auto flex size-8 items-center justify-center rounded-full text-xs font-bold ${
                  studied ? 'bg-brand text-white' : 'bg-surface-alt text-ink-faint'
                } ${index === todayIndex ? 'ring-2 ring-brand-300' : ''}`}
                // Màu không đứng một mình: có/chưa học đọc được bằng chữ.
                aria-label={`${day}${index === todayIndex ? ' (hôm nay)' : ''}: ${
                  studied ? 'đã học' : 'chưa học'
                }`}
              >
                {day}
              </span>
            </li>
          );
        })}
      </ul>

      <p className="mt-3 text-sm text-ink-muted">
        {checkedIn ? (
          <span className="font-semibold text-emerald-700">
            Hôm nay bạn đã có mặt!
          </span>
        ) : (
          'Hoàn thành ít nhất một bài học để duy trì chuỗi. Bỏ lỡ một ngày, chuỗi sẽ thiết lập lại.'
        )}
      </p>
    </div>
  );
}

function DayDetail({
  date,
  day,
}: {
  date: string;
  day: StudyJournalDayDetail | null;
}) {
  return (
    <div
      className="mt-2 rounded-xl border border-hairline bg-surface p-4"
      aria-live="polite"
    >
      <h3 className="font-semibold text-ink">{formatDayTitle(date)}</h3>
      {day === null ? (
        <p role="alert" className="mt-2 text-sm text-red-700">
          Không tải được ngày này.
        </p>
      ) : day.courses.length === 0 && day.habits.length === 0 ? (
        <div className="mt-2 text-sm text-ink-muted">
          <p className="font-semibold text-ink">Không có hoạt động</p>
          <p>Một ngày nghỉ nhỏ. Điều quan trọng là bạn luôn quay lại!</p>
        </div>
      ) : (
        <>
          <p className="mt-1 text-sm text-ink-muted">
            {day.summary.lessons} bài học · {day.summary.minutes} phút
            {day.summary.habits ? ` · ${day.summary.habits} thói quen` : ''}
          </p>
          {day.courses.length > 0 ? (
            <>
              <h4 className="mt-3 text-xs font-bold tracking-wide text-brand-700 uppercase">
                Bài học
              </h4>
              <ul className="mt-1 space-y-1">
                {day.courses.map((course) => (
                  <li key={course.courseId}>
                    <Link
                      href={`/khoa-hoc/${course.courseId}`}
                      className="flex justify-between gap-3 rounded-lg px-2 py-1.5 text-sm transition hover:bg-brand-50"
                    >
                      <span className="font-semibold text-ink">
                        {course.title || 'Khoá học'}
                      </span>
                      <span className="shrink-0 text-ink-faint">
                        {course.lessons} bài · {course.minutes} phút
                      </span>
                    </Link>
                  </li>
                ))}
              </ul>
            </>
          ) : null}
          {day.habits.length > 0 ? (
            <>
              <h4 className="mt-3 text-xs font-bold tracking-wide text-brand-700 uppercase">
                Thói quen được luyện tập
              </h4>
              <ul className="mt-1 space-y-1 text-sm">
                {day.habits.map((habit) => (
                  <li key={habit.userHabitId} className="px-2">
                    <span className="text-ink">{habit.title}</span>
                    {habit.note ? (
                      <span className="block text-ink-muted">{habit.note}</span>
                    ) : null}
                  </li>
                ))}
              </ul>
            </>
          ) : null}
        </>
      )}
    </div>
  );
}

function AchievementRow({ item }: { item: Achievement }) {
  const total = item.totalKeypoints ?? 0;
  const done = item.completedKeypoints ?? 0;
  const percent = total ? Math.round((done / total) * 100) : 0;
  const courses = item.courses ?? [];
  const badges = courses.filter((course) => course.isCompleted).length;
  return (
    <li className="rounded-xl border border-hairline bg-surface p-3">
      <div className="flex items-baseline justify-between gap-3">
        <span className="font-semibold text-ink">
          {text(item.categoryTitle) || 'Chủ đề'}
        </span>
        <span className="shrink-0 text-sm text-ink-faint">
          {done}/{total} keypoint
        </span>
      </div>
      <div
        className="mt-2 h-1.5 overflow-hidden rounded-full bg-brand-100"
        role="progressbar"
        aria-label={`Tiến độ chủ đề ${text(item.categoryTitle)}`}
        aria-valuenow={percent}
        aria-valuemin={0}
        aria-valuemax={100}
      >
        <div className="h-full rounded-full bg-brand" style={{ width: `${percent}%` }} />
      </div>
      {courses.length > 0 ? (
        <p className="mt-2 text-xs text-ink-muted">
          {badges}/{courses.length} huy hiệu khoá học
        </p>
      ) : null}
    </li>
  );
}
