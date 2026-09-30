import {
  CoachSituationSource,
  CoachSituationVariant,
} from '../enum/situation.enum';

/**
 * A cached short situation: one scene, one question, for one habit in one
 * language.
 *
 * Write-through cache, not authored content. The first reader to hit a
 * `(habitId, locale, variant)` that does not exist pays a generation; everyone
 * after reads the row. There is no approval queue — an editor fixes a bad one
 * in admin after the fact, which flips `source` to EDITED so generation never
 * overwrites the fix.
 */
/**
 * One named way to answer a scene's question.
 *
 * Structurally the same as the AI layer's `CoachSceneOption` and deliberately
 * declared here rather than imported: this is the PERSISTED shape, and the
 * situation module has no other reason to depend on the model's response types.
 */
export interface ICoachSituationOption {
  /** "A" · "B" · "C" — the shorthand the reader may answer with. */
  key: string;
  /** The approach's NAME, 2–4 words. */
  label: string;
  /** A short line in that approach's voice — never a finished answer. */
  text: string;
}

export interface ICoachSituation {
  habitId: string;
  locale: string;
  variant: CoachSituationVariant;
  audience: string;
  goalKey: string;
  /** Position in the key's pool — see `SITUATION_POOL_SIZE`. */
  slot: number;
  /**
   * Which corner of life the scene is set in — see `CoachSituationContextGroup`.
   * The pool now grows along `habit × nhóm bối cảnh`, not a fixed count per
   * habit, because "mỗi người có tuổi tác, công việc, mối quan tâm khác nhau".
   */
  contextGroup?: string | null;
  /** The scene plus the question, as one block of prose. Second person. */
  prompt: string;
  /**
   * The SAME scene told about somebody else — "Có một người đang ở cuộc họp…".
   * Shown when the day's mood is Tệ or Hơi mệt, so an exposed reader is asked
   * about a third party. Same scene, same id: only the telling changes.
   */
  promptThirdPerson?: string | null;
  /**
   * Nhịp 4 — the scene's SECOND stage, written by the same editor.
   *
   * The other person reacts, the situation turns one notch harder, and it ends
   * in a question again: "An nói lại: 'nhưng deadline gấp rồi…' Giờ bạn nói
   * gì?" Same people, same place — "không phải một bối cảnh mới". Null means
   * the scene has one stage and the flow skips nhịp 4 and 5.
   */
  promptStage2?: string | null;
  /** The second stage told about somebody else, for a low-mood day. */
  promptStage2ThirdPerson?: string | null;
  /** Two ways in, cached with the scene so every reader sees the same pair. */
  samples: string[];
  /**
   * The three named ways to answer stage one's own question.
   *
   * Written WITH the scene, in the same generation, because the row is a
   * write-through cache: one call serves every later reader of this slot, and
   * the reader waiting on the scene pays nothing extra for them.
   *
   * Rendered as TEXT under the question and never as pills — the rule they sit
   * next to is the owner's, and it is about this exact moment: "Không có nút
   * gợi ý câu trả lời — có nút đó thì người dùng sẽ bấm và chép, và cả bài tập
   * mất nghĩa." Naming the approaches teaches the contrast; the sentence the
   * reader sends is still one they typed, which is what `sceneFirstLine` files
   * and what the verdict reads.
   *
   * Empty on legacy rows and whenever the model gave nothing usable — the
   * opening then reads exactly as it did before this field existed.
   */
  openingOptions: ICoachSituationOption[];
  /**
   * The scene's script: the ordered probe intents the Coach walks after the
   * reader's first answer. One entry = one follow-up question (Medium's default
   * is one, the ceiling is two). Empty on legacy rows written before the script
   * existed, which then run the old improvised single-probe behaviour.
   */
  beats?: string[];
  /**
   * What the OTHER person in the scene says at each beat, aligned with `beats`
   * by index — the design's "AI đóng vai A". When a beat has a line the Coach
   * SPEAKS it in character instead of asking about it, which is what turns the
   * practice from an interview about a moment into the moment itself.
   *
   * Optional and sparse: an empty string at index i means "probe, do not act".
   */
  beatLines?: string[];
  /**
   * Difficulty band, 1–5 — see `SITUATION_MIN_LEVEL`. A property of the written
   * scene (how much pressure it applies), not of the reader. Absent on rows
   * written before levels existed, which are read as level 1.
   */
  level?: number;
  /**
   * The other person in the scene, by the name the scene uses ("Linh").
   *
   * Authored with the scene rather than parsed out of it: a heuristic that
   * guesses a name from prose will one day put the reader's own word in the
   * Coach's mouth, and the roleplay turn addresses this person by name.
   */
  counterpart?: string | null;
  /**
   * The lesson this scene is built to make — a real, specific conclusion, not a
   * platitude. Woven into the closing reply in the Coach's own words. Null on
   * legacy rows.
   */
  takeaway?: string | null;
  /**
   * The one concrete move this scene teaches for its moment, ≤10 words. The
   * default pre-fill for the reminder's "sẽ làm gì" when the reader practises
   * this scene. Null on legacy rows.
   */
  goodMove?: string | null;
  source: CoachSituationSource;
  /** Model id that produced it, so a bad batch is traceable to a model change. */
  model?: string | null;
}
