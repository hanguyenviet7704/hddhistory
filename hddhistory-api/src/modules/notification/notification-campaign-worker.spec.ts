import { Types } from 'mongoose';

import { NotificationCampaignService } from './notification-campaign.service';
import { NotificationDispatchService } from './notification-dispatch.service';
import { canonicalTimeZone } from './notification-timezone.helper';
import {
  NotificationCampaignSendMode,
  NotificationCampaignStatus,
} from './notification.enum';

/**
 * The campaign worker's scheduling half: which campaign gets picked up, and
 * which zones count as due.
 *
 * Both bugs these cover shipped and stayed invisible for a day, because neither
 * produces an error — one campaign quietly never leaves `queued`, and a send
 * lands on the wrong date looking perfectly healthy. There is nothing in a log
 * to grep for, so the tests are the only cheap way to hold the behaviour.
 */

// --------------------------------------------------------------------- fakes

/**
 * Stands in for the Mongo collection, reproducing the two behaviours the worker
 * actually leans on: `claimNext` hands back the OLDEST claimable campaign, and a
 * live lease makes a campaign unclaimable.
 */
function fakeCampaignRepository(campaigns: any[]) {
  return {
    campaigns,
    async claimNext(now: Date, leaseUntil: Date) {
      const claimable = campaigns
        .filter(
          campaign =>
            campaign.status === NotificationCampaignStatus.QUEUED ||
            campaign.status === NotificationCampaignStatus.SENDING,
        )
        .filter(
          campaign =>
            !campaign.leaseUntil || campaign.leaseUntil.getTime() <= now.getTime(),
        )
        .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());

      const next = claimable[0];
      if (!next) return null;
      next.leaseUntil = leaseUntil;
      next.status = NotificationCampaignStatus.SENDING;
      return { ...next };
    },
    async releaseLease(id: any) {
      const found = campaigns.find(c => String(c._id) === String(id));
      if (found) found.leaseUntil = null;
    },
    async patch(id: any, set: Record<string, unknown>, inc?: Record<string, number>) {
      const found = campaigns.find(c => String(c._id) === String(id));
      if (!found) return;
      Object.assign(found, set);
      for (const [key, delta] of Object.entries(inc ?? {})) {
        found[key] = (found[key] ?? 0) + delta;
      }
    },
  };
}

/** Users are only ever counted here, so one push token each is enough. */
function fakeUserRepository(usersByZone: Record<string, number>) {
  const users = Object.entries(usersByZone).flatMap(([zone, count]) =>
    Array.from({ length: count }, (_, index) => ({
      // Ids ascend in creation order so `$gt` paging is meaningful.
      _id: new Types.ObjectId(),
      name: `${zone}-${index}`,
      language: 'en',
      timezone: zone,
      devices: [{ pushToken: `token-${zone}-${index}`, pushEnabled: true }],
    })),
  );

  return {
    calls: [] as { zones: string[]; limit: number; afterId: any }[],
    async findPushCandidatesByTimezones(
      zones: string[],
      limit: number,
      _extraFilter: unknown,
      afterId: Types.ObjectId | null = null,
    ) {
      this.calls.push({ zones, limit, afterId });
      return users
        .filter(user => zones.includes(user.timezone))
        .filter(user => !afterId || String(user._id) > String(afterId))
        .slice(0, limit);
    },
    async findPushCandidatesAfterId() {
      return [];
    },
  };
}

function makeService(overrides: {
  campaignRepository: any;
  userRepository?: any;
  dispatchService?: any;
}) {
  const userRepository = overrides.userRepository ?? fakeUserRepository({});
  const service = new NotificationCampaignService(
    overrides.campaignRepository,
    {
      claimUser: async () => true,
      finalize: async () => undefined,
    } as any,
    userRepository as any,
    { memberFilterForSegments: async () => null } as any,
    (overrides.dispatchService ?? { zonesDueAt: async () => [] }) as any,
    {
      sendToTokens: async () => ({ successCount: 1, failureCount: 0 }),
    } as any,
    {} as any,
  );
  return { service, userRepository };
}

function makeCampaign(fields: Partial<any>): any {
  return {
    _id: new Types.ObjectId(),
    name: 'campaign',
    copies: { en: { title: 'Title', body: 'Body' } },
    deeplink: 'home',
    deeplinkParams: {},
    segmentIds: [],
    sendMode: NotificationCampaignSendMode.LOCAL_HOUR,
    localHour: 20,
    localMinute: 0,
    scheduledDate: null,
    status: NotificationCampaignStatus.QUEUED,
    processedZones: [],
    activeZones: [],
    zoneCursorUserId: null,
    cursorUserId: null,
    leaseUntil: null,
    createdAt: new Date('2026-09-03T02:00:00Z'),
    ...fields,
  };
}

// ------------------------------------------------------ head-of-line blocking

describe('runDueCampaigns', () => {
  /**
   * The 2026-09-03 incident, in one test.
   *
   * A LOCAL_HOUR campaign stays `sending` for up to 36 hours whether or not it
   * has anything to do, and it used to own the only slot for all of them.
   */
  it('does not let an idle older campaign starve a younger one', async () => {
    const idle = makeCampaign({
      // Alive (its day has not closed) but nowhere near its hour.
      scheduledDate: '2026-09-03',
      localHour: 20,
      createdAt: new Date('2026-09-03T01:52:00Z'),
      status: NotificationCampaignStatus.SENDING,
    });
    const younger = makeCampaign({
      scheduledDate: '2026-09-03',
      localHour: 14,
      createdAt: new Date('2026-09-03T02:00:00Z'),
    });

    const campaignRepository = fakeCampaignRepository([idle, younger]);
    const { service } = makeService({
      campaignRepository,
      userRepository: fakeUserRepository({ 'Asia/Ho_Chi_Minh': 3 }),
      dispatchService: {
        // Only the 14:00 campaign has a zone due right now.
        zonesDueAt: async (hour: number) =>
          hour === 14 ? ['Asia/Ho_Chi_Minh'] : [],
      },
    });

    const result = await service.runDueCampaigns(new Date('2026-09-03T07:00:00Z'));

    expect(result.picked).toBe(2);
    expect(result.sent).toBe(3);
    expect(younger.processedZones).toEqual(['Asia/Ho_Chi_Minh']);
  });

  it('releases every lease it took, so the next tick starts clean', async () => {
    const campaigns = [
      makeCampaign({ createdAt: new Date('2026-09-03T01:00:00Z') }),
      makeCampaign({ createdAt: new Date('2026-09-03T02:00:00Z') }),
    ];
    const campaignRepository = fakeCampaignRepository(campaigns);
    const { service } = makeService({ campaignRepository });

    await service.runDueCampaigns(new Date('2026-09-03T07:00:00Z'));

    expect(campaigns.map(c => c.leaseUntil)).toEqual([null, null]);
  });

  it('a failing campaign does not stop the ones behind it', async () => {
    const broken = makeCampaign({
      createdAt: new Date('2026-09-03T01:00:00Z'),
      scheduledDate: '2026-09-03',
      localHour: 14,
    });
    const healthy = makeCampaign({
      createdAt: new Date('2026-09-03T02:00:00Z'),
      scheduledDate: '2026-09-03',
      localHour: 14,
    });

    const campaignRepository = fakeCampaignRepository([broken, healthy]);
    let firstCall = true;
    const { service } = makeService({
      campaignRepository,
      userRepository: fakeUserRepository({ 'Asia/Ho_Chi_Minh': 2 }),
      dispatchService: {
        zonesDueAt: async () => {
          if (firstCall) {
            firstCall = false;
            throw new Error('mongo went away');
          }
          return ['Asia/Ho_Chi_Minh'];
        },
      },
    });

    const result = await service.runDueCampaigns(new Date('2026-09-03T07:00:00Z'));

    expect(broken.lastError).toBe('mongo went away');
    expect(result.sent).toBe(2);
  });
});

// ------------------------------------------------------------ the zone walk

describe('stepLocalHour', () => {
  it('pins the zone set and pages it, retiring it only once drained', async () => {
    // 400 readers against a 300-user batch: two ticks, and the zone must not be
    // retired after the first or the remaining 100 are silently dropped — the
    // old one-shot 5000 query had the same hole at a bigger number.
    const campaign = makeCampaign({
      scheduledDate: '2026-09-03',
      localHour: 14,
    });
    const campaignRepository = fakeCampaignRepository([campaign]);
    const userRepository = fakeUserRepository({ 'Asia/Ho_Chi_Minh': 400 });
    const { service } = makeService({
      campaignRepository,
      userRepository,
      dispatchService: { zonesDueAt: async () => ['Asia/Ho_Chi_Minh'] },
    });

    const first = await service.runDueCampaigns(new Date('2026-09-03T07:00:00Z'));
    expect(first.sent).toBe(300);
    expect(campaign.activeZones).toEqual(['Asia/Ho_Chi_Minh']);
    expect(campaign.processedZones).toEqual([]);
    expect(campaign.zoneCursorUserId).not.toBeNull();

    const second = await service.runDueCampaigns(new Date('2026-09-03T07:01:00Z'));
    expect(second.sent).toBe(100);
    expect(campaign.processedZones).toEqual(['Asia/Ho_Chi_Minh']);
    expect(campaign.activeZones).toEqual([]);
    expect(campaign.zoneCursorUserId).toBeNull();

    // Second page resumed from the cursor rather than re-reading from the top.
    expect(userRepository.calls[1].afterId).not.toBeNull();
  });

  it('keeps walking a pinned zone after its due window has closed', async () => {
    const campaign = makeCampaign({
      scheduledDate: '2026-09-03',
      localHour: 14,
      activeZones: ['Asia/Ho_Chi_Minh'],
    });
    const campaignRepository = fakeCampaignRepository([campaign]);
    const { service } = makeService({
      campaignRepository,
      userRepository: fakeUserRepository({ 'Asia/Ho_Chi_Minh': 5 }),
      // The window has moved on: nothing is due any more.
      dispatchService: { zonesDueAt: async () => [] },
    });

    const result = await service.runDueCampaigns(new Date('2026-09-03T07:20:00Z'));

    expect(result.sent).toBe(5);
    expect(campaign.processedZones).toEqual(['Asia/Ho_Chi_Minh']);
  });

  it('hands the scheduled date to the zone query', async () => {
    const campaign = makeCampaign({
      scheduledDate: '2026-09-03',
      localHour: 14,
    });
    const campaignRepository = fakeCampaignRepository([campaign]);
    const seen: unknown[] = [];
    const { service } = makeService({
      campaignRepository,
      dispatchService: {
        zonesDueAt: async (
          _hour: number,
          _minute: number,
          _now: Date,
          onLocalDate?: string,
        ) => {
          seen.push(onLocalDate);
          return [];
        },
      },
    });

    await service.runDueCampaigns(new Date('2026-09-03T07:00:00Z'));

    expect(seen).toEqual(['2026-09-03']);
  });

  it('does not touch the zone query before the date has begun anywhere', async () => {
    const campaign = makeCampaign({
      // UTC+14 opens 2026-09-10 at 2026-09-09T10:00Z; this is well before that.
      scheduledDate: '2026-09-10',
      localHour: 20,
    });
    const campaignRepository = fakeCampaignRepository([campaign]);
    const zonesDueAt = jest.fn(async () => ['Asia/Ho_Chi_Minh']);
    const { service } = makeService({
      campaignRepository,
      dispatchService: { zonesDueAt },
    });

    const result = await service.runDueCampaigns(new Date('2026-09-04T07:00:00Z'));

    expect(zonesDueAt).not.toHaveBeenCalled();
    expect(result.sent).toBe(0);
    expect(campaign.status).toBe(NotificationCampaignStatus.SENDING);
  });

  it('closes the campaign once the day is over in the last zone on earth', async () => {
    const campaign = makeCampaign({
      scheduledDate: '2026-09-03',
      localHour: 20,
    });
    const campaignRepository = fakeCampaignRepository([campaign]);
    const { service } = makeService({ campaignRepository });

    // 2026-09-03 ends in UTC-12 at 2026-09-04T12:00Z.
    await service.runDueCampaigns(new Date('2026-09-04T12:30:00Z'));

    expect(campaign.status).toBe(NotificationCampaignStatus.SENT);
  });
});

// -------------------------------------------------- the local-date zone filter

describe('zonesDueAt with a local date', () => {
  /**
   * Only the user repository is reached: everything under test here is clock and
   * calendar arithmetic plus the stored-spelling lookup.
   */
  function dispatchService() {
    const unused = null as any;
    return new NotificationDispatchService(
      {
        distinctPushCandidateTimezones: async () => ['Asia/Ho_Chi_Minh'],
      } as any,
      unused,
      unused,
      unused,
      unused,
      unused,
      unused,
      unused,
      unused,
      unused,
      unused,
      unused,
    );
  }

  /** True when the result carries Vietnam under either ICU spelling. */
  function includesVietnam(zones: string[]) {
    const vietnam = canonicalTimeZone('Asia/Ho_Chi_Minh');
    return zones.some(zone => canonicalTimeZone(zone) === vietnam);
  }

  it('accepts the zone on the scheduled day', async () => {
    // 07:00Z is 14:00 on 2026-09-04 in Vietnam.
    const zones = await dispatchService().zonesDueAt(
      14,
      0,
      new Date('2026-09-04T07:00:00Z'),
      '2026-09-04',
    );
    expect(includesVietnam(zones)).toBe(true);
  });

  it('rejects the same clock reading on the wrong day', async () => {
    // This is the day-late send: yesterday's campaign, today's 14:00.
    const zones = await dispatchService().zonesDueAt(
      14,
      0,
      new Date('2026-09-04T07:00:00Z'),
      '2026-09-03',
    );
    expect(includesVietnam(zones)).toBe(false);
  });

  it('dates a late catch-up by the send time, not by the tick', async () => {
    // 17:05Z is 00:05 on 2026-09-05 in Vietnam, seven minutes into the window of
    // a 23:58 send that belongs to 2026-09-04. Dating it by "now" would drop the
    // very readers the catch-up window exists for.
    const now = new Date('2026-09-04T17:05:00Z');
    expect(
      includesVietnam(await dispatchService().zonesDueAt(23, 58, now, '2026-09-04')),
    ).toBe(true);
    expect(
      includesVietnam(await dispatchService().zonesDueAt(23, 58, now, '2026-09-05')),
    ).toBe(false);
  });

  it('is unchanged when no date is given, for the standing templates', async () => {
    const now = new Date('2026-09-04T07:00:00Z');
    const dated = await dispatchService().zonesDueAt(14, 0, now, '2026-09-04');
    const undated = await dispatchService().zonesDueAt(14, 0, now);
    expect(undated).toEqual(dated);
  });
});
