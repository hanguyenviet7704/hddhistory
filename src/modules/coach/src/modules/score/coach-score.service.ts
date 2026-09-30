import { Injectable, Logger } from '@nestjs/common';

import { ITranslation } from '@utils/interface/common.interface';

import { ICoachSceneScore } from './interface/score.interface';
import { CoachSceneScoreRepository } from './repository/coach-scene-score.repository';
import {
  RUBRIC_MAX_CRITERIA,
  SCENE_SCORE_DEMOTE_UNDER,
  SCENE_SCORE_MAX,
  SCENE_SCORE_PROMOTE_AT,
  SITUATION_MAX_LEVEL,
  SITUATION_MIN_LEVEL,
  SITUATION_START_LEVEL,
  SKILL_SCORE_WINDOW,
} from '../../shared/coach.constant';
import { CoachRubricCriterion } from '../ai/coach-ai.types';

/**
 * Tầng 4 — rubric scores, the skill number they add up to, and the difficulty
 * ladder they drive.
 *
 * All three live together because they are one loop: a scene is scored, the
 * score moves the skill number, and the number decides how hard the next scene
 * is. Splitting them would put the ladder's rule in one file and the data it
 * reads in another.
 */
@Injectable()
export class CoachScoreService {
  private readonly logger = new Logger(CoachScoreService.name);

  constructor(private readonly repository: CoachSceneScoreRepository) {}

  /**
   * The skill's rubric, parsed from the habit's `key | label` lines.
   *
   * Tolerant on purpose — this text is typed in admin and pasted from a sheet.
   * A line with no separator becomes a criterion whose key is a slug of its
   * label, so a hurried editor still gets a working rubric rather than silence.
   */
  parseRubric(value: ITranslation | null | undefined, locale: string): CoachRubricCriterion[] {
    const raw =
      (value as Record<string, string | undefined> | null | undefined)?.[locale] ||
      value?.en ||
      value?.vi ||
      '';

    const seen = new Set<string>();

    return raw
      .split(/\r?\n/)
      .map((line) => line.trim().replace(/^[-•·]\s*/, ''))
      .filter(Boolean)
      .map((line) => {
        const [head, ...rest] = line.split('|');
        const label = (rest.length ? rest.join('|') : head).trim();
        const key = (rest.length ? head : label)
          .trim()
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, '_')
          .replace(/^_+|_+$/g, '')
          .slice(0, 40);

        return { key, label };
      })
      .filter((c) => {
        if (!c.key || !c.label || seen.has(c.key)) return false;
        seen.add(c.key);

        return true;
      })
      .slice(0, RUBRIC_MAX_CRITERIA);
  }

  /** File one scored scene. Best-effort: a lost score must never break a turn. */
  async record(score: ICoachSceneScore) {
    return this.repository.create(score as never).catch((error: any) => {
      this.logger.warn(`Could not record a scene score: ${error?.message}`);

      return null;
    });
  }

  /**
   * The skill number on 0–100 — "Điểm kỹ năng: 78/100" from the design.
   *
   * A mean over the last `SKILL_SCORE_WINDOW` scenes rather than a lifetime
   * average, because the question it answers is "am I better at this than I
   * was", and a lifetime mean stops moving. Null with no history at all: showing
   * 0/100 to somebody who has never practised reads as a verdict.
   */
  async skillScore(
    userId: string,
    habitId: string,
  ): Promise<{
    score: number | null;
    scenes: number;
    level: number;
    trend: number | null;
  }> {
    const rows = (await this.repository
      .findRecent(userId, habitId, SKILL_SCORE_WINDOW)
      .catch(() => [])) as ICoachSceneScore[];

    if (!rows.length) {
      return { score: null, scenes: 0, level: SITUATION_START_LEVEL, trend: null };
    }

    const mean = (list: ICoachSceneScore[]) =>
      list.reduce((sum, r) => sum + (r.overall ?? 0), 0) / list.length;

    const recent = mean(rows);

    // Trend compares the newer half against the older half of the window — the
    // "2 tuần trước bạn…" claim needs a comparison, not a single number.
    const half = Math.floor(rows.length / 2);
    const trend =
      half >= 1 && rows.length >= 4
        ? Math.round((mean(rows.slice(0, half)) - mean(rows.slice(-half))) * 10) / 10
        : null;

    return {
      score: Math.round((recent / SCENE_SCORE_MAX) * 100),
      scenes: rows.length,
      level: this.nextLevel(rows),
      trend,
    };
  }

  /**
   * How hard the next scene for this skill should be.
   *
   * Reads the last two scored scenes, not the window's mean: the ladder is about
   * "can they do it NOW", and a strong month should not keep pushing somebody
   * who just came unstuck twice. Promotion needs the last TWO scenes at or above
   * the bar — one lucky answer is not a level.
   */
  async levelFor(userId: string, habitId: string): Promise<number> {
    const rows = (await this.repository
      .findRecent(userId, habitId, 2)
      .catch(() => [])) as ICoachSceneScore[];

    return this.nextLevel(rows);
  }

  private nextLevel(rows: ICoachSceneScore[]): number {
    if (!rows.length) return SITUATION_START_LEVEL;

    const last = rows[0];
    const at = last.level ?? SITUATION_START_LEVEL;
    const clamp = (n: number) =>
      Math.max(SITUATION_MIN_LEVEL, Math.min(SITUATION_MAX_LEVEL, n));

    const twoStrong =
      rows.length >= 2 &&
      rows.slice(0, 2).every((r) => (r.overall ?? 0) >= SCENE_SCORE_PROMOTE_AT);
    if (twoStrong) return clamp(at + 1);

    if ((last.overall ?? 0) < SCENE_SCORE_DEMOTE_UNDER) return clamp(at - 1);

    return clamp(at);
  }
}
