'use client';

/**
 * Một câu trong trình khởi động/ôn tập — `DailyWarmUpQuestionStep` của app,
 * dùng chung cho khởi động hằng ngày, khởi động khoá học và ôn tập ngắt
 * quãng (app chiếu cả ba về cùng một `DailyWarmUpState`).
 *
 * Luật ở đây KHÁC bài tập keypoint: chấm bằng `evaluateWarmUpQuestion` (chọn
 * đúng và đủ, so theo id phương án), không có điểm, không ghi tiến độ.
 */
import { useState } from 'react';

import { buttonClass } from '@/components/ui-classes';
import type { Question } from '@/lib/practice';
import {
  EMPTY_WARM_UP_DRAFT,
  canCheckWarmUp,
  evaluateWarmUpQuestion,
  mlText,
  optionLabel,
  questionKind,
  runtimeAnswers,
  runtimeOptions,
  warmUpChoiceState,
  warmUpOptions,
  warmUpWords,
  type ChoiceAnswerState,
  type SlotState,
  type WarmUpDraft,
  type WarmUpResult,
} from '@/lib/practice-scoring';

import { gapSpans, positionSpans } from './answer-spans';
import {
  ArrangeList,
  CheckButton,
  ChoiceOptions,
  CorrectAnswerBlock,
  GapSentence,
  Instruction,
  QuestionPrompt,
  ResultBox,
  SentenceAnswer,
  WordBank,
  WordPicker,
} from './question-parts';

export function WarmUpQuestion({
  question,
  questionIndex,
  onChecked,
  onContinue,
}: {
  question: Question;
  questionIndex: number;
  onChecked: (result: WarmUpResult) => void;
  onContinue: () => void;
}) {
  const [draft, setDraft] = useState<WarmUpDraft>(EMPTY_WARM_UP_DRAFT);
  const [result, setResult] = useState<WarmUpResult | null>(null);
  const kind = questionKind(question);
  const locked = result !== null;

  function update(change: Partial<WarmUpDraft>) {
    if (locked) return;
    setDraft((current) => ({ ...current, ...change }));
  }

  function check() {
    if (locked || !canCheckWarmUp(question, draft)) return;
    const evaluated = evaluateWarmUpQuestion(question, draft, questionIndex);
    setResult(evaluated);
    onChecked(evaluated);
  }

  let body: React.ReactNode = null;
  let answer: React.ReactNode = null;

  if (kind === 'single' || kind === 'multiple' || kind === 'no_correct') {
    const multiple = kind === 'multiple';
    const options = runtimeOptions(question);
    body = (
      <>
        <Instruction>
          {multiple
            ? 'Chọn tất cả đáp án đúng'
            : kind === 'no_correct'
              ? 'Chọn phương án phù hợp với bạn'
              : 'Chọn đáp án đúng nhất'}
        </Instruction>
        <ChoiceOptions
          labels={options.map(optionLabel)}
          states={options.map((_, index) => warmUpChoiceState(question, draft, index, result))}
          selected={options.map((_, index) =>
            multiple
              ? draft.selectedAnswersIndices.includes(index)
              : draft.selectedAnswerIndex === index,
          )}
          multiple={multiple}
          locked={locked}
          onSelect={(index) =>
            multiple
              ? update({
                  selectedAnswersIndices: draft.selectedAnswersIndices.includes(index)
                    ? draft.selectedAnswersIndices.filter((i) => i !== index)
                    : [...draft.selectedAnswersIndices, index],
                })
              : update({ selectedAnswerIndex: index })
          }
        />
      </>
    );
  } else if (kind === 'gap_filling') {
    const options = warmUpOptions(question);
    const slotCount = question.answer.length;
    const placed = draft.placedOptionIds;
    const usedIds = new Set(Object.values(placed));
    const byId = new Map(options.map((option) => [option.id, option]));
    // `placeOption`: một ô một chữ, một chữ một ô.
    const place = (slot: number, optionId: number) => {
      const next: Record<number, number> = {};
      for (const [key, value] of Object.entries(placed)) {
        if (Number(key) !== slot && value !== optionId) next[Number(key)] = value;
      }
      next[slot] = optionId;
      update({ placedOptionIds: next });
    };
    const slotState = (slot: number): SlotState => {
      const id = placed[slot];
      if (!result || id === undefined || slot >= result.correctOptionIds.length) return 'normal';
      return id === result.correctOptionIds[slot] ? 'correct' : 'incorrect';
    };
    const target = mlText(question.targetArea);
    body = (
      <>
        <div className="mt-4">
          <GapSentence
            text={target}
            slots={Array.from({ length: slotCount }, (_, slot) => {
              const option = byId.get(placed[slot]);
              return { label: option ? optionLabel(option) : undefined, state: slotState(slot) };
            })}
            locked={locked}
            onClear={(slot) => {
              const next = { ...placed };
              delete next[slot];
              update({ placedOptionIds: next });
            }}
            onDropWord={(slot, id) => {
              if (placed[slot] === undefined && !usedIds.has(id)) place(slot, id);
            }}
          />
        </div>
        <Instruction>Chạm vào từ để điền vào chỗ trống</Instruction>
        <WordBank
          words={options.map((option) => ({
            key: option.id,
            label: optionLabel(option),
            used: usedIds.has(option.id),
          }))}
          locked={locked}
          onPick={(id) => {
            if (usedIds.has(id)) return;
            for (let slot = 0; slot < slotCount; slot++) {
              if (placed[slot] === undefined) return place(slot, id);
            }
          }}
        />
      </>
    );
    const labels = correctLabels(question, result);
    answer = (
      <CorrectAnswerBlock>
        <SentenceAnswer spans={gapSpans(target, labels)} />
      </CorrectAnswerBlock>
    );
  } else if (kind === 'arrange') {
    const options = warmUpOptions(question);
    // Chưa kéo lần nào thì giữ thứ tự gốc (`_orderedOptions`).
    const ordered = [
      ...draft.orderedOptionIds
        .map((id) => options.find((option) => option.id === id))
        .filter((option): option is NonNullable<typeof option> => !!option),
      ...options.filter((option) => !draft.orderedOptionIds.includes(option.id)),
    ];
    body = (
      <>
        <Instruction>Sắp xếp theo thứ tự</Instruction>
        <ArrangeList
          items={ordered.map((option, index) => ({
            key: option.id,
            label: optionLabel(option),
            state: !result
              ? 'normal'
              : index < result.correctOptionIds.length &&
                  option.id === result.correctOptionIds[index]
                ? 'correct'
                : 'incorrect',
          }))}
          locked={locked}
          onMove={(from, to) => {
            if (to < 0 || to >= ordered.length) return;
            const ids = ordered.map((option) => option.id);
            const [moved] = ids.splice(from, 1);
            ids.splice(to, 0, moved);
            update({ orderedOptionIds: ids });
          }}
        />
      </>
    );
    answer = (
      <CorrectAnswerBlock>
        <ol className="list-decimal space-y-1 pl-5 text-sm text-ink-muted">
          {correctLabels(question, result).map((label, index) => (
            <li key={index}>{label}</li>
          ))}
        </ol>
      </CorrectAnswerBlock>
    );
  } else if (kind === 'cues') {
    const words = warmUpWords(question);
    const options = warmUpOptions(question);
    const placed = draft.placedOptionIds;
    const usedIds = new Set(Object.values(placed));
    const available = options.filter((option) => !usedIds.has(option.id));
    const markOf = (id: number | undefined) => {
      const option = options.find((item) => item.id === id);
      return option ? optionLabel(option) : null;
    };
    const markState = (index: number): ChoiceAnswerState | null => {
      const isPlaced = placed[index] !== undefined;
      if (!result) return isPlaced ? 'selected' : null;
      if (isPlaced) return result.correctIndices.includes(index) ? 'correct' : 'incorrect';
      return null;
    };
    body = (
      <>
        <Instruction>Đánh dấu trọng âm</Instruction>
        <p className="mb-2 text-xs text-ink-faint">
          Chạm vào một từ để đặt dấu ngắt ngay sau từ đó, chạm lại để bỏ. Còn{' '}
          {available.length} dấu.
        </p>
        <WordPicker
          words={words}
          states={words.map((_, index) => markState(index))}
          marks={words.map((_, index) => markOf(placed[index]))}
          locked={locked}
          describe={(word, index) =>
            placed[index] !== undefined
              ? `${word} — đã đặt dấu ngắt sau từ này`
              : `${word} — đặt dấu ngắt sau từ này`
          }
          onToggle={(index) => {
            if (placed[index] !== undefined) {
              const next = { ...placed };
              delete next[index];
              update({ placedOptionIds: next });
            } else if (available.length) {
              update({ placedOptionIds: { ...placed, [index]: available[0].id } });
            }
          }}
        />
      </>
    );
    const mark = options[0] ? optionLabel(options[0]) : '/';
    answer = (
      <CorrectAnswerBlock>
        <SentenceAnswer
          spans={positionSpans(words, result?.correctIndices ?? [], { suffix: ` ${mark}` })}
        />
      </CorrectAnswerBlock>
    );
  } else if (kind === 'stress') {
    const words = warmUpWords(question);
    const selected = draft.selectedWordIndices;
    const wordState = (index: number): ChoiceAnswerState => {
      const isSelected = selected.includes(index);
      if (!result) return isSelected ? 'selected' : 'normal';
      const isCorrect = result.correctIndices.includes(index);
      if (isCorrect && isSelected) return 'correct';
      if (isSelected) return 'incorrect';
      if (isCorrect) return 'correctNotSelected';
      return 'disabled';
    };
    body = (
      <>
        <Instruction>Đánh dấu trọng âm</Instruction>
        <WordPicker
          words={words}
          states={words.map((_, index) => wordState(index))}
          locked={locked}
          describe={(word) => word}
          onToggle={(index) =>
            update({
              selectedWordIndices: selected.includes(index)
                ? selected.filter((i) => i !== index)
                : [...selected, index],
            })
          }
        />
      </>
    );
    answer = (
      <CorrectAnswerBlock>
        <SentenceAnswer
          spans={positionSpans(words, result?.correctIndices ?? [], { uppercase: true })}
        />
      </CorrectAnswerBlock>
    );
  }

  const title =
    result?.type === 'neutral'
      ? 'Đã lưu câu trả lời'
      : result?.isCorrect
        ? 'Chính xác!'
        : 'Không đúng!';

  return (
    <div>
      <QuestionPrompt speechBubble={question.speechBubble} documents={question.document} />
      {body}
      {!result ? (
        <CheckButton enabled={canCheckWarmUp(question, draft)} onCheck={check} />
      ) : (
        <ResultBox
          verdict={result.type === 'neutral' ? 'neutral' : result.isCorrect ? 'correct' : 'incorrect'}
          title={title}
          explanation={mlText(question.explanation).trim()}
          explanationMode="toggle"
          answer={answer ?? undefined}
        >
          <div className="mt-4 flex justify-end">
            <button type="button" onClick={onContinue} className={buttonClass.primary}>
              Tiếp tục
            </button>
          </div>
        </ResultBox>
      )}
    </div>
  );
}

/** `_correctOptionLabels`: nhãn theo id đúng, không có thì lấy chữ đáp án. */
function correctLabels(question: Question, result: WarmUpResult | null): string[] {
  const byId = new Map(runtimeOptions(question).map((option) => [option.id, optionLabel(option)]));
  const labels = (result?.correctOptionIds ?? [])
    .map((id) => (byId.get(id) ?? '').trim())
    .filter(Boolean);
  if (labels.length) return labels;
  return runtimeAnswers(question)
    .map((answer) => mlText(answer.correctAnswer).trim())
    .filter(Boolean);
}
