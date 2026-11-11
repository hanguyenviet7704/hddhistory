'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useEffect, useRef, useState } from 'react';

import { buttonClass, inputClass } from '@/components/ui';
import {
  closeCoachSession,
  explainKeypointAgain,
  openCoachSession,
  recordCoachExit,
  sendCoachTurn,
  setCoachPersona,
  type CoachTurnPayload,
} from '@/lib/actions/coach';
import type {
  CoachChoice,
  CoachPersona,
  CoachReplayItem,
  CoachTurn,
  CoachUi,
} from '@/lib/coach';

import {
  chipSpecsFor,
  coachPrompt,
  coachStepLabel,
  dividerLabel,
  exitPleaLine,
  HUB_TASK_LABELS,
  MOOD_LABELS,
  PERSONA_LABELS,
  type ChipSpec,
} from './coach-copy';
import {
  Chip,
  CourseCardView,
  ExitFeedback,
  PlanForm,
  SafetyPanel,
  ScheduleForm,
  ScoreCardView,
  TwoColumns,
  type SchedulePayload,
} from './coach-parts';

interface Message {
  id: number;
  kind: 'coach' | 'user' | 'divider';
  text: string;
  /** Tiêu đề in đậm của bong bóng (tên habit, "Tôi có tình huống:", "A. …"). */
  title?: string | null;
  /** Người trong cảnh đang nói (nhập vai) — gắn tên lên bong bóng. */
  speaker?: string | null;
  /** Câu hỏi khép cảnh — nhấn mạnh. */
  emphasis?: boolean;
}

type Status = 'opening' | 'ready' | 'sending' | 'failed' | 'silent' | 'closed';

/** Bước composer là ô chữ (kèm chip gợi ý phía trên). */
const TEXT_KINDS = new Set([
  'text',
  'text_skippable',
  'depth',
  'hub',
  'two_cols',
  'scene_score',
  'next_action',
  'closing',
  'shrink',
]);

const MOOD_FACES = ['😞', '😕', '😐', '🙂', '😄'];
const MAX_INPUT = 2000;

let nextId = 1;

/** Một trả lời chia theo dòng trống thành nhiều bong bóng — "không chat 1 cục lớn". */
function paragraphs(reply: string): string[] {
  const parts = reply
    .split(/\n\s*\n/)
    .map((part) => part.trim())
    .filter(Boolean);
  return parts.length ? parts : [reply.trim()];
}

/**
 * Các bong bóng một lượt thêm vào, đúng thứ tự đọc của app (`_linesFor`):
 * câu trả lời → dòng ghi chú → cảnh (habit · bối cảnh · câu hỏi · các hướng)
 * → câu cố định của bước. Dùng chung cho lượt sống và cho phần phát lại.
 */
function linesFor(
  turn: Pick<CoachTurn, 'reply' | 'promptKey' | 'promptArgs' | 'noteKey' | 'speaker'> & {
    ui: Pick<CoachUi, 'situation' | 'scene'>;
  },
  userLine?: string | null,
): Message[] {
  const out: Message[] = [];
  const add = (message: Omit<Message, 'id'>) => out.push({ id: nextId++, ...message });
  const args = turn.promptArgs ?? {};

  if (userLine) add({ kind: 'user', text: userLine });
  if (turn.reply) {
    for (const part of paragraphs(turn.reply)) {
      add({ kind: 'coach', text: part, speaker: turn.speaker });
    }
  }

  const note = turn.noteKey ? coachPrompt(turn.noteKey, args) : null;
  if (note) add({ kind: 'coach', text: note });

  const scene = turn.ui.scene;
  const situation = turn.ui.situation;
  if (scene) {
    if (scene.habit) add({ kind: 'coach', title: 'Với thói quen:', text: scene.habit });
    // Nhịp thứ hai của cảnh: thân cảnh nằm ở `situation`, không có nhãn.
    if (situation && !scene.setup) add({ kind: 'coach', text: situation });
    if (scene.setup) add({ kind: 'coach', title: 'Tôi có tình huống:', text: scene.setup });
    if (scene.question) add({ kind: 'coach', text: scene.question, emphasis: true });
    // Các hướng trả lời là CHỮ, không phải nút: bấm-rồi-chép là làm bài tập
    // mất nghĩa. Gõ "A" cũng chọn được.
    if (scene.optionsLead) add({ kind: 'coach', text: scene.optionsLead });
    for (const option of scene.options ?? []) {
      add({ kind: 'coach', title: `${option.key}. ${option.label}`, text: `“${option.text}”` });
    }
  } else if (situation) {
    const lead = turn.noteKey === 'coach.prompt.lessonIntro' ? 'Một cảnh ngắn:' : null;
    add({ kind: 'coach', text: lead ? `${lead} ${situation}` : situation });
  }

  // Câu cố định của bước — trừ khi cảnh vừa khép bằng câu hỏi của chính nó.
  const sceneAskedItsOwn = scene ? Boolean(scene.question) : Boolean(situation);
  if (!sceneAskedItsOwn && turn.promptKey) {
    const line = coachPrompt(turn.promptKey, args);
    if (line) add({ kind: 'coach', text: line, emphasis: Boolean(scene) });
  }
  return out;
}

function replayLines(items: CoachReplayItem[] = []): Message[] {
  const out: Message[] = [];
  for (const item of items) {
    if (item.divider) {
      out.push({ id: nextId++, kind: 'divider', text: dividerLabel(item.divider.at, item.divider.entry) });
      continue;
    }
    out.push(
      ...linesFor(
        {
          reply: item.reply ?? null,
          promptKey: item.promptKey ?? null,
          promptArgs: item.promptArgs,
          noteKey: item.noteKey,
          speaker: item.speaker,
          ui: { situation: item.situation, scene: item.scene },
        },
        item.userLine,
      ),
    );
  }
  return out;
}

/**
 * HDDhistory Coach trên web — bản chữ của sheet Coach trong app.
 *
 * Server giữ toàn bộ kịch bản (state machine); client chỉ làm ba việc: vẽ
 * lượt về thành bong bóng, vẽ đúng điều khiển cho `ui.kind` + `step`, và gửi
 * đúng loại sự kiện bước đó nhận. Gửi sai loại thì API trả 400 — nên bảng
 * chip → sự kiện ở đây chép nguyên `_dispatchChip` của app.
 */
export function CoachChat() {
  const router = useRouter();
  const [status, setStatus] = useState<Status>('opening');
  const [turn, setTurn] = useState<CoachTurn | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [columns, setColumns] = useState<{ left: string[]; right: string[] }>({ left: [], right: [] });
  const [persona, setPersonaState] = useState<CoachPersona>('friend');
  const [error, setError] = useState<string | null>(null);
  const [draft, setDraft] = useState('');
  const [closing, setClosing] = useState<null | 'plea' | 'feedback'>(null);
  const [explained, setExplained] = useState<string[]>([]);
  const [habitPage, setHabitPage] = useState(0);
  const opened = useRef(false);
  const endRef = useRef<HTMLDivElement>(null);

  const busy = status === 'sending' || status === 'opening';
  const ui = turn?.ui;
  const step = turn?.step ?? '';

  function applyTurn(next: CoachTurn) {
    setTurn(next);
    if (next.persona) setPersonaState(next.persona);
    if (next.ui.columns && (next.ui.columns.left.length || next.ui.columns.right.length)) {
      setColumns(next.ui.columns);
    }
    setHabitPage(0);
  }

  async function open() {
    setStatus('opening');
    setError(null);
    setClosing(null);
    const result = await openCoachSession(-new Date().getTimezoneOffset());
    if (!result.ok) {
      setError(result.error);
      setStatus('failed');
      return;
    }
    if ('silent' in result.data) {
      setStatus('silent');
      return;
    }
    const data = result.data;
    // Phiên nối lại: các dòng hiện tại đã nằm sẵn trong `replay`.
    setMessages([...replayLines(data.replay), ...(data.resumed ? [] : linesFor(data))]);
    applyTurn(data);
    setStatus('ready');
  }

  useEffect(() => {
    // Strict Mode chạy effect hai lần ở dev; mở hai lần thì lần sau chỉ nối
    // lại đúng phiên đó, nhưng vẫn là một request thừa.
    if (opened.current) return;
    opened.current = true;
    void open();
    // Chỉ mở MỘT lần khi vào trang; các lần mở lại đi qua nút "Thử lại".
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: 'smooth', block: 'end' });
  }, [messages, status, closing]);

  async function send(payload: CoachTurnPayload, userLine: string) {
    if (busy || !turn) return;
    setError(null);
    setStatus('sending');
    setMessages((current) => [...current, { id: nextId++, kind: 'user', text: userLine }]);
    // Chữ trên chip đi kèm sự kiện: server giữ để mở lại sheet còn vẽ được câu
    // trả lời. Chữ gõ thì đã nằm trong `text` rồi.
    const body = payload.kind === 'text' ? payload : { ...payload, label: userLine.slice(0, 200) };
    const result = await sendCoachTurn(turn.sessionId, body);
    if (!result.ok) {
      // 410 = phiên quá hạn 48 giờ. Mở lại chứ không báo lỗi.
      if (result.status === 410) {
        await open();
        return;
      }
      setError(result.error);
      setStatus('failed');
      return;
    }
    setMessages((current) => [...current, ...linesFor(result.data)]);
    applyTurn(result.data);
    setStatus('ready');
    return result.data;
  }

  function submitText(text: string) {
    const trimmed = text.trim().slice(0, MAX_INPUT);
    if (!trimmed) return;
    setDraft('');
    if (ui?.kind === 'two_cols') {
      // Câu được lưu NGUYÊN: ô chỉ hỏi phần đuôi, nên ghép đầu câu nếu người
      // đọc chưa tự gõ.
      const prefix = 'Vấn đề thật của tôi là';
      const sentence = trimmed.toLowerCase().startsWith(prefix.toLowerCase())
        ? trimmed
        : `${prefix} ${trimmed}`;
      void send({ kind: 'text', text: sentence, leftLines: columns.left, rightLines: columns.right }, sentence);
      return;
    }
    void send({ kind: 'text', text: trimmed }, trimmed);
  }

  function dispatchChip(spec: ChipSpec) {
    const echo = spec.echo ?? spec.label;
    const yes = spec.value === 'yes';
    switch (step) {
      case 'mood':
        return send({ kind: 'mood', mood: Number(spec.value) }, spec.label);
      case 'moodEnd':
        return send({ kind: 'moodEnd', mood: Number(spec.value) }, spec.label);
      case 'intent':
        return send({ kind: 'intent', answer: spec.value }, echo);
      case 'invite':
      case 'checkinOffer':
        return send({ kind: 'invite', accept: yes }, echo);
      case 'sceneAgain':
        return send({ kind: 'sceneAgain', again: yes }, echo);
      case 'sceneFix':
        return send({ kind: 'sceneAgain', again: spec.value === 'retry' }, echo);
      case 'sceneMet':
        return send({ kind: 'sceneMet', met: yes }, echo);
      case 'planAsk':
        return send({ kind: 'planAsk', accept: yes }, echo);
      case 'loop':
        return send({ kind: 'loop', keepGoing: spec.value === 'continue' }, spec.label);
      case 'shrinkAsk':
        return send({ kind: 'shrink', accept: yes }, echo);
      case 'pickNew':
      case 'pickHabit':
      case 'scenePick':
        return send({ kind: 'pickNew', habitId: spec.value }, spec.label);
      case 'checkinAsk':
        return send({ kind: 'checkin', done: yes }, echo);
      case 'quizInChat':
        return send({ kind: 'quizAnswer', quizAnswer: spec.value }, spec.label);
      case 'quizHandoff':
      case 'talkWhen':
      case 'recapQuiz':
      case 'recapPick':
      case 'onboardAddressConfirm':
        return send({ kind: 'pick', value: spec.value }, echo);
      case 'depth':
        return send({ kind: 'depth', deep: spec.value === 'deep' }, spec.label);
      case 'contextAsk':
        return send({ kind: 'context', keep: spec.value === 'keep' }, spec.label);
      case 'nextSession':
        return send({ kind: 'nextSession', again: spec.value === 'again' }, echo);
    }
  }

  async function courseAction(action: 'open' | 'save' | 'close' | 'harder') {
    const course = ui?.course;
    const echo = {
      open: 'Đi tới khoá học.',
      save: 'Lưu để sau.',
      close: 'Bỏ qua.',
      harder: 'Luyện cảnh khó hơn.',
    }[action];
    const next = await send({ kind: 'course', courseAction: action }, echo);
    // "Đi tới khoá học": phiên kết thúc phía server, rời thẳng sang khoá.
    if (action === 'open' && next?.ended && course) {
      router.push(`/khoa-hoc/${encodeURIComponent(course.courseId)}`);
    }
  }

  async function changePersona(next: CoachPersona) {
    setPersonaState(next);
    if (turn) await setCoachPersona(turn.sessionId, next);
  }

  async function finish() {
    setClosing(null);
    setStatus('closed');
    if (turn) await closeCoachSession(turn.sessionId);
  }

  /** Luồng 6 — Đóng giữa phiên: níu một câu trước, rồi mới hỏi vừa rồi thế nào. */
  function requestClose() {
    if (turn && !turn.ended && status === 'ready') {
      setClosing('plea');
      return;
    }
    void finish();
  }

  // ------------------------------------------------------------------ render

  if (status === 'silent') {
    return (
      <Panel>
        <p className="text-ink">Lúc này Coach chưa có gì để nói ở đây. Quay lại sau nhé.</p>
      </Panel>
    );
  }

  if (status === 'closed') {
    return (
      <Panel>
        <p className="font-semibold text-brand-900">Đã đóng cuộc trò chuyện.</p>
        <p className="mt-1 text-sm text-ink-muted">Khi nào muốn nói tiếp thì Coach ở đây.</p>
        <div className="mt-3 flex flex-wrap gap-2">
          <button type="button" onClick={() => void open()} className={buttonClass.primary}>
            Trò chuyện tiếp
          </button>
          <Link href="/" className={buttonClass.secondary}>
            Về trang chủ
          </Link>
        </div>
      </Panel>
    );
  }

  const isSafety = ui?.kind === 'safety';
  const stepLabel = coachStepLabel(step);
  const showCourse = ui?.course && (ui.kind === 'course_card' || step === 'leave');

  return (
    <div className="mt-4 flex flex-col rounded-xl border border-hairline bg-surface-alt">
      {/* ---- header: tên, bước, giọng, đóng */}
      <div className="flex flex-wrap items-center gap-2 border-b border-hairline px-4 py-3">
        <div className="min-w-0 flex-1">
          <p className="font-bold text-brand-900">HDDhistory Coach</p>
          <p className="truncate text-xs text-ink-faint">
            {busy ? 'đang trả lời…' : stepLabel ?? ''}
          </p>
        </div>
        <label className="flex items-center gap-1 text-sm text-ink-muted">
          Giọng
          <select
            value={persona}
            onChange={(event) => void changePersona(event.target.value as CoachPersona)}
            disabled={!turn}
            className="rounded-lg border border-hairline bg-surface px-2 py-1 text-sm text-ink"
          >
            {Object.entries(PERSONA_LABELS).map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </select>
        </label>
        <button type="button" onClick={requestClose} className={buttonClass.ghost}>
          Đóng
        </button>
      </div>

      {/* ---- thanh trạng thái: làm quen · habit · phạm vi */}
      {!isSafety && ui?.onboard && ui.onboard.step > 0 ? (
        <div className="flex items-center gap-3 border-b border-hairline px-4 py-2">
          <span className="text-xs text-ink-muted">
            Câu {ui.onboard.step}/{ui.onboard.total}
          </span>
          <span className="h-1.5 flex-1 overflow-hidden rounded-full bg-brand-100" aria-hidden>
            <span
              className="block h-full bg-brand"
              style={{ width: `${(ui.onboard.step / Math.max(1, ui.onboard.total)) * 100}%` }}
            />
          </span>
          {ui.onboard.skippable ? (
            <button
              type="button"
              disabled={busy}
              onClick={() => void send({ kind: 'pick', value: 'skip' }, 'Bỏ qua.')}
              className="text-xs font-semibold text-brand-700 hover:underline disabled:opacity-50"
            >
              Bỏ qua
            </button>
          ) : null}
        </div>
      ) : null}
      {!isSafety && ui?.habit ? (
        <div className="flex items-center justify-center gap-2 border-b border-hairline px-4 py-2 text-sm">
          <span className="text-ink-muted">Đang nói về</span>
          <span className="font-semibold text-ink">{ui.habit.title}</span>
          <button
            type="button"
            disabled={busy}
            onClick={() => void send({ kind: 'changeHabit' }, 'Đổi habit khác.')}
            className="text-xs font-semibold text-brand-700 hover:underline disabled:opacity-50"
          >
            Đổi habit
          </button>
        </div>
      ) : !isSafety && ui?.scope ? (
        <p className="border-b border-hairline px-4 py-2 text-center text-sm text-ink-muted">
          {ui.scope.kind === 'course' ? 'Khoá' : 'Keypoint'} · {ui.scope.title}
        </p>
      ) : null}

      {/* ---- luồng hội thoại */}
      <div
        className="max-h-[60vh] min-h-[16rem] space-y-2 overflow-y-auto px-4 py-4"
        role="log"
        aria-live="polite"
        aria-label="Cuộc trò chuyện với Coach"
      >
        {isSafety ? (
          <SafetyPanel hotlines={ui?.hotlines ?? []} />
        ) : (
          <>
            {messages.map((message) => (
              <Bubble key={message.id} message={message} />
            ))}

            {showCourse && ui?.course ? (
              <CourseCardView
                course={ui.course}
                active={ui.kind === 'course_card'}
                busy={busy}
                onAction={(action) => void courseAction(action)}
              />
            ) : null}

            {ui?.score ? <ScoreCardView score={ui.score} /> : null}

            {ui?.keypoints && ui.keypoints.length > 0 ? (
              <div className="rounded-xl border border-hairline bg-surface p-3">
                <p className="text-xs font-bold tracking-wide text-brand-700 uppercase">
                  Có thể giúp bạn
                </p>
                <ul className="mt-2 space-y-2">
                  {ui.keypoints.map((keypoint) => (
                    <li key={keypoint.id} className="text-sm">
                      <p className="font-semibold text-ink">{keypoint.title}</p>
                      {keypoint.courseId ? (
                        <Link
                          href={`/khoa-hoc/${encodeURIComponent(keypoint.courseId)}`}
                          className="text-xs font-semibold text-brand-700 hover:underline"
                        >
                          {keypoint.courseTitle || 'Mở khoá học'}
                        </Link>
                      ) : null}
                      <div className="mt-1">
                        {explained.includes(keypoint.id) ? (
                          <span role="status" className="text-xs text-emerald-700">
                            Đã ghi nhận — cảm ơn bạn.
                          </span>
                        ) : (
                          <Chip
                            onClick={() => {
                              // Không chờ: một lần đếm hỏng không được làm đứt cuộc trò chuyện.
                              setExplained((current) => [...current, keypoint.id]);
                              void explainKeypointAgain(keypoint.id);
                            }}
                          >
                            Giải thích đơn giản hơn
                          </Chip>
                        )}
                      </div>
                    </li>
                  ))}
                </ul>
              </div>
            ) : null}

            {turn?.courseInvite ? (
              <Link
                href={`/khoa-hoc/${encodeURIComponent(turn.courseInvite.courseId)}`}
                className="ml-auto block max-w-md rounded-xl border border-brand-200 bg-brand-50 p-3"
              >
                <span className="block text-xs font-bold text-brand-700">
                  Một khoá gần với chuyện bạn kể
                </span>
                <span className="mt-1 block font-semibold text-ink">{turn.courseInvite.title}</span>
                <span className="mt-1 block text-xs text-ink-muted">
                  Lời mời, không phải chẩn đoán. Bỏ qua cũng được.
                </span>
              </Link>
            ) : null}

            {ui?.kind === 'two_cols' ? (
              <TwoColumns left={columns.left} right={columns.right} onChange={setColumns} />
            ) : null}

            {/* ⟨Phương án⟩ nằm TRONG luồng, căn phải, như design. */}
            {ui && (ui.kind === 'chips' || ui.kind === 'next_session') && status === 'ready' ? (
              <OptionPills
                step={step}
                ui={ui}
                busy={busy}
                habitPage={habitPage}
                onReroll={() => setHabitPage((page) => page + 1)}
                onPick={(spec) => void dispatchChip(spec)}
              />
            ) : null}

            {busy ? (
              <p className="text-sm text-ink-faint" role="status">
                Coach đang trả lời…
              </p>
            ) : null}
          </>
        )}
        <div ref={endRef} />
      </div>

      {/* ---- lỗi */}
      {status === 'failed' ? (
        <div className="border-t border-hairline px-4 py-3">
          <p role="alert" className="text-sm font-medium text-red-700">
            {error || 'Có lỗi ở phía mình. Những gì bạn nói không mất đi đâu cả.'}
          </p>
          <button type="button" onClick={() => void open()} className={`${buttonClass.secondary} mt-2`}>
            Thử lại
          </button>
        </div>
      ) : null}

      {/* ---- Đóng: níu, rồi đánh giá */}
      {closing === 'plea' && turn ? (
        <div className="border-t border-hairline px-4 py-3" role="alertdialog" aria-labelledby="coach-plea">
          <p id="coach-plea" className="font-semibold text-ink">
            {exitPleaLine(step, ui?.quizRemaining)}
          </p>
          <div className="mt-3 grid grid-cols-2 gap-2">
            <button
              type="button"
              className={buttonClass.primary}
              onClick={() => {
                setClosing(null);
                void recordCoachExit(turn.sessionId, true);
              }}
            >
              Ở lại một câu
            </button>
            <button
              type="button"
              className={buttonClass.secondary}
              onClick={() => {
                if (turn.exitFeedback) {
                  setClosing('feedback');
                } else {
                  void recordCoachExit(turn.sessionId, false);
                  void finish();
                }
              }}
            >
              Vẫn đóng
            </button>
          </div>
        </div>
      ) : null}
      {closing === 'feedback' && turn ? (
        <div className="border-t border-hairline px-4 py-3">
          <ExitFeedback
            kind={turn.sessionKind}
            onDone={(chips, note) => {
              void recordCoachExit(turn.sessionId, false, chips, note);
              void finish();
            }}
          />
        </div>
      ) : null}

      {/* ---- composer theo ui.kind */}
      {!closing && ui && !isSafety && (status === 'ready' || status === 'sending') ? (
        <div className="border-t border-hairline px-4 py-3">
          {TEXT_KINDS.has(ui.kind) ? (
            <TextComposer
              step={step}
              ui={ui}
              busy={busy}
              draft={draft}
              setDraft={setDraft}
              onSubmit={submitText}
              onSend={(payload, label) => void send(payload, label)}
            />
          ) : ui.kind === 'plan' ? (
            <PlanForm
              key={`${turn?.sessionId}:${step}:${messages.length}`}
              suggested={ui.suggested}
              busy={busy}
              onSave={(context, action) =>
                void send({ kind: 'plan', planContext: context, planAction: action }, `${context} — ${action}`)
              }
            />
          ) : ui.kind === 'schedule' ? (
            <ScheduleForm
              busy={busy}
              onSave={(payload: SchedulePayload, label) => void send({ kind: 'schedule', ...payload }, label)}
            />
          ) : ui.kind === 'end' ? (
            step === 'leave' && ui.course ? (
              <Link
                href={`/khoa-hoc/${encodeURIComponent(ui.course.courseId)}`}
                className={`${buttonClass.primary} w-full`}
              >
                Sang Roadmap khoá học
              </Link>
            ) : (
              <button type="button" onClick={() => void finish()} className={`${buttonClass.secondary} w-full`}>
                Đóng
              </button>
            )
          ) : null}
          <p className="mt-2 text-xs text-ink-faint">
            Trên web bạn trả lời bằng chữ — nói bằng giọng chỉ có trong ứng dụng.
          </p>
        </div>
      ) : null}
    </div>
  );
}

function Panel({ children }: { children: React.ReactNode }) {
  return <div className="mt-4 rounded-xl border border-hairline bg-surface p-4">{children}</div>;
}

function Bubble({ message }: { message: Message }) {
  if (message.kind === 'divider') {
    return (
      <p className="py-2 text-center text-xs text-ink-faint">
        <span className="rounded-full bg-surface px-3 py-1">{message.text}</span>
      </p>
    );
  }
  const mine = message.kind === 'user';
  return (
    <div className={`flex ${mine ? 'justify-end' : 'justify-start'}`}>
      <div
        className={`max-w-[85%] rounded-2xl px-3 py-2 text-sm leading-relaxed whitespace-pre-line ${
          mine
            ? 'rounded-br-sm bg-brand text-white'
            : `rounded-bl-sm border border-hairline bg-surface text-ink ${message.emphasis ? 'font-semibold' : ''}`
        }`}
      >
        {message.speaker ? (
          <span className="mb-0.5 block text-xs font-bold text-brand-700">{message.speaker}</span>
        ) : null}
        {message.title ? <span className="block font-bold text-brand-900">{message.title}</span> : null}
        {message.text}
      </div>
    </div>
  );
}

/**
 * Lựa chọn trong luồng: hàng mood năm mức, kho habit ba-cái-một, hoặc các
 * viên chip theo bước.
 */
function OptionPills({
  step,
  ui,
  busy,
  habitPage,
  onReroll,
  onPick,
}: {
  step: string;
  ui: CoachUi;
  busy: boolean;
  habitPage: number;
  onReroll: () => void;
  onPick: (spec: ChipSpec) => void;
}) {
  if (step === 'mood' || step === 'moodEnd') {
    return (
      <div className="flex flex-wrap justify-end gap-2" role="group" aria-label="Hôm nay bạn thấy thế nào">
        {MOOD_LABELS.map((label, index) => (
          <button
            key={label}
            type="button"
            disabled={busy}
            onClick={() => onPick({ value: String(index + 1), label: `${MOOD_FACES[index]}  ${label}` })}
            className="flex flex-col items-center rounded-xl border border-brand-200 bg-surface px-2 py-1.5 text-xs font-semibold text-brand-900 hover:bg-brand-50 disabled:opacity-50"
          >
            <span aria-hidden className="text-xl">
              {MOOD_FACES[index]}
            </span>
            {label}
          </button>
        ))}
      </div>
    );
  }

  // Kho habit dài (13+): ba cái một lần, đổi tại chỗ — không tốn lượt, không
  // ghi gì vào cuộc trò chuyện.
  if (step === 'pickNew' || step === 'pickHabit' || step === 'scenePick') {
    const choices: CoachChoice[] = ui.choices ?? [];
    const pages = Math.max(1, Math.ceil(choices.length / 3));
    const start = (habitPage % pages) * 3;
    const shown = choices.slice(start, start + 3);
    return (
      <div className="flex flex-col items-end gap-2">
        {shown.map((choice) => (
          <Chip key={choice.value} disabled={busy} onClick={() => onPick({ value: choice.value, label: choice.label ?? choice.value })}>
            {choice.label ?? choice.value}
          </Chip>
        ))}
        {choices.length > 3 ? (
          <button type="button" onClick={onReroll} className="text-xs font-semibold text-brand-700 hover:underline">
            Gợi ý 3 thói quen khác
          </button>
        ) : null}
      </div>
    );
  }

  const specs = chipSpecsFor(step, ui.choices ?? [], ui.allowNewSession ?? true);
  return (
    <div className="flex flex-col items-end gap-2">
      {specs.map((spec) => (
        <Chip key={spec.value} disabled={busy} onClick={() => onPick(spec)}>
          {spec.label}
        </Chip>
      ))}
    </div>
  );
}

/** Ô chữ, với chip thao tác phía trên và gợi ý (bấm để ĐIỀN, không gửi). */
function TextComposer({
  step,
  ui,
  busy,
  draft,
  setDraft,
  onSubmit,
  onSend,
}: {
  step: string;
  ui: CoachUi;
  busy: boolean;
  draft: string;
  setDraft: (value: string) => void;
  onSubmit: (text: string) => void;
  onSend: (payload: CoachTurnPayload, label: string) => void;
}) {
  const onboarding = step.startsWith('onboard');
  const actions: { label: string; selected?: boolean; run: () => void }[] = [];

  switch (ui.kind) {
    case 'text_skippable':
      actions.push({ label: 'Không có gì đặc biệt', run: () => onSend({ kind: 'skip' }, 'Không có gì đặc biệt.') });
      if (!ui.habit) {
        actions.push({
          label: 'hoặc chọn habit muốn bàn',
          run: () => onSend({ kind: 'changeHabit' }, 'Mình muốn bàn một habit.'),
        });
      }
      break;
    case 'text':
      if (step === 'tell2') {
        actions.push({ label: 'Chỉ ghi lại thôi', run: () => onSend({ kind: 'ack' }, 'Chỉ ghi lại thôi') });
      }
      break;
    case 'depth':
      actions.push(
        { label: 'Kể sâu hơn', run: () => onSend({ kind: 'depth', deep: true }, 'Kể sâu hơn') },
        { label: 'Chỉ ghi lại thôi', run: () => onSend({ kind: 'depth', deep: false }, 'Chỉ ghi lại thôi') },
      );
      break;
    case 'two_cols':
      if (ui.rejectAvailable) {
        actions.push({ label: 'Không đúng với mình', run: () => onSend({ kind: 'rejectDraft' }, 'Không đúng với mình.') });
      }
      break;
    case 'hub': {
      // HUB nhận `task`; làm quen và TALK_ASK nhận `pick`. Gửi nhầm loại là 400.
      const picks = onboarding || step === 'talkAsk';
      for (const choice of ui.choices ?? []) {
        const label = onboarding ? (choice.label ?? choice.value) : HUB_TASK_LABELS[choice.value];
        if (!label) continue;
        actions.push({
          label,
          selected: choice.selected,
          run: () =>
            onSend(picks ? { kind: 'pick', value: choice.value } : { kind: 'task', task: choice.value }, label),
        });
      }
      break;
    }
  }

  // Cảnh có các hướng trả lời thì giấu gợi ý: chúng là chữ để đọc, không phải nút để chép.
  const samples = ui.scene?.options?.length ? [] : (ui.samples ?? []);
  const hint =
    ui.kind === 'two_cols'
      ? 'Vấn đề thật của tôi là…'
      : step === 'talkAsk'
        ? 'Hoặc kể luôn điều bạn nhớ nhất…'
        : step === 'onboardIntro'
          ? 'Hoặc hỏi mình gì đó trước…'
          : step === 'onboardAddress'
            ? 'Hoặc gõ tên bạn muốn mình gọi…'
            : onboarding
              ? 'Hoặc gõ câu trả lời của bạn…'
              : ui.kind === 'hub'
                ? 'Hoặc kể luôn chuyện hôm nay của bạn…'
                : 'Gõ câu trả lời của bạn…';

  return (
    <form
      onSubmit={(event) => {
        event.preventDefault();
        onSubmit(draft);
      }}
    >
      {actions.length > 0 || samples.length > 0 ? (
        <div className="mb-2 flex flex-wrap gap-2">
          {actions.map((action) => (
            <Chip key={action.label} disabled={busy} selected={action.selected} onClick={action.run}>
              {action.label}
            </Chip>
          ))}
          {samples.map((sample) => (
            <Chip key={sample} disabled={busy} onClick={() => setDraft(sample)} title="Điền vào ô để sửa trước khi gửi">
              {sample}
            </Chip>
          ))}
        </div>
      ) : null}
      <div className="flex items-end gap-2">
        <label htmlFor="coach-input" className="sr-only">
          Tin nhắn cho Coach
        </label>
        <textarea
          id="coach-input"
          value={draft}
          onChange={(event) => setDraft(event.target.value)}
          onKeyDown={(event) => {
            // Enter gửi, Shift+Enter xuống dòng — như mọi khung chat.
            if (event.key === 'Enter' && !event.shiftKey && !event.nativeEvent.isComposing) {
              event.preventDefault();
              onSubmit(draft);
            }
          }}
          rows={2}
          maxLength={MAX_INPUT}
          placeholder={hint}
          className={`${inputClass} resize-none text-sm`}
        />
        <button type="submit" disabled={busy || !draft.trim()} className={buttonClass.primary}>
          Gửi
        </button>
      </div>
    </form>
  );
}
