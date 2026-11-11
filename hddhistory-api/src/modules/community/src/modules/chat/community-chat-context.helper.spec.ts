import { assembleChatContextWindow } from './community-chat-context.helper';

// The halves as the repository hands them over: `older` starts AT the anchor
// and walks back, `newer` starts just after it and walks forward. Both are
// over-fetched by one so the caller can tell "that is all there is" from
// "there is more, I just stopped".
const older = (...ids: string[]) => ids;
const newer = (...ids: string[]) => ids;

describe('assembleChatContextWindow', () => {
  it('returns the window newest first, the same order page 1 arrives in', () => {
    // The client swaps this straight in for a page, so a different order here
    // would draw the room upside down.
    expect(
      assembleChatContextWindow({
        olderNewestFirst: older('anchor', 'o1', 'o2'),
        newerOldestFirst: newer('n1', 'n2'),
        half: 2,
      }).items,
    ).toEqual(['n2', 'n1', 'anchor', 'o1', 'o2']);
  });

  it('keeps at most `half` on each side of the anchor', () => {
    const result = assembleChatContextWindow({
      olderNewestFirst: older('anchor', 'o1', 'o2', 'o3'),
      newerOldestFirst: newer('n1', 'n2', 'n3'),
      half: 2,
    });

    expect(result.items).toEqual(['n2', 'n1', 'anchor', 'o1', 'o2']);
  });

  it('says there is more on both sides when the over-fetch came back full', () => {
    const result = assembleChatContextWindow({
      olderNewestFirst: older('anchor', 'o1', 'o2', 'o3'),
      newerOldestFirst: newer('n1', 'n2', 'n3'),
      half: 2,
    });

    expect(result).toMatchObject({ hasOlder: true, hasNewer: true });
  });

  it('reports no newer when the anchor window touches the live bottom', () => {
    // This is what tells the screen it is back on the live transcript, so the
    // "về tin mới nhất" button can hide and polling can resume merging.
    const result = assembleChatContextWindow({
      olderNewestFirst: older('anchor', 'o1'),
      newerOldestFirst: newer(),
      half: 2,
    });

    expect(result).toMatchObject({ items: ['anchor', 'o1'], hasNewer: false });
  });

  it('reports no older when the room starts inside the window', () => {
    const result = assembleChatContextWindow({
      olderNewestFirst: older('anchor'),
      newerOldestFirst: newer('n1'),
      half: 2,
    });

    expect(result).toMatchObject({ items: ['n1', 'anchor'], hasOlder: false });
  });

  it('is just the anchor in a room with one message', () => {
    expect(
      assembleChatContextWindow({
        olderNewestFirst: older('anchor'),
        newerOldestFirst: newer(),
        half: 20,
      }),
    ).toEqual({ items: ['anchor'], hasOlder: false, hasNewer: false });
  });
});
