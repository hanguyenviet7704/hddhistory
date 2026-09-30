import { KeypointAccessService } from './keypoint-access.service';

/**
 * The rule these pin down (product call, 2026-08-21): a free reader's day is
 * counted in keypoints FINISHED. Reading part of a keypoint and leaving costs
 * nothing, so while the day has room every keypoint opens in full; once the day's
 * keypoints are done, everything else stops at the lock card until tomorrow.
 *
 * See `hddhistory-api/plans/260812-daily-keypoint-quota/README.md`.
 */
describe('KeypointAccessService', () => {
  const KEYPOINT = 'kp-new';
  const VN = 420; // UTC+7

  function build(options: {
    quota?: { enabled: boolean; freeKeypointsPerDay?: number; afterCards?: number } | null;
    completedToday?: string[];
    passedEver?: string[];
    premium?: boolean;
    userId?: string;
  }) {
    const ledger = {
      completedToday: jest.fn().mockResolvedValue(options.completedToday ?? []),
      recordCompletion: jest.fn(),
    };
    const paywallConfig = {
      getMobileConfig: jest.fn().mockResolvedValue({
        dailyKeypointQuota:
          options.quota === undefined
            ? { enabled: true, freeKeypointsPerDay: 1, afterCards: 4 }
            : options.quota,
      }),
    };
    const subscriptions = {
      findActivePremiumForUser: jest
        .fn()
        .mockResolvedValue(options.premium ? { id: 'sub' } : null),
    };
    const userProgress = {
      findPassedKeypointIds: jest.fn().mockResolvedValue(options.passedEver ?? []),
    };
    const request = { user: { id: options.userId ?? 'reader-1' } };

    const service = new KeypointAccessService(
      ledger as any,
      paywallConfig as any,
      subscriptions as any,
      userProgress as any,
      request as any,
    );

    return { service, ledger, paywallConfig, subscriptions, userProgress };
  }

  describe('getAccess', () => {
    it('opens a keypoint in full while the day still has room', async () => {
      const { service } = build({ completedToday: [] });

      const view = await service.getAccess(KEYPOINT, VN);

      // No cap: nothing is charged for READING — the charge lands when the reader
      // finishes it, which is the whole point of the new rule.
      expect(view.cardCap).toBeNull();
      expect(view.reason).toBe('ticket_available');
      expect(view.quota).toEqual({
        limit: 1,
        used: 0,
        remaining: 1,
        claimedKeypointId: null,
      });
    });

    it('walls a new keypoint once the day is used up', async () => {
      const { service } = build({ completedToday: ['kp-finished'] });

      const view = await service.getAccess(KEYPOINT, VN);

      // afterCards 4 → the lock stands at card 4, so the last readable index is 2.
      expect(view.cardCap).toBe(2);
      expect(view.reason).toBe('quota_spent');
      expect(view.quota?.used).toBe(1);
      expect(view.quota?.claimedKeypointId).toBe('kp-finished');
    });

    it('keeps a keypoint finished today open for the rest of the day', async () => {
      const { service } = build({ completedToday: [KEYPOINT] });

      const view = await service.getAccess(KEYPOINT, VN);

      expect(view.cardCap).toBeNull();
      expect(view.reason).toBe('todays_free_keypoint');
    });

    it('never meters a keypoint finished on an earlier day', async () => {
      const { service, ledger } = build({
        passedEver: [KEYPOINT],
        completedToday: ['kp-other'],
      });

      const view = await service.getAccess(KEYPOINT, VN);

      expect(view.cardCap).toBeNull();
      expect(view.reason).toBe('already_completed');
      // Revision is decided before the ledger is even read.
      expect(ledger.completedToday).not.toHaveBeenCalled();
    });

    it('leaves premium readers uncapped', async () => {
      const { service } = build({ premium: true, completedToday: ['a', 'b'] });

      const view = await service.getAccess(KEYPOINT, VN);

      expect(view.cardCap).toBeNull();
      expect(view.reason).toBe('premium');
    });

    it('leaves a lesson the reader generated out of the quota', async () => {
      const { service, paywallConfig } = build({});

      const view = await service.getAccess('abc::user-lesson::1', VN);

      expect(view.reason).toBe('user_lesson');
      expect(view.cardCap).toBeNull();
      // Checked before any I/O at all.
      expect(paywallConfig.getMobileConfig).not.toHaveBeenCalled();
    });

    it('leaves the keypoint open when the quota is off', async () => {
      const { service } = build({ quota: { enabled: false } });

      const view = await service.getAccess(KEYPOINT, VN);

      expect(view.reason).toBe('quota_disabled');
      expect(view.cardCap).toBeNull();
    });

    it('fails open when the config cannot be read', async () => {
      const { service, paywallConfig } = build({});
      paywallConfig.getMobileConfig.mockRejectedValue(new Error('remote config down'));

      const view = await service.getAccess(KEYPOINT, VN);

      // A paywall that cannot be evaluated must not lock content away.
      expect(view.reason).toBe('quota_disabled');
      expect(view.cardCap).toBeNull();
    });

    it('honours a bigger allowance', async () => {
      const { service } = build({
        quota: { enabled: true, freeKeypointsPerDay: 3, afterCards: 4 },
        completedToday: ['one', 'two'],
      });

      const view = await service.getAccess(KEYPOINT, VN);

      expect(view.cardCap).toBeNull();
      expect(view.quota).toEqual({
        limit: 3,
        used: 2,
        remaining: 1,
        claimedKeypointId: 'two',
      });
    });
  });

  describe('claim', () => {
    /**
     * The endpoint older app builds call when a swipe reaches the wall. It no
     * longer spends anything — it only answers whether the day still has room.
     */
    it('lets the reader through without touching the ledger', async () => {
      const { service, ledger } = build({ completedToday: [] });

      const result = await service.claim(KEYPOINT, VN);

      expect(result.granted).toBe(true);
      expect(result.cardCap).toBeNull();
      expect(ledger.recordCompletion).not.toHaveBeenCalled();
    });

    it('refuses once the day is used up', async () => {
      const { service } = build({ completedToday: ['kp-finished'] });

      const result = await service.claim(KEYPOINT, VN);

      expect(result.granted).toBe(false);
      expect(result.cardCap).toBe(2);
      expect(result.reason).toBe('quota_spent');
      expect(result.claimedKeypointId).toBe('kp-finished');
    });

    it('treats a zero allowance as a hard wall', async () => {
      const { service } = build({
        quota: { enabled: true, freeKeypointsPerDay: 0, afterCards: 4 },
      });

      const result = await service.claim(KEYPOINT, VN);

      expect(result.granted).toBe(false);
      expect(result.reason).toBe('quota_spent');
    });
  });
});
