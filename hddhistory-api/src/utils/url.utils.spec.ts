import { encodeUrlForPush, isPushSafeUrl, toPushSafeUrl } from './url.utils';

describe('url.utils', () => {
  // The exact URL that made a 2279-device campaign fail with
  // messaging/invalid-payload on 2026-09-10.
  const spaced = 'https://cdn.meup.training/notification-campaign/Pop up (1).png';
  const encoded =
    'https://cdn.meup.training/notification-campaign/Pop%20up%20(1).png';

  it('encodes the spaces FCM rejects and keeps the parentheses it allows', () => {
    expect(encodeUrlForPush(spaced)).toBe(encoded);
    expect(isPushSafeUrl(spaced)).toBe(false);
    expect(isPushSafeUrl(encoded)).toBe(true);
  });

  it('never double-encodes a URL that is already escaped', () => {
    expect(toPushSafeUrl(encoded)).toBe(encoded);
  });

  it('encodes a non-ASCII filename as whole code points', () => {
    expect(toPushSafeUrl('https://cdn.meup.training/noti/khoá mới.png')).toBe(
      'https://cdn.meup.training/noti/kho%C3%A1%20m%E1%BB%9Bi.png',
    );
  });

  it('treats empty and whitespace as "no image"', () => {
    expect(toPushSafeUrl('')).toBeNull();
    expect(toPushSafeUrl('   ')).toBeNull();
    expect(toPushSafeUrl(undefined)).toBeNull();
    expect(toPushSafeUrl(null)).toBeNull();
  });

  it('drops what no encoding can save, rather than failing the whole send', () => {
    expect(toPushSafeUrl('not-a-url')).toBeNull();
    expect(toPushSafeUrl('ftp://cdn.meup.training/a.png')).toBeNull();
    expect(toPushSafeUrl('/notification-campaign/a.png')).toBeNull();
  });

  it('leaves a query string and hash alone', () => {
    const url = 'https://cdn.meup.training/a.png?v=2#top';
    expect(toPushSafeUrl(url)).toBe(url);
  });
});
