import { isTagName, nextPatchTag } from './course-version.util';

/**
 * Tags are owner-facing names, not internal counters — the owner asked for
 * `v1.0.1` / `v1.0.0` semantics (`plans/260907-course-content-versions/
 * README.md`). Keeping the format canonical is what lets the admin suggest the
 * next patch and lets drive-sync `autoTag` pick a name unattended.
 */
describe('isTagName', () => {
  it('accepts a three-part v-prefixed tag', () => {
    expect(isTagName('v1.0.0')).toBe(true);
    expect(isTagName('v10.4.12')).toBe(true);
    expect(isTagName('v0.0.1')).toBe(true);
  });

  it('rejects anything that is not exactly three numeric parts', () => {
    expect(isTagName('v1.0')).toBe(false);
    expect(isTagName('v1.0.0.1')).toBe(false);
    expect(isTagName('1.0.0')).toBe(false);
    expect(isTagName('v1.0.0-beta')).toBe(false);
    expect(isTagName('')).toBe(false);
  });

  /** Two spellings of one version would break the unique (courseId, tag). */
  it('rejects leading zeros', () => {
    expect(isTagName('v01.0.0')).toBe(false);
    expect(isTagName('v1.00.0')).toBe(false);
  });
});

describe('nextPatchTag', () => {
  it('starts at v1.0.0 when the course has no tag yet', () => {
    expect(nextPatchTag([])).toBe('v1.0.0');
  });

  it('bumps the patch of the highest existing tag', () => {
    expect(nextPatchTag(['v1.0.0'])).toBe('v1.0.1');
    expect(nextPatchTag(['v1.0.9'])).toBe('v1.0.10');
  });

  /** Tags come back in creation order, which is not version order. */
  it('finds the highest tag by version, not by insertion order', () => {
    expect(nextPatchTag(['v1.0.0', 'v1.1.0', 'v1.0.5'])).toBe('v1.1.1');
  });

  /** String comparison would call v2 higher than v10. */
  it('compares parts numerically', () => {
    expect(nextPatchTag(['v2.0.0', 'v10.0.0'])).toBe('v10.0.1');
  });

  it('ignores names that are not tags', () => {
    expect(nextPatchTag(['draft', 'v1.2.3', 'v1.2'])).toBe('v1.2.4');
  });
});
