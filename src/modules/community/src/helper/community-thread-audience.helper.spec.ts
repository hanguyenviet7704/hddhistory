import { threadFollowUpRecipients } from './community-thread-audience.helper';

describe('threadFollowUpRecipients', () => {
  it('reaches people who commented but never pressed the bell', () => {
    // The whole point of the union: these are the accounts that answered a
    // thread before auto-follow existed, so no SAVE row was ever written for
    // them and the follower query alone would miss them for good.
    expect(
      threadFollowUpRecipients({
        followerIds: [],
        commenterIds: ['old-answerer'],
        alreadyNotified: ['actor'],
      }),
    ).toEqual(['old-answerer']);
  });

  it('says each person once when they both follow and commented', () => {
    expect(
      threadFollowUpRecipients({
        followerIds: ['both'],
        commenterIds: ['both'],
        alreadyNotified: [],
      }),
    ).toEqual(['both']);
  });

  it('drops anyone the caller has already notified about this comment', () => {
    // The post author and the person being replied to are told by name
    // upstream; a second row for the same comment is how a badge stops
    // meaning anything.
    expect(
      threadFollowUpRecipients({
        followerIds: ['author', 'follower'],
        commenterIds: ['author', 'actor'],
        alreadyNotified: ['actor', 'author'],
      }),
    ).toEqual(['follower']);
  });

  it('drops anyone who turned the bell off, even though they commented', () => {
    // Without this the bell would be a lie: switching notifications off on a
    // thread you once answered would still leave the comment half notifying.
    expect(
      threadFollowUpRecipients({
        followerIds: [],
        commenterIds: ['muted', 'still-listening'],
        alreadyNotified: [],
        mutedUserIds: ['muted'],
      }),
    ).toEqual(['still-listening']);
  });

  it('ignores empty ids rather than pushing to nobody', () => {
    expect(
      threadFollowUpRecipients({
        followerIds: ['', 'real'],
        commenterIds: [''],
        alreadyNotified: [],
      }),
    ).toEqual(['real']);
  });

  it('is empty when the only candidates were already told', () => {
    expect(
      threadFollowUpRecipients({
        followerIds: ['a'],
        commenterIds: ['a'],
        alreadyNotified: ['a'],
      }),
    ).toEqual([]);
  });
});
