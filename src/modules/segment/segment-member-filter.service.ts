import { Injectable } from '@nestjs/common';
import { FilterQuery, Types } from 'mongoose';

import { SegmentCriteriaDto } from './dto/upsert-segment.dto';
import { SegmentRepository } from './repository/segment.repository';
import { SegmentCriteria } from './schema/segment.schema';
import { USER_TYPES, UserType } from './segment-match.util';
import { SubscriptionService } from '../payment/subscriptions/subscription.service';
import { User } from '../user/src/modules/auth/schema/user.schema';

const DAY_MS = 86_400_000;

/**
 * Compiles segment criteria into Mongo filters — and nothing else.
 *
 * Split out of `SegmentService` for one hard reason: that service injects the
 * REQUEST-scoped `RequestService`, so Nest makes it request-scoped too. The
 * notification dispatcher is driven by an `@Cron` singleton, and injecting a
 * request-scoped provider there would bubble the scope up until the cron itself
 * was never registered — the schedule would stop firing with no error anywhere.
 * `nest build` cannot see that; only a boot can.
 *
 * So anything a background job needs lives here, where the only dependencies are
 * singletons.
 */
@Injectable()
export class SegmentMemberFilterService {
  /** See `memberFilterForSegments` for why this cache exists. */
  private static readonly MEMBER_FILTER_TTL_MS = 60 * 1000;
  private readonly memberFilterCache = new Map<
    string,
    { filter: FilterQuery<User>; expiresAt: number }
  >();

  constructor(
    private readonly segmentRepository: SegmentRepository,
    private readonly subscriptionService: SubscriptionService,
  ) {}

  /**
   * One Mongo filter selecting every member of ANY of [segmentIds] — the same
   * OR that `filterItemsForViewer` applies per viewer, so "targeted at these
   * segments" means one thing whether it is evaluated for a Home banner or for
   * a push notification.
   *
   * Returns null when nothing was targeted (the caller should not filter at
   * all). When ids WERE given but none resolves — every segment deleted after
   * the admin picked it — the filter matches nobody rather than everybody.
   * Failing open here would turn a narrow campaign into a blast to the whole
   * user base, which is the one mistake a push cannot take back.
   *
   * Cached briefly because `buildMemberFilter` warns against the serve path:
   * compiling `userTypes` pulls the entire active-premium population out of
   * MySQL, and the notification dispatcher asks per due timezone group, many
   * times an hour. Segment criteria change at admin speed, so a stale minute is
   * harmless.
   */
  async memberFilterForSegments(
    segmentIds: string[] | undefined,
  ): Promise<FilterQuery<User> | null> {
    const wanted = (segmentIds ?? [])
      .map(id => id.trim())
      .filter(id => id && Types.ObjectId.isValid(id));
    if (wanted.length === 0) return null;

    const cacheKey = [...new Set(wanted)].sort().join(',');
    const cached = this.memberFilterCache.get(cacheKey);
    if (cached && cached.expiresAt > Date.now()) return cached.filter;

    const segments = await this.segmentRepository.findByIds(wanted);
    const filter: FilterQuery<User> =
      segments.length === 0
        ? { _id: { $in: [] } }
        : {
            $or: await Promise.all(
              segments.map(segment => this.buildMemberFilter(segment.criteria)),
            ),
          };

    this.memberFilterCache.set(cacheKey, {
      filter,
      expiresAt: Date.now() + SegmentMemberFilterService.MEMBER_FILTER_TTL_MS,
    });
    return filter;
  }

  /**
   * The same rules as `matchesCriteria`, compiled to a Mongo filter.
   *
   * Two deliberate compromises, both admin-path-only:
   * - `lastSession` falls back to `updatedAt` for users with no recorded
   *   action, mirroring the fact resolution above.
   * - `userTypes` pulls the whole active-premium population from MySQL and
   *   compiles it into `$in`/`$nin` lists. Fine at admin click frequency;
   *   never let the serve path in here.
   */
  async buildMemberFilter(
    criteria: SegmentCriteria | SegmentCriteriaDto | undefined,
  ): Promise<FilterQuery<User>> {
    const and: FilterQuery<User>[] = [];
    if (!criteria) return {};

    const createdAt: Record<string, Date> = {};
    if (criteria.firstSessionFrom) {
      createdAt.$gte = new Date(criteria.firstSessionFrom);
    }
    if (criteria.firstSessionTo) {
      createdAt.$lte = new Date(criteria.firstSessionTo);
    }

    // Lifecycle D-days are a second window on createdAt: day ∈ [from, to]
    // ⇔ createdAt ≤ now − from·d and createdAt > now − (to+1)·d.
    const now = Date.now();
    if (criteria.lifecycleFrom != null) {
      const cap = new Date(now - criteria.lifecycleFrom * DAY_MS);
      if (!createdAt.$lte || cap < createdAt.$lte) createdAt.$lte = cap;
    }
    if (criteria.lifecycleTo != null) {
      const floor = new Date(now - (criteria.lifecycleTo + 1) * DAY_MS);
      if (!createdAt.$gte || floor > createdAt.$gte) createdAt.$gt = floor;
    }
    if (Object.keys(createdAt).length > 0) and.push({ createdAt });

    if (criteria.lastSessionFrom || criteria.lastSessionTo) {
      const range: Record<string, Date> = {};
      if (criteria.lastSessionFrom) {
        range.$gte = new Date(criteria.lastSessionFrom);
      }
      if (criteria.lastSessionTo) range.$lte = new Date(criteria.lastSessionTo);
      and.push({
        $or: [
          { 'lastAction.time': range },
          { 'lastAction.time': null, updatedAt: range },
        ],
      });
    }

    if (criteria.languages?.length) {
      // Stored values are not guaranteed a case, so match both spellings
      // rather than assume a write path normalised them.
      and.push({
        language: {
          $in: [
            ...criteria.languages,
            ...criteria.languages.map(code => code.toUpperCase()),
          ],
        },
      });
    }

    if (criteria.countries?.length) {
      and.push({
        country: {
          $in: [
            ...criteria.countries,
            ...criteria.countries.map(code => code.toLowerCase()),
          ],
        },
      });
    }

    if (criteria.deviceTypes?.length) {
      and.push({ 'devices.pushPlatform': { $in: criteria.deviceTypes } });
    }

    if (criteria.userIds?.length) {
      and.push({
        _id: {
          $in: criteria.userIds
            .filter(id => Types.ObjectId.isValid(id))
            .map(id => new Types.ObjectId(id)),
        },
      });
    }

    if (criteria.userGoals?.length) {
      and.push({ 'onboarding.learningGoal': { $in: criteria.userGoals } });
    }

    if (criteria.topicIds?.length) {
      and.push({
        'onboarding.skillsetWantToMaster': { $in: criteria.topicIds },
      });
    }

    const userTypes = (criteria.userTypes ?? []).filter(
      (type): type is UserType => USER_TYPES.includes(type as UserType),
    );
    if (userTypes.length > 0 && userTypes.length < USER_TYPES.length) {
      const premium =
        await this.subscriptionService.findAllActivePremiumUsers();
      const toObjectIds = (ids: string[]) =>
        ids
          .filter(id => Types.ObjectId.isValid(id))
          .map(id => new Types.ObjectId(id));

      const lifetimeIds = toObjectIds(
        premium.filter(row => row.lifetime).map(row => row.userId),
      );
      const subscriptionIds = toObjectIds(
        premium.filter(row => !row.lifetime).map(row => row.userId),
      );
      const allPremiumIds = [...lifetimeIds, ...subscriptionIds];

      const buckets: FilterQuery<User>[] = [];
      if (userTypes.includes('pro_lifetime')) {
        buckets.push({ _id: { $in: lifetimeIds } });
      }
      if (userTypes.includes('pro_subscription')) {
        buckets.push({ _id: { $in: subscriptionIds } });
      }
      if (userTypes.includes('free_logged_in')) {
        buckets.push({ anonymous: false, _id: { $nin: allPremiumIds } });
      }
      if (userTypes.includes('free_guest')) {
        buckets.push({ anonymous: true, _id: { $nin: allPremiumIds } });
      }
      and.push({ $or: buckets });
    }

    return and.length > 0 ? { $and: and } : {};
  }
}
