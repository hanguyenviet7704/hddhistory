import {
  DEEPLINK_DESTINATIONS,
  DeeplinkParamPicker,
  sanitizeDeeplinkParams,
} from './deeplink.catalog';

/**
 * Danh mục này là hợp đồng giữa 3 stack: enum trong Flutter, dropdown trong
 * admin, và validate của giai đoạn 2. Một khoá gõ sai ở đây sinh ra link chết
 * mà không có gì báo lỗi, nên nó xứng đáng có test riêng.
 */
describe('DEEPLINK_DESTINATIONS', () => {
  const EXPECTED_KEYS = [
    'home',
    'explore',
    'habit',
    'profile',
    'library',
    'course-roadmap',
    'lesson',
    'category-courses',
    'paywall',
    'manage-subscription',
    'daily-warm-up',
    'learning-streak',
    'daily-check-in',
    'my-lessons',
    'import-lesson',
    'notification-setting',
    'change-language',
    'coach',
    'community',
    'community-post',
    'community-chat',
  ];

  it('khai đúng 21 khoá, không trùng', () => {
    const keys = DEEPLINK_DESTINATIONS.map((d) => d.key);
    expect(keys).toHaveLength(21);
    expect(new Set(keys).size).toBe(21);
  });

  it('khớp từng ký tự với enum DeeplinkDestination bên Flutter', () => {
    expect(DEEPLINK_DESTINATIONS.map((d) => d.key).sort()).toEqual(
      [...EXPECTED_KEYS].sort(),
    );
  });

  it('mọi đích đều có label, group và minAppBuild', () => {
    for (const destination of DEEPLINK_DESTINATIONS) {
      expect(destination.label.trim().length).toBeGreaterThan(0);
      expect(destination.group.trim().length).toBeGreaterThan(0);
      expect(destination.minAppBuild).toBeGreaterThan(0);
    }
  });

  it('param dạng select luôn mang sẵn options', () => {
    const selects = DEEPLINK_DESTINATIONS.flatMap((d) => d.params).filter(
      (p) => p.picker === DeeplinkParamPicker.SELECT,
    );

    expect(selects.length).toBeGreaterThan(0);
    for (const param of selects) {
      expect(param.options?.length).toBeGreaterThan(0);
    }
  });

  it('lesson cần courseId và nhận keypointId tuỳ chọn', () => {
    const lesson = DEEPLINK_DESTINATIONS.find((d) => d.key === 'lesson');
    const courseId = lesson?.params.find((p) => p.name === 'courseId');
    const keypointId = lesson?.params.find((p) => p.name === 'keypointId');

    expect(courseId?.required).toBe(true);
    expect(keypointId?.required).toBe(false);
  });
});

/**
 * Bộ này được BƠM THẲNG vào payload push của campaign, nên nó là biên tin cậy:
 * mọi thứ lọt qua đây đi tới tay người dùng thật.
 */
describe('sanitizeDeeplinkParams', () => {
  it('giữ giá trị select hợp lệ', () => {
    expect(sanitizeDeeplinkParams('paywall', { variant: 'full' })).toEqual({
      variant: 'full',
    });
    expect(sanitizeDeeplinkParams('paywall', { variant: 'compact' })).toEqual({
      variant: 'compact',
    });
  });

  it('bỏ giá trị ngoài options — app rơi về bảng entry-point im lặng', () => {
    expect(sanitizeDeeplinkParams('paywall', { variant: 'FULL' })).toEqual({});
    expect(sanitizeDeeplinkParams('paywall', { variant: 'huge' })).toEqual({});
  });

  it('bỏ tên tham số mà đích không khai', () => {
    expect(
      sanitizeDeeplinkParams('paywall', { variant: 'full', courseId: 'abc' }),
    ).toEqual({ variant: 'full' });
  });

  it('KHÔNG cho gắn khoá điều khiển của payload push', () => {
    expect(
      sanitizeDeeplinkParams('paywall', {
        deeplink: 'home',
        type: 'week_recap',
        campaignId: 'x',
      }),
    ).toEqual({});
  });

  it('đích không có tham số nào thì trả rỗng', () => {
    expect(sanitizeDeeplinkParams('home', { variant: 'full' })).toEqual({});
  });

  it('khoá lạ, null và chuỗi rỗng đều ra rỗng', () => {
    expect(sanitizeDeeplinkParams('khong-ton-tai', { a: 'b' })).toEqual({});
    expect(sanitizeDeeplinkParams('paywall', null)).toEqual({});
    expect(sanitizeDeeplinkParams('paywall', { variant: '   ' })).toEqual({});
  });

  it('trim trước khi so với options', () => {
    expect(sanitizeDeeplinkParams('paywall', { variant: ' full ' })).toEqual({
      variant: 'full',
    });
  });
});
