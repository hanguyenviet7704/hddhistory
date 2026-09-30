import {
  campaignReaderName,
  renderCampaignCopy,
  unknownCampaignVariables,
} from './notification-campaign-copy.helper';

describe('campaignReaderName', () => {
  it('uses the reader own name when there is one', () => {
    expect(campaignReaderName('  Hà  ', 'vi')).toEqual({
      value: 'Hà',
      isFallback: false,
    });
  });

  it('falls back per WORDING locale, not per reader locale', () => {
    // A `vi` reader with no Vietnamese wording gets the English one, and
    // "for bạn" would be a broken sentence.
    expect(campaignReaderName('', 'en').value).toBe('you');
    expect(campaignReaderName(null, 'vi').value).toBe('bạn');
    expect(campaignReaderName(undefined, 'ko').value).toBe('회원님');
  });

  it('treats an unknown locale as English rather than dropping the send', () => {
    expect(campaignReaderName('', 'th')).toEqual({
      value: 'you',
      isFallback: true,
    });
  });
});

describe('renderCampaignCopy', () => {
  const reader = (rawName: string, locale: string) =>
    campaignReaderName(rawName, locale);

  it('substitutes the name mid-sentence', () => {
    expect(
      renderCampaignCopy(
        'HDDhistory just unlocked 3 FREE lessons for {user_name}.',
        reader('Ha', 'en'),
      ),
    ).toBe('HDDhistory just unlocked 3 FREE lessons for Ha.');
  });

  it('substitutes the fallback when the reader has no name', () => {
    expect(
      renderCampaignCopy(
        'HDDhistory just unlocked 3 FREE lessons for {user_name}.',
        reader('', 'en'),
      ),
    ).toBe('HDDhistory just unlocked 3 FREE lessons for you.');
  });

  it('capitalises the fallback at the start of a sentence', () => {
    expect(renderCampaignCopy('{user_name} ơi, vào học nhé!', reader('', 'vi'))).toBe(
      'Bạn ơi, vào học nhé!',
    );
  });

  it('leaves a real name exactly as the reader typed it', () => {
    // Their own spelling, even lowercase, is not ours to correct.
    expect(renderCampaignCopy('{user_name} ơi!', reader('an', 'vi'))).toBe(
      'an ơi!',
    );
  });

  it('leaves a variable it cannot fill alone', () => {
    // Left visible on purpose: `assertCopies` refuses to save this, so seeing it
    // means the guard was bypassed, and a silent blank would hide that.
    expect(
      renderCampaignCopy('Học tiếp "{course_name}" nhé', reader('Hà', 'vi')),
    ).toBe('Học tiếp "{course_name}" nhé');
  });

  it('handles an empty template', () => {
    expect(renderCampaignCopy('', reader('Hà', 'vi'))).toBe('');
  });
});

describe('unknownCampaignVariables', () => {
  it('accepts the one variable a campaign can fill', () => {
    expect(unknownCampaignVariables('Chào {user_name}')).toEqual([]);
  });

  it('reports the scheduled-only variables, deduplicated', () => {
    expect(
      unknownCampaignVariables('{course_name} · {quote} · {course_name}'),
    ).toEqual(['course_name', 'quote']);
  });

  it('says nothing about plain text', () => {
    expect(unknownCampaignVariables('Không có biến nào')).toEqual([]);
  });
});
