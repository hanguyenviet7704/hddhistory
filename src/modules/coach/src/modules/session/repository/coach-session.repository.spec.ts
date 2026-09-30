import { Connection, Model } from 'mongoose';

import { CoachSessionRepository } from './coach-session.repository';
import { CoachEntry } from '../../../shared/coach.enum';
import { CoachSession } from '../schema/coach-session.schema';


/**
 * `existsSince` is a query BUILDER, and the bug it carried was in the filter it
 * builds rather than in anything it computes: three flows now open with
 * `entry: LESSON` (the keypoint talk, the course recap, and luồng 7's
 * habit-practice invitation), and the guard that asks "already shown today?"
 * counted all three. So the assertions here are about the filter object.
 */
describe('CoachSessionRepository.existsSince', () => {
  const since = new Date('2026-09-04T00:00:00.000Z');

  function repositoryWithSpy(): {
    repository: CoachSessionRepository;
    exists: jest.Mock;
  } {
    const exists = jest.fn().mockResolvedValue(null);
    const model = { exists } as unknown as Model<CoachSession>;
    const repository = new CoachSessionRepository(
      model,
      {} as unknown as Connection,
    );

    return { repository, exists };
  }

  it('omits talkMode entirely when the caller does not ask for a flavour', async () => {
    const { repository, exists } = repositoryWithSpy();

    await repository.existsSince({
      userId: 'u1',
      entry: CoachEntry.LESSON,
      since,
    });

    expect(exists).toHaveBeenCalledTimes(1);
    expect('talkMode' in exists.mock.calls[0][0]).toBe(false);
  });

  it('filters on talkMode null — luồng 7 only — when asked for it', async () => {
    const { repository, exists } = repositoryWithSpy();

    await repository.existsSince({
      userId: 'u1',
      entry: CoachEntry.LESSON,
      since,
      lessonId: 'lesson-1',
      talkMode: null,
    });

    // `null` is falsy, so a truthiness spread would have dropped it and left
    // the guard counting keypoint talks again. This is that regression.
    expect(exists).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: 'u1',
        entry: CoachEntry.LESSON,
        lessonId: 'lesson-1',
        talkMode: null,
      }),
    );
  });

  it('filters on a named flavour when given one', async () => {
    const { repository, exists } = repositoryWithSpy();

    await repository.existsSince({
      userId: 'u1',
      entry: CoachEntry.LESSON,
      since,
      talkMode: 'talk',
    });

    expect(exists).toHaveBeenCalledWith(
      expect.objectContaining({ talkMode: 'talk' }),
    );
  });

  it('leaves lessonId out when it is empty, so the guard stays day-wide', async () => {
    const { repository, exists } = repositoryWithSpy();

    await repository.existsSince({
      userId: 'u1',
      entry: CoachEntry.LESSON,
      since,
      lessonId: null,
    });

    expect('lessonId' in exists.mock.calls[0][0]).toBe(false);
  });
});
