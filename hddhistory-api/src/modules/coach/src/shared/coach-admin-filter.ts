/**
 * The one where-clause behind every admin read of reader-written text.
 *
 * Four collections answer the same four questions — whose, which habit, which
 * window, containing what — and each answers them twice: once for the reading
 * list and once for the per-user roll-up. Eight copies of the same builder is
 * how one of them quietly stops matching the others, so it lives here.
 */
export interface ICoachAdminFilter {
  userId?: string;
  habitId?: string;
  from?: Date;
  to?: Date;
  search?: string;
}

export function coachAdminWhere(
  filter: ICoachAdminFilter,
  options: {
    /**
     * The field the search box searches. `dip` lives on the session under its
     * own name; everywhere else the reader's words are in `content`.
     */
    textField?: string;
    /** Conditions the collection always carries — see the dip repository. */
    base?: Record<string, unknown>;
  } = {},
): Record<string, unknown> {
  const textField = options.textField ?? 'content';
  const where: Record<string, unknown> = { ...(options.base ?? {}) };

  if (filter.userId) where.userId = filter.userId;
  if (filter.habitId) where.habitId = filter.habitId;
  if (filter.from || filter.to) {
    where.createdAt = {
      ...(filter.from ? { $gte: filter.from } : {}),
      ...(filter.to ? { $lte: filter.to } : {}),
    };
  }
  if (filter.search) {
    // Unindexed on purpose: a text index on people's own words is a bigger
    // commitment than a scan over a collection this size, and the search box is
    // used to find one row, not to power a feature.
    //
    // Merged into whatever the base already says about this field rather than
    // replacing it: on `dip` the base is what excludes the sessions that never
    // reached T4, and dropping it would count every session as a dip.
    where[textField] = {
      ...((where[textField] as Record<string, unknown>) ?? {}),
      $regex: filter.search,
      $options: 'i',
    };
  }

  return where;
}

/**
 * One reader's footprint in ONE collection — merged across the four by
 * `CoachContentService`.
 *
 * Unlike the reading list, this is never capped per source: a cap would have to
 * fall somewhere in the middle of a user's rows, and the count it produced
 * would be a number that is wrong rather than a number that is missing. These
 * collections are small — a group over all of them is cheaper than explaining
 * the alternative.
 */
export interface ICoachUserRollup {
  userId: string;
  count: number;
  firstAt: Date;
  lastAt: Date;
}
