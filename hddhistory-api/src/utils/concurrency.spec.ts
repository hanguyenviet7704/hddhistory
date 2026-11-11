import { runWithConcurrency } from './concurrency';

/** A task that resolves after `ticks` macrotask turns, recording when it ran. */
function deferred<T>(value: T, ticks = 1): () => Promise<T> {
  return async () => {
    for (let i = 0; i < ticks; i++) await new Promise(setImmediate);
    return value;
  };
}

describe('runWithConcurrency', () => {
  it('returns results aligned with the task order, not the completion order', async () => {
    // The slowest task is first, so anything that collected results as they
    // finished would come back reversed. This alignment is what lets the
    // voiceover dub write each clip into its own card slot.
    const results = await runWithConcurrency(
      [deferred('a', 5), deferred('b', 3), deferred('c', 1)],
      3,
    );

    expect(results.map((r) => (r as PromiseFulfilledResult<string>).value)).toEqual([
      'a',
      'b',
      'c',
    ]);
  });

  it('never exceeds the limit, and still runs every task', async () => {
    let inFlight = 0;
    let peak = 0;
    const tasks = Array.from({ length: 20 }, (_, i) => async () => {
      inFlight += 1;
      peak = Math.max(peak, inFlight);
      await new Promise(setImmediate);
      inFlight -= 1;
      return i;
    });

    const results = await runWithConcurrency(tasks, 4);

    expect(peak).toBe(4);
    expect(results).toHaveLength(20);
    expect(results.every((r) => r.status === 'fulfilled')).toBe(true);
  });

  it('keeps going after a task rejects, and reports it in place', async () => {
    // A synth failure is a normal outcome on the dub path — one refused request
    // must not abandon the rest of the keypoint.
    const boom = new Error('edge-tts refused');
    const results = await runWithConcurrency(
      [
        deferred('ok-1'),
        async () => {
          throw boom;
        },
        deferred('ok-2'),
      ],
      2,
    );

    expect(results[0]).toEqual({ status: 'fulfilled', value: 'ok-1' });
    expect(results[1]).toEqual({ status: 'rejected', reason: boom });
    expect(results[2]).toEqual({ status: 'fulfilled', value: 'ok-2' });
  });

  it('degrades to sequential instead of dividing by zero on a bad limit', async () => {
    let inFlight = 0;
    let peak = 0;
    const tasks = Array.from({ length: 3 }, () => async () => {
      inFlight += 1;
      peak = Math.max(peak, inFlight);
      await new Promise(setImmediate);
      inFlight -= 1;
    });

    // What a missing or malformed VOICEOVER_CONCURRENCY would produce.
    await runWithConcurrency(tasks, 0);

    expect(peak).toBe(1);
  });

  it('handles an empty task list', async () => {
    await expect(runWithConcurrency([], 4)).resolves.toEqual([]);
  });
});
