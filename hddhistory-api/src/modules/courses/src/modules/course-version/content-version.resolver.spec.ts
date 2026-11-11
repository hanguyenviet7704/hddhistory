import { BadRequestException } from '@nestjs/common';

import { experimentBucket } from '@utils/experiment-bucket.util';

import {
  allowDraftFromHeaders,
  ExperimentFacts,
  resolveVersionRequest,
  ResolveVersionInput,
} from './content-version.resolver';

/**
 * Which content a request gets. `courses`/`lesson`/`keypoint` controllers do
 * NOT split admin from app -- both call `GET /courses/:id` behind the same
 * `AuthGuard` -- so something on the request has to say which side it is.
 *
 * That something is a header, not `user.role`. Nothing in this codebase
 * populates `role`: every account defaults to `USER`, no endpoint runs
 * `RoleGuard`, and the real admin account is `role: USER` -- an assumption that
 * has already broken the admin panel three times (see the notes on
 * [UserHabitAdminController] and [AnalyticsController]). Here it would break
 * quietly and expensively: the panel would show editors the PUBLISHED content
 * while they were trying to edit the draft. Same reasoning, and same shape, as
 * `IGNORE_MARKET_TARGETING_HEADER` in `@utils/market-query.util`.
 * See `plans/260907-course-content-versions/README.md` section 3.
 */
describe('resolveVersionRequest', () => {
  const CURRENT = '68c0000000000000000000f1';

  it('serves an app request the course current version', () => {
    expect(
      resolveVersionRequest({ currentVersionId: CURRENT, allowDraft: false }),
    ).toEqual({ source: 'version', versionId: CURRENT });
  });

  /**
   * A course that has never been tagged keeps behaving exactly as it does
   * today, which is what makes the rollout invisible to users.
   */
  it('serves the working tree when the course has never been tagged', () => {
    expect(
      resolveVersionRequest({ currentVersionId: null, allowDraft: false }),
    ).toEqual({ source: 'working' });
  });

  /** The editor must see the edit they just made, not the published tag. */
  it('serves the admin panel the working tree by default', () => {
    expect(
      resolveVersionRequest({ currentVersionId: CURRENT, allowDraft: true }),
    ).toEqual({ source: 'working' });
  });

  /** How an operator checks what real users are actually being served. */
  it('lets ?version=current pin the panel to the published content', () => {
    expect(
      resolveVersionRequest({
        currentVersionId: CURRENT,
        allowDraft: true,
        requested: 'current',
      }),
    ).toEqual({ source: 'version', versionId: CURRENT });
  });

  it('falls back to the working tree for ?version=current with no tag', () => {
    expect(
      resolveVersionRequest({
        currentVersionId: null,
        allowDraft: true,
        requested: 'current',
      }),
    ).toEqual({ source: 'working' });
  });

  it('resolves a tag name for the panel', () => {
    expect(
      resolveVersionRequest({
        currentVersionId: CURRENT,
        allowDraft: true,
        requested: 'v1.0.0',
      }),
    ).toEqual({ source: 'tag', tag: 'v1.0.0' });
  });

  /**
   * `?version=` means nothing without the panel header. Ignored rather than
   * rejected so a stray query string cannot 500 someone's lesson screen -- and
   * ignored rather than honoured because once A/B lands, a client that could
   * pick its own arm would poison the measurement.
   */
  it('ignores a tag name on an app request', () => {
    expect(
      resolveVersionRequest({
        currentVersionId: CURRENT,
        allowDraft: false,
        requested: 'v1.0.0',
      }),
    ).toEqual({ source: 'version', versionId: CURRENT });
  });

  it('rejects a malformed version from the panel', () => {
    expect(() =>
      resolveVersionRequest({
        currentVersionId: CURRENT,
        allowDraft: true,
        requested: 'latest',
      }),
    ).toThrow(BadRequestException);
  });

  it('ignores a malformed version on an app request', () => {
    expect(
      resolveVersionRequest({
        currentVersionId: CURRENT,
        allowDraft: false,
        requested: 'latest',
      }),
    ).toEqual({ source: 'version', versionId: CURRENT });
  });

  /** Least privilege: anything but an explicit opt-in is an app request. */
  it('treats a missing allowDraft as an app request', () => {
    expect(resolveVersionRequest({ currentVersionId: CURRENT })).toEqual({
      source: 'version',
      versionId: CURRENT,
    });
  });
});

/**
 * Mirrors `viewerMarketsForRequest`: explicit truthy values only, so an absent
 * or empty header is the app's behaviour and the safe default for any caller
 * that never heard of it.
 */
describe('allowDraftFromHeaders', () => {
  it('accepts the values the admin client sends', () => {
    expect(allowDraftFromHeaders({ 'x-ignore-content-version': '1' })).toBe(true);
    expect(allowDraftFromHeaders({ 'x-ignore-content-version': 'true' })).toBe(true);
    expect(allowDraftFromHeaders({ 'x-ignore-content-version': 'YES' })).toBe(true);
  });

  it('treats absent, empty and falsy values as an app request', () => {
    expect(allowDraftFromHeaders(undefined)).toBe(false);
    expect(allowDraftFromHeaders({})).toBe(false);
    expect(allowDraftFromHeaders({ 'x-ignore-content-version': '' })).toBe(false);
    expect(allowDraftFromHeaders({ 'x-ignore-content-version': '0' })).toBe(false);
    expect(allowDraftFromHeaders({ 'x-ignore-content-version': 'false' })).toBe(false);
  });
});

/**
 * A/B nội dung khoá học. Bảng quyết định đầy đủ nằm ở ĐÂY, trong một hàm
 * thuần — I/O (tra đợt, tra tiến trình) do `ContentSource` làm rồi truyền sự
 * kiện vào, giống cách `segment-match.util.ts` tách đường serve khỏi đường đếm.
 */
describe('resolveVersionRequest với đợt A/B', () => {
  const CURRENT = '68c0000000000000000000f1';
  const ARM_A = '68c0000000000000000000aa';
  const ARM_B = '68c0000000000000000000bb';
  const RUN_START = new Date('2026-09-08T00:00:00Z');

  const run = (over: Partial<ExperimentFacts> = {}): ExperimentFacts => ({
    key: 'content_2026_09',
    percentB: 50,
    armA: ARM_A,
    armB: ARM_B,
    runStartedAt: RUN_START,
    progressStartedAt: null,
    ...over,
  });

  const resolve = (over: Partial<ResolveVersionInput> = {}) =>
    resolveVersionRequest({
      currentVersionId: CURRENT,
      viewerId: 'user-42',
      experiment: run(),
      ...over,
    });

  it('khoá không tham gia đợt thì đọc tag đang phát hành', () => {
    expect(resolve({ experiment: null })).toEqual({
      source: 'version',
      versionId: CURRENT,
    });
  });

  /** Khách không có id ổn định để băm — loại khỏi test, không phải chia bừa. */
  it('không có viewerId thì đọc tag đang phát hành', () => {
    expect(resolve({ viewerId: null })).toEqual({
      source: 'version',
      versionId: CURRENT,
    });
  });

  /**
   * Người đang học giữa khoá không bị đổi nội dung: việc họ hoàn thành
   * keypoint 9 đã bị ảnh hưởng bởi keypoint 1-8 ở bản kia.
   */
  it('tiến trình bắt đầu TRƯỚC đợt thì giữ tag đang phát hành', () => {
    const before = new Date('2026-09-01T00:00:00Z');
    expect(
      resolve({ experiment: run({ progressStartedAt: before }) }),
    ).toEqual({ source: 'version', versionId: CURRENT });
  });

  it('tiến trình bắt đầu SAU khi đợt mở thì vào test', () => {
    const after = new Date('2026-09-09T00:00:00Z');
    const got = resolve({
      experiment: run({ percentB: 100, progressStartedAt: after }),
    });

    expect(got).toEqual({
      source: 'version',
      versionId: ARM_B,
      experiment: { key: 'content_2026_09', arm: 'B' },
    });
  });

  it('chưa có tiến trình thì vào test', () => {
    expect(resolve({ experiment: run({ percentB: 100 }) })).toEqual({
      source: 'version',
      versionId: ARM_B,
      experiment: { key: 'content_2026_09', arm: 'B' },
    });
  });

  /** 0 và 100 hợp lệ để thu hẹp đợt về một nhánh mà không xoá `key`. */
  it('percentB 0 thì mọi người vào nhánh A', () => {
    expect(resolve({ experiment: run({ percentB: 0 }) })).toEqual({
      source: 'version',
      versionId: ARM_A,
      experiment: { key: 'content_2026_09', arm: 'A' },
    });
  });

  it('một người luôn ở nguyên một nhánh', () => {
    const a = resolve();
    const b = resolve();
    expect(a).toEqual(b);
  });

  it('chia theo đúng bucket của experimentBucket', () => {
    const inB = experimentBucket('content_2026_09', 'user-42') < 50;
    expect((resolve() as any).versionId).toBe(inB ? ARM_B : ARM_A);
  });

  /** Panel luôn thấy bản đang sửa, đợt A/B không đổi được điều đó. */
  it('panel vẫn thấy bản đang sửa dù đợt đang chạy', () => {
    expect(resolve({ allowDraft: true })).toEqual({ source: 'working' });
  });

  it('panel xin một tag cụ thể thì thắng đợt', () => {
    expect(resolve({ allowDraft: true, requested: 'v1.0.0' })).toEqual({
      source: 'tag',
      tag: 'v1.0.0',
    });
  });

  /**
   * Đợt cấu hình thiếu một nhánh (tên tag khai sai, hoặc tag đã bị xoá): phục
   * vụ nửa vời còn tệ hơn không chạy, nên rơi về tag đang phát hành.
   */
  it('thiếu một nhánh thì không chạy đợt', () => {
    expect(resolve({ experiment: run({ armB: '' }) })).toEqual({
      source: 'version',
      versionId: CURRENT,
    });
  });

  /** Khoá chưa từng tag mà lại bị đưa vào đợt: đọc bản đang sửa, không đoán. */
  it('không có currentVersionId và không vào test thì đọc bản đang sửa', () => {
    expect(
      resolve({ currentVersionId: null, experiment: null }),
    ).toEqual({ source: 'working' });
  });
});
