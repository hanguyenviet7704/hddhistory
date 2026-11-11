'use client';

/**
 * Một câu bài tập trong keypoint — luật của các cubit
 * `lib/src/lesson/presentation/cubits/{choice,drag_and_drop,cues_placement,
 * mark_stress_word,arrange_the_sequence}` của app.
 *
 * Mỗi dạng tự giữ bài làm của nó; khi bấm "Kiểm tra" nó chấm bằng
 * `practice-scoring.ts`, dựng payload tiến độ y như app rồi báo lên qua
 * `onChecked`. Component cha quyết định có ghi tiến độ hay không.
 */
import { useState } from 'react';

import { buttonClass } from '@/components/ui-classes';
import type { Question } from '@/lib/practice';
import {
  arrangeCorrectOrder,
  arrangeCorrectPositionFor,
  arrangeItemState,
  buildArrangeProgress,
  buildChoiceProgress,
  buildCuesProgress,
  buildGapFillingProgress,
  buildStressProgress,
  checkArrange,
  checkGapFilling,
  checkPositions,
  choiceAnswerState,
  correctPositions,
  cueMarkState,
  gapDropZoneCount,
  gapFirstEmptySlot,
  gapIsAllFilled,
  gapSlotState,
  gradeChoice,
  lessonWords,
  mlText,
  noCorrectDocumentGroup,
  optionLabel,
  questionKind,
  runtimeAnswers,
  runtimeOptions,
  scoreArrange,
  scoreGapFilling,
  scorePositions,
  stressWordState,
  targetAreaText,
  type ExerciseProgressData,
  type PlacedWords,
  type RuntimeOption,
} from '@/lib/practice-scoring';

import { gapSpans, positionSpans } from './answer-spans';
import {
  ArrangeList,
  CheckButton,
  ChoiceOptions,
  CorrectAnswerBlock,
  DocumentList,
  GapSentence,
  Instruction,
  QuestionPrompt,
  ResultBox,
  SentenceAnswer,
  SpeakingSkip,
  UnsupportedSkip,
  WordBank,
  WordPicker,
} from './question-parts';

export interface LessonCheck {
  isCorrect: boolean;
  /** Câu "không có đáp án đúng" không tính vào đúng/sai và không gọi câu phụ. */
  neutral: boolean;
  progress: ExerciseProgressData;
}

interface Props {
  question: Question;
  onChecked: (check: LessonCheck) => void;
  onNext: () => void;
  nextLabel: string;
}

// Chữ trên thẻ bài tập (exercise.yaml / lesson.yaml của app).
const INLINE_CORRECT = 'Chính xác!';
const INLINE_WRONG = 'Sai';
const SHEET_CORRECT = 'Chính xác!';
const SHEET_WRONG = 'Không đúng!';

function NextButton({ onNext, label }: { onNext: () => void; label: string }) {
  return (
    <div className="mt-4 flex justify-end">
      <button type="button" onClick={onNext} className={buttonClass.primary}>
        {label}
      </button>
    </div>
  );
}

export function LessonQuestion(props: Props) {
  const { question, onNext } = props;
  switch (questionKind(question)) {
    case 'single':
    case 'multiple':
    case 'no_correct':
      return <LessonChoice {...props} />;
    case 'gap_filling':
      return <LessonGapFilling {...props} />;
    case 'cues':
      return <LessonCues {...props} />;
    case 'stress':
      return <LessonStress {...props} />;
    case 'arrange':
      return <LessonArrange {...props} />;
    case 'speaking':
      return (
        <SpeakingSkip
          speechBubble={question.speechBubble}
          documents={question.document}
          onSkip={onNext}
        />
      );
    default:
      return <UnsupportedSkip onSkip={onNext} />;
  }
}

// ---------------------------------------------------------------------------

function LessonChoice({ question, onChecked, onNext, nextLabel }: Props) {
  const kind = questionKind(question);
  const multiple = kind === 'multiple';
  const [selectedAnswerIndex, setSelectedAnswerIndex] = useState(-1);
  const [selectedAnswersIndices, setSelectedAnswersIndices] = useState<number[]>([]);
  const [checked, setChecked] = useState<{ isCorrect: boolean } | null>(null);

  const selection = { selectedAnswerIndex, selectedAnswersIndices };
  const options = runtimeOptions(question);
  const canCheck = multiple ? selectedAnswersIndices.length > 0 : selectedAnswerIndex !== -1;

  function select(index: number) {
    if (checked) return;
    if (multiple) {
      setSelectedAnswersIndices((current) =>
        current.includes(index) ? current.filter((i) => i !== index) : [...current, index],
      );
    } else {
      setSelectedAnswerIndex(index);
    }
  }

  function check() {
    if (!canCheck || checked) return;
    const graded = gradeChoice(question, selection);
    setChecked({ isCorrect: graded.isCorrect });
    onChecked({
      isCorrect: graded.isCorrect,
      neutral: kind === 'no_correct',
      progress: buildChoiceProgress(question, selection, graded),
    });
  }

  const group = checked ? noCorrectDocumentGroup(question, selectedAnswerIndex) : null;

  return (
    <div>
      <QuestionPrompt speechBubble={question.speechBubble} documents={question.document} />
      <Instruction>
        {multiple
          ? 'Chọn tất cả đáp án đúng'
          : kind === 'no_correct'
            ? 'Chọn phương án phù hợp với bạn'
            : 'Chọn đáp án đúng nhất'}
      </Instruction>
      <ChoiceOptions
        labels={options.map(optionLabel)}
        states={options.map((_, index) =>
          choiceAnswerState(question, selection, checked !== null, index),
        )}
        selected={options.map((_, index) =>
          multiple ? selectedAnswersIndices.includes(index) : selectedAnswerIndex === index,
        )}
        multiple={multiple}
        locked={checked !== null}
        onSelect={select}
      />
      {!checked ? (
        <CheckButton enabled={canCheck} onCheck={check} label="Kiểm tra đáp án" />
      ) : kind === 'no_correct' ? (
        // Phương án có nhóm tài liệu riêng thì hiện tài liệu đó (app mở một
        // tấm riêng); không có thì báo xong như tấm kết quả của app.
        group && group.documents.length ? (
          <div className="mt-4 rounded-xl border border-hairline bg-surface-alt p-4">
            <DocumentList documents={group.documents} />
            <NextButton onNext={onNext} label={nextLabel} />
          </div>
        ) : (
          <ResultBox
            verdict="neutral"
            title="Hoàn thành bài học!"
            explanation=""
            explanationMode="toggle"
          >
            <NextButton onNext={onNext} label={nextLabel} />
          </ResultBox>
        )
      ) : (
        <ResultBox
          verdict={checked.isCorrect ? 'correct' : 'incorrect'}
          title={checked.isCorrect ? INLINE_CORRECT : INLINE_WRONG}
          explanation={mlText(question.explanation)}
          explanationMode="inline"
        >
          <NextButton onNext={onNext} label={nextLabel} />
        </ResultBox>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------

function LessonGapFilling({ question, onChecked, onNext, nextLabel }: Props) {
  const options = runtimeOptions(question);
  // Ô → chỉ số phương án. Giữ chỉ số (không giữ chữ như app) để hai chữ trùng
  // nhau không "nuốt" mất nhau khi trả về ngân hàng; luật chấm vẫn so CHỮ.
  const [placed, setPlaced] = useState<Record<number, number>>({});
  const [checked, setChecked] = useState<{ isCorrect: boolean } | null>(null);

  const placedWords: PlacedWords = Object.fromEntries(
    Object.entries(placed).map(([slot, index]) => [slot, optionLabel(options[index])]),
  );
  const slotCount = gapDropZoneCount(question);
  const used = new Set(Object.values(placed));

  function pick(key: number) {
    if (checked || used.has(key)) return;
    const slot = gapFirstEmptySlot(question, placedWords);
    if (slot === null) return;
    setPlaced({ ...placed, [slot]: key });
  }

  function drop(slot: number, key: number) {
    if (checked || used.has(key) || placed[slot] !== undefined || slot >= slotCount) return;
    setPlaced({ ...placed, [slot]: key });
  }

  function clear(slot: number) {
    if (checked) return;
    const next = { ...placed };
    delete next[slot];
    setPlaced(next);
  }

  function check() {
    if (checked || !gapIsAllFilled(question, placedWords)) return;
    const graded = {
      isCorrect: checkGapFilling(question, placedWords),
      score: scoreGapFilling(question, placedWords),
    };
    setChecked({ isCorrect: graded.isCorrect });
    onChecked({
      isCorrect: graded.isCorrect,
      neutral: false,
      progress: buildGapFillingProgress(question, placedWords, graded),
    });
  }

  const target = targetAreaText(question);
  return (
    <div>
      <QuestionPrompt speechBubble={question.speechBubble} documents={question.document} />
      <div className="mt-4">
        <GapSentence
          text={target}
          slots={Array.from({ length: slotCount }, (_, slot) => ({
            label: placedWords[slot],
            state: gapSlotState(question, placedWords, checked !== null, slot),
          }))}
          locked={checked !== null}
          onClear={clear}
          onDropWord={drop}
        />
      </div>
      <Instruction>Chạm vào từ để điền vào chỗ trống</Instruction>
      <WordBank
        words={options
          .map((option, key) => ({ key, label: optionLabel(option), used: used.has(key) }))
          .filter((word) => word.label !== '')}
        locked={checked !== null}
        onPick={pick}
      />
      {!checked ? (
        <CheckButton
          enabled={gapIsAllFilled(question, placedWords)}
          onCheck={check}
          label="Kiểm tra đáp án"
        />
      ) : (
        <ResultBox
          verdict={checked.isCorrect ? 'correct' : 'incorrect'}
          title={checked.isCorrect ? INLINE_CORRECT : INLINE_WRONG}
          explanation={mlText(question.explanation)}
          explanationMode="inline"
          answer={
            checked.isCorrect ? undefined : (
              <CorrectAnswerBlock>
                <SentenceAnswer
                  spans={gapSpans(
                    target,
                    runtimeAnswers(question).map((answer) => mlText(answer.correctAnswer)),
                  )}
                />
              </CorrectAnswerBlock>
            )
          }
        >
          <NextButton onNext={onNext} label={nextLabel} />
        </ResultBox>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------

function LessonCues({ question, onChecked, onNext, nextLabel }: Props) {
  const words = lessonWords(question);
  const options = runtimeOptions(question);
  // Từ (0-based) → id dấu ngắt đặt ngay sau từ đó.
  const [placedMarks, setPlacedMarks] = useState<Record<number, number>>({});
  const [checked, setChecked] = useState<{ isCorrect: boolean } | null>(null);

  const placedIds = new Set(Object.values(placedMarks));
  const placedCount = Object.keys(placedMarks).length;
  // `CuesPlacementStateX.availableOptions` — lọc theo id như app.
  const available = options.filter((option) => !placedIds.has(option.id));
  const positions = new Set(Object.keys(placedMarks).map(Number));

  function toggle(index: number) {
    if (checked) return;
    if (placedMarks[index] !== undefined) {
      const next = { ...placedMarks };
      delete next[index];
      setPlacedMarks(next);
      return;
    }
    // `placePauseMark`: hết dấu thì không đặt thêm được.
    if (options.length - placedCount <= 0 || available.length === 0) return;
    setPlacedMarks({ ...placedMarks, [index]: available[0].id });
  }

  // App chỉ cho kiểm tra khi đã đặt HẾT các dấu.
  const canCheck = placedCount > 0 && available.length === 0;

  function check() {
    if (checked || !canCheck) return;
    const graded = {
      isCorrect: checkPositions(question, positions),
      score: scorePositions(question, positions),
    };
    setChecked({ isCorrect: graded.isCorrect });
    onChecked({
      isCorrect: graded.isCorrect,
      neutral: false,
      progress: buildCuesProgress(question, placedMarks, graded),
    });
  }

  const markLabel = (id: number) => {
    const option = options.find((item) => item.id === id);
    return (option && optionLabel(option)) || '/';
  };
  const firstMark = options[0] ? optionLabel(options[0]) || '/' : '/';

  return (
    <div>
      <QuestionPrompt speechBubble={question.speechBubble} documents={question.document} />
      <Instruction>Đánh dấu trọng âm</Instruction>
      <p className="mb-2 text-xs text-ink-faint">
        Chạm vào một từ để đặt dấu ngắt ngay sau từ đó, chạm lại để bỏ. Còn{' '}
        {available.length} dấu.
      </p>
      <WordPicker
        words={words}
        states={words.map((_, index) => cueMarkState(question, positions, checked !== null, index))}
        marks={words.map((_, index) =>
          placedMarks[index] !== undefined ? markLabel(placedMarks[index]) : null,
        )}
        locked={checked !== null}
        describe={(word, index) =>
          placedMarks[index] !== undefined
            ? `${word} — đã đặt dấu ngắt sau từ này`
            : `${word} — đặt dấu ngắt sau từ này`
        }
        onToggle={toggle}
      />
      {!checked ? (
        <CheckButton enabled={canCheck} onCheck={check} />
      ) : (
        <ResultBox
          verdict={checked.isCorrect ? 'correct' : 'incorrect'}
          title={checked.isCorrect ? SHEET_CORRECT : SHEET_WRONG}
          explanation={mlText(question.explanation)}
          explanationMode="toggle"
          answer={
            <CorrectAnswerBlock>
              <SentenceAnswer
                spans={positionSpans(words, correctPositions(question), {
                  suffix: ` ${firstMark}`,
                })}
              />
            </CorrectAnswerBlock>
          }
        >
          <NextButton onNext={onNext} label={nextLabel} />
        </ResultBox>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------

function LessonStress({ question, onChecked, onNext, nextLabel }: Props) {
  const words = lessonWords(question);
  const [selected, setSelected] = useState<number[]>([]);
  const [checked, setChecked] = useState<{ isCorrect: boolean } | null>(null);
  const selectedSet = new Set(selected);

  function toggle(index: number) {
    if (checked) return;
    setSelected((current) =>
      current.includes(index) ? current.filter((i) => i !== index) : [...current, index],
    );
  }

  function check() {
    if (checked || selected.length === 0) return;
    const graded = {
      isCorrect: checkPositions(question, selectedSet),
      score: scorePositions(question, selectedSet),
    };
    setChecked({ isCorrect: graded.isCorrect });
    onChecked({
      isCorrect: graded.isCorrect,
      neutral: false,
      progress: buildStressProgress(question, selectedSet, graded),
    });
  }

  return (
    <div>
      <QuestionPrompt speechBubble={question.speechBubble} documents={question.document} />
      <Instruction>Đánh dấu trọng âm</Instruction>
      <WordPicker
        words={words}
        states={words.map((_, index) =>
          stressWordState(question, selectedSet, checked !== null, index),
        )}
        locked={checked !== null}
        describe={(word) => word}
        onToggle={toggle}
      />
      {!checked ? (
        <CheckButton enabled={selected.length > 0} onCheck={check} />
      ) : (
        <ResultBox
          verdict={checked.isCorrect ? 'correct' : 'incorrect'}
          title={checked.isCorrect ? SHEET_CORRECT : SHEET_WRONG}
          explanation={mlText(question.explanation)}
          explanationMode="toggle"
          answer={
            <CorrectAnswerBlock>
              <SentenceAnswer
                spans={positionSpans(words, correctPositions(question), { uppercase: true })}
              />
            </CorrectAnswerBlock>
          }
        >
          <NextButton onNext={onNext} label={nextLabel} />
        </ResultBox>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------

function LessonArrange({ question, onChecked, onNext, nextLabel }: Props) {
  const [items, setItems] = useState<(RuntimeOption & { key: number })[]>(() =>
    runtimeOptions(question).map((option, key) => ({ ...option, key })),
  );
  const [checked, setChecked] = useState<{ isCorrect: boolean } | null>(null);
  const labels = items.map(optionLabel);

  function move(from: number, to: number) {
    if (checked || to < 0 || to >= items.length) return;
    const next = [...items];
    const [item] = next.splice(from, 1);
    next.splice(to, 0, item);
    setItems(next);
  }

  function check() {
    if (checked || items.length === 0) return;
    const graded = {
      isCorrect: checkArrange(question, labels),
      score: scoreArrange(question, labels),
    };
    setChecked({ isCorrect: graded.isCorrect });
    onChecked({
      isCorrect: graded.isCorrect,
      neutral: false,
      progress: buildArrangeProgress(question, items, graded),
    });
  }

  return (
    <div>
      <QuestionPrompt speechBubble={question.speechBubble} documents={question.document} />
      <Instruction>Sắp xếp theo thứ tự</Instruction>
      <ArrangeList
        items={items.map((item, index) => ({
          key: item.key,
          label: labels[index],
          state: arrangeItemState(question, labels, checked !== null, index),
          correctPosition: arrangeCorrectPositionFor(question, labels, index),
        }))}
        locked={checked !== null}
        onMove={move}
      />
      {!checked ? (
        <CheckButton enabled={items.length > 0} onCheck={check} label="Kiểm tra đáp án" />
      ) : (
        <ResultBox
          verdict={checked.isCorrect ? 'correct' : 'incorrect'}
          title={checked.isCorrect ? INLINE_CORRECT : INLINE_WRONG}
          explanation={mlText(question.explanation)}
          explanationMode="inline"
          answer={
            checked.isCorrect ? undefined : (
              <CorrectAnswerBlock>
                <ol className="list-decimal space-y-1 pl-5 text-sm text-ink-muted">
                  {arrangeCorrectOrder(question).map((label, index) => (
                    <li key={index}>{label}</li>
                  ))}
                </ol>
              </CorrectAnswerBlock>
            )
          }
        >
          <NextButton onNext={onNext} label={nextLabel} />
        </ResultBox>
      )}
    </div>
  );
}
