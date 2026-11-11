// The database half of market targeting. `viewer-market.util` answers "should
// this viewer see this ONE item" for a surface that already holds its items in
// memory (the Home banner's slide roster). Courses are the other shape: there
// are hundreds of them and the filter has to be part of the QUERY, so a
// market-restricted course never becomes a page-size hole or a paginated
// count that is off by the courses it silently dropped.
//
// Both halves must stay one rule. This file is the Mongo translation of
// `isVisibleInMarkets` and nothing more — change one, change the other.
import { FilterQuery } from 'mongoose';

import { resolveViewerMarkets } from './viewer-market.util';

/**
 * The Mongo clause for "targeted at a market this viewer belongs to".
 *
 * Mirrors [[isVisibleInMarkets]] exactly, including both cases that look like
 * edge cases and are not:
 *
 * - An item with `countries: []` (the default) or no `countries` field at all
 *   is targeted at nobody in particular, so EVERYONE sees it. That is what
 *   makes this deployable without a migration: every course written before the
 *   field existed reads back as untargeted and keeps behaving as it does today.
 * - A viewer we could place in NO market (`viewerMarkets: []`) sees only
 *   untargeted items. `{ $in: [] }` matches nothing, which is the wanted
 *   answer rather than an accident: the admin said "only these markets", and
 *   showing the item to someone we know nothing about does the opposite.
 *
 * Deliberately NOT indexed. `$size: 0` cannot use an index at all, and the
 * courses collection is in the hundreds — the existing `status` indexes narrow
 * first and the rest is a trivial in-memory pass. Revisit if the catalogue
 * grows by an order of magnitude, in which case store an explicit
 * `isMarketTargeted` boolean rather than trying to index the array's emptiness.
 */
export function marketVisibilityFilter<T>(
  viewerMarkets: string[],
): FilterQuery<T> {
  return {
    $or: [
      { countries: { $size: 0 } },
      { countries: { $exists: false } },
      { countries: { $in: viewerMarkets } },
    ],
  } as FilterQuery<T>;
}

/**
 * Merge the market clause into a filter that may already carry an `$or`.
 *
 * Written as a helper because the naive `{ ...where, ...marketFilter }` is a
 * silent bug: `findOption` puts the title/description search in `$or`, and
 * spreading a second `$or` over it drops the search entirely — the query still
 * runs, still returns courses, and nobody finds out until a user reports that
 * searching stopped narrowing anything. `$and` is the only composition that
 * keeps both.
 */
export function withMarketVisibility<T>(
  where: FilterQuery<T>,
  viewerMarkets: string[] | null | undefined,
): FilterQuery<T> {
  // `null`/`undefined` means "do not filter at all" — an admin reading the
  // whole catalogue, or a scheduler with no viewer to speak of. Distinct from
  // `[]`, which is a real viewer we simply could not place. Collapsing the two
  // would hand the admin panel a market-filtered catalogue.
  if (!viewerMarkets) return where;

  const marketClause = marketVisibilityFilter<T>(viewerMarkets);

  return { $and: [where, marketClause] } as FilterQuery<T>;
}

/**
 * Set by the admin panel's axios client on EVERY request, which is the only
 * reason market targeting can be trusted not to break the panel.
 *
 * ## Why a header and not a role check
 *
 * The obvious gate -- `user.role === UserRole.ADMIN` -- cannot work here.
 * Nothing in this codebase ever populates `role`: `CreateUserDto` defaults
 * every account to `USER` and no endpoint runs `RoleGuard`, so no admin account
 * has ever had `ADMIN`. That exact assumption has already broken the panel
 * three times (see the note on [AnalyticsController]), and here it would break
 * quietly rather than with a 403: an operator in Vietnam would simply not see
 * the Japan-only courses, and nothing would say why.
 *
 * ## Why a header and not a query flag or a separate route
 *
 * `isAll` is not available -- the app sends `isAll: true` too, so it separates
 * nothing. A separate admin route (the pattern `/home-banner/config` uses) does
 * work, but NINE admin pages list courses, and eight of them are course-picker
 * dropdowns in other entities' forms; a route only the Courses page switched to
 * would leave the other eight silently short of the restricted courses. A
 * header set once in `axiosClient` is the one chokepoint every admin request
 * already passes through, so no page can forget it.
 *
 * ## What this is not
 *
 * Not a security boundary, and it does not pretend to be one -- anyone can send
 * the header. It does not need to be: market targeting decides where a course
 * is PROMOTED, not who may open one (`GET /courses/:id` stays unfiltered by
 * design), and this codebase has no working role gate to be weaker than.
 */
export const IGNORE_MARKET_TARGETING_HEADER = 'x-ignore-market-targeting';

/**
 * The markets to filter this request by, or `null` for "do not filter" -- the
 * value [[withMarketVisibility]] wants, resolved in one place so the three
 * services that need it cannot disagree.
 */
export function viewerMarketsForRequest(
  headers: Record<string, any> | undefined,
): string[] | null {
  const optOut = String(headers?.[IGNORE_MARKET_TARGETING_HEADER] ?? '')
    .trim()
    .toLowerCase();

  // Explicit truthy values only. An absent header, an empty one, or a literal
  // '0'/'false' all mean "filter normally" -- the app's behaviour, and the safe
  // default for any caller that never heard of this header.
  if (['1', 'true', 'yes'].includes(optOut)) return null;

  return viewerMarketsFromHeaders(headers);
}

/**
 * The viewer's markets from the request headers the app already sends.
 *
 * A thin adapter over [[resolveViewerMarkets]] so the three services that need
 * it (`course`, `category`, `user-progress`) do not each carry their own copy
 * of the header names — one of them would drift the first time a signal is
 * added, and a market filter that reads the wrong header fails by showing the
 * wrong catalogue, with nothing in the logs.
 */
export function viewerMarketsFromHeaders(
  headers: Record<string, any> | undefined,
): string[] {
  return resolveViewerMarkets({
    // Where the phone IS — set by Cloudflare on every request through it.
    cfCountry: headers?.['cf-ipcountry'],
    // The device's own region, and the only country signal on requests that
    // never went through Cloudflare (local development).
    deviceCountry: headers?.['x-device-country'],
    // What the reader chose IN the app — the signal that reaches a diaspora.
    appLanguage: headers?.['lang'],
  });
}
