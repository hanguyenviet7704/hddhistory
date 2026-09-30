/**
 * `vMAJOR.MINOR.PATCH`, no leading zeros so one version has exactly one
 * spelling — the unique `(courseId, tag)` index depends on that.
 */
const TAG_PATTERN = /^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;

export const isTagName = (value: string): boolean => TAG_PATTERN.test(value);

const partsOf = (tag: string): [number, number, number] | null => {
  const match = TAG_PATTERN.exec(tag);
  if (!match) return null;

  return [Number(match[1]), Number(match[2]), Number(match[3])];
};

/**
 * The name to offer for the next tag: patch-bump the highest tag the course
 * already has, or `v1.0.0` for a course that has never been tagged. Used by
 * the admin's "new tag" field and by drive-sync's unattended `autoTag`.
 */
export const nextPatchTag = (existingTags: string[]): string => {
  let highest: [number, number, number] | null = null;

  for (const tag of existingTags) {
    const parts = partsOf(tag);
    if (!parts) continue;
    if (!highest || compareParts(parts, highest) > 0) highest = parts;
  }

  if (!highest) return 'v1.0.0';

  return `v${highest[0]}.${highest[1]}.${highest[2] + 1}`;
};

const compareParts = (
  a: [number, number, number],
  b: [number, number, number],
): number => a[0] - b[0] || a[1] - b[1] || a[2] - b[2];
