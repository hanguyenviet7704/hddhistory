import { Injectable, Logger } from '@nestjs/common';

import { Configuration } from '@base/config/configuration';

import {
  CoachAi,
  CoachAiError,
  CoachClosingLineResult,
  CoachHabitMatchResult,
  CoachPlanQuote,
  CoachQuestionVerdict,
  CoachReflectResult,
  CoachRiskResult,
  CoachRubricCriterion,
  CoachSceneScoreResult,
  CoachSituationInput,
  CoachSituationResult,
  CoachSituationRest,
  CoachTranscriptResult,
  CoachTurnContext,
  CoachLessonTalkInput,
  CoachMemoryExtraction,
  CoachMemoryExtractionInput,
  CoachQuizFeedbackInput,
  CoachQuizGenerationInput,
  CoachQuizGenerationResult,
  CoachSceneJudgeResult,
  CoachSceneOption,
  CoachSceneReactResult,
  CoachStoryTalkResult,
  CoachTwoColsResult,
} from './coach-ai.types';
import { CoachJsonFieldStream } from './coach-json-field-stream';
import {
  buildClosingLinePrompt,
  buildHabitMatchPrompt,
  buildKeypointQuizPrompt,
  buildSceneReactPrompt,
  buildQuestionGuardPrompt,
  buildReflectPrompt,
  buildRiskPrompt,
  buildSceneScorePrompt,
  buildSituationCritiquePrompt,
  buildSituationPrompt,
  buildSituationRestPrompt,
  buildTranscribePrompt,
  buildLessonTalkPrompt,
  buildMemoryExtractionPrompt,
  buildQuizFeedbackPrompt,
  buildSceneJudgePrompt,
  buildStoryTalkPrompt,
  buildTwoColsPrompt,
  CLOSING_LINE_RESPONSE_SCHEMA,
  HABIT_MATCH_RESPONSE_SCHEMA,
  QUESTION_GUARD_RESPONSE_SCHEMA,
  ENGAGED_REPLY_RESPONSE_SCHEMA,
  REFLECT_RESPONSE_SCHEMA,
  RISK_RESPONSE_SCHEMA,
  SCENE_SCORE_RESPONSE_SCHEMA,
  SITUATION_OPENING_RESPONSE_SCHEMA,
  SITUATION_REST_RESPONSE_SCHEMA,
  SITUATION_RESPONSE_SCHEMA,
  MEMORY_EXTRACTION_RESPONSE_SCHEMA,
  SCENE_JUDGE_RESPONSE_SCHEMA,
  KEYPOINT_QUIZ_RESPONSE_SCHEMA,
  SCENE_REACT_RESPONSE_SCHEMA,
  STORY_TALK_RESPONSE_SCHEMA,
  TRANSCRIBE_RESPONSE_SCHEMA,
  TWO_COLS_RESPONSE_SCHEMA,
} from './coach-prompt';
import { CoachSentenceHold } from './coach-sentence-hold';
import { coachTimeLeftMs } from '../../shared/coach-deadline';
import { CoachStreamSink, coachStreamSink } from '../../shared/coach-stream';
import {
  COACH_SCENE_DEFAULT_QUESTION,
  MEMORY_GREETING_TOPIC_MAX_CHARS,
  SCENE_SCORE_MAX,
  SCENE_OPTION_LABEL_MAX_CHARS,
  SCENE_OPTION_MAX,
  SCENE_OPTION_MIN,
  SCENE_OPTION_TEXT_MAX_CHARS,
  SITUATION_MAX_BEATS,
  SITUATION_MAX_WORDS,
  SITUATION_MIN_WORDS,
} from '../../shared/coach.constant';
import {
  CoachScenePosture, CoachStoryKind
} from '../../shared/coach.enum';
import { CoachAiCallKind } from '../ai-usage/coach-ai-usage.enum';
import { CoachAiUsageService } from '../ai-usage/coach-ai-usage.service';
import { CoachConfigService } from '../config/coach-config.service';

const API_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';

/**
 * Ceiling for one reply — and, on a thinking model, for its THINKING too.
 *
 * This used to read "a coach reply is one or two sentences, and truncating is
 * cheaper than paying for it". That is no longer true in either half: the cap
 * now bounds reasoning as well as prose, and truncating is not cheaper — a cut
 * reply is billed in full and delivers nothing.
 *
 * 512 was written for models that answered straight away. Gemini 3 spends the
 * same budget reasoning first, and measured against a 36-token prompt it burned
 * 345-465 of them before writing a word; a real Coach prompt (core rules +
 * culture + voice + habit + material + transcript) reasons harder still. The
 * budget ran out mid-thought, the response came back `finishReason: MAX_TOKENS`
 * with no text part, and the turn fell to a canned line — while the call was
 * billed in full. That is the 81-of-84 failures the admin cost page showed on
 * gemini-flash-latest (owner, 2026-09-05).
 *
 * Raising it costs nothing extra per se: the thinking happens either way and is
 * billed either way. The ceiling only decides whether the money buys an answer.
 *
 * `thinkingBudget: 0` is NOT the lever — see THINKING_LEVEL below, which is.
 */
const MAX_OUTPUT_TOKENS = 3072;

/**
 * How hard the model may think before it writes.
 *
 * The note above this used to end "`thinkingLevel` the v1beta endpoint rejects
 * outright". That is half right, and the half that is wrong cost us the lever:
 * `generationConfig.thinkingLevel` is indeed refused (400, "Unknown name
 * thinkingLevel at generation_config"), but the SAME key one level deeper, at
 * `generationConfig.thinkingConfig.thinkingLevel`, is accepted. Measured on gemini-3.7-flash against a 3,970-token prompt
 * (2026-09-16): thinking fell from 340-560 tokens to 186-247 with the answer
 * unchanged in shape. `thinkingBudget: 0` is refused outright on this model
 * (400 INVALID_ARGUMENT), which is why the budget was never the lever either.
 *
 * Applied to conversational calls only. Scene and quiz WRITING keep the default
 * — those are the prompts with a dozen simultaneous constraints, they run once
 * rather than every turn, and reasoning is what makes them coherent.
 *
 * This is a reversible knob on a number nobody had measured. If the reply
 * quality moves, take it out — the report now carries per-kind latency, so the
 * trade is visible from both sides.
 */
const THINKING_LEVEL_LOW = { thinkingLevel: 'low' } as const;

/**
 * Writing a whole scene, or a quiz, in one call.
 *
 * These carry the heaviest prompts and return the most: two stages, both
 * tellings, the samples, the counterpart, the takeaway. 512 could not hold the
 * ANSWER alone, let alone the reasoning before it — which is why generation
 * kept falling back to a scene already in the pool ("loanh quanh 1 vài tình
 * huống").
 */
const GENERATION_OUTPUT_TOKENS = 8192;

/**
 * The wait a reader will actually tolerate mid-conversation.
 *
 * Nothing like the ten minutes the import generator allows itself: that one
 * runs behind a progress screen, this one runs while somebody watches a typing
 * indicator. Past fifteen seconds the fallback reply is strictly better than
 * the real one, because the real one is no longer part of the conversation
 * they were having.
 */
const TURN_TIMEOUT_MS = 15_000;

/**
 * The risk classifier's own, shorter budget.
 *
 * It races the main call rather than gating it, so its timeout only decides how
 * long we keep the safety verdict open — and a verdict that arrives after the
 * reply has been sent is worthless. Six seconds is comfortably above the
 * observed latency of a one-word classification on a lite model.
 */
const RISK_TIMEOUT_MS = 6_000;

/**
 * Model for the risk classifier, pinned separately from the conversational one.
 *
 * Deliberately not `GEMINI_MODEL`: this call runs on EVERY free-text turn and
 * decides one enum value. Spending the conversational model's latency and price
 * on it would tax every turn in the product for no better answer — a lite model
 * classifies "is this a statement of intent to die" as well as a large one.
 */
const RISK_MODEL = 'gemini-flash-lite-latest';

/**
 * Speech gets its own, longer budget.
 *
 * A minute of audio is a far bigger upload than any text turn, and cutting it
 * at the conversational fifteen seconds would fail exactly the long answers the
 * microphone exists to make easy.
 */
const TRANSCRIBE_TIMEOUT_MS = 45_000;

/**
 * Writing a quiz is not a turn: it runs while the reader is answering the one
 * before it (or after the sheet has closed), so it may take longer than a
 * reply is allowed to.
 */
const QUIZ_GEN_TIMEOUT_MS = 40_000;

/**
 * The pause before the one retry, when the provider did not name its own.
 *
 * A 503 means the model is full rather than that we asked for too much, and
 * that clears in the low seconds or not at all. Long enough to be a different
 * moment, short enough that the reader is still watching.
 */
const RETRY_PAUSE_MS = 900;

/**
 * Longest wait worth honouring from a 429 before giving up on this turn.
 *
 * Google's quota messages routinely ask for twenty-odd seconds. That is a fine
 * answer for a batch job and a useless one here — nobody holds a chat open that
 * long — so a wait this size is treated as "not today" and the turn falls to
 * its fixed line immediately instead of pretending.
 */
const RETRY_MAX_WAIT_MS = 4_000;

/**
 * Where a busy model hands the turn on to, when nobody has said otherwise.
 *
 * Aliases rather than pinned versions, for the reason `model` below gives: this
 * feature has been broken twice by Google retiring a pinned id, and a fallback
 * that 404s is a fallback that makes a bad morning worse. Two of them because
 * they fail differently — `flash-latest` is a peer of the conversational model,
 * `flash-lite-latest` is smaller and answers out of a pool the big models are
 * not competing for.
 *
 * A lite model writing one scene is a worse scene. It is still a scene, and the
 * alternative on this path is the fixed line — `runAi` catches what comes out
 * of here and answers the reader with silence.
 */
const DEFAULT_FALLBACK_MODELS = 'gemini-flash-latest,gemini-flash-lite-latest';

/** What an operator types into the admin field to stop hopping entirely. */
const FALLBACK_OFF = /^(off|none|tat|tắt)$/i;

/**
 * Least time in which a scene rewrite is worth starting.
 *
 * Measured against gemini-3.7-flash on a real scene prompt (2026-09-16): the
 * successful calls came back between 5.6s and 13.2s. Ten seconds is under the
 * slow end and over the fast one — below it, the rewrite is more likely to be
 * cut off than to finish.
 */
const SCENE_REWRITE_MIN_MS = 10_000;

/** A retry needs room for the wait AND a real call after it, not just the wait. */
const RETRY_MIN_ROOM_MS = 3_000;

/**
 * Below this, there is no point dialling at all.
 *
 * A budget clamped to two seconds does not produce a coach reply on any model
 * measured; it produces a billed call that aborts mid-thought. Failing here is
 * the same outcome three seconds earlier, which the reader gets to spend on the
 * fallback line instead of on the three dots.
 */
const MIN_USEFUL_TIMEOUT_MS = 2_500;

/**
 * The delay a 429 body asks for, in milliseconds, or null.
 *
 * Google puts it in prose rather than in a `Retry-After` header — the body
 * reads "Please retry in 23.610698153s" — so prose is what we parse. A miss is
 * a null and the caller falls back to its own pause; this is a hint, and no
 * behaviour may depend on the wording holding.
 */
function retryAfterMsFrom(body: string): number | null {
  const match = /retry in ([\d.]+)s/i.exec(body);
  if (!match) return null;

  const seconds = Number.parseFloat(match[1]);

  return Number.isFinite(seconds) ? Math.round(seconds * 1000) : null;
}

/**
 * Did the scene run past the word ceiling?
 *
 * Words are whitespace tokens, which is the right unit for vi/en/ko. zh and ja
 * write without spaces, so a whole scene can be two "tokens" — when the count
 * is implausibly low for prose, fall back to counting characters, at roughly
 * two per word. Tolerance of a few words on top: the point is to catch a
 * runaway paragraph, not to punish a 71st word.
 */
function situationTooLong(prompt: string): boolean {
  const limit = SITUATION_MAX_WORDS + 8;
  const tokens = prompt.trim().split(/\s+/).filter(Boolean);

  if (tokens.length > 5) return tokens.length > limit;

  const chars = prompt.replace(/\s+/g, '').length;

  return chars > limit * 2;
}

/**
 * Up to three tappable suggestions, or none.
 *
 * Three, not two: with two, one of them is read as "the right answer and the
 * other one" — a third breaks that pairing and gives the reluctant option
 * somewhere to sit without looking like the wrong choice. The app wraps the row
 * onto a second line rather than pushing the input off-screen. Anything long
 * enough to need a third line is not a suggestion, it is an essay the reader is
 * being asked to endorse, so the length cap stays.
 */
function cleanSamples(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];

  return raw
    .filter((s): s is string => typeof s === 'string')
    .map((s) => s.trim())
    .filter((s) => s.length > 0 && s.length <= 120)
    .slice(0, 3);
}

/**
 * The named ways forward offered after a reaction.
 *
 * Dropped wholesale rather than patched when the model gives fewer than two: a
 * single "option" is not a choice, and the turn reads perfectly well with none
 * — a reaction and a blank box, exactly as it did before this existed. Keys are
 * re-lettered here rather than trusted, because the reader types the letter
 * back and a duplicated or skipped key resolves to the wrong approach.
 */
const sceneOptionLogger = new Logger('cleanSceneOptions');

function cleanSceneOptions(raw: unknown): CoachSceneOption[] {
  if (!Array.isArray(raw)) return [];

  const options = raw
    .filter((item): item is Record<string, unknown> => Boolean(item) && typeof item === 'object')
    .map((item) => ({
      label: typeof item.label === 'string' ? item.label.trim() : '',
      text: typeof item.text === 'string' ? item.text.trim() : '',
    }))
    .filter(
      (item) =>
        item.label.length > 0 &&
        item.label.length <= SCENE_OPTION_LABEL_MAX_CHARS &&
        item.text.length > 0 &&
        item.text.length <= SCENE_OPTION_TEXT_MAX_CHARS,
    )
    .slice(0, SCENE_OPTION_MAX)
    .map((item, index) => ({
      key: String.fromCharCode(65 + index),
      ...item,
    }));

  // Said out loud from here on. Dropping was silent, so a scene arriving with
  // no answers to choose from looked like the model had written none — when in
  // fact it had written three and this function had eaten them.
  const written = Array.isArray(raw) ? raw.length : 0;
  if (written > options.length) {
    sceneOptionLogger.warn(
      `Dropped ${written - options.length} of ${written} scene options for being over the character bounds`,
    );
  }
  if (options.length && options.length < SCENE_OPTION_MIN) {
    sceneOptionLogger.warn(
      `Only ${options.length} scene option survived; the set is dropped because one choice is not a choice`,
    );
  }

  return options.length >= SCENE_OPTION_MIN ? options : [];
}

/** A scene's probe intents, clamped to the ceiling (2–4, see the constants). */
function cleanBeats(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];

  return raw
    .filter((b): b is string => typeof b === 'string')
    .map((b) => b.trim())
    .filter(Boolean)
    .slice(0, SITUATION_MAX_BEATS);
}

/**
 * Is the scene too thin to practise in?
 *
 * The mirror of `situationTooLong`, and the one that matters more now: the
 * failure being fixed is scenes arriving as one-line captions with nothing in
 * them to draw a lesson from. Same token/character fallback for zh and ja, and a
 * few words of slack under the floor.
 */
function situationTooShort(prompt: string): boolean {
  const floor = Math.max(0, SITUATION_MIN_WORDS - 8);
  const tokens = prompt.trim().split(/\s+/).filter(Boolean);

  if (tokens.length > 5) return tokens.length < floor;

  return prompt.replace(/\s+/g, '').length < floor * 2;
}

/** A single short script line (takeaway / goodMove) or null when the model left it empty. */
function cleanLine(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const trimmed = raw.trim();

  return trimmed.length ? trimmed : null;
}

/** The raw shape the situation schema returns — a scene plus its script. */
interface RawSituation {
  prompt?: string;
  promptThirdPerson?: unknown;
  promptStage2?: unknown;
  promptStage2ThirdPerson?: unknown;
  samples?: unknown;
  beats?: unknown;
  beatLines?: unknown;
  counterpart?: unknown;
  takeaway?: unknown;
  goodMove?: unknown;
  openingOptions?: unknown;
}

/**
 * A stage or retelling of the scene is only usable if it still ASKS something —
 * `splitScene` and the whole two-beat flow hang off that question. A part that
 * lost its question is dropped (null), which gracefully shortens the scene
 * rather than stranding the reader on a beat with nothing to answer.
 */
function cleanScenePart(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const trimmed = raw.trim();

  return trimmed && /[?？]/.test(trimmed) ? trimmed : null;
}

/**
 * A second stage that NARRATES the reader's answer — "Bạn vừa nhắn hỏi Minh
 * lấy số liệu ở đâu" — has invented an action they never took: it is written
 * before they answer. "Bạn nói xong thì…" (contentless) is fine; "bạn/you
 * vừa/just <did X>" is the banned shape. One regenerate, then the stage is
 * dropped: a one-stage scene beats a scene that puts words in their mouth.
 */
function stageAssumesReader(part: string | null): boolean {
  return Boolean(
    part && /^\s*["“]?\s*(bạn|you|người đó|they)\s+(vừa|just)\b/i.test(part),
  );
}

/**
 * The counterpart's lines, lined up with the beats.
 *
 * Empties are PRESERVED and the array is padded to the beat count: index i
 * belongs to beat i, so dropping a blank would shift every later line onto the
 * wrong beat and make the Coach perform the wrong pressure at the wrong moment.
 */
function cleanBeatLines(raw: unknown, beatCount: number): string[] {
  const list = Array.isArray(raw) ? raw : [];
  const lines = list
    .slice(0, beatCount)
    .map((line) => (typeof line === 'string' ? line.trim() : ''));

  while (lines.length < beatCount) lines.push('');

  return lines;
}

interface GeminiResponse {
  candidates?: Array<{
    content?: { parts?: Array<{ text?: string }> };
    finishReason?: string;
  }>;
  promptFeedback?: { blockReason?: string };
  /** What the call is billed on. Absent on some error envelopes. */
  usageMetadata?: {
    promptTokenCount?: number;
    candidatesTokenCount?: number;
  };
}

/**
 * Gemini implementation of the coach's five tasks.
 *
 * Raw `fetch` rather than an SDK, matching `GeminiLessonGeneratorService` and
 * `OutputPracticeAiService`: these are plain POSTs, and an SDK would be the only
 * AI client dependency in the tree. Nothing outside this file knows the
 * provider's name — see `CoachAi`.
 */
@Injectable()
export class GeminiCoachService extends CoachAi {
  private readonly logger = new Logger(GeminiCoachService.name);

  constructor(
    private readonly configuration: Configuration,
    private readonly usage: CoachAiUsageService,
    private readonly coachConfig: CoachConfigService,
  ) {
    super();
  }

  /**
   * The conversational model — admin's coach-config override first, so a model
   * swap needs no env change and no deploy; then the GEMINI_MODEL env; then
   * the alias default. Config read failures fall through silently: a broken
   * config row must not silence the Coach.
   */
  private async chatModel(): Promise<string> {
    const cfg = await this.coachConfig.get().catch(() => null);

    return cfg?.geminiModel?.trim() || this.model;
  }

  /** Scene writing — its own override chain, ending at the conversational model. */
  private async sceneModel(): Promise<string> {
    const cfg = await this.coachConfig.get().catch(() => null);

    return (
      cfg?.geminiSceneModel?.trim() ||
      cfg?.geminiModel?.trim() ||
      this.configuration.getGeminiSceneModel?.trim() ||
      this.model
    );
  }

  private get apiKey(): string | undefined {
    return this.configuration.getGeminiApiKey?.trim() || undefined;
  }

  /**
   * An alias, not a pinned version — the same call the import feature made, for
   * the same reason: this feature has already been broken twice by Google
   * retiring a pinned model, and a shifted alias degrades far more gently than
   * a hard 404. `GEMINI_MODEL` still overrides.
   */
  private get model(): string {
    return this.configuration.getGeminiModel?.trim() || 'gemini-flash-latest';
  }

  isConfigured(): boolean {
    return Boolean(this.apiKey);
  }

  async reflect(context: CoachTurnContext): Promise<CoachReflectResult> {
    const payload = await this.request<{
      reply?: string;
      samples?: unknown;
      nextMove?: unknown;
      nextMoment?: unknown;
    }>({
      model: await this.chatModel(),
      kind: CoachAiCallKind.REFLECT,
      prompt: buildReflectPrompt(context),
      responseSchema: REFLECT_RESPONSE_SCHEMA,
      timeoutMs: TURN_TIMEOUT_MS,
      streamField: 'reply',
    });

    const reply = (payload?.reply || '').trim();
    if (!reply) throw new CoachAiError('Empty reply from provider');

    // The two pre-fills are optional on purpose: an empty string means the
    // model had nothing honest to name, and the form then starts blank.
    const line = (value: unknown): string | null =>
      typeof value === 'string' && value.trim() ? value.trim() : null;

    return {
      reply,
      samples: cleanSamples(payload?.samples),
      nextMove: line(payload?.nextMove),
      nextMoment: line(payload?.nextMoment),
    };
  }

  async talkStory(context: CoachTurnContext): Promise<CoachStoryTalkResult> {
    const payload = await this.request<{ kind?: unknown; reply?: string; newAddress?: unknown }>({
      model: await this.chatModel(),
      kind: CoachAiCallKind.TALK_STORY,
      prompt: buildStoryTalkPrompt(context),
      responseSchema: STORY_TALK_RESPONSE_SCHEMA,
      timeoutMs: TURN_TIMEOUT_MS,
      streamField: 'reply',
    });

    // The kind routes the machine, so anything not on the list is read as
    // "carry on" rather than trusted: a misspelt or invented kind must never
    // open the course card or end the session.
    const known = Object.values(CoachStoryKind) as string[];
    const raw =
      typeof payload?.kind === 'string' ? payload.kind.trim().toLowerCase() : '';
    const kind = known.includes(raw)
      ? (raw as CoachStoryKind)
      : CoachStoryKind.NORMAL;

    const reply = (payload?.reply || '').trim();
    // A stop is answered by the app's own fixed line; every other kind has to
    // say something, and an empty answer is a provider failure like any other.
    if (!reply && kind !== CoachStoryKind.STOP) {
      throw new CoachAiError('Empty reply from provider');
    }

    const newAddress =
      typeof payload?.newAddress === 'string' ? payload.newAddress.trim().slice(0, 30) : '';

    return { kind, reply, newAddress: newAddress || null };
  }

  async judgeScene(
    context: CoachTurnContext,
    scene: { prompt: string; retry: boolean },
  ): Promise<CoachSceneJudgeResult> {
    const payload = await this.request<{
      onTrack?: unknown;
      reply?: string;
      engaged?: unknown;
    }>({
      model: await this.chatModel(),
      kind: CoachAiCallKind.JUDGE_SCENE,
      prompt: buildSceneJudgePrompt(context, scene),
      responseSchema: SCENE_JUDGE_RESPONSE_SCHEMA,
      timeoutMs: TURN_TIMEOUT_MS,
      streamField: 'reply',
    });

    const reply = (payload?.reply || '').trim();
    if (!reply) throw new CoachAiError('Empty reply from provider');

    // Booleans arrive as booleans from a schema-bound call, but a lite model
    // has been seen returning "true"/"false" as strings — read both.
    //
    // Owner 2026-09-05: the DEFAULT is now on track. This used to be "anything
    // that is not exactly true is a miss", so a dropped field, a null or a
    // "yes" all sent the reader to the retry offer with a sample line — a
    // parsing accident telling somebody their answer was wrong. This is
    // practice, not an exam: only an explicit false is a miss.
    const raw = payload?.onTrack;
    const onTrack = !(
      raw === false ||
      (typeof raw === 'string' && raw.trim().toLowerCase() === 'false')
    );

    return { onTrack, reply, engaged: payload?.engaged !== false };
  }

  async quizFeedback(
    context: CoachTurnContext,
    quiz: CoachQuizFeedbackInput,
  ): Promise<{ reply: string }> {
    const payload = await this.request<{ reply?: string }>({
      model: await this.chatModel(),
      kind: CoachAiCallKind.QUIZ_FEEDBACK,
      prompt: buildQuizFeedbackPrompt(context, quiz),
      responseSchema: REFLECT_RESPONSE_SCHEMA,
      timeoutMs: TURN_TIMEOUT_MS,
    });

    const reply = (payload?.reply || '').trim();
    if (!reply) throw new CoachAiError('Empty reply from provider');

    return { reply };
  }

  async reactScene(
    context: CoachTurnContext,
    input: { scene: string; said: string; habitTitle?: string | null },
  ): Promise<CoachSceneReactResult> {
    const payload = await this.request<{
      posture?: unknown;
      reply?: string;
      speaker?: string;
      gesture?: unknown;
      engaged?: unknown;
      options?: unknown;
    }>({
      model: await this.chatModel(),
      kind: CoachAiCallKind.REACT_SCENE,
      prompt: buildSceneReactPrompt(context, input),
      responseSchema: SCENE_REACT_RESPONSE_SCHEMA,
      timeoutMs: TURN_TIMEOUT_MS,
      streamField: 'reply',
    });

    const known = Object.values(CoachScenePosture) as string[];
    const raw = typeof payload?.posture === 'string' ? payload.posture.trim().toLowerCase() : '';
    // An invented posture reads as "they said something ordinary" rather than
    // being trusted to drive the reaction's tone.
    const posture = known.includes(raw)
      ? (raw as CoachScenePosture)
      : CoachScenePosture.HESITANT;

    const reply = (payload?.reply || '').trim();
    if (!reply) throw new CoachAiError('Empty reply from provider');

    return {
      posture,
      reply,
      speaker: (payload?.speaker || '').trim().slice(0, 24),
      gesture: cleanLine(payload?.gesture) ?? '',
      // Only an explicit false counts: a model that omits the field has not
      // said the reader was off-topic, and holding on silence would strand them.
      engaged: payload?.engaged !== false,
      options: cleanSceneOptions(payload?.options),
    };
  }

  async makeQuiz(input: CoachQuizGenerationInput): Promise<CoachQuizGenerationResult> {
    const payload = await this.request<{
      questions?: Array<{
        question?: string;
        options?: unknown;
        correctIndex?: unknown;
        explanation?: string;
      }>;
    }>({
      model: await this.chatModel(),
      kind: CoachAiCallKind.MAKE_QUIZ,
      prompt: buildKeypointQuizPrompt(input),
      responseSchema: KEYPOINT_QUIZ_RESPONSE_SCHEMA,
      maxOutputTokens: GENERATION_OUTPUT_TOKENS,
      // Written once and stored, off the reader's clock, so it may take longer
      // than a turn is allowed to.
      timeoutMs: QUIZ_GEN_TIMEOUT_MS,
      fullThinking: true,
    });

    // A malformed question is dropped rather than trusted: a quiz with no right
    // answer, or with the index pointing past the options, would mark a correct
    // answer wrong in front of somebody.
    const questions = (payload?.questions ?? [])
      .map((row) => {
        const options = Array.isArray(row?.options)
          ? row.options.map((option) => String(option ?? '').trim()).filter(Boolean)
          : [];
        const correctIndex = Number(row?.correctIndex);
        const question = (row?.question ?? '').trim();

        return { question, options, correctIndex, explanation: (row?.explanation ?? '').trim() || null };
      })
      .filter(
        (row) =>
          row.question &&
          row.options.length >= 2 &&
          Number.isInteger(row.correctIndex) &&
          row.correctIndex >= 0 &&
          row.correctIndex < row.options.length,
      );
    if (!questions.length) throw new CoachAiError('No usable question from provider');

    return { questions };
  }

  async extractMemory(
    input: CoachMemoryExtractionInput,
  ): Promise<CoachMemoryExtraction> {
    const payload = await this.request<Partial<CoachMemoryExtraction>>({
      model: await this.chatModel(),
      kind: CoachAiCallKind.EXTRACT_MEMORY,
      prompt: buildMemoryExtractionPrompt(input),
      responseSchema: MEMORY_EXTRACTION_RESPONSE_SCHEMA,
      // Runs after the session, off the reader's clock — it may take its time.
      timeoutMs: TURN_TIMEOUT_MS * 2,
    });

    const list = <T>(value: unknown): T[] => (Array.isArray(value) ? (value as T[]) : []);

    const topic = (payload?.greetingTopic ?? '').toString().trim();

    return {
      memories: list(payload?.memories),
      goals: list(payload?.goals),
      episodes: list(payload?.episodes),
      progress: list(payload?.progress),
      // Cắt ở đây chứ không tin lời hứa trong prompt: mảnh này được nhét vào
      // một câu cố định bên client, dài quá thì câu chào vỡ dòng trên máy hẹp.
      greetingTopic: topic
        ? topic.slice(0, MEMORY_GREETING_TOPIC_MAX_CHARS).trim()
        : null,
    };
  }

  async lessonTalk(
    context: CoachTurnContext,
    input: CoachLessonTalkInput,
  ): Promise<{ reply: string; engaged: boolean }> {
    const payload = await this.request<{ reply?: string; engaged?: unknown }>({
      model: await this.chatModel(),
      kind: CoachAiCallKind.LESSON_TALK,
      prompt: buildLessonTalkPrompt(context, input),
      responseSchema: ENGAGED_REPLY_RESPONSE_SCHEMA,
      timeoutMs: TURN_TIMEOUT_MS,
      streamField: 'reply',
    });

    const reply = (payload?.reply || '').trim();
    if (!reply) throw new CoachAiError('Empty reply from provider');

    return { reply, engaged: payload?.engaged !== false };
  }

  async draftTwoCols(context: CoachTurnContext): Promise<CoachTwoColsResult> {
    const payload = await this.request<{ reply?: string; lines?: unknown }>({
      model: await this.chatModel(),
      kind: CoachAiCallKind.DRAFT_TWO_COLS,
      prompt: buildTwoColsPrompt(context),
      responseSchema: TWO_COLS_RESPONSE_SCHEMA,
      timeoutMs: TURN_TIMEOUT_MS,
    });

    const reply = (payload?.reply || '').trim();
    if (!reply) throw new CoachAiError('Empty reply from provider');

    const lines = Array.isArray(payload?.lines)
      ? payload.lines
          .filter((l): l is string => typeof l === 'string')
          .map((l) => l.trim())
          .filter(Boolean)
      : [];

    return { reply, lines };
  }

  async matchHabit(
    context: CoachTurnContext,
    candidates: Array<{ id: string; title: string }>,
  ): Promise<CoachHabitMatchResult> {
    const payload = await this.request<{
      reply?: string;
      habitId?: string | null;
      confidence?: number;
      enough?: boolean;
    }>({
      model: await this.chatModel(),
      kind: CoachAiCallKind.MATCH_HABIT,
      prompt: buildHabitMatchPrompt(context, candidates),
      responseSchema: HABIT_MATCH_RESPONSE_SCHEMA,
      timeoutMs: TURN_TIMEOUT_MS,
    });

    const reply = (payload?.reply || '').trim();
    if (!reply) throw new CoachAiError('Empty reply from provider');

    const confidence =
      typeof payload?.confidence === 'number' ? payload.confidence : 0;

    return {
      reply,
      habitId: payload?.habitId ? String(payload.habitId) : null,
      confidence,
      enough: payload?.enough === true,
    };
  }

  async closingLine(
    context: CoachTurnContext,
    plan: CoachPlanQuote,
    reminder: { enabled: boolean; hour: number; minute: number } | null,
  ): Promise<CoachClosingLineResult> {
    const payload = await this.request<{ line?: string }>({
      model: await this.chatModel(),
      kind: CoachAiCallKind.CLOSING_LINE,
      prompt: buildClosingLinePrompt(context, plan, reminder),
      responseSchema: CLOSING_LINE_RESPONSE_SCHEMA,
      timeoutMs: TURN_TIMEOUT_MS,
    });

    const line = (payload?.line || '').trim();
    // A question is not a closing line — the caller falls back to the fixed
    // one rather than reopening the conversation with the model's words.
    if (!line || /[?？]/.test(line)) {
      throw new CoachAiError('Unusable closing line from provider');
    }

    return { line };
  }

  async generateSituation(
    input: CoachSituationInput,
  ): Promise<CoachSituationResult> {
    const payload = await this.request<RawSituation>({
      // Scene writing runs once per practice and carries the coach's most
      // multi-constraint prompt — the admin's scene-model override (then the
      // GEMINI_SCENE_MODEL env) lets it run a stronger model than the
      // every-turn replies without taxing every turn.
      model: await this.sceneModel(),
      kind: CoachAiCallKind.GENERATE_SITUATION,
      prompt: buildSituationPrompt(input),
      // Chỉ phần người đọc nhìn thấy khi cảnh mở ra, khi người gọi xin thế.
      responseSchema: input.openingOnly
        ? SITUATION_OPENING_RESPONSE_SCHEMA
        : SITUATION_RESPONSE_SCHEMA,
      timeoutMs: TURN_TIMEOUT_MS,
      maxOutputTokens: GENERATION_OUTPUT_TOKENS,
      /**
       * `low` thinking, not full — and the reason is the SPREAD, not the mean.
       *
       * Measured on this same prompt and schema (2026-09-16):
       *   full thinking     -> 5.584 / 8.653 / 13.214 ms
       *   thinkingLevel low -> 7.543 / 7.814 /  9.644 ms
       *
       * Full is faster on a good run, which is what made it look like the right
       * setting. But the budget is 15s and a timeout is decided by the BAD run:
       * 13.2s left under two seconds of headroom, and the dev log for
       * 2026-09-17 shows this call crossing the line three times in half an
       * hour. Low gives up about two seconds at the good end to buy back three
       * and a half at the bad end, which is the only end that fails.
       *
       * The scene's SECOND stage keeps full thinking (`writeRest` below): it
       * runs detached, off the reader's clock, so its worst case costs nobody
       * anything.
       */
      /**
       * The scene's setup and question, shown while the rest is still written.
       *
       * The biggest win in the feature — this is the longest wait there is
       * (5.6-13.2s measured) and `prompt` is barely a quarter of what the call
       * returns; the reader does not need the second stage, the chips or the
       * takeaway until they answer.
       *
       * FIRST ATTEMPT ONLY. If a gate rejects this draft the whole scene is
       * rewritten, and streaming the rewrite would type a second, different
       * scene over the first one in front of the reader. The rewrite arrives
       * whole, through the response, and replaces the preview in one step.
       */
      streamField: input.retried ? undefined : 'prompt',
    });

    let prompt = (payload?.prompt || '').trim();
    if (!prompt) throw new CoachAiError('Empty situation from provider');

    /**
     * Every way this draft falls short, judged in ONE pass.
     *
     * The bounds are enforced here rather than in the prompt because scenes are
     * reused: a bad one is not one bad turn, it is every reader's turn until an
     * editor notices.
     *
     * What changed (2026-09-16) is the retry ARITHMETIC, not the gate. Each of
     * these four used to own a separate `if` that recursed on its own flag, so
     * a draft that was both too long and short of a question spent two whole
     * regenerations fixing one fault at a time — up to four, at roughly eight
     * seconds and 8k output tokens each, while a reader sat in front of a
     * typing indicator. The rejection notes already compose in the prompt
     * (`buildSituationPrompt` appends one paragraph per flag), so the model can
     * be told about all of them at once and answer all of them at once.
     */
    const faults = {
      // The whole two-beat flow hangs off the scene's closing question — a
      // scene ending on a statement leaves the feeling beat nothing to ask.
      retryNoQuestion: !/[?？]/.test(prompt),
      retryTooLong: situationTooLong(prompt),
      // The one that earns its keep: a caption is the defect this gate exists
      // to remove.
      retryTooShort: situationTooShort(prompt),
      // A second stage that narrates the reader's answer — it is written
      // before they answer, so it may know THAT they responded, never what.
      retryStage2Assumed:
        stageAssumesReader(cleanScenePart(payload?.promptStage2)) ||
        stageAssumesReader(cleanScenePart(payload?.promptStage2ThirdPerson)),
    };
    const faulted = Object.entries(faults)
      .filter(([, failed]) => failed)
      .map(([name]) => name);

    // One regeneration, carrying every rejection. Then trust the second answer
    // and repair what is left below — a slightly-off scene beats no scene, and
    // beats one that arrives after the app has stopped listening.
    if (faulted.length && !input.retried && this.roomForSceneRewrite()) {
      this.logger.warn(
        `Coach scene rewritten once for: ${faulted.join(', ')}`,
      );

      return this.generateSituation({ ...input, ...faults, retried: true });
    }

    // Second pass, still no question: append the server's own plain one rather
    // than ship a dead end.
    if (faults.retryNoQuestion) {
      prompt = `${prompt} ${
        COACH_SCENE_DEFAULT_QUESTION[input.locale] ??
        COACH_SCENE_DEFAULT_QUESTION.en
      }`;
    }

    const draftedBeats = cleanBeats(payload?.beats);
    const stage2 = cleanScenePart(payload?.promptStage2);
    const stage2Third = cleanScenePart(payload?.promptStage2ThirdPerson);
    // Still narrating after the retry: drop BOTH tellings of the stage — the
    // scene runs one-stage rather than putting words in the reader's mouth.
    const stageBad = stageAssumesReader(stage2) || stageAssumesReader(stage2Third);
    const drafted: CoachSituationResult = {
      prompt,
      promptThirdPerson: cleanScenePart(payload?.promptThirdPerson),
      promptStage2: stageBad ? null : stage2,
      promptStage2ThirdPerson: stageBad ? null : stage2Third,
      samples: cleanSamples(payload?.samples),
      beats: draftedBeats,
      beatLines: cleanBeatLines(payload?.beatLines, draftedBeats.length),
      counterpart: cleanLine(payload?.counterpart),
      takeaway: cleanLine(payload?.takeaway),
      goodMove: cleanLine(payload?.goodMove),
      openingOptions: cleanSceneOptions(payload?.openingOptions),
    };

    // Scenes are written AT PRACTICE TIME now (owner, 2026-08-28) — the reader
    // is waiting on this very call, so the offline editor pass no longer runs:
    // it doubled the wait, and an editor pass over stage one alone could
    // rename the people out from under the other three texts one call wrote
    // together. The word-bound retries above are the whole quality gate.
    return drafted;
  }

  /**
   * Is there time left to write the scene AGAIN, or only to spoil it?
   *
   * A scene generation is the most expensive call in the feature — the heaviest
   * prompt, 8k output tokens, 8-13s when it goes well. Under a turn budget the
   * rewrite gets whatever the first attempt left behind, and a rewrite handed
   * five seconds does not produce a better scene: it produces a billed call
   * that aborts, after which the reader gets a pooled scene anyway, five
   * seconds later than they could have.
   *
   * So the rewrite is skipped rather than attempted in a window it cannot fit,
   * and the faulted draft is repaired in code below. Outside a reader-facing
   * request there is no budget and the rewrite always runs.
   */
  private roomForSceneRewrite(): boolean {
    const left = coachTimeLeftMs();

    return left === null || left >= SCENE_REWRITE_MIN_MS;
  }

  /**
   * Pha hai của một cảnh: ba trường người đọc chưa cần lúc mở.
   *
   * Chạy NGOÀI đồng hồ người đọc — cảnh đã ở trên màn hình và họ đang đọc nó.
   * Chặng hai chỉ tới sau khi họ trả lời chặng một (vài chục giây sau), còn
   * `takeaway` và `goodMove` tới lúc kết buổi.
   *
   * Timeout riêng và rộng hơn một lượt chat, vì không ai ngồi nhìn ba chấm chờ
   * nó. `fullThinking` giữ nguyên: chặng hai là chỗ dễ hỏng nhất trong cả cảnh
   * — nó phải biết đã có người trả lời mà tuyệt đối không được đoán họ nói gì.
   *
   * Ném lỗi khi hỏng, và người gọi nuốt: một cảnh thiếu chặng hai vẫn luyện
   * được (nó chạy một chặng), còn một cảnh không có gì thì không.
   */
  async completeSituation(
    input: CoachSituationInput,
    scene: { prompt: string; counterpart: string | null },
  ): Promise<CoachSituationRest> {
    const payload = await this.request<RawSituation>({
      model: await this.sceneModel(),
      kind: CoachAiCallKind.COMPLETE_SITUATION,
      prompt: buildSituationRestPrompt(input, scene),
      responseSchema: SITUATION_REST_RESPONSE_SCHEMA,
      timeoutMs: QUIZ_GEN_TIMEOUT_MS,
      maxOutputTokens: GENERATION_OUTPUT_TOKENS,
      fullThinking: true,
    });

    const stage2 = cleanScenePart(payload?.promptStage2);

    return {
      // Chặng hai kể hộ câu trả lời của người đọc thì BỎ HẲN, không sinh lại:
      // cảnh chạy một chặng còn hơn đặt lời vào miệng họ, và cảnh thì đã ở
      // trên màn hình rồi nên không có gì để chờ thêm nữa.
      promptStage2: stageAssumesReader(stage2) ? null : stage2,
      takeaway: cleanLine(payload?.takeaway),
      goodMove: cleanLine(payload?.goodMove),
    };
  }

  /**
   * The offline editor pass over a freshly-drafted scene script — see
   * `buildSituationCritiquePrompt`. Returns the corrected script, or null when
   * the provider gave nothing usable (the caller then keeps the draft).
   */
  private async critiqueSituation(
    input: CoachSituationInput,
    draft: CoachSituationResult,
  ): Promise<CoachSituationResult | null> {
    const payload = await this.request<RawSituation>({
      model: await this.chatModel(),
      kind: CoachAiCallKind.CRITIQUE_SITUATION,
      prompt: buildSituationCritiquePrompt(input, {
        prompt: draft.prompt,
        beats: draft.beats,
        takeaway: draft.takeaway ?? '',
        goodMove: draft.goodMove ?? '',
      }),
      responseSchema: SITUATION_RESPONSE_SCHEMA,
      timeoutMs: TURN_TIMEOUT_MS,
      maxOutputTokens: GENERATION_OUTPUT_TOKENS,
      fullThinking: true,
    });

    const prompt = (payload?.prompt || '').trim();
    if (!prompt) return null;

    const beats = cleanBeats(payload?.beats);

    return {
      prompt,
      promptThirdPerson: cleanScenePart(payload?.promptThirdPerson),
      promptStage2: cleanScenePart(payload?.promptStage2),
      promptStage2ThirdPerson: cleanScenePart(payload?.promptStage2ThirdPerson),
      samples: cleanSamples(payload?.samples),
      beats,
      beatLines: cleanBeatLines(payload?.beatLines, beats.length),
      counterpart: cleanLine(payload?.counterpart),
      takeaway: cleanLine(payload?.takeaway),
      goodMove: cleanLine(payload?.goodMove),
      openingOptions: cleanSceneOptions(payload?.openingOptions),
    };
  }

  /**
   * The meaning-question gate. Same lite model and short budget as the risk
   * read: it decides one enum value, and paying the conversational model's
   * latency for it would tax the beat it is protecting.
   */
  async classifyQuestion(
    reply: string,
    locale: string,
  ): Promise<CoachQuestionVerdict> {
    const payload = await this.request<{ verdict?: string }>({
      model: RISK_MODEL,
      kind: CoachAiCallKind.CLASSIFY_QUESTION,
      prompt: buildQuestionGuardPrompt(reply, locale),
      responseSchema: QUESTION_GUARD_RESPONSE_SCHEMA,
      timeoutMs: RISK_TIMEOUT_MS,
    });

    return { banned: payload?.verdict === 'banned' };
  }

  async scoreScene(
    context: CoachTurnContext,
    rubric: CoachRubricCriterion[],
    scene: { prompt: string; takeaway?: string | null; goodMove?: string | null },
  ): Promise<CoachSceneScoreResult> {
    const payload = await this.request<{
      criteria?: unknown;
      strength?: string;
      improve?: string;
      tip?: string;
      betterPhrasing?: string;
    }>({
      model: await this.chatModel(),
      kind: CoachAiCallKind.SCORE_SCENE,
      prompt: buildSceneScorePrompt(context, rubric, scene),
      responseSchema: SCENE_SCORE_RESPONSE_SCHEMA,
      timeoutMs: TURN_TIMEOUT_MS,
    });

    // Keys come back from the model, so they are checked against the rubric
    // rather than trusted: an invented key would render as a criterion nobody
    // wrote, and a missing one would silently drop from the reader's average.
    const allowed = new Map(rubric.map((c) => [c.key, c.label]));
    const seen = new Set<string>();
    const criteria = (Array.isArray(payload?.criteria) ? payload.criteria : [])
      .map((raw) => {
        const row = (raw ?? {}) as { key?: unknown; score?: unknown; note?: unknown };
        const key = typeof row.key === 'string' ? row.key.trim() : '';
        if (!allowed.has(key) || seen.has(key)) return null;
        seen.add(key);

        const score = Number(row.score);

        return {
          key,
          score: Number.isFinite(score)
            ? Math.max(0, Math.min(SCENE_SCORE_MAX, Math.round(score * 10) / 10))
            : 0,
          note: typeof row.note === 'string' ? row.note.trim() : '',
        };
      })
      .filter((c): c is { key: string; score: number; note: string } => Boolean(c));

    if (!criteria.length) {
      throw new CoachAiError('Scene score came back with no usable criteria');
    }

    return {
      criteria,
      strength: (payload?.strength || '').trim(),
      improve: (payload?.improve || '').trim(),
      tip: (payload?.tip || '').trim(),
      betterPhrasing: (payload?.betterPhrasing || '').trim(),
    };
  }

  async classifyRisk(text: string, locale: string): Promise<CoachRiskResult> {
    const payload = await this.request<{ level?: string }>({
      model: RISK_MODEL,
      kind: CoachAiCallKind.CLASSIFY_RISK,
      prompt: buildRiskPrompt(text, locale),
      responseSchema: RISK_RESPONSE_SCHEMA,
      timeoutMs: RISK_TIMEOUT_MS,
    });

    const level =
      payload?.level === 'high' || payload?.level === 'low'
        ? payload.level
        : 'none';

    // Only `high` diverts the conversation. `low` is recorded for tuning but
    // does not interrupt: passive hopelessness is a large share of what people
    // legitimately bring here, and answering it with a hotline reads as being
    // handed off rather than heard.
    return { risk: level === 'high', level };
  }

  /**
   * A spoken turn.
   *
   * Its own timeout: a minute of speech is a much bigger upload than any text
   * turn, and cutting it at the conversational 15s would fail the long answers
   * this exists to make easy. The bytes ride inline and are gone the moment the
   * request ends — nothing writes them anywhere.
   */
  async transcribe(
    audio: Buffer,
    mimeType: string,
    locale: string,
  ): Promise<CoachTranscriptResult> {
    const payload = await this.request<{ text?: string }>({
      model: await this.chatModel(),
      kind: CoachAiCallKind.TRANSCRIBE,
      prompt: buildTranscribePrompt(locale),
      responseSchema: TRANSCRIBE_RESPONSE_SCHEMA,
      timeoutMs: TRANSCRIBE_TIMEOUT_MS,
      inlineData: { mimeType, data: audio.toString('base64') },
    });

    return { text: (payload?.text || '').trim() };
  }

  private async request<T>(params: {
    kind: CoachAiCallKind;
    model: string;
    prompt: string;
    responseSchema: object;
    timeoutMs: number;
    inlineData?: { mimeType: string; data: string };
    /** Heavier calls (a whole scene, a quiz) say so; everything else takes the default. */
    maxOutputTokens?: number;
    /**
     * Let the model reason at its own default instead of the low level.
     *
     * Set by the WRITING calls only — a scene, a quiz, the critic pass. Their
     * prompts carry a dozen constraints at once and they run once per practice
     * rather than once per turn, so reasoning is what buys their coherence and
     * nobody is watching a typing indicator while it happens.
     */
    fullThinking?: boolean;
    /**
     * Send this JSON field's prose to the reader while it is still being
     * written — see `coach-stream.ts`.
     *
     * Named rather than boolean because the field differs by call: a reply
     * streams `reply`, a scene streams `prompt`.
     *
     * How much this buys depends on where the field sits in that schema's
     * `propertyOrdering`, since the document arrives in exactly that order:
     *
     * - `SITUATION` (`prompt` first) and `REFLECT` (`reply` its only field) win
     *   most — the reader starts reading while several thousand tokens of
     *   second stage, chips and takeaway are still being written.
     * - `STORY_TALK`, `ENGAGED_REPLY` and `SCENE_REACT` pay a boolean and a
     *   couple of short enums first. Near enough to free.
     * - `SCENE_JUDGE` puts `evidence` — the model's working notes — ahead of
     *   `reply`, and gains least. Left alone deliberately: notes-before-answer
     *   is why that reply is any good, and reordering the schema to stream
     *   sooner would buy a second by spending the judgement.
     *
     * Ignored entirely when no preview channel is open, which is every admin
     * call, every background call, and every older client.
     */
    streamField?: string;
  }): Promise<T> {
    /**
     * The fallback chain is read only once a call has actually failed.
     *
     * Reading it up front would put a second coach-config query on EVERY AI
     * call in the product — the model the call is about to use already cost
     * one — to answer a question that 99.96% of calls never ask (9,594 calls
     * on prod in the week to 2026-09-18; four of them saw a 503).
     */
    let chain: string[] | null = null;
    let model = params.model;

    for (;;) {
      try {
        return await this.attemptWithThinkingRetry<T>({ ...params, model });
      } catch (error: any) {
        if (!(error instanceof CoachAiError)) throw error;
        if (!error.retryable) throw error;

        chain = chain ?? (await this.modelChain(params.model));
        const next = chain[chain.indexOf(model) + 1];

        /**
         * The model is full; the NEXT one is not. Switch immediately.
         *
         * No pause before this hop, unlike the same-model retry below: a
         * different model is a different pool, so the second the first one says
         * 503 the second one is already able to answer. The pause exists to let
         * ONE pool drain, and paying it here would spend the reader's seconds
         * on a wait that buys nothing.
         *
         * Safe with the preview stream for a reason worth stating: every
         * retryable failure is raised BEFORE a byte reaches the sink —
         * `response.ok` is checked before `readStream` is entered, and
         * `readStream` itself never throws (it returns whatever document
         * arrived). So a hop can never write a second reply over one the reader
         * is already reading.
         */
        if (next && this.roomForAnotherModel()) {
          this.logger.warn(
            `Coach AI ${params.kind} falling back from ${model} to ${next} after ${error.message}`,
          );
          model = next;
          continue;
        }

        /**
         * Nothing left to switch to — the one same-model retry, as before.
         *
         * Reached on the last model of the chain, and on any model when the
         * turn no longer has room for a whole further call. Keeping it here
         * means a deployment with no fallbacks configured behaves exactly as it
         * did before this chain existed. It RETURNS rather than looping: one
         * wait per call is the whole budget, and a chain cannot buy a second.
         */
        const waitMs = this.retryWaitMs(error.retryAfterMs);
        if (waitMs === null) throw error;

        this.logger.warn(
          `Coach AI retrying ${params.kind} on ${model} after ${error.message} (waiting ${waitMs}ms)`,
        );
        await new Promise(resolve => setTimeout(resolve, waitMs));

        return this.attemptWithThinkingRetry<T>({ ...params, model });
      }
    }
  }

  /**
   * One model, with the one retry that is about the REQUEST rather than the
   * provider's load.
   *
   * The model does not understand `thinkingConfig` — drop it and go again.
   *
   * The conversational model is an ADMIN setting, changeable without a deploy,
   * and the whole point of the per-kind latency now in the report is to let
   * somebody try a different one. A model that predates thinking would refuse
   * every conversational call in the product with a 400, and the Coach would go
   * silent product-wide on a dropdown change — from a knob whose only job was
   * to shave a second off.
   *
   * Retried immediately rather than after a pause: nothing is overloaded, we
   * simply asked for something this model has never heard of. And handled per
   * model rather than once per turn: the fallback a busy model hops to may well
   * be an older one, and it gets the same courtesy.
   */
  private async attemptWithThinkingRetry<T>(
    params: Parameters<GeminiCoachService['attempt']>[0],
  ): Promise<T> {
    try {
      return await this.attempt<T>(params);
    } catch (error: any) {
      if (
        error instanceof CoachAiError &&
        error.unsupportedThinking &&
        !params.fullThinking
      ) {
        this.logger.warn(
          `Coach AI model ${params.model} rejected thinkingConfig; retrying without it`,
        );

        return this.attempt<T>({ ...params, fullThinking: true });
      }

      throw error;
    }
  }

  /**
   * The models this call may use, best first.
   *
   * Head is whatever the caller picked — the admin's conversational or scene
   * model, or the pinned lite model the classifiers run on. The tail is the
   * fallback list, and the model at the head is dropped from it so a reader
   * never waits through the same busy model twice under two names.
   *
   * Order of authority matches every other model knob in this feature: the
   * admin's coach-config first (swappable without a deploy, which is the whole
   * point when a provider is having a bad morning), then the env, then the
   * built-in pair.
   */
  private async modelChain(primary: string): Promise<string[]> {
    const cfg = await this.coachConfig.get().catch(() => null);
    const configured =
      cfg?.geminiFallbackModels?.trim() ||
      this.configuration.getGeminiFallbackModels?.trim() ||
      DEFAULT_FALLBACK_MODELS;

    // The way to turn the whole thing off from the admin page without a deploy
    // — for the morning a fallback model is itself the problem.
    if (FALLBACK_OFF.test(configured)) return [primary];

    const chain = [primary, ...configured.split(',')]
      .map(model => model.trim())
      .filter(Boolean);

    return [...new Set(chain)];
  }

  /**
   * Whether the turn can still pay for a whole call on another model.
   *
   * Same bar as the same-model retry uses for "a real call after the wait". A
   * hop started with less than this is a reader watching the dots for three
   * more seconds and then getting the fixed line anyway — strictly worse than
   * the fixed line now. Outside a reader-facing request there is no deadline
   * and the hop always has room.
   */
  private roomForAnotherModel(): boolean {
    const left = coachTimeLeftMs();

    return left === null || left > RETRY_MIN_ROOM_MS;
  }

  /**
   * Turns the provider's event stream into the envelope the rest of this method
   * already knows how to read, pushing prose to the reader as it arrives.
   *
   * `alt=sse` sends `data: {…}` lines, each carrying the NEXT PIECE of the
   * answer rather than the answer so far, so the full document is the pieces
   * joined. Two readers walk that text: `CoachJsonFieldStream` pulls the one
   * field worth showing out of JSON that is still half-written, and
   * `CoachSentenceHold` keeps the closing sentence off the screen until a gate
   * has had its say.
   *
   * Nothing here may throw on a malformed line. A stream that goes strange
   * mid-flight must still produce whatever document did arrive, because the
   * caller's own parse — and the reader's actual answer — depend on it. A line
   * we cannot read is a line we skip.
   */
  private async readStream(
    response: Response,
    sink: CoachStreamSink,
    field: string,
  ): Promise<GeminiResponse> {
    const json = new CoachJsonFieldStream(field);
    const hold = new CoachSentenceHold();
    const decoder = new TextDecoder();

    let text = '';
    let pending = '';
    let usageMetadata: GeminiResponse['usageMetadata'];
    let finishReason: string | undefined;
    let blockReason: string | undefined;

    const take = (line: string) => {
      if (!line.startsWith('data:')) return;
      const body = line.slice(5).trim();
      if (!body || body === '[DONE]') return;

      let event: GeminiResponse;
      try {
        event = JSON.parse(body) as GeminiResponse;
      } catch {
        return;
      }

      blockReason = event.promptFeedback?.blockReason ?? blockReason;
      // Both are LAST-writer-wins: the stream reports them as it learns them,
      // and what the final event says is what the call finished as.
      finishReason = event.candidates?.[0]?.finishReason ?? finishReason;
      usageMetadata = event.usageMetadata ?? usageMetadata;

      const delta = event.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!delta) return;

      text += delta;
      const safe = hold.push(json.push(delta));
      if (safe) sink.push(safe);
    };

    const body = response.body as unknown as
      | AsyncIterable<Uint8Array>
      | undefined;
    try {
      if (body) {
        for await (const piece of body) {
          pending += decoder.decode(piece, { stream: true });
          const lines = pending.split('\n');
          // The last element is whatever arrived after the final newline — half
          // a line, most of the time. It waits for the rest of itself.
          pending = lines.pop() ?? '';
          for (const line of lines) take(line);
        }
      }
      if (pending) take(pending);
    } catch (error: any) {
      /**
       * The socket died mid-answer. Keep what arrived; do not rethrow.
       *
       * Rethrowing here would be the one way this feature could put the same
       * words on screen twice: text has already gone to the reader, and an
       * error escaping this method lands in the retry above, which would write
       * the reply again from the top. Returning the partial document instead
       * sends it down the ordinary path — where an unparseable or question-less
       * answer is already handled, and the REST response the client is still
       * waiting on remains the authority.
       */
      this.logger.warn(`Coach AI stream cut short: ${error?.message}`);
    }

    return {
      candidates: [{ content: { parts: [{ text }] }, finishReason }],
      promptFeedback: blockReason ? { blockReason } : undefined,
      usageMetadata,
    };
  }

  /**
   * How long to wait before the one retry, or null when there is no room for
   * one.
   *
   * A 429 body names its own delay ("Please retry in 23.6s") and that number is
   * authoritative — retrying sooner earns another 429 and spends the budget on
   * being refused twice. A 503 has no such hint, so it takes a short fixed
   * pause: overload passes in the low seconds or it does not pass at all.
   *
   * Null whenever the budget cannot hold the wait AND a whole second call. A
   * retry that is going to be cut off mid-flight is worse than no retry: it
   * costs the reader the wait and still answers with silence.
   */
  private retryWaitMs(retryAfterMs: number | null): number | null {
    const waitMs = retryAfterMs ?? RETRY_PAUSE_MS;
    if (waitMs > RETRY_MAX_WAIT_MS) return null;

    const left = coachTimeLeftMs();
    if (left === null) return waitMs;

    return left > waitMs + RETRY_MIN_ROOM_MS ? waitMs : null;
  }

  private async attempt<T>(params: {
    kind: CoachAiCallKind;
    model: string;
    prompt: string;
    responseSchema: object;
    timeoutMs: number;
    inlineData?: { mimeType: string; data: string };
    maxOutputTokens?: number;
    fullThinking?: boolean;
    streamField?: string;
  }): Promise<T> {
    const { kind, model, prompt, responseSchema, inlineData } = params;

    const apiKey = this.apiKey;
    if (!apiKey) {
      this.usage.record({
        kind,
        model,
        inputTokens: 0,
        outputTokens: 0,
        ok: false,
        latencyMs: 0,
        errorCode: 'no_key',
      });
      throw new CoachAiError('GEMINI_API_KEY is not configured');
    }

    /**
     * The shorter of this call's own ceiling and what the turn has left.
     *
     * Without the second half, a turn's calls each got a fresh 15s and the
     * reader paid for all of them in series. Outside a reader-facing request
     * there is no budget and the call's own timeout stands.
     */
    const left = coachTimeLeftMs();
    const timeoutMs = left === null ? params.timeoutMs : Math.min(params.timeoutMs, left);
    if (timeoutMs < MIN_USEFUL_TIMEOUT_MS) {
      this.usage.record({
        kind,
        model,
        inputTokens: 0,
        outputTokens: 0,
        ok: false,
        latencyMs: 0,
        errorCode: 'budget_spent',
      });
      // NOT retryable: there is by definition no time to try again.
      throw new CoachAiError(`Coach AI ran out of turn budget before ${kind}`);
    }

    /**
     * Stream only when somebody is actually watching this call.
     *
     * Both halves have to be true: the CALLER asked for a field to be previewed
     * (`streamField`), and a preview channel is open for this request. An admin
     * regenerating a scene, the nightly quiz writer and an older app all fail
     * the second test and take the plain path, byte for byte as before.
     */
    const sink = params.streamField ? coachStreamSink() : null;
    const streaming = Boolean(sink);

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

    let response: Response;
    const startedAt = Date.now();
    try {
      response = await fetch(
        `${API_BASE}/${encodeURIComponent(model)}:${
          streaming ? 'streamGenerateContent?alt=sse' : 'generateContent'
        }`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            // Header rather than ?key=, so the secret never lands in a proxy or
            // access log that records query strings.
            'x-goog-api-key': apiKey,
          },
          body: JSON.stringify({
            contents: [
              {
                role: 'user',
                // Media FIRST, instructions after: a model follows instructions
                // that come after their material more closely than ones the
                // material is appended to — the same ordering the import
                // generator settled on for PDFs.
                parts: inlineData
                  ? [
                      {
                        inline_data: {
                          mime_type: inlineData.mimeType,
                          data: inlineData.data,
                        },
                      },
                      { text: prompt },
                    ]
                  : [{ text: prompt }],
              },
            ],
            generationConfig: {
              responseMimeType: 'application/json',
              responseSchema,
              maxOutputTokens: params.maxOutputTokens ?? MAX_OUTPUT_TOKENS,
              // Writing calls keep the model's own default; see THINKING_LEVEL_LOW.
              ...(params.fullThinking
                ? {}
                : { thinkingConfig: THINKING_LEVEL_LOW }),
            },
          }),
          signal: controller.signal,
        },
      );
    } catch (error: any) {
      const failedAfterMs = Date.now() - startedAt;
      const timedOut = error?.name === 'AbortError';
      this.usage.record({
        kind,
        model,
        inputTokens: 0,
        outputTokens: 0,
        ok: false,
        latencyMs: failedAfterMs,
        errorCode: timedOut ? 'timeout' : 'network',
      });

      if (timedOut) {
        // Not retried: the abort fired because the budget is spent, and a
        // second call would be cut off sooner than the first.
        throw new CoachAiError(`Coach AI timed out after ${timeoutMs}ms`, {
          timedOut: true,
        });
      }
      // A socket that never opened is the one failure worth an immediate second
      // look — nothing was generated, so nothing is being paid for twice.
      throw new CoachAiError(error?.message || 'Coach AI request failed', {
        retryable: true,
      });
    } finally {
      clearTimeout(timeoutId);
    }

    if (!response.ok) {
      const body = await response.text().catch(() => '');
      /**
       * Recorded with zero tokens, which is the truth: a refusal is not billed.
       *
       * It is still the single most important row in this collection. Every one
       * of these is a turn that answered a reader with silence — `runAi` catches
       * `CoachAiError` and returns `{ reply: null }` — and until now the report
       * showed `failedCalls: 0` straight through them.
       */
      this.usage.record({
        kind,
        model,
        inputTokens: 0,
        outputTokens: 0,
        ok: false,
        latencyMs: Date.now() - startedAt,
        errorCode: String(response.status),
      });

      throw new CoachAiError(
        `Coach AI responded ${response.status}: ${body.slice(0, 300)}`,
        {
          // 429 is quota, 503 is the model being full: both mean "not now"
          // rather than "not ever". Every other status is our own bug and
          // retrying it just spends the reader's remaining seconds.
          retryable: response.status === 429 || response.status === 503,
          retryAfterMs: retryAfterMsFrom(body),
          unsupportedThinking:
            response.status === 400 && /thinking/i.test(body),
        },
      );
    }

    const latencyMs = Date.now() - startedAt;
    const envelope = streaming
      ? await this.readStream(response, sink as CoachStreamSink, params.streamField as string)
      : ((await response.json()) as GeminiResponse);

    /**
     * Books the call for the cost report.
     *
     * Every path from here on is BILLED — a blocked prompt and a malformed
     * answer both cost the same as a good one — so the failure paths record too,
     * flagged `ok: false`. The paths above record too, with zero tokens and an
     * `errorCode`: they cost no money, but each one is a reader who watched the
     * three dots and got nothing, and a report that cannot see them is what let
     * this go unnoticed across 8,955 calls.
     *
     * Fire and forget by contract: a telemetry write must never turn a working
     * coach reply into an error, and must never add latency to one.
     */
    const bill = (ok: boolean, errorCode: string | null = null) =>
      this.usage.record({
        kind,
        model,
        inputTokens: envelope?.usageMetadata?.promptTokenCount ?? 0,
        outputTokens: envelope?.usageMetadata?.candidatesTokenCount ?? 0,
        ok,
        latencyMs,
        errorCode,
      });

    const blockReason = envelope?.promptFeedback?.blockReason;
    if (blockReason) {
      bill(false, 'blocked');
      throw new CoachAiError(`Provider blocked the request (${blockReason})`);
    }

    const text = envelope?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) {
      // The MAX_TOKENS shape gets its own code: it is the one failure here that
      // a ceiling change fixes, and it looks identical to every other empty
      // answer until the report separates them (see MAX_OUTPUT_TOKENS above —
      // 81 of 84 calls died this way once already).
      const finishReason = envelope?.candidates?.[0]?.finishReason;
      bill(false, finishReason === 'MAX_TOKENS' ? 'max_tokens' : 'no_text');
      throw new CoachAiError(
        `Provider returned no text part${finishReason ? ` (${finishReason})` : ''}`,
      );
    }

    try {
      const parsed = JSON.parse(text) as T;
      bill(true);
      return parsed;
    } catch {
      bill(false, 'malformed');
      throw new CoachAiError('Provider returned malformed JSON');
    }
  }
}
