import { SITUATION_MIN_LEVEL } from '../../shared/coach.constant';

/** The little a pool row has to carry for this choice. */
export interface PooledScene {
  id: string;
  level?: number | null;
  slot?: number | null;
}

/**
 * The best scene already in the pool for a reader who cannot wait for a new one.
 *
 * Used in two places, both of which would otherwise hand back nothing: the
 * reader who tapped "Luyện cảnh khó hơn" while Gemini was over its 15s budget,
 * and the pre-generation that has already written the next rung.
 *
 * The ordering, in order:
 *
 * 1. **Never a scene they have seen.** A fallback exists to beat nothing, and
 *    replaying the scene they just practised is worse than nothing.
 * 2. **Nearest rung to what was asked.** A scene one level off is still a
 *    scene; a typing indicator that ends in an error is not.
 * 3. **Ties break UPWARD.** `wantedLevel` is set by "Luyện cảnh khó hơn" and by
 *    nothing else in the product, so answering a request to go up with the rung
 *    below is the one direction that reads as the button having failed.
 * 4. **Then the lowest slot**, purely so the choice is stable: two calls a
 *    second apart must not hand the same reader two different scenes.
 *
 * A row with no `level` is a legacy one and reads as the easiest rung, matching
 * how the rest of the module treats it.
 */
export function pickPooledScene<T extends PooledScene>(params: {
  pool: T[];
  wantedLevel: number;
  avoidIds: string[];
}): T | null {
  const avoid = new Set(params.avoidIds.filter(Boolean));

  const ranked = params.pool
    .filter((scene) => scene.id && !avoid.has(scene.id))
    .map((scene) => {
      const level = scene.level ?? SITUATION_MIN_LEVEL;

      return {
        scene,
        distance: Math.abs(level - params.wantedLevel),
        // Negated so a plain ascending sort puts the HIGHER rung first.
        downward: -level,
        slot: scene.slot ?? 0,
      };
    })
    .sort(
      (a, b) =>
        a.distance - b.distance || a.downward - b.downward || a.slot - b.slot,
    );

  return ranked[0]?.scene ?? null;
}
