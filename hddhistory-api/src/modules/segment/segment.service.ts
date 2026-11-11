import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { FilterQuery, Types } from 'mongoose';

import { RequestService } from '@base/service/request.service';
import {
  normalizeCountryCodes,
  normalizeLocaleCodes,
} from '@utils/viewer-market.util';

import { SegmentCriteriaDto, UpsertSegmentDto } from './dto/upsert-segment.dto';
import { SegmentSnapshotRepository } from './repository/segment-snapshot.repository';
import { SegmentRepository } from './repository/segment.repository';
import { SegmentSnapshot } from './schema/segment-snapshot.schema';
import { Segment, SegmentCriteria } from './schema/segment.schema';
import {
  matchesCriteria,
  USER_TYPES,
  UserType,
  ViewerFacts,
} from './segment-match.util';
import { SegmentMemberFilterService } from './segment-member-filter.service';
import { SubscriptionService } from '../payment/subscriptions/subscription.service';
import { UserRepository } from '../user/src/modules/auth/repository/user.repository';
import { User } from '../user/src/modules/auth/schema/user.schema';

const DAY_MS = 86_400_000;

/** What the admin's stats panel receives for one segment. */
export interface SegmentStatsView {
  count: number;
  history: Array<{ date: string; count: number }>;
}

/** Pairwise overlap for the admin's Venn view. */
export interface SegmentOverlapView {
  a: { id: string; name: string; count: number };
  b: { id: string; name: string; count: number };
  intersection: number;
}

/**
 * Audiences (segments) and the two questions asked about them:
 *
 * - The SERVE path ("does the viewer of this request belong?") answers from
 *   one user document + at most one subscription lookup, via the pure matcher
 *   in `segment-match.util.ts`. It runs on every Home open, so it must never
 *   scan a collection.
 * - The ADMIN path ("how many belong? how much do two overlap?") compiles the
 *   SAME criteria into a Mongo filter and counts. It may be slow; it runs when
 *   an operator clicks.
 *
 * Membership is always computed live — a segment stores criteria, never a
 * member list, so nobody has to keep one fresh.
 */
@Injectable()
export class SegmentService {
  constructor(
    private readonly segmentRepository: SegmentRepository,
    private readonly snapshotRepository: SegmentSnapshotRepository,
    private readonly userRepository: UserRepository,
    private readonly subscriptionService: SubscriptionService,
    private readonly requestService: RequestService,
    private readonly memberFilter: SegmentMemberFilterService,
  ) {}

  // ------------------------------------------------------------------ CRUD

  async list(): Promise<Segment[]> {
    return this.segmentRepository.findAll();
  }

  async create(dto: UpsertSegmentDto): Promise<Segment> {
    return this.segmentRepository.create(
      {
        name: dto.name.trim(),
        criteria: this.normalizeCriteria(dto.criteria),
      },
      this.requestService.user,
    );
  }

  async update(id: string, dto: UpsertSegmentDto): Promise<Segment> {
    const updated = await this.segmentRepository.findOneAndUpdate(
      { _id: this.objectIdOf(id) },
      {
        $set: {
          name: dto.name.trim(),
          criteria: this.normalizeCriteria(dto.criteria),
          updatedAt: new Date(),
        },
      },
    );
    if (!updated) throw new NotFoundException('Segment not found');

    return updated;
  }

  /**
   * Deleting also drops the snapshot history. It does NOT touch banner/popup
   * `segmentIds` on purpose: a dangling id simply never matches, so the
   * surface quietly loses one restriction instead of breaking.
   */
  async remove(id: string): Promise<{ deleted: boolean }> {
    await this.segmentRepository.deleteOne({ _id: this.objectIdOf(id) });
    await this.snapshotRepository.deleteFor(id);

    return { deleted: true };
  }

  // ------------------------------------------------------------- serve path

  /**
   * Keep only the items this viewer may see, by segment.
   *
   * The shared fast path for banner slides and popup campaigns: items with no
   * `segmentIds` pass untouched (no targeting), and everything needed to judge
   * the rest is resolved ONCE — one segment fetch, one user read, at most one
   * subscription lookup — however many items there are.
   *
   * An unidentifiable viewer is hidden from every TARGETED item, the same
   * contract as market/language targeting: the admin said "these people", and
   * someone we know nothing about is not provably one of them.
   */
  async filterItemsForViewer<T extends { segmentIds?: string[] }>(
    items: T[],
    viewerId: string,
  ): Promise<T[]> {
    const targeted = items.filter(
      item => (item.segmentIds ?? []).length > 0,
    );
    if (targeted.length === 0) return items;

    const wantedIds = [
      ...new Set(targeted.flatMap(item => item.segmentIds ?? [])),
    ];

    const matched = viewerId
      ? await this.matchingSegmentIdsFor(viewerId, wantedIds)
      : new Set<string>();

    return items.filter(item => {
      const segmentIds = item.segmentIds ?? [];
      if (segmentIds.length === 0) return true;

      return segmentIds.some(id => matched.has(id));
    });
  }

  /** Which of `segmentIds` this user belongs to, as a set. */
  private async matchingSegmentIdsFor(
    userId: string,
    segmentIds: string[],
  ): Promise<Set<string>> {
    const segments = await this.segmentRepository.findByIds(
      segmentIds.filter(id => Types.ObjectId.isValid(id)),
    );
    if (segments.length === 0) return new Set();

    const facts = await this.resolveViewerFacts(
      userId,
      // The subscription lookup costs a MySQL round-trip on the Home path, so
      // it is skipped unless some criterion actually asks about user type.
      segments.some(s => (s.criteria?.userTypes ?? []).length > 0),
    );
    if (!facts) return new Set();

    const now = new Date();

    return new Set(
      segments
        .filter(segment => matchesCriteria(segment.criteria, facts, now))
        .map(segment => String(segment._id)),
    );
  }

  /** One viewer reduced to what criteria can ask about; null when unknown. */
  private async resolveViewerFacts(
    userId: string,
    needsUserType: boolean,
  ): Promise<ViewerFacts | null> {
    const user = await this.userRepository.findById(userId);
    if (!user) return null;

    let userType: UserType = user.anonymous ? 'free_guest' : 'free_logged_in';
    if (needsUserType) {
      const premium =
        await this.subscriptionService.findActivePremiumForUser(userId);
      if (premium) {
        // A lifetime unlock is the row with no period end — the same rule the
        // activity query itself uses.
        userType =
          premium.currentPeriodEnd == null
            ? 'pro_lifetime'
            : 'pro_subscription';
      }
    }

    return {
      userId,
      firstSessionAt: user.createdAt ?? null,
      lastSessionAt: user.lastAction?.time ?? user.updatedAt ?? null,
      language: (user.language ?? '').trim().toLowerCase().split(/[-_]/)[0],
      country: (user.country ?? '').trim().toUpperCase(),
      deviceTypes: [
        ...new Set(
          (user.devices ?? [])
            .map(device => (device.pushPlatform ?? '').trim().toLowerCase())
            .filter(platform => platform.length > 0),
        ),
      ],
      userType,
      learningGoal: user.onboarding?.learningGoal ?? null,
      topicIds: user.onboarding?.categoryWantToMaster ?? [],
    };
  }

  // ------------------------------------------------------------- admin path

  /** Live member count plus the snapshot history the growth chart draws. */
  async statsFor(id: string): Promise<SegmentStatsView> {
    const segment = await this.segmentRepository.findById(this.idOrThrow(id));
    if (!segment) throw new NotFoundException('Segment not found');

    const [count, history] = await Promise.all([
      this.countMembers(segment.criteria),
      this.snapshotRepository.historyFor(id, 90),
    ]);

    return {
      count,
      history: history.map((row: SegmentSnapshot) => ({
        date: row.date,
        count: row.count,
      })),
    };
  }

  /** |A|, |B| and |A∩B| — the numbers behind the admin's Venn view. */
  async overlap(aId: string, bId: string): Promise<SegmentOverlapView> {
    const [a, b] = await Promise.all([
      this.segmentRepository.findById(this.idOrThrow(aId)),
      this.segmentRepository.findById(this.idOrThrow(bId)),
    ]);
    if (!a || !b) throw new NotFoundException('Segment not found');

    const [filterA, filterB] = await Promise.all([
      this.memberFilter.buildMemberFilter(a.criteria),
      this.memberFilter.buildMemberFilter(b.criteria),
    ]);

    const [countA, countB, intersection] = await Promise.all([
      this.userRepository.countByFilter(filterA),
      this.userRepository.countByFilter(filterB),
      this.userRepository.countByFilter({ $and: [filterA, filterB] }),
    ]);

    return {
      a: { id: String(a._id), name: a.name, count: countA },
      b: { id: String(b._id), name: b.name, count: countB },
      intersection,
    };
  }

  /** How many users match `criteria` right now. */
  async countMembers(criteria: SegmentCriteria | undefined): Promise<number> {
    return this.userRepository.countByFilter(
      await this.memberFilter.buildMemberFilter(criteria),
    );
  }





  // ----------------------------------------------------------------- shared

  private normalizeCriteria(dto?: SegmentCriteriaDto): SegmentCriteria {
    const lifecycleFrom = dto?.lifecycleFrom ?? null;
    const lifecycleTo = dto?.lifecycleTo ?? null;
    if (lifecycleFrom != null && lifecycleTo != null && lifecycleTo < lifecycleFrom) {
      throw new BadRequestException('lifecycleTo must be ≥ lifecycleFrom');
    }

    return {
      firstSessionFrom: dto?.firstSessionFrom ?? null,
      firstSessionTo: dto?.firstSessionTo ?? null,
      lastSessionFrom: dto?.lastSessionFrom ?? null,
      lastSessionTo: dto?.lastSessionTo ?? null,
      languages: normalizeLocaleCodes(dto?.languages),
      countries: normalizeCountryCodes(dto?.countries),
      deviceTypes: [
        ...new Set(
          (dto?.deviceTypes ?? []).map(type => type.trim().toLowerCase()),
        ),
      ].filter(type => type === 'ios' || type === 'android'),
      lifecycleFrom,
      lifecycleTo,
      userIds: [
        ...new Set(
          (dto?.userIds ?? [])
            .map(id => id.trim())
            .filter(id => Types.ObjectId.isValid(id)),
        ),
      ],
      userGoals: [...new Set(dto?.userGoals ?? [])],
      topicIds: [...new Set(dto?.topicIds ?? [])],
      userTypes: (dto?.userTypes ?? []).filter(type =>
        USER_TYPES.includes(type as UserType),
      ),
    };
  }

  private objectIdOf(id: string): Types.ObjectId {
    return new Types.ObjectId(this.idOrThrow(id));
  }

  private idOrThrow(id: string): string {
    const trimmed = (id ?? '').trim();
    if (!Types.ObjectId.isValid(trimmed)) {
      throw new BadRequestException('Invalid segment id');
    }

    return trimmed;
  }
}
