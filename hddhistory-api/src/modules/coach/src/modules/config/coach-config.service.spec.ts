import { CoachConfigService } from './coach-config.service';

/**
 * `update()` writes through an explicit allow-list, so a knob added to the
 * schema and the DTO but forgotten here saves NOTHING — and says it succeeded.
 * That shape has bitten this codebase before; these tests are the tripwire.
 */
describe('CoachConfigService.update', () => {
  const upsertDefault = jest.fn();
  const findDefault = jest.fn().mockResolvedValue({});
  const service = new CoachConfigService({
    upsertDefault,
    findDefault,
  } as any);

  beforeEach(() => {
    upsertDefault.mockClear();
  });

  const setFor = async (dto: Record<string, unknown>) => {
    await service.update(dto as any);

    return upsertDefault.mock.calls[0][0].$set;
  };

  it('writes every rating-ask knob it is given', async () => {
    expect(
      await setFor({
        ratingAskEnabled: false,
        ratingAskMinDays: 0,
        ratingAskSnoozeDays: 0,
        ratingAskEveryNthExit: 3,
        ratingAskProbability: 40,
        ratingAskMaxPerUser: 2,
      }),
    ).toEqual({
      ratingAskEnabled: false,
      ratingAskMinDays: 0,
      ratingAskSnoozeDays: 0,
      ratingAskEveryNthExit: 3,
      ratingAskProbability: 40,
      ratingAskMaxPerUser: 2,
    });
  });

  it('writes zero rather than dropping it — 0 is how a knob is switched off', async () => {
    expect(await setFor({ ratingAskMinDays: 0 })).toEqual({ ratingAskMinDays: 0 });
  });

  it('writes false rather than dropping it', async () => {
    expect(await setFor({ ratingAskEnabled: false })).toEqual({ ratingAskEnabled: false });
  });

  it('writes talkFreeMaxTurns', async () => {
    expect(await setFor({ talkFreeMaxTurns: 0 })).toEqual({ talkFreeMaxTurns: 0 });
  });

  it('touches nothing it was not given', async () => {
    expect(await setFor({ ratingAskProbability: 50 })).toEqual({ ratingAskProbability: 50 });
  });
});
