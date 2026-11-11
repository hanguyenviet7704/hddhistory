import { createHash } from 'crypto';

/**
 * A stable 0-99 for this viewer within this run.
 *
 * SHA-256 rather than a hand-rolled string hash because the arms have to be
 * the same SIZE as the configured split, not merely deterministic: a weak hash
 * over sequential ids skews the buckets, and a skewed split is a biased
 * experiment that still looks fine in the config screen.
 *
 * The assignment is never stored. It is recomputed on every resolve, so it is
 * stable for a viewer without a row per viewer, and re-deriving it later (in a
 * query, in a support ticket) needs nothing but the key and the id. That is
 * also why `key` MUST change when a new run starts: reusing it would hand
 * every viewer the arm they were in last time, quietly turning a fresh test
 * into a continuation of the old one.
 *
 * Shared by the paywall body experiment and the course-content experiment —
 * one hash, not two copies that can drift apart.
 */
export const experimentBucket = (key: string, viewerId: string): number => {
  const digest = createHash('sha256').update(`${key}:${viewerId}`).digest();

  return digest.readUInt32BE(0) % 100;
};
