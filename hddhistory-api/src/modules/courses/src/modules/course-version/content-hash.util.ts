import { createHash } from 'crypto';

/**
 * Metadata that a write restamps without the editor changing anything, so it
 * must not count as a content change. Stripped at the top level only — the
 * nested content shapes (roadmap nodes, theory documents, exercise questions)
 * have no fields by these names.
 */
const VOLATILE_KEYS = new Set(['updatedAt', 'updatedBy']);

/**
 * Objects that stand for a scalar (Mongo's ObjectId, Buffer) rather than a
 * bag of fields. They arrive as objects from a non-lean query and as strings
 * from a lean one, and both must hash alike.
 */
const isScalarLike = (value: object): boolean =>
  (value as any).toString !== Object.prototype.toString;

const canonicalize = (value: unknown, depth = 0): unknown => {
  if (value === null || value === undefined) return null;
  if (Array.isArray(value)) {
    // Order is preserved: `lesson.keypoints[]` is the study order and
    // `learningItem.questions[]` the question order, so a reorder is a real
    // content change.
    return value.map(item => canonicalize(item, depth + 1));
  }
  if (value instanceof Date) return value.toISOString();
  if (typeof value !== 'object') return value;
  if (isScalarLike(value as object)) return String(value);

  const out: Record<string, unknown> = {};
  for (const key of Object.keys(value as object).sort()) {
    if (depth === 0 && VOLATILE_KEYS.has(key)) continue;
    out[key] = canonicalize((value as any)[key], depth + 1);
  }

  return out;
};

/**
 * Fingerprint of one content document, used to answer "is the working tree
 * different from the tag the app is serving?" without relying on `updatedAt`,
 * which the `bulkWrite` edit paths never stamp.
 * See `plans/260907-course-content-versions/README.md` §4.
 */
export const contentHash = (doc: unknown): string =>
  createHash('sha256').update(JSON.stringify(canonicalize(doc))).digest('hex');
