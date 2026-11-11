'use client';

/**
 * Mảnh giao diện dùng chung cho mọi dạng câu hỏi, ở cả bài tập keypoint lẫn
 * khởi động/ôn tập. Các mảnh ở đây chỉ VẼ — trạng thái và luật chấm nằm ở
 * component gọi chúng và ở `lib/practice-scoring.ts`.
 *
 * Mọi thao tác đều làm được bằng chuột/chạm và bàn phím (nút thật). Kéo-thả
 * HTML5 chỉ là lối tắt thêm cho ai quen kéo, không bao giờ là cách duy nhất.
 */
import { useState } from 'react';

import { buttonClass } from '@/components/ui-classes';
import { mlText, type ChoiceAnswerState, type SlotState } from '@/lib/practice-scoring';
import type { MultiLang } from '@/lib/content';
import type { QuestionDocument } from '@/lib/practice';

// ---------------------------------------------------------------------------
// Đề bài
// ---------------------------------------------------------------------------

function DocumentBlock({ block }: { block: QuestionDocument }) {
  const content = mlText(block.data.content);
  const url = mlText(block.data.url);
  switch (block.type) {
    case 'title':
      return content ? <p className="text-lg font-bold text-brand-900">{content}</p> : null;
    case 'caption':
      return content ? <p className="text-sm text-ink-faint italic">{content}</p> : null;
    case 'image':
      return url ? (
        // Ảnh từ CDN của API, tên miền không cố định — dùng <img> thường.
        // eslint-disable-next-line @next/next/no-img-element
        <img src={url} alt={content || ''} className="w-full rounded-xl border border-hairline" />
      ) : null;
    case 'video':
      return url ? (
        <video
          controls
          preload="metadata"
          poster={block.data.thumbnail || undefined}
          className="w-full rounded-xl border border-hairline"
        >
          <source src={url} />
        </video>
      ) : null;
    case 'audio':
      return url ? (
        <audio controls preload="metadata" className="w-full">
          <source src={url} />
        </audio>
      ) : null;
    case 'explanation':
      return content ? (
        <div className="rounded-xl bg-brand-50 p-3 text-sm leading-relaxed text-ink-muted">
          {content}
        </div>
      ) : null;
    default:
      return content ? (
        <p className="leading-relaxed font-semibold whitespace-pre-line text-ink">{content}</p>
      ) : null;
  }
}

export function DocumentList({ documents }: { documents: QuestionDocument[] }) {
  if (documents.length === 0) return null;
  return (
    <div className="space-y-2">
      {documents.map((block, index) => (
        <DocumentBlock key={`${block.id}-${index}`} block={block} />
      ))}
    </div>
  );
}

export function QuestionPrompt({
  speechBubble,
  documents,
}: {
  speechBubble: MultiLang;
  documents: QuestionDocument[];
}) {
  const bubble = mlText(speechBubble);
  return (
    <div className="space-y-2">
      {bubble ? (
        <p className="rounded-xl bg-surface-alt px-3 py-2 text-sm text-ink-muted">{bubble}</p>
      ) : null}
      <DocumentList documents={documents} />
    </div>
  );
}

export function Instruction({ children }: { children: React.ReactNode }) {
  return <p className="mt-4 mb-2 text-sm font-semibold text-brand-700">{children}</p>;
}

// ---------------------------------------------------------------------------
// Trạng thái màu dùng chung
// ---------------------------------------------------------------------------

const STATE_CLASS: Record<ChoiceAnswerState, string> = {
  normal: 'border-hairline bg-surface hover:border-brand-300',
  selected: 'border-brand bg-brand-50',
  correct: 'border-emerald-500 bg-emerald-50 text-emerald-900',
  incorrect: 'border-red-400 bg-red-50 text-red-900',
  correctNotSelected: 'border-dashed border-emerald-500 bg-surface text-emerald-900',
  disabled: 'border-hairline bg-surface opacity-60',
};

/** Chữ đọc cho trình đọc màn hình — màu thôi thì người không thấy màu mất thông tin. */
const STATE_LABEL: Partial<Record<ChoiceAnswerState, string>> = {
  correct: 'đúng',
  incorrect: 'sai',
  correctNotSelected: 'đáp án đúng bạn chưa chọn',
};

function StateMark({ state }: { state: ChoiceAnswerState }) {
  const label = STATE_LABEL[state];
  if (!label) return null;
  const symbol = state === 'incorrect' ? '✕' : '✓';
  const tone = state === 'incorrect' ? 'bg-red-500' : 'bg-emerald-500';
  return (
    <span className="ml-auto flex shrink-0 items-center">
      <span
        aria-hidden
        className={`inline-flex size-5 items-center justify-center rounded-md text-xs font-bold text-white ${tone} ${state === 'correctNotSelected' ? 'opacity-60' : ''}`}
      >
        {symbol}
      </span>
      <span className="sr-only">({label})</span>
    </span>
  );
}

// ---------------------------------------------------------------------------
// Trắc nghiệm
// ---------------------------------------------------------------------------

export function ChoiceOptions({
  labels,
  states,
  selected,
  multiple,
  locked,
  onSelect,
}: {
  labels: string[];
  states: ChoiceAnswerState[];
  selected: boolean[];
  multiple: boolean;
  locked: boolean;
  onSelect: (index: number) => void;
}) {
  return (
    <ul className="space-y-2">
      {labels.map((label, index) => {
        const state = states[index] ?? 'normal';
        const isSelected = selected[index] ?? false;
        return (
          <li key={index}>
            <button
              type="button"
              aria-pressed={isSelected}
              disabled={locked}
              onClick={() => onSelect(index)}
              className={`flex w-full items-center gap-3 rounded-xl border-2 px-4 py-3 text-left text-sm font-medium transition focus-visible:ring-2 focus-visible:ring-brand/40 focus-visible:outline-none disabled:cursor-default ${STATE_CLASS[state]}`}
            >
              <span
                aria-hidden
                className={`inline-flex size-5 shrink-0 items-center justify-center border-2 ${multiple ? 'rounded-md' : 'rounded-full'} ${isSelected ? 'border-brand bg-brand text-white' : 'border-ink-faint/50'}`}
              >
                {isSelected ? (multiple ? '✓' : '•') : null}
              </span>
              <span className="leading-relaxed">{label}</span>
              <StateMark state={state} />
            </button>
          </li>
        );
      })}
    </ul>
  );
}

// ---------------------------------------------------------------------------
// Điền chỗ trống
// ---------------------------------------------------------------------------

const DRAG_TYPE = 'text/x-hdd-practice';

export interface GapSlot {
  label?: string;
  state: SlotState;
}

const SLOT_CLASS: Record<SlotState, string> = {
  normal: 'border-brand-300 bg-brand-50 text-brand-900',
  correct: 'border-emerald-500 bg-emerald-50 text-emerald-900',
  incorrect: 'border-red-400 bg-red-50 text-red-900',
};

/**
 * Câu có chỗ trống (`___`). Chạm vào ô đã điền để trả chữ về ngân hàng; thả
 * một chữ kéo từ ngân hàng vào ô trống để điền đúng ô đó.
 */
export function GapSentence({
  text,
  slots,
  locked,
  onClear,
  onDropWord,
}: {
  text: string;
  slots: GapSlot[];
  locked: boolean;
  onClear: (slot: number) => void;
  onDropWord: (slot: number, key: number) => void;
}) {
  const parts = text.split('___');
  const nodes: React.ReactNode[] = [];
  const slotNode = (index: number) => {
    const slot = slots[index];
    if (!slot) return null;
    if (slot.label) {
      return (
        <button
          key={`slot-${index}`}
          type="button"
          disabled={locked}
          onClick={() => onClear(index)}
          aria-label={locked ? `Ô ${index + 1}: ${slot.label}` : `Ô ${index + 1}: ${slot.label}. Chạm để bỏ`}
          className={`mx-1 inline-flex min-w-16 items-center justify-center rounded-lg border-2 px-2 py-0.5 align-baseline font-semibold focus-visible:ring-2 focus-visible:ring-brand/40 focus-visible:outline-none disabled:cursor-default ${SLOT_CLASS[slot.state]}`}
        >
          {slot.label}
          {slot.state !== 'normal' ? (
            <span className="sr-only">({slot.state === 'correct' ? 'đúng' : 'sai'})</span>
          ) : null}
        </button>
      );
    }
    return (
      <span
        key={`slot-${index}`}
        role="img"
        aria-label={`Ô trống ${index + 1}`}
        onDragOver={(event) => {
          if (!locked && event.dataTransfer.types.includes(DRAG_TYPE)) event.preventDefault();
        }}
        onDrop={(event) => {
          event.preventDefault();
          const key = Number(event.dataTransfer.getData(DRAG_TYPE));
          if (!locked && Number.isInteger(key)) onDropWord(index, key);
        }}
        className="mx-1 inline-block h-7 min-w-16 rounded-lg border-2 border-dashed border-ink-faint/50 align-middle"
      />
    );
  };

  parts.forEach((part, index) => {
    if (part) nodes.push(<span key={`text-${index}`}>{part}</span>);
    if (index < parts.length - 1) nodes.push(slotNode(index));
  });
  // Ít dấu `___` hơn số ô: các ô còn lại xếp cuối câu cho vẫn điền được.
  for (let index = Math.max(parts.length - 1, 0); index < slots.length; index++) {
    nodes.push(slotNode(index));
  }

  return (
    <p className="rounded-xl border-2 border-hairline bg-surface px-3 py-3 text-base leading-[2.4] font-medium text-ink">
      {nodes}
    </p>
  );
}

/** Ngân hàng chữ: chạm một chữ để điền vào ô trống đầu tiên. */
export function WordBank({
  words,
  locked,
  onPick,
}: {
  words: { key: number; label: string; used: boolean }[];
  locked: boolean;
  onPick: (key: number) => void;
}) {
  return (
    <ul className="flex flex-wrap gap-2">
      {words.map((word) => (
        <li key={word.key}>
          <button
            type="button"
            disabled={locked || word.used}
            draggable={!locked && !word.used}
            onDragStart={(event) => {
              event.dataTransfer.setData(DRAG_TYPE, String(word.key));
              event.dataTransfer.effectAllowed = 'move';
            }}
            onClick={() => onPick(word.key)}
            aria-label={word.used ? `${word.label} (đã dùng)` : word.label}
            className={`rounded-lg border-2 px-3 py-1.5 text-sm font-semibold transition focus-visible:ring-2 focus-visible:ring-brand/40 focus-visible:outline-none ${
              word.used
                ? 'border-dashed border-hairline bg-surface-alt text-transparent'
                : 'border-brand-200 bg-surface text-brand-900 hover:bg-brand-50 disabled:cursor-default'
            }`}
          >
            {word.label}
          </button>
        </li>
      ))}
    </ul>
  );
}

// ---------------------------------------------------------------------------
// Đặt dấu ngắt / đánh dấu từ
// ---------------------------------------------------------------------------

/**
 * Câu tách thành từng từ bấm được. Với dấu ngắt, bấm một từ để đặt (hoặc bỏ)
 * dấu NGAY SAU từ đó; với đánh dấu từ, bấm để chọn/bỏ chọn.
 */
export function WordPicker({
  words,
  states,
  marks,
  locked,
  describe,
  onToggle,
}: {
  words: string[];
  states: (ChoiceAnswerState | null)[];
  /** Dấu đang đặt sau từ thứ i (chỉ dạng dấu ngắt). */
  marks?: (string | null)[];
  locked: boolean;
  describe: (word: string, index: number) => string;
  onToggle: (index: number) => void;
}) {
  return (
    <div className="flex flex-wrap items-center gap-x-1 gap-y-2 rounded-xl border-2 border-hairline bg-surface px-3 py-3">
      {words.map((word, index) => {
        const state = states[index];
        const mark = marks?.[index] ?? null;
        const markState = marks ? state : null;
        const wordState = marks ? null : state;
        return (
          <span key={index} className="inline-flex items-center gap-1">
            <button
              type="button"
              disabled={locked}
              onClick={() => onToggle(index)}
              aria-pressed={marks ? mark !== null : wordState === 'selected'}
              aria-label={describe(word, index)}
              className={`rounded-lg border-2 px-1.5 py-0.5 text-base font-medium focus-visible:ring-2 focus-visible:ring-brand/40 focus-visible:outline-none disabled:cursor-default ${
                wordState ? STATE_CLASS[wordState] : 'border-transparent hover:border-brand-200'
              }`}
            >
              {word}
            </button>
            {marks && (mark !== null || markState === 'correctNotSelected') ? (
              <span
                className={`rounded-md border-2 px-1.5 text-sm font-bold ${STATE_CLASS[markState ?? 'selected']}`}
              >
                {mark ?? '•'}
                {markState && STATE_LABEL[markState] ? (
                  <span className="sr-only"> ({STATE_LABEL[markState]})</span>
                ) : null}
              </span>
            ) : null}
          </span>
        );
      })}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Sắp xếp thứ tự
// ---------------------------------------------------------------------------

export function ArrangeList({
  items,
  locked,
  onMove,
}: {
  items: { key: number; label: string; state: SlotState; correctPosition?: number | null }[];
  locked: boolean;
  onMove: (from: number, to: number) => void;
}) {
  const [dragFrom, setDragFrom] = useState<number | null>(null);
  return (
    <ol className="space-y-2">
      {items.map((item, index) => (
        <li
          key={item.key}
          draggable={!locked}
          onDragStart={(event) => {
            setDragFrom(index);
            event.dataTransfer.setData(DRAG_TYPE, String(index));
            event.dataTransfer.effectAllowed = 'move';
          }}
          onDragOver={(event) => {
            if (!locked && dragFrom !== null) event.preventDefault();
          }}
          onDrop={(event) => {
            event.preventDefault();
            if (!locked && dragFrom !== null && dragFrom !== index) onMove(dragFrom, index);
            setDragFrom(null);
          }}
          onDragEnd={() => setDragFrom(null)}
          className={`flex items-center gap-3 rounded-xl border-2 px-3 py-2.5 text-sm font-medium ${STATE_CLASS[item.state]} ${dragFrom === index ? 'opacity-50' : ''}`}
        >
          <span
            aria-hidden
            className={`inline-flex size-7 shrink-0 items-center justify-center rounded-full text-xs font-bold ${
              item.state === 'normal'
                ? 'bg-brand-100 text-brand-900'
                : item.state === 'correct'
                  ? 'bg-emerald-500 text-white'
                  : 'bg-red-500 text-white'
            }`}
          >
            {item.state === 'incorrect' && item.correctPosition ? item.correctPosition : index + 1}
          </span>
          <span className="flex-1 leading-relaxed">
            {item.label}
            {item.state !== 'normal' ? (
              <span className="sr-only">
                {item.state === 'correct'
                  ? ' (đúng vị trí)'
                  : item.correctPosition
                    ? ` (sai, đúng là vị trí ${item.correctPosition})`
                    : ' (sai vị trí)'}
              </span>
            ) : null}
          </span>
          {!locked ? (
            <span className="flex shrink-0 gap-1">
              <button
                type="button"
                disabled={index === 0}
                onClick={() => onMove(index, index - 1)}
                aria-label={`Đưa "${item.label}" lên`}
                className={`${buttonClass.ghost} px-2 py-1`}
              >
                ↑
              </button>
              <button
                type="button"
                disabled={index === items.length - 1}
                onClick={() => onMove(index, index + 1)}
                aria-label={`Đưa "${item.label}" xuống`}
                className={`${buttonClass.ghost} px-2 py-1`}
              >
                ↓
              </button>
            </span>
          ) : null}
        </li>
      ))}
    </ol>
  );
}

// ---------------------------------------------------------------------------
// Đáp án đúng + giải thích
// ---------------------------------------------------------------------------

/** Câu mẫu: phần chữ đề nhạt, phần đáp án đậm. */
export function SentenceAnswer({ spans }: { spans: { text: string; strong: boolean }[] }) {
  return (
    <p className="text-base leading-relaxed font-semibold">
      {spans.map((span, index) =>
        span.strong ? (
          <strong key={index} className="text-ink">
            {span.text}
          </strong>
        ) : (
          <span key={index} className="text-ink-faint">
            {span.text}
          </span>
        ),
      )}
    </p>
  );
}

export function CorrectAnswerBlock({ children }: { children: React.ReactNode }) {
  return (
    <div className="mt-3">
      <p className="text-sm font-bold text-emerald-700">Câu trả lời đúng</p>
      <div className="mt-1">{children}</div>
    </div>
  );
}

export type Verdict = 'correct' | 'incorrect' | 'neutral';

/**
 * Khối kết quả sau khi kiểm tra. `explanationMode`:
 * - `inline`: giải thích hiện luôn (thẻ bài tập keypoint của app);
 * - `toggle`: nút "Giải thích"/"Đóng" như tấm kết quả của app.
 */
export function ResultBox({
  verdict,
  title,
  explanation,
  explanationMode,
  answer,
  children,
}: {
  verdict: Verdict;
  title: string;
  explanation: string;
  explanationMode: 'inline' | 'toggle';
  /** Đáp án đúng — trong chế độ `toggle` chỉ hiện khi mở giải thích (như app). */
  answer?: React.ReactNode;
  children?: React.ReactNode;
}) {
  const [open, setOpen] = useState(false);
  const tone =
    verdict === 'correct'
      ? 'bg-emerald-50 text-emerald-800'
      : verdict === 'neutral'
        ? 'bg-brand-50 text-brand-700'
        : 'bg-red-50 text-red-800';
  const showDetails = explanationMode === 'inline' || open;
  return (
    <div className="mt-4" role="status">
      {explanationMode === 'inline' && answer ? answer : null}
      <div className={`mt-3 rounded-2xl px-4 py-3 ${tone}`}>
        <p className="font-bold">{title}</p>
        {explanationMode === 'inline' && explanation ? (
          <p className="mt-2 text-sm leading-relaxed whitespace-pre-line text-ink-muted">
            {explanation}
          </p>
        ) : null}
      </div>
      {explanationMode === 'toggle' && (explanation || answer) ? (
        <>
          <button
            type="button"
            aria-expanded={open}
            onClick={() => setOpen((value) => !value)}
            className={`${buttonClass.ghost} mt-2`}
          >
            {open ? 'Đóng' : 'Giải thích'}
          </button>
          {showDetails ? (
            <div className="mt-2 rounded-xl border border-hairline bg-surface p-3">
              {answer}
              {explanation ? (
                <div className={answer ? 'mt-3 border-t border-hairline pt-3' : ''}>
                  <p className="text-sm font-bold text-ink">Giải thích</p>
                  <p className="mt-1 text-sm leading-relaxed whitespace-pre-line text-ink-muted">
                    {explanation}
                  </p>
                </div>
              ) : null}
            </div>
          ) : null}
        </>
      ) : null}
      {children}
    </div>
  );
}

/** Câu nói (ghi âm + chấm giọng ở dịch vụ ngoài) — web không làm được. */
export function SpeakingSkip({
  speechBubble,
  documents,
  onSkip,
  skipLabel = 'Tiếp',
}: {
  speechBubble: MultiLang;
  documents: QuestionDocument[];
  onSkip: () => void;
  skipLabel?: string;
}) {
  return (
    <div>
      <QuestionPrompt speechBubble={speechBubble} documents={documents} />
      <div className="mt-4 rounded-xl border border-dashed border-brand-300 bg-brand-50 p-4 text-sm text-ink-muted">
        <p className="font-semibold text-brand-900">Câu nói chỉ làm được trên ứng dụng</p>
        <p className="mt-1">
          Câu này cần ghi âm giọng nói và chấm điểm phát âm — hãy làm trên ứng dụng di
          động. Bạn có thể bỏ qua để làm tiếp.
        </p>
      </div>
      <div className="mt-4 flex justify-end">
        <button type="button" onClick={onSkip} className={buttonClass.secondary}>
          {skipLabel}
        </button>
      </div>
    </div>
  );
}

export function UnsupportedSkip({ onSkip }: { onSkip: () => void }) {
  return (
    <div>
      <p className="rounded-xl border border-dashed border-hairline bg-surface-alt p-4 text-sm text-ink-muted">
        Dạng câu hỏi này chưa làm được trên web.
      </p>
      <div className="mt-4 flex justify-end">
        <button type="button" onClick={onSkip} className={buttonClass.secondary}>
          Tiếp
        </button>
      </div>
    </div>
  );
}

export function CheckButton({
  enabled,
  onCheck,
  label = 'Kiểm tra',
}: {
  enabled: boolean;
  onCheck: () => void;
  label?: string;
}) {
  return (
    <div className="mt-5 flex justify-center">
      <button
        type="button"
        disabled={!enabled}
        onClick={onCheck}
        className={`${buttonClass.primary} min-w-40 rounded-full`}
      >
        {label}
      </button>
    </div>
  );
}
