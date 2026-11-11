'use client';

import Link from 'next/link';
import { useState } from 'react';

import { buttonClass, inputClass } from '@/components/ui';
import type {
  CoachCourseCard,
  CoachHotline,
  CoachScore,
} from '@/lib/coach';

import { coachCourseReason, DAY_LABELS, ratingChipsFor } from './coach-copy';

/** Viên chip chung: gợi ý, lựa chọn, thao tác phụ. */
export function Chip({
  children,
  onClick,
  disabled,
  selected,
  title,
}: {
  children: React.ReactNode;
  onClick?: () => void;
  disabled?: boolean;
  selected?: boolean;
  title?: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      aria-pressed={selected}
      title={title}
      className={`rounded-full border px-3 py-1.5 text-sm font-semibold transition focus:outline-none focus-visible:ring-2 focus-visible:ring-brand/40 disabled:cursor-not-allowed disabled:opacity-50 ${
        selected
          ? 'border-brand bg-brand-100 text-brand-900'
          : 'border-brand-200 bg-surface text-brand-900 hover:bg-brand-50'
      }`}
    >
      {children}
    </button>
  );
}

// ------------------------------------------------------------- course card

/**
 * Khoá học khớp với chuyện vừa kể — đọc từ thư viện, không do model bịa.
 * Dòng đầu là LÝ DO (một sự thật về người đọc), không phải tên khoá.
 */
export function CourseCardView({
  course,
  active,
  busy,
  onAction,
}: {
  course: CoachCourseCard;
  /** Chỉ bấm được khi bước hiện tại đúng là thẻ khoá học (không phải lúc LEAVE). */
  active: boolean;
  busy: boolean;
  onAction: (action: 'open' | 'save' | 'close' | 'harder') => void;
}) {
  const reason = coachCourseReason(course.reasonKey, course.reasonArgs ?? {});
  const disabled = !active || busy;
  return (
    <div className="ml-auto w-full max-w-md rounded-xl border border-brand-200 bg-brand-50 p-3">
      <p className="text-xs font-bold text-brand-700">{reason || 'Một khoá gần với chuyện bạn kể'}</p>
      <div className="mt-2 flex gap-3">
        {course.image ? (
          // Ảnh từ CDN của API, tên miền không cố định — <img> thường.
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={course.image}
            alt=""
            className="size-14 shrink-0 rounded-lg border border-hairline object-cover"
          />
        ) : null}
        <div className="min-w-0">
          <p className="font-semibold text-ink">{course.title}</p>
          {course.author ? (
            <p className="text-xs text-ink-muted">{course.author}</p>
          ) : null}
        </div>
      </div>
      {active ? (
        <div className="mt-3 grid grid-cols-2 gap-2">
          <button type="button" disabled={disabled} onClick={() => onAction('open')} className={buttonClass.primary}>
            Đi tới khoá học
          </button>
          <button type="button" disabled={disabled} onClick={() => onAction('save')} className={buttonClass.secondary}>
            Lưu để sau
          </button>
          <button type="button" disabled={disabled} onClick={() => onAction('harder')} className={buttonClass.secondary}>
            Luyện cảnh khó hơn
          </button>
          <button type="button" disabled={disabled} onClick={() => onAction('close')} className={buttonClass.ghost}>
            Bỏ qua
          </button>
        </div>
      ) : (
        <Link
          href={`/khoa-hoc/${encodeURIComponent(course.courseId)}`}
          className="mt-2 inline-block text-sm font-semibold text-brand-700 hover:underline"
        >
          Sang Roadmap khoá học →
        </Link>
      )}
    </div>
  );
}

// -------------------------------------------------------------- score card

/** Tầng 4 — thẻ chấm theo rubric của kỹ năng cho cảnh vừa tập. */
export function ScoreCardView({ score }: { score: CoachScore }) {
  return (
    <div className="rounded-xl border border-hairline bg-surface p-4">
      <div className="flex items-baseline justify-between">
        <p className="text-xs font-bold tracking-wide text-brand-700">CÁCH BẠN XỬ LÝ</p>
        <p className="text-xs text-ink-faint">Độ khó {score.level}/5</p>
      </div>
      <p className="mt-1 text-2xl font-bold text-brand-900">
        {score.overall}
        <span className="text-sm font-semibold text-ink-faint">/10</span>
      </p>
      <ul className="mt-2 space-y-1 text-sm">
        {score.criteria.map((criterion) => (
          <li key={criterion.key}>
            <span className="font-semibold text-ink">{criterion.label}</span>{' '}
            <span className="text-ink-muted">{criterion.score}/10</span>
            {criterion.note ? (
              <span className="block text-xs text-ink-muted">{criterion.note}</span>
            ) : null}
          </li>
        ))}
      </ul>
      {[
        ['Làm được:', score.strength],
        ['Sắc hơn được:', score.improve],
        ['Mẹo:', score.tip],
      ].map(([label, value]) =>
        value ? (
          <p key={label} className="mt-2 text-sm text-ink">
            <span className="font-semibold">{label}</span> {value}
          </p>
        ) : null,
      )}
      {score.betterPhrasing ? (
        <div className="mt-3 rounded-lg bg-brand-50 p-3">
          <p className="text-xs font-bold tracking-wide text-brand-700">CÓ THỂ NÓI THẾ NÀY</p>
          <p className="mt-1 text-sm text-ink">{score.betterPhrasing}</p>
        </div>
      ) : null}
      {score.skill && score.skill.score !== null ? (
        <p className="mt-2 text-xs text-ink-muted">
          Điểm kỹ năng {score.skill.score}/100 · {score.skill.scenes} lần tập
          {score.skill.trend !== null && score.skill.trend !== 0
            ? ` · ${score.skill.trend > 0 ? '▲' : '▼'} ${Math.abs(score.skill.trend)}`
            : ''}
        </p>
      ) : null}
    </div>
  );
}

// ----------------------------------------------------------------- safety

/** ⑧ — đường thoát an toàn. Danh sách số rỗng là câu trả lời hợp lệ. */
export function SafetyPanel({ hotlines }: { hotlines: CoachHotline[] }) {
  return (
    <section role="alert" className="rounded-xl border border-red-200 bg-surface p-4">
      <p className="text-xs font-bold tracking-wide text-red-700 uppercase">
        Đường thoát an toàn
      </p>
      <p className="mt-2 font-semibold text-ink">
        Cảm ơn bạn đã nói ra điều này. Mình muốn bạn không phải ở một mình với nó.
      </p>
      <p className="mt-2 text-sm text-ink">
        Nếu bạn đang không an toàn, xin liên hệ cấp cứu tại nơi bạn ở. Nếu có
        một người bạn tin, hãy nói với họ hôm nay.
      </p>
      <div className="mt-3 rounded-lg bg-surface-alt p-3">
        <p className="text-sm font-semibold text-ink">Có người nghe bạn ngay lúc này</p>
        {hotlines.length === 0 ? (
          <p className="mt-1 text-sm text-ink-muted">
            Mình chưa có số đường dây nóng cho khu vực của bạn. Xin liên hệ cấp
            cứu tại địa phương.
          </p>
        ) : (
          <ul className="mt-1 space-y-1">
            {hotlines.map((hotline) => (
              <li key={`${hotline.label}-${hotline.number}`} className="text-sm">
                <span className="text-ink-muted">{hotline.label}: </span>
                <a
                  href={`tel:${hotline.number.replace(/\s+/g, '')}`}
                  className="font-semibold text-brand-700 hover:underline"
                >
                  {hotline.number}
                </a>
              </li>
            ))}
          </ul>
        )}
      </div>
      <p className="mt-3 text-xs text-ink-faint">
        Mình là AI, không thay thế được chuyên gia tâm lý.
      </p>
    </section>
  );
}

// ------------------------------------------------------------- two columns

/**
 * Nhịp 3 — nháp hai cột, toàn bằng lời người đọc. Bấm một dòng để chuyển cột;
 * sửa hoặc xoá dòng model chép sai. Thuần cục bộ cho tới khi câu được gửi.
 */
export function TwoColumns({
  left,
  right,
  onChange,
}: {
  left: string[];
  right: string[];
  onChange: (next: { left: string[]; right: string[] }) => void;
}) {
  const [editing, setEditing] = useState<{ right: boolean; index: number; text: string } | null>(null);

  function move(index: number, fromRight: boolean) {
    const source = [...(fromRight ? right : left)];
    const [line] = source.splice(index, 1);
    const target = [...(fromRight ? left : right), line];
    onChange(fromRight ? { left: target, right: source } : { left: source, right: target });
  }

  function save() {
    if (!editing) return;
    const lines = [...(editing.right ? right : left)];
    // Xoá hết chữ = bỏ dòng, như app.
    if (editing.text.trim()) lines[editing.index] = editing.text.trim();
    else lines.splice(editing.index, 1);
    onChange(editing.right ? { left, right: lines } : { left: lines, right });
    setEditing(null);
  }

  function column(lines: string[], isRight: boolean, title: string) {
    return (
      <div className={`rounded-xl border p-3 ${isRight ? 'border-brand bg-brand-50' : 'border-hairline bg-surface'}`}>
        <p className="text-xs font-bold tracking-wide text-brand-700 uppercase">{title}</p>
        {lines.length === 0 ? (
          <p className="mt-2 text-sm text-ink-faint">Chưa có dòng nào</p>
        ) : (
          <ul className="mt-2 space-y-2">
            {lines.map((line, index) =>
              editing && editing.right === isRight && editing.index === index ? (
                <li key={index} className="space-y-1">
                  <label className="sr-only" htmlFor={`line-${isRight}-${index}`}>
                    Sửa dòng này — xoá hết để bỏ
                  </label>
                  <textarea
                    id={`line-${isRight}-${index}`}
                    value={editing.text}
                    onChange={(event) => setEditing({ ...editing, text: event.target.value })}
                    rows={2}
                    className={`${inputClass} text-sm`}
                  />
                  <button type="button" onClick={save} className={buttonClass.ghost}>
                    Xong
                  </button>
                </li>
              ) : (
                <li key={index} className="flex items-start gap-1">
                  <button
                    type="button"
                    onClick={() => move(index, isRight)}
                    className="flex-1 rounded-lg px-2 py-1 text-left text-sm text-ink hover:bg-brand-100"
                    title="Chạm để chuyển sang cột kia"
                  >
                    {line}
                    <span className="sr-only"> — chuyển sang cột {isRight ? 'trái' : 'phải'}</span>
                  </button>
                  <button
                    type="button"
                    aria-label={`Sửa dòng: ${line}`}
                    onClick={() => setEditing({ right: isRight, index, text: line })}
                    className="rounded-lg px-2 py-1 text-xs font-semibold text-brand-700 hover:bg-brand-100"
                  >
                    Sửa
                  </button>
                </li>
              ),
            )}
          </ul>
        )}
      </div>
    );
  }

  return (
    <div>
      <div className="grid gap-2 sm:grid-cols-2">
        {column(left, false, 'Mình quan sát được')}
        {column(right, true, 'Vấn đề thật của tôi')}
      </div>
      <p className="mt-2 text-xs text-ink-faint">
        Bấm vào một dòng để chuyển sang cột kia. Coach chỉ dựng nháp bằng lời bạn đã kể.
      </p>
    </div>
  );
}

// -------------------------------------------------------------------- plan

/** Nhắc hẹn — "khi nào" và "sẽ làm gì", bằng chữ của người đọc. */
export function PlanForm({
  suggested,
  busy,
  onSave,
}: {
  suggested?: { context: string; action: string } | null;
  busy: boolean;
  onSave: (context: string, action: string) => void;
}) {
  const [context, setContext] = useState(suggested?.context ?? '');
  const [action, setAction] = useState(suggested?.action ?? '');
  const ready = context.trim() && action.trim();
  return (
    <form
      className="space-y-2"
      onSubmit={(event) => {
        event.preventDefault();
        if (ready) onSave(context.trim(), action.trim());
      }}
    >
      <p className="text-xs font-bold tracking-wide text-brand-700 uppercase">
        Nhắc hẹn — chữ của bạn
      </p>
      <label className="sr-only" htmlFor="plan-context">Khi nào?</label>
      <input
        id="plan-context"
        value={context}
        onChange={(event) => setContext(event.target.value)}
        placeholder="Khi nào? vd: khi họp nhóm"
        maxLength={200}
        disabled={busy}
        className={inputClass}
      />
      <label className="sr-only" htmlFor="plan-action">Sẽ làm gì?</label>
      <input
        id="plan-action"
        value={action}
        onChange={(event) => setAction(event.target.value)}
        placeholder="Sẽ làm gì? vd: nói ra ý mình"
        maxLength={200}
        disabled={busy}
        className={inputClass}
      />
      <button type="submit" disabled={busy || !ready} className={`${buttonClass.primary} w-full`}>
        Lưu nhắc hẹn
      </button>
    </form>
  );
}

// ---------------------------------------------------------------- schedule

export interface SchedulePayload {
  reminderEnabled: boolean;
  reminderHour?: number;
  reminderMinute?: number;
  reminderDays?: 'once' | 'daily' | 'custom';
  reminderCustomDays?: number[];
  reminderDate?: string;
}

function isoDate(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

/** Thứ ISO (T2 = 1 … CN = 7) của hôm nay, như `DateTime.weekday` của Dart. */
function isoWeekday(date: Date): number {
  return date.getDay() === 0 ? 7 : date.getDay();
}

/**
 * Giờ nhắc: một lần / hằng ngày / hằng tuần (chọn thứ), hoặc tắt nhắc.
 * Ngày "một lần" là ngày THEO MÁY người đọc — server so với lịch của họ.
 */
export function ScheduleForm({
  busy,
  onSave,
}: {
  busy: boolean;
  onSave: (payload: SchedulePayload, label: string) => void;
}) {
  const [time, setTime] = useState('20:00');
  const [mode, setMode] = useState<'once' | 'daily' | 'weekly'>('daily');
  const [weekdays, setWeekdays] = useState<number[]>(() => [isoWeekday(new Date())]);
  const [onceOffset, setOnceOffset] = useState(0);

  const [hour, minute] = time.split(':').map((part) => Number(part));
  const valid = Number.isInteger(hour) && Number.isInteger(minute);
  const modeLabel = { once: 'Chỉ một lần', daily: 'Hằng ngày', weekly: 'Hằng tuần' }[mode];

  function save() {
    if (!valid) return;
    const label = `Nhắc lúc ${time} · ${modeLabel}`;
    if (mode === 'once') {
      const date = new Date();
      date.setDate(date.getDate() + onceOffset);
      onSave({ reminderEnabled: true, reminderHour: hour, reminderMinute: minute, reminderDays: 'once', reminderDate: isoDate(date) }, label);
    } else if (mode === 'weekly') {
      onSave(
        {
          reminderEnabled: true,
          reminderHour: hour,
          reminderMinute: minute,
          reminderDays: 'custom',
          reminderCustomDays: [...weekdays].sort((a, b) => a - b),
        },
        label,
      );
    } else {
      onSave({ reminderEnabled: true, reminderHour: hour, reminderMinute: minute, reminderDays: 'daily' }, label);
    }
  }

  return (
    <div className="space-y-3">
      <p className="text-xs font-bold tracking-wide text-brand-700 uppercase">Nhắc bạn lúc nào?</p>
      <div className="flex flex-wrap items-center gap-2">
        <label htmlFor="schedule-time" className="text-sm text-ink-muted">Giờ</label>
        <input
          id="schedule-time"
          type="time"
          value={time}
          onChange={(event) => setTime(event.target.value)}
          disabled={busy}
          className="rounded-xl border border-hairline bg-surface px-3 py-2 outline-none focus:border-brand focus:ring-2 focus:ring-brand/30"
        />
      </div>
      <div role="radiogroup" aria-label="Lặp lại" className="flex flex-wrap gap-2">
        {(['once', 'daily', 'weekly'] as const).map((value) => (
          <button
            key={value}
            type="button"
            role="radio"
            aria-checked={mode === value}
            onClick={() => setMode(value)}
            disabled={busy}
            className={`rounded-full border px-3 py-1.5 text-sm font-semibold ${
              mode === value ? 'border-brand bg-brand-100 text-brand-900' : 'border-brand-200 bg-surface text-brand-900'
            }`}
          >
            {{ once: 'Chỉ một lần', daily: 'Hằng ngày', weekly: 'Hằng tuần' }[value]}
          </button>
        ))}
      </div>
      {mode === 'once' ? (
        <div>
          <label htmlFor="schedule-day" className="mb-1 block text-sm text-ink-muted">Ngày</label>
          <select
            id="schedule-day"
            value={onceOffset}
            onChange={(event) => setOnceOffset(Number(event.target.value))}
            disabled={busy}
            className="rounded-xl border border-hairline bg-surface px-3 py-2"
          >
            {Array.from({ length: 7 }, (_, offset) => {
              const date = new Date();
              date.setDate(date.getDate() + offset);
              return (
                <option key={offset} value={offset}>
                  {offset === 0
                    ? 'Hôm nay'
                    : `${DAY_LABELS[isoWeekday(date) - 1]} ${date.getDate()}/${date.getMonth() + 1}`}
                </option>
              );
            })}
          </select>
        </div>
      ) : null}
      {mode === 'weekly' ? (
        <div className="flex flex-wrap gap-1.5" role="group" aria-label="Các thứ trong tuần">
          {DAY_LABELS.map((label, index) => {
            const day = index + 1;
            const on = weekdays.includes(day);
            return (
              <Chip
                key={day}
                selected={on}
                disabled={busy}
                onClick={() =>
                  setWeekdays((current) =>
                    on ? current.filter((d) => d !== day) : [...current, day],
                  )
                }
              >
                {label}
              </Chip>
            );
          })}
        </div>
      ) : null}
      <div className="grid grid-cols-2 gap-2">
        <button
          type="button"
          onClick={save}
          disabled={busy || !valid || (mode === 'weekly' && weekdays.length === 0)}
          className={buttonClass.primary}
        >
          Bật nhắc
        </button>
        <button
          type="button"
          onClick={() => onSave({ reminderEnabled: false }, 'Tắt nhắc.')}
          disabled={busy}
          className={buttonClass.secondary}
        >
          Tắt nhắc
        </button>
      </div>
    </div>
  );
}

// ------------------------------------------------------------ exit feedback

/**
 * Sau "Vẫn đóng": vừa rồi thế nào. Bộ chip theo loại việc server báo;
 * "Để sau" vẫn được ghi — server cần phân biệt "không ai chê" với "không ai
 * buồn trả lời".
 */
export function ExitFeedback({
  kind,
  onDone,
}: {
  kind?: string;
  onDone: (chips: string[], note: string) => void;
}) {
  const [chips, setChips] = useState<string[]>([]);
  const [note, setNote] = useState('');
  const hub = kind === 'hub';
  return (
    <section aria-labelledby="coach-rate-title" className="rounded-xl border border-hairline bg-surface p-4">
      <p id="coach-rate-title" className="font-semibold text-ink">
        {hub ? 'Chưa có gì hợp để bắt đầu à?' : 'Nói chuyện với HDDhistory Coach vừa rồi thế nào?'}
      </p>
      <p className="mt-1 text-sm text-ink-muted">
        {hub
          ? 'Cho mình biết vì sao, để lần sau mở ra đúng thứ bạn cần hơn.'
          : 'Chọn những gì đúng với bạn, rồi viết thêm nếu muốn.'}
      </p>
      <div className="mt-3 flex flex-wrap gap-2">
        {ratingChipsFor(kind).map(([value, label]) => {
          const on = chips.includes(value);
          return (
            <Chip
              key={value}
              selected={on}
              onClick={() =>
                setChips((current) => (on ? current.filter((c) => c !== value) : [...current, value]))
              }
            >
              {label}
            </Chip>
          );
        })}
      </div>
      <label htmlFor="coach-rate-note" className="sr-only">Viết đánh giá của bạn</label>
      <textarea
        id="coach-rate-note"
        value={note}
        onChange={(event) => setNote(event.target.value)}
        maxLength={300}
        rows={3}
        placeholder="Viết đánh giá của bạn..."
        className={`${inputClass} mt-3 text-sm`}
      />
      <div className="mt-3 grid grid-cols-2 gap-2">
        <button type="button" onClick={() => onDone(chips, note)} className={buttonClass.primary}>
          Gửi đánh giá
        </button>
        <button type="button" onClick={() => onDone([], '')} className={buttonClass.secondary}>
          Để sau
        </button>
      </div>
    </section>
  );
}
