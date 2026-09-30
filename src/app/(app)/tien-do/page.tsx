import { Notice, SectionHeader } from '@/components/section';
import { text } from '@/lib/content';
import {
  getAchievements,
  getStreak,
  getStudyJournal,
  type Achievement,
  type Streak,
  type StudyJournal,
} from '@/lib/progress';

const WEEKDAYS = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

export default async function ProgressPage() {
  // Ba lời gọi độc lập; mỗi phần tự chịu lỗi để một cái hỏng không làm trắng
  // cả trang.
  const [streak, achievements, journal] = await Promise.all([
    getStreak().catch(() => null),
    getAchievements().catch(() => null),
    getStudyJournal().catch(() => null),
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
        <StreakCard streak={streak} />
      )}

      <SectionHeader title="Thành tích theo kỹ năng" />
      {achievements === null ? (
        <Notice>Không tải được thành tích.</Notice>
      ) : achievements.length === 0 ? (
        <Notice>Chưa có thành tích nào — hãy bắt đầu một khoá học.</Notice>
      ) : (
        <ul className="space-y-2">
          {achievements.map((item, index) => (
            <AchievementRow key={item.skillsetId ?? index} item={item} />
          ))}
        </ul>
      )}

      <SectionHeader title="Nhật ký học tập" />
      {journal === null ? (
        <Notice>Không tải được nhật ký.</Notice>
      ) : (
        <JournalCard journal={journal} />
      )}
    </div>
  );
}

function StreakCard({ streak }: { streak: Streak }) {
  return (
    <div className="rounded-xl border border-hairline bg-surface p-4">
      <div className="flex gap-6">
        <div>
          <p className="text-2xl font-bold text-brand">
            {streak.currentStreak}
          </p>
          <p className="text-xs text-ink-faint">ngày liên tiếp</p>
        </div>
        <div>
          <p className="text-2xl font-bold text-ink">{streak.bestStreak}</p>
          <p className="text-xs text-ink-faint">kỷ lục</p>
        </div>
        <div>
          <p className="text-2xl font-bold text-ink">
            {Math.round((streak.studyTime ?? 0) / 60)}
          </p>
          <p className="text-xs text-ink-faint">phút tuần này</p>
        </div>
      </div>

      <ul className="mt-4 flex gap-2">
        {WEEKDAYS.map((day, index) => {
          const studied = streak.weekStudy?.[index] ?? false;
          return (
            <li key={day} className="flex-1 text-center">
              <span
                className={`mx-auto flex size-8 items-center justify-center rounded-full text-xs font-bold ${
                  studied
                    ? 'bg-brand text-white'
                    : 'bg-surface-alt text-ink-faint'
                }`}
                // Màu không đứng một mình: có/chưa học đọc được bằng chữ.
                aria-label={`${day}: ${studied ? 'đã học' : 'chưa học'}`}
              >
                {day}
              </span>
            </li>
          );
        })}
      </ul>
    </div>
  );
}

function AchievementRow({ item }: { item: Achievement }) {
  const total = item.total ?? 0;
  const done = item.completed ?? 0;
  const percent = item.percent ?? (total ? Math.round((done / total) * 100) : 0);
  return (
    <li className="rounded-xl border border-hairline bg-surface p-3">
      <div className="flex items-baseline justify-between gap-3">
        <span className="font-semibold text-ink">
          {text(item.title) || 'Kỹ năng'}
        </span>
        <span className="text-sm text-ink-faint">
          {done}/{total}
        </span>
      </div>
      <div
        className="mt-2 h-1.5 overflow-hidden rounded-full bg-brand-100"
        role="progressbar"
        aria-valuenow={percent}
        aria-valuemin={0}
        aria-valuemax={100}
      >
        <div
          className="h-full rounded-full bg-brand"
          style={{ width: `${percent}%` }}
        />
      </div>
    </li>
  );
}

function JournalCard({ journal }: { journal: StudyJournal }) {
  return (
    <div className="rounded-xl border border-hairline bg-surface p-4">
      <p className="text-sm text-ink-muted">
        Tháng {journal.month} — <strong>{journal.summary.activeDays}</strong> ngày
        có học, <strong>{journal.summary.keypoints}</strong> phần đã xong.
      </p>
      {journal.days.length === 0 ? (
        <p className="mt-2 text-sm text-ink-faint">
          Chưa có ngày nào được ghi nhận trong tháng này.
        </p>
      ) : (
        <ul className="mt-3 space-y-1 text-sm text-ink-muted">
          {journal.days.map((day) => (
            <li key={day.date}>
              {day.date} — {day.keypoints ?? 0} phần
              {day.minutes ? `, ${day.minutes} phút` : ''}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
