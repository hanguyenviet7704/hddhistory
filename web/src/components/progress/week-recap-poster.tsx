import Link from 'next/link';

import { SectionHeader } from '@/components/section';
import type { WeekRecapDetail } from '@/lib/progress';

import { WEEKDAY_SHORT, formatWeekRange } from './format';

/**
 * Câu động viên chọn theo số ngày có mặt — cùng ngưỡng và lời của app
 * (`_encouragement` trong week_recap_poster.dart). Client tự chọn chứ API không
 * gửi: đó là lời văn, còn con số thì đã có sẵn trên tấm.
 */
function encouragement(days: number): string {
  if (days >= 7) {
    return 'Trọn vẹn cả 7 ngày! Bạn đã có mặt mỗi ngày trong tuần. Thật đáng nể — cứ giữ nhịp này nhé!';
  }
  if (days >= 5) {
    return `Một tuần thật đáng nhớ! Bạn đã có mặt ${days}/7 ngày và không bỏ cuộc. Cứ giữ nhịp này nhé — bạn đang làm rất tốt!`;
  }
  if (days >= 3) {
    return `Bạn đã có mặt ${days}/7 ngày trong tuần này. Không cần hoàn hảo, chỉ cần quay lại — và bạn đã làm được điều đó.`;
  }
  return `Tuần này bạn có mặt ${days}/7 ngày. Bắt đầu lại luôn khó hơn bắt đầu, vậy mà bạn vẫn ở đây.`;
}

export function WeekRecapPoster({ recap }: { recap: WeekRecapDetail }) {
  const stats = [
    { label: 'Chuỗi', value: recap.stats.streakDays },
    { label: 'Thói quen', value: recap.stats.habitsKept },
    { label: 'Bài học', value: recap.stats.keypoints },
    { label: 'Phút học', value: recap.stats.minutes },
  ];

  return (
    <article>
      <div className="rounded-xl border border-hairline bg-surface p-4">
        <p className="text-sm text-ink-faint">
          {formatWeekRange(recap.weekStart, recap.weekEnd)}
        </p>
        <p className="mt-3 text-ink">{encouragement(recap.stats.activeDays)}</p>

        <ul className="mt-4 flex gap-2" aria-label="Bảy ngày trong tuần">
          {WEEKDAY_SHORT.map((label, index) => {
            const day = recap.days[index];
            const active = day?.active ?? false;
            return (
              <li key={label} className="flex-1 text-center">
                <span
                  className={`mx-auto flex size-9 items-center justify-center rounded-full text-xs font-bold ${
                    active ? 'bg-brand text-white' : 'bg-surface-alt text-ink-faint'
                  }`}
                  aria-label={`${label}: ${active ? 'có học' : 'nghỉ'}`}
                >
                  {label}
                </span>
              </li>
            );
          })}
        </ul>

        <dl className="mt-4 grid grid-cols-4 gap-2 text-center">
          {stats.map((stat) => (
            // dt phải đứng trước dd; đảo bằng CSS để con số vẫn nằm trên.
            <div
              key={stat.label}
              className="flex flex-col-reverse rounded-lg bg-brand-50 px-1 py-2"
            >
              <dt className="text-xs text-ink-muted">{stat.label}</dt>
              <dd className="text-xl font-bold text-brand-900">{stat.value}</dd>
            </div>
          ))}
        </dl>
      </div>

      {recap.lessons.length > 0 ? (
        <>
          <SectionHeader title="Bài học tuần qua" />
          <ul className="space-y-2">
            {recap.lessons.map((lesson) => (
              <li key={lesson.lessonId}>
                <Link
                  href={`/bai-hoc/${lesson.lessonId}`}
                  className="flex items-center gap-3 rounded-xl border border-hairline bg-surface p-3 transition hover:border-brand-200"
                >
                  {lesson.image ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={lesson.image}
                      alt=""
                      className="size-12 shrink-0 rounded-lg bg-surface-alt object-cover"
                    />
                  ) : null}
                  <span className="min-w-0">
                    <span className="block truncate font-semibold text-ink">
                      {lesson.lessonTitle || 'Bài học'}
                    </span>
                    <span className="block truncate text-sm text-ink-muted">
                      {lesson.courseTitle}
                    </span>
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        </>
      ) : null}

      {recap.favouriteCourse ? (
        <>
          <SectionHeader title="Khoá học ưa thích" />
          <Link
            href={`/khoa-hoc/${recap.favouriteCourse.courseId}`}
            className="block rounded-xl border border-hairline bg-surface p-4 font-semibold text-ink transition hover:border-brand-200"
          >
            {recap.favouriteCourse.title}
          </Link>
        </>
      ) : null}

      {recap.habits.length > 0 ? (
        <>
          <SectionHeader title="Thói quen đã giữ" />
          <ul className="space-y-1 rounded-xl border border-hairline bg-surface p-4 text-sm">
            {recap.habits.map((habit) => (
              <li key={habit.habitId} className="flex justify-between gap-3">
                <span className="text-ink">{habit.title}</span>
                <span className="shrink-0 text-ink-faint">
                  {habit.doneCount}/7 ngày
                </span>
              </li>
            ))}
          </ul>
        </>
      ) : null}

      {recap.coach ? <CoachBlock coach={recap.coach} /> : null}

      <p className="mt-6 text-center text-sm text-ink-faint italic">
        “Không cần thấy hết cầu thang, chỉ cần bước bước đầu tiên.”
      </p>
    </article>
  );
}

/**
 * "Bản ghi cải thiện" của AI Coach. API trả null cho tuần không có gì để nói,
 * và từng khối con cũng có thể rỗng — khối rỗng thì không vẽ, vì một ô "đổi
 * thay" trống đọc như một tuần chẳng có gì thay đổi.
 */
function CoachBlock({ coach }: { coach: NonNullable<WeekRecapDetail['coach']> }) {
  const evidence = coach.evidence ?? [];
  const ownWords = coach.ownWords ?? [];
  const practised = coach.practised;
  const hasPractice =
    practised !== undefined &&
    practised.done + practised.missed + practised.noOccasion > 0;
  if (!evidence.length && !ownWords.length && !hasPractice && !coach.change) return null;

  return (
    <>
      <SectionHeader title="Bản ghi cải thiện" />
      <div className="space-y-4 rounded-xl border border-hairline bg-surface p-4 text-sm">
        {evidence.length ? (
          <CoachPart title="Đời thật">
            <ul className="list-disc space-y-1 pl-5">
              {evidence.map((line, index) => (
                <li key={index}>{line}</li>
              ))}
            </ul>
          </CoachPart>
        ) : null}
        {hasPractice && practised ? (
          <CoachPart title="Đã tập">
            <p>
              {practised.done} lần làm được · {practised.noOccasion} lần chưa có
              dịp · {practised.missed} lần bỏ lỡ
            </p>
          </CoachPart>
        ) : null}
        {coach.change ? (
          <CoachPart title="Đổi thay">
            <p>
              <span className="text-ink-faint">Trước:</span> {coach.change.before}
            </p>
            <p className="mt-1">
              <span className="text-ink-faint">
                Sau {coach.change.weeksApart} tuần:
              </span>{' '}
              {coach.change.after}
            </p>
          </CoachPart>
        ) : null}
        {ownWords.length ? (
          <CoachPart title="Chữ của chính bạn">
            <ul className="space-y-1">
              {ownWords.map((line, index) => (
                <li key={index}>“{line}”</li>
              ))}
            </ul>
          </CoachPart>
        ) : null}
      </div>
    </>
  );
}

function CoachPart({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section>
      <h3 className="mb-1 text-xs font-bold tracking-wide text-brand-700 uppercase">
        {title}
      </h3>
      <div className="text-ink">{children}</div>
    </section>
  );
}
