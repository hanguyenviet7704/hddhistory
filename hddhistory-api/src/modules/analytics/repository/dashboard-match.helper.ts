import { FilterQuery } from 'mongoose';

import { IDashboardFilter } from '../interface/dashboard.interface';
import { UserEvent } from '../schema/user-event.schema';

/**
 * The `$match` every cross-user event pipeline starts with.
 *
 * Lifted out of [AnalyticsDashboardRepository] when the Coach panel needed the
 * same three dimension filters: two repositories reading the same collection
 * must agree on what "prod, iOS, 1.6.0" means, and the way to guarantee that is
 * one function rather than two copies that drift.
 */
export const buildEventMatch = (
  filter: IDashboardFilter,
): FilterQuery<UserEvent> => {
  const where: FilterQuery<UserEvent> = {
    clientTs: { $gte: filter.from, $lte: filter.to },
  };

  if (filter.appEnv) where.appEnv = filter.appEnv;
  if (filter.platform) where.platform = filter.platform;
  if (filter.appVersion) where.appVersion = filter.appVersion;

  return where;
};

/** The same dimension filters without the range — used inside `$lookup`. */
export const buildDimensionOnlyMatch = (
  filter: IDashboardFilter,
): Record<string, unknown> => {
  const where: Record<string, unknown> = {};

  if (filter.appEnv) where.appEnv = filter.appEnv;
  if (filter.platform) where.platform = filter.platform;
  if (filter.appVersion) where.appVersion = filter.appVersion;

  return where;
};

/** `YYYY-MM-DD` in the report's timezone, for `$group` keys on a date field. */
export const dateStringField = (field: string, timezone: string) => ({
  $dateToString: { format: '%Y-%m-%d', date: `$${field}`, timezone },
});

/**
 * Nth-percentile of an already-sorted array field.
 *
 * `$percentile` and `$median` would be the obvious tools but they need
 * MongoDB 7; this indexes into the sorted array instead and works anywhere.
 * The index is clamped so a single-element array returns that element rather
 * than reading past the end.
 */
export const percentileOf = (
  valuesField: string,
  countField: string,
  q: number,
) => ({
  $arrayElemAt: [
    `$${valuesField}`,
    {
      $toInt: {
        $floor: {
          $multiply: [{ $max: [{ $subtract: [`$${countField}`, 1] }, 0] }, q],
        },
      },
    },
  ],
});
