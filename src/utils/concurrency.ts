/**
 * Run `tasks` with at most `limit` of them in flight at a time.
 *
 * Written for batch work against an external endpoint that is fast but neither
 * free nor unlimited (the Edge TTS "Read Aloud" endpoint): running the whole
 * list at once trips its limits, running one at a time wastes almost all of the
 * wall clock waiting on the network. Measured on the voiceover dub path, five
 * synthesis calls take 26.5s sequentially and 1.1s at a concurrency of five.
 *
 * Deliberately returns `PromiseSettledResult`s rather than throwing: for this
 * kind of work a single failure is a normal outcome the caller has to record
 * per item, not a reason to abandon the rest of the batch. Results are
 * index-aligned with `tasks`, so a caller can write straight into a pre-sized
 * array without tracking completion order.
 *
 * `limit` is clamped to at least 1 (and never more than the task count), so a
 * misconfigured env var degrades to sequential instead of dividing by zero.
 */
export async function runWithConcurrency<T>(
  tasks: ReadonlyArray<() => Promise<T>>,
  limit: number,
): Promise<PromiseSettledResult<T>[]> {
  const results: PromiseSettledResult<T>[] = new Array(tasks.length);
  if (!tasks.length) return results;

  const workers = Math.max(1, Math.min(Math.floor(limit) || 1, tasks.length));

  // Shared cursor rather than pre-sliced chunks: tasks here differ wildly in
  // cost (a one-line card vs a whole keypoint), and chunking would leave a
  // worker idle while another still holds the long tail of its slice.
  let cursor = 0;
  const worker = async (): Promise<void> => {
    while (cursor < tasks.length) {
      // Safe without a lock: `cursor++` has no await between the read and the
      // increment, so no two workers can claim the same index.
      const index = cursor++;
      try {
        results[index] = { status: 'fulfilled', value: await tasks[index]() };
      } catch (reason) {
        results[index] = { status: 'rejected', reason };
      }
    }
  };

  await Promise.all(Array.from({ length: workers }, () => worker()));

  return results;
}
