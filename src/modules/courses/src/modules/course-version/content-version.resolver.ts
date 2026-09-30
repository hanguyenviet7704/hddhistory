import { BadRequestException } from '@nestjs/common';

import { experimentBucket } from '@utils/experiment-bucket.util';

import { isTagName } from './course-version.util';

/**
 * Where one request should read course content from.
 * `working` = the live collections (what the admin panel edits); `version` = a
 * resolved `published_content` snapshot; `tag` = a snapshot still to be looked
 * up by name.
 */
export type VersionRequest =
  | { source: 'working' }
  | {
      source: 'version';
      versionId: string;
      /** Chỉ có khi đợt A/B áp dụng — app đóng dấu hai giá trị này lên event. */
      experiment?: { key: string; arm: 'A' | 'B' };
    }
  | { source: 'tag'; tag: string };

/**
 * Sự kiện của đợt A/B nội dung, do `ContentSource` tra sẵn rồi truyền vào:
 * đợt nào đang chạy cho khoá này, hai nhánh trỏ tới versionId nào, và người
 * xem bắt đầu học khoá này lúc nào. I/O ở ngoài, quyết định ở trong — giống
 * cách `segment-match.util.ts` tách đường serve khỏi đường đếm.
 */
export interface ExperimentFacts {
  /** Đổi mỗi đợt. Dùng lại là trả mọi người về đúng nhánh cũ. */
  key: string;
  /** Tỉ lệ vào nhánh B. 0 và 100 hợp lệ để thu hẹp đợt mà không xoá key. */
  percentB: number;
  armA: string;
  armB: string;
  runStartedAt: Date;
  /** null = chưa có tiến trình trong khoá này, tức đang bắt đầu bây giờ. */
  progressStartedAt?: Date | null;
}

/**
 * Set by the admin panel's axios client on EVERY request, next to
 * `x-ignore-market-targeting`, which exists for the same reason.
 *
 * ## Why a header and not a role check
 *
 * `user.role === UserRole.ADMIN` cannot work here. Nothing in this codebase
 * populates `role`: `CreateUserDto` defaults every account to `USER`, no
 * endpoint runs `RoleGuard`, and the real admin account is `role: USER`. That
 * assumption has already broken the admin panel three times (see the notes on
 * [UserHabitAdminController], [HabitPracticeAdminController] and
 * [CommunityPostController]). Here it would break quietly rather than with a
 * 403: editors would be shown the PUBLISHED content while trying to edit the
 * draft, and nothing would say why.
 *
 * ## Why a header and not a query flag or a separate route
 *
 * Nine admin pages read course content, and most of them are pickers inside
 * other entities' forms; a flag only the Courses page passed would leave the
 * rest reading published content. A header set once in `axiosClient` is the one
 * chokepoint every admin request already goes through, so no page can forget.
 *
 * ## What this is not
 *
 * Not a security boundary, and it does not pretend to be one -- anyone can send
 * the header, exactly as with market targeting, and this codebase has no
 * working role gate to be weaker than. What it must not become is a way for a
 * client to pick its own content: once A/B lands, arm assignment has to be
 * decided server-side from the user, never from a request the client controls.
 */
export const IGNORE_CONTENT_VERSION_HEADER = 'x-ignore-content-version';

/**
 * Explicit truthy values only. An absent header, an empty one, or a literal
 * '0'/'false' all mean "serve the published tag" -- the app's behaviour, and
 * the safe default for any caller that never heard of this header. Mirrors
 * `viewerMarketsForRequest`.
 */
export const allowDraftFromHeaders = (
  headers: Record<string, any> | undefined,
): boolean => {
  const value = String(headers?.[IGNORE_CONTENT_VERSION_HEADER] ?? '')
    .trim()
    .toLowerCase();

  return ['1', 'true', 'yes'].includes(value);
};

export interface ResolveVersionInput {
  currentVersionId?: string | null;
  /** `allowDraftFromHeaders(request.headers)` — the admin panel opt-in. */
  allowDraft?: boolean;
  /** The `?version=` query value: `current` or a `vX.Y.Z` tag name. */
  requested?: string | null;
  /** Id ổn định của người xem. Thiếu (khách) thì bị loại khỏi đợt A/B. */
  viewerId?: string | null;
  experiment?: ExperimentFacts | null;
}

/**
 * The admin panel and the app share these routes, so the panel header is what
 * decides who sees unpublished edits. `?version=` refines that, and only means
 * anything when the header is present.
 * See `plans/260907-course-content-versions/README.md` section 3.
 */
export const resolveVersionRequest = ({
  currentVersionId,
  allowDraft,
  requested,
  viewerId,
  experiment,
}: ResolveVersionInput): VersionRequest => {
  const current = (): VersionRequest =>
    currentVersionId
      ? { source: 'version', versionId: currentVersionId }
      : { source: 'working' };

  /** Nhánh A/B của người này, hoặc null khi họ không thuộc đợt. */
  const arm = (): VersionRequest | null => {
    if (!experiment || !viewerId) return null;
    // Hai nhánh phải trỏ tới tag thật. Thiếu một bên thì đợt cấu hình sai và
    // phục vụ nửa vời còn tệ hơn không chạy.
    if (!experiment.armA || !experiment.armB) return null;
    // Đang học giữa khoá từ trước khi đợt mở: đổi nội dung giữa đường vừa hỏng
    // trải nghiệm, vừa trộn hai bản vào cùng một con số.
    if (
      experiment.progressStartedAt &&
      experiment.progressStartedAt < experiment.runStartedAt
    ) {
      return null;
    }

    const inB = experimentBucket(experiment.key, viewerId) < experiment.percentB;

    return {
      source: 'version',
      versionId: inB ? experiment.armB : experiment.armA,
      experiment: { key: experiment.key, arm: inB ? 'B' : 'A' },
    };
  };

  // Without the panel header, `?version=` carries no meaning at all: ignored
  // rather than rejected, so a stray query string cannot break a lesson
  // screen, and ignored rather than honoured so no client can choose its own
  // content.
  if (!allowDraft) return arm() ?? current();

  if (!requested) return { source: 'working' };
  // `current` là CON TRỎ đang phát hành, không phải nhánh: khi đợt đang chạy
  // thì "cái user thật thấy" phụ thuộc id từng người, không có một câu trả lời.
  if (requested === 'current') return current();

  if (!isTagName(requested)) {
    throw new BadRequestException(
      'version must be "current" or a tag name like v1.0.0',
    );
  }

  return { source: 'tag', tag: requested };
};
