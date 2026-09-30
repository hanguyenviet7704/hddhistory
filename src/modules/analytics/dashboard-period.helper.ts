import {
  DEFAULT_APP_ENV,
  DEFAULT_TIMEZONE,
} from './constant/dashboard.constant';
import { GetDashboardDto } from './dto/get-dashboard.dto';
import {
  IDashboardFilter,
  IDashboardRange,
} from './interface/dashboard.interface';

const DAY_MS = 24 * 60 * 60 * 1000;
const DEFAULT_RANGE_DAYS = 7;

/**
 * What "this period" and "the period before" mean, in one place.
 *
 * Lifted out of [AnalyticsDashboardService] when the Coach page needed the same
 * arithmetic. Two report pages that disagree about where the comparison window
 * starts would put two different "so với kỳ trước" badges on the same screen,
 * and nobody looking at them could tell which one was lying.
 */
export const resolveDashboardFilter = (
  dto: GetDashboardDto,
): IDashboardFilter => {
  const to = dto.to ? new Date(dto.to) : new Date();
  const from = dto.from
    ? new Date(dto.from)
    : new Date(to.getTime() - (DEFAULT_RANGE_DAYS - 1) * DAY_MS);

  return {
    // A reversed range is a typo in a saved link, not something to 400 over.
    from: from <= to ? from : to,
    to: from <= to ? to : from,
    appEnv: dto.appEnv ?? DEFAULT_APP_ENV,
    platform: dto.platform,
    appVersion: dto.appVersion,
    timezone: dto.timezone || DEFAULT_TIMEZONE,
  };
};

export const toDashboardRange = (filter: IDashboardFilter): IDashboardRange => ({
  from: filter.from,
  to: filter.to,
  days: Math.max(
    1,
    Math.round((filter.to.getTime() - filter.from.getTime()) / DAY_MS) + 1,
  ),
});

/**
 * The period immediately before, of the same length — what every delta badge
 * compares against. It ends one millisecond before the current range starts, so
 * a day is never counted in both.
 */
export const previousDashboardPeriod = (
  filter: IDashboardFilter,
): IDashboardFilter => {
  const span = filter.to.getTime() - filter.from.getTime();

  return {
    ...filter,
    to: new Date(filter.from.getTime() - 1),
    from: new Date(filter.from.getTime() - 1 - span),
  };
};

/** A rate with no denominator is `null`, never 0 — printing 0% would be a lie. */
export const rateOf = (
  numerator: number,
  denominator: number,
): number | null => {
  if (!denominator) return null;
  return numerator / denominator;
};
