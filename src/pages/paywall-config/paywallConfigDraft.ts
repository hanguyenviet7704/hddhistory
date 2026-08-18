// Draft model for the paywall-config editor: a form-friendly mirror of
// `PaywallConfig` (numbers as strings for controlled inputs, stable
// `_localId`s on every repeatable array so React keys / add-remove stay
// simple), plus the mapping to/from the wire shape and client-side
// validation that mirrors `PaywallConfigService.validateShape` +
// `assertProductsExist` field-for-field so the operator sees inline errors
// immediately, without a round trip -- see PaywallConfigPage for why this
// matters (the shared AllExceptionsFilter/BaseValidationPipe in meup-api
// collapse structured `errors` arrays down to a single message today).
import {
  PAYWALL_CONFIG_LOCALES,
  PAYWALL_ENTRY_POINTS,
  PaywallAudienceSegment,
  PaywallAutoOpen,
  PaywallWinBack,
  PaywallDailyKeypointQuota,
  PaywallInLesson,
  PaywallBenefit,
  PaywallConfig,
  PaywallDefaultUser,
  PaywallEntryPoint,
  PaywallEntryPointVariants,
  PaywallLocale,
  PaywallLogicSale,
  PaywallLocaleContent,
  PaywallLocalizedContent,
  PaywallProductRef,
  PaywallProductVariant,
  PaywallGiftCampaign,
  PaywallCompactPaywall,
  PaywallLocalizedLine,
  PaywallReview,
  PaywallReviewContent,
  PaywallReviewLocaleContent,
  PaywallSaleEvent,
  PaywallSaleStrategy,
} from "../../types/interface/paywall-config.interface";

let localIdCounter = 0;
export const nextLocalId = () => `local-${++localIdCounter}`;

const randomBase36Chars = (length: number): string =>
  Array.from({ length }, () => Math.floor(Math.random() * 36).toString(36)).join("");

/**
 * `id` is the STABLE attribution key purchases are counted by — generated
 * once, client-side, when a LogicSale row is added, and never reused even
 * after that row is later removed.
 */
export const generateLogicSaleId = (): string => `ls-${randomBase36Chars(8)}`;

export interface ProductOption {
  id: string;
  productId: string;
  title: string;
}

export interface ProductsByPlatform {
  apple: ProductOption[];
  google: ProductOption[];
}

export interface ProductRefDraft extends PaywallProductRef {
  _localId: string;
}

export interface BenefitDraft extends PaywallBenefit {
  _localId: string;
}

export interface LocaleContentDraft {
  subheading: string;
  heading: string;
  benefits: BenefitDraft[];
}

export type LocalizedContentDraft = Record<PaywallLocale, LocaleContentDraft>;

export interface DefaultUserDraft {
  content: LocalizedContentDraft;
  products: ProductRefDraft[];
  compactProducts: ProductRefDraft[];
}

export interface ImpressionRuleDraft {
  _localId: string;
  fromImpression: string;
  content: LocalizedContentDraft;
  products: ProductRefDraft[];
  compactProducts: ProductRefDraft[];
}

export interface SaleEventDraft {
  enabled: boolean;
  campaignId: string;
  startAtUtc: string;
  endAtUtc: string;
  /** One flag per audience — the wire shape is an enum array, not free text. */
  appliesToDefaultUser: boolean;
  content: LocalizedContentDraft;
  products: ProductRefDraft[];
  compactProducts: ProductRefDraft[];
}

/** One string per locale; `en` is the only one the backend requires non-absent. */
export type LocalizedLineDraft = Record<PaywallLocale, string>;

export interface GiftCampaignDraft {
  enabled: boolean;
  title: LocalizedLineDraft;
  /** Chuỗi để bind input; rỗng = không gửi, app dùng mặc định 7. */
  windowDays: string;
  triggerOnFirstHabit: boolean;
  triggerOnDailyOpen: boolean;
}

/** Copy owned by the compact paywall itself; SKUs stay per-strategy. */
export interface CompactPaywallDraft {
  /** Chuỗi để bind input; rỗng = không gửi. */
  discountPercent: string;
  urgencyLine: LocalizedLineDraft;
}

export type EntryPointVariantsDraft = Record<
  PaywallEntryPoint,
  PaywallProductVariant
>;

export interface ReviewContentDraft {
  title: string;
  body: string;
}

export type ReviewLocalizedContentDraft = Record<PaywallLocale, ReviewContentDraft>;

export interface ReviewDraft {
  _localId: string;
  name: string;
  avatarUrl: string;
  /** Kept as text like every numeric draft field; "5" when absent, matching the backend default. */
  rating: string;
  content: ReviewLocalizedContentDraft;
}

export interface LogicSaleDraft {
  _localId: string;
  /** Attribution key. Generated once when the row is added (see `generateLogicSaleId`); read-only afterward. */
  id: string;
  name: string;
  enabled: boolean;
  segmentIds: string[];
  products: ProductRefDraft[];
  /** Chuỗi để bind input; rỗng = không gửi. */
  priority: string;
  /**
   * ISO string or `null` (open bound) — unlike the other campaign windows on
   * this page, converted to/from a `datetime-local` input at the component
   * boundary via `src/utils/promoCampaignForm.ts`, matching the Home
   * banner/popup campaign editors this row is closest to.
   */
  startAtUtc: string | null;
  endAtUtc: string | null;
  countdown: boolean;
}

export interface ConfigDraft {
  schemaVersion: string;
  enableLessonLock: boolean;
  /** Lessons left free before the gate, as a count. Was a raw-JSON textarea. */
  lessonLockCount: string;
  autoOpenEnabled: boolean;
  autoOpenPercent: string;
  winBackEnabled: boolean;
  winBackDelaySeconds: string;
  winBackMaxPerSession: string;
  inLessonEnabled: boolean;
  inLessonKeypointOrdinal: string;
  inLessonAfterCards: string;
  dailyQuotaEnabled: boolean;
  dailyQuotaFreeKeypointsPerDay: string;
  dailyQuotaAfterCards: string;
  entryPointVariants: EntryPointVariantsDraft;
  defaultUser: DefaultUserDraft;
  saleEvent: SaleEventDraft;
  giftCampaign: GiftCampaignDraft;
  compactPaywall: CompactPaywallDraft;
  showCredibilityBlock: boolean;
  reviews: ReviewDraft[];
  logicSales: LogicSaleDraft[];
}

// ---------------------------------------------------------------------
// Empty / default builders
// ---------------------------------------------------------------------

export const emptyLocaleContent = (): LocaleContentDraft => ({
  subheading: "",
  heading: "",
  benefits: [],
});

export const emptyLocalizedContent = (): LocalizedContentDraft =>
  Object.fromEntries(
    PAYWALL_CONFIG_LOCALES.map((locale) => [locale, emptyLocaleContent()])
  ) as LocalizedContentDraft;

export const emptyProductRef = (): ProductRefDraft => ({
  _localId: nextLocalId(),
  appleProductId: "",
  googleProductId: "",
});

export const emptyImpressionRule = (): ImpressionRuleDraft => ({
  _localId: nextLocalId(),
  fromImpression: "",
  content: emptyLocalizedContent(),
  products: [],
  compactProducts: [],
});

export const emptyLocalizedLine = (): LocalizedLineDraft =>
  Object.fromEntries(PAYWALL_CONFIG_LOCALES.map((locale) => [locale, ""])) as LocalizedLineDraft;

export const emptyReviewContent = (): ReviewContentDraft => ({
  title: "",
  body: "",
});

export const emptyReviewLocalizedContent = (): ReviewLocalizedContentDraft =>
  Object.fromEntries(
    PAYWALL_CONFIG_LOCALES.map((locale) => [locale, emptyReviewContent()])
  ) as ReviewLocalizedContentDraft;

export const emptyReview = (): ReviewDraft => ({
  _localId: nextLocalId(),
  name: "",
  avatarUrl: "",
  rating: "5",
  content: emptyReviewLocalizedContent(),
});

export const emptyLogicSale = (): LogicSaleDraft => ({
  _localId: nextLocalId(),
  id: generateLogicSaleId(),
  name: "",
  enabled: false,
  segmentIds: [],
  products: [],
  priority: "",
  startAtUtc: null,
  endAtUtc: null,
  countdown: false,
});

/**
 * Everything `full` — the behaviour of every config published before entry-point
 * variants existed, so a fresh draft never quietly narrows anyone's plan list.
 */
export const defaultEntryPointVariants = (): EntryPointVariantsDraft =>
  Object.fromEntries(
    PAYWALL_ENTRY_POINTS.map((entryPoint) => [entryPoint, "full"])
  ) as EntryPointVariantsDraft;

export const defaultDraft = (): ConfigDraft => ({
  schemaVersion: "1",
  enableLessonLock: false,
  lessonLockCount: "",
  autoOpenEnabled: false,
  autoOpenPercent: "0",
  winBackEnabled: false,
  // Defaults are the spec: three seconds, once a session.
  winBackDelaySeconds: "3",
  winBackMaxPerSession: "1",
  inLessonEnabled: false,
  inLessonKeypointOrdinal: "2",
  inLessonAfterCards: "1",
  dailyQuotaEnabled: false,
  // Defaults are the design intent: one keypoint a day, locked at card 3.
  dailyQuotaFreeKeypointsPerDay: "1",
  dailyQuotaAfterCards: "3",
  entryPointVariants: defaultEntryPointVariants(),
  defaultUser: {
    content: emptyLocalizedContent(),
    products: [],
    compactProducts: [],
  },
  saleEvent: {
    enabled: false,
    campaignId: "",
    startAtUtc: "",
    endAtUtc: "",
    appliesToDefaultUser: true,
    content: emptyLocalizedContent(),
    products: [],
    compactProducts: [],
  },
  giftCampaign: {
    enabled: false,
    title: emptyLocalizedLine(),
    windowDays: "",
    triggerOnFirstHabit: true,
    triggerOnDailyOpen: true,
  },
  compactPaywall: {
    discountPercent: "",
    urgencyLine: emptyLocalizedLine(),
  },
  // SHOWN by default, matching the app build that introduced the strip.
  showCredibilityBlock: true,
  // Empty by default: the app falls back to its 3 bundled reviews.
  reviews: [],
  // Empty by default: no merchandising rule is layered on the base strategy.
  logicSales: [],
});

// ---------------------------------------------------------------------
// Wire (PaywallConfig) -> Draft
// ---------------------------------------------------------------------

const toLocaleContentDraft = (content?: PaywallLocaleContent): LocaleContentDraft => ({
  subheading: content?.subheading ?? "",
  heading: content?.heading ?? "",
  benefits: (content?.benefits ?? []).map((b) => ({ ...b, _localId: nextLocalId() })),
});

const toLocalizedContentDraft = (
  content?: PaywallLocalizedContent
): LocalizedContentDraft =>
  Object.fromEntries(
    PAYWALL_CONFIG_LOCALES.map((locale) => [
      locale,
      toLocaleContentDraft(content?.[locale]),
    ])
  ) as LocalizedContentDraft;

const toProductRefDraft = (ref: PaywallProductRef): ProductRefDraft => ({
  _localId: nextLocalId(),
  appleProductId: ref.appleProductId ?? "",
  googleProductId: ref.googleProductId ?? "",
});

const toLocalizedLineDraft = (title?: PaywallLocalizedLine): LocalizedLineDraft =>
  Object.fromEntries(
    PAYWALL_CONFIG_LOCALES.map((locale) => [locale, title?.[locale] ?? ""])
  ) as LocalizedLineDraft;

const toDateTimeInput = (value?: string): string => {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(
    date.getDate()
  )}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
};

/**
 * Whether a saved `appliesTo` selects `segment`.
 *
 * A value that is not an array of these names — the bare `"all"` the old
 * free-text field invited, an object, anything else — was always dropped by the
 * client, so there is no audience to recover from it. Those start with every
 * audience selected rather than an empty list the backend now rejects.
 */
const hasAudience = (
  appliesTo: PaywallAudienceSegment[] | undefined,
  segment: PaywallAudienceSegment
): boolean => {
  if (!Array.isArray(appliesTo)) return true;
  return appliesTo.includes(segment);
};

/**
 * A config saved before entry-point variants existed has no such object; every
 * missing entry point reads as `full`, which is what the client does too.
 */
const toEntryPointVariantsDraft = (
  variants?: PaywallEntryPointVariants
): EntryPointVariantsDraft =>
  Object.fromEntries(
    PAYWALL_ENTRY_POINTS.map((entryPoint) => [
      entryPoint,
      variants?.[entryPoint] === "compact" ? "compact" : "full",
    ])
  ) as EntryPointVariantsDraft;

const toReviewContentDraft = (content?: PaywallReviewLocaleContent): ReviewContentDraft => ({
  title: content?.title ?? "",
  body: content?.body ?? "",
});

const toReviewLocalizedContentDraft = (
  content?: PaywallReviewContent
): ReviewLocalizedContentDraft =>
  Object.fromEntries(
    PAYWALL_CONFIG_LOCALES.map((locale) => [
      locale,
      toReviewContentDraft(content?.[locale]),
    ])
  ) as ReviewLocalizedContentDraft;

const toReviewDraft = (review: PaywallReview): ReviewDraft => ({
  _localId: nextLocalId(),
  name: review.name ?? "",
  avatarUrl: review.avatarUrl ?? "",
  rating: review.rating != null ? String(review.rating) : "5",
  content: toReviewLocalizedContentDraft(review.content),
});

const toLogicSaleDraft = (row: PaywallLogicSale): LogicSaleDraft => ({
  _localId: nextLocalId(),
  // Carried through as-is — this is the id already generated (client-side,
  // in an earlier session) or assigned server-side when the row was first
  // published, never regenerated on load.
  id: row.id,
  name: row.name ?? "",
  enabled: Boolean(row.enabled),
  segmentIds: row.segmentIds ?? [],
  products: (row.products ?? []).map(toProductRefDraft),
  priority: row.priority != null ? String(row.priority) : "",
  startAtUtc: row.startAtUtc ?? null,
  endAtUtc: row.endAtUtc ?? null,
  countdown: Boolean(row.countdown),
});

export const toDraft = (config: PaywallConfig): ConfigDraft => ({
  schemaVersion: String(config.schemaVersion ?? 1),
  enableLessonLock: Boolean(config.enableLessonLock),
  lessonLockCount:
    config.lessonLock != null ? String(config.lessonLock) : "",
  winBackEnabled: Boolean(config.winBack?.enabled),
  winBackDelaySeconds:
    config.winBack?.delaySeconds == null ? "3" : String(config.winBack.delaySeconds),
  winBackMaxPerSession:
    config.winBack?.maxPerSession == null ? "1" : String(config.winBack.maxPerSession),
  autoOpenEnabled: Boolean(config.autoOpen?.enabled),
  autoOpenPercent:
    config.autoOpen?.sessionRolloutPercent != null
      ? String(config.autoOpen.sessionRolloutPercent)
      : "0",
  inLessonEnabled: Boolean(config.inLessonPaywall?.enabled),
  // Defaults match the design intent (2nd keypoint, leaving card 1) so a
  // version saved before this gate existed opens the form on sane numbers
  // rather than zeros.
  inLessonKeypointOrdinal:
    config.inLessonPaywall?.keypointOrdinal != null
      ? String(config.inLessonPaywall.keypointOrdinal)
      : "2",
  inLessonAfterCards:
    config.inLessonPaywall?.afterCards != null
      ? String(config.inLessonPaywall.afterCards)
      : "1",
  dailyQuotaEnabled: Boolean(config.dailyKeypointQuota?.enabled),
  dailyQuotaFreeKeypointsPerDay:
    config.dailyKeypointQuota?.freeKeypointsPerDay != null
      ? String(config.dailyKeypointQuota.freeKeypointsPerDay)
      : "1",
  dailyQuotaAfterCards:
    config.dailyKeypointQuota?.afterCards != null
      ? String(config.dailyKeypointQuota.afterCards)
      : "3",
  entryPointVariants: toEntryPointVariantsDraft(config.entryPointVariants),
  defaultUser: {
    content: toLocalizedContentDraft(config.saleStrategy?.defaultUser?.content),
    products: (config.saleStrategy?.defaultUser?.products ?? []).map(
      toProductRefDraft
    ),
    compactProducts: (
      config.saleStrategy?.defaultUser?.compactProducts ?? []
    ).map(toProductRefDraft),
  },
  saleEvent: {
    enabled: Boolean(config.saleStrategy?.saleEvent?.enabled),
    campaignId: config.saleStrategy?.saleEvent?.campaignId ?? "",
    startAtUtc: toDateTimeInput(config.saleStrategy?.saleEvent?.startAtUtc),
    endAtUtc: toDateTimeInput(config.saleStrategy?.saleEvent?.endAtUtc),
    // A pre-existing free-text value (`"all"`, an object, anything that is not
    // this list of names) never matched on the client, so there is no audience
    // to carry forward from it — default both on and let the operator confirm.
    appliesToDefaultUser: hasAudience(
      config.saleStrategy?.saleEvent?.appliesTo,
      "defaultUser"
    ),
    content: toLocalizedContentDraft(config.saleStrategy?.saleEvent?.content),
    products: (config.saleStrategy?.saleEvent?.products ?? []).map(
      toProductRefDraft
    ),
    compactProducts: (
      config.saleStrategy?.saleEvent?.compactProducts ?? []
    ).map(toProductRefDraft),
  },
  giftCampaign: {
    enabled: Boolean(config.giftCampaign?.enabled),
    title: toLocalizedLineDraft(config.giftCampaign?.title),
    windowDays: config.giftCampaign?.windowDays != null ? String(config.giftCampaign.windowDays) : "",
    // Absent reads as ON, matching the app's parser and every build that
    // shipped before these toggles existed.
    triggerOnFirstHabit: config.giftCampaign?.triggerOnFirstHabit !== false,
    triggerOnDailyOpen: config.giftCampaign?.triggerOnDailyOpen !== false,
  },
  compactPaywall: {
    discountPercent: config.compactPaywall?.discountPercent != null ? String(config.compactPaywall.discountPercent) : "",
    urgencyLine: toLocalizedLineDraft(config.compactPaywall?.urgencyLine),
  },
  // Absent reads as SHOWN — the behaviour of the app build that introduced it.
  showCredibilityBlock: config.showCredibilityBlock !== false,
  reviews: (config.reviews ?? []).map(toReviewDraft),
  // Absent (every version published before this section existed) reads as
  // an empty list — no merchandising rule is layered on the base strategy.
  logicSales: (config.logicSales ?? []).map(toLogicSaleDraft),
});

// ---------------------------------------------------------------------
// Draft -> Wire (PaywallConfig payload)
// ---------------------------------------------------------------------

export const isLocaleContentEmpty = (content: LocaleContentDraft): boolean =>
  !content.subheading.trim() &&
  !content.heading.trim() &&
  content.benefits.every((b) => !b.icon.trim() && !b.title.trim());

export const isLocalizedContentEmpty = (content: LocalizedContentDraft): boolean =>
  PAYWALL_CONFIG_LOCALES.every((locale) => isLocaleContentEmpty(content[locale]));

export const isReviewContentEmpty = (content: ReviewContentDraft): boolean =>
  !content.title.trim() && !content.body.trim();

export const isReviewLocalizedContentEmpty = (
  content: ReviewLocalizedContentDraft
): boolean => PAYWALL_CONFIG_LOCALES.every((locale) => isReviewContentEmpty(content[locale]));

const fromLocaleContentDraft = (content: LocaleContentDraft): PaywallLocaleContent => {
  const result: PaywallLocaleContent = {};
  if (content.subheading.trim()) result.subheading = content.subheading.trim();
  if (content.heading.trim()) result.heading = content.heading.trim();
  const benefits = content.benefits
    .filter((b) => b.icon.trim() || b.title.trim())
    .map((b) => ({ icon: b.icon.trim(), title: b.title.trim() }));
  if (benefits.length) result.benefits = benefits;
  return result;
};

/** Always includes `en`; other locales only if they have any content. */
const fromLocalizedContentDraft = (
  content: LocalizedContentDraft
): PaywallLocalizedContent => {
  const result = { en: fromLocaleContentDraft(content.en) } as PaywallLocalizedContent;
  PAYWALL_CONFIG_LOCALES.forEach((locale) => {
    if (locale === "en") return;
    if (!isLocaleContentEmpty(content[locale])) {
      (result as any)[locale] = fromLocaleContentDraft(content[locale]);
    }
  });
  return result;
};

const fromProductRefDraft = (ref: ProductRefDraft): PaywallProductRef => ({
  appleProductId: ref.appleProductId?.trim() || undefined,
  googleProductId: ref.googleProductId?.trim() || undefined,
});

const fromDateTimeInput = (value: string): string | undefined => {
  if (!value) return undefined;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return undefined;
  return date.toISOString();
};

/**
 * `compactProducts` is omitted entirely when empty rather than sent as `[]`.
 * Both mean "fall back to `products`" to the client, but omitting keeps the
 * stored JSON free of keys that assert nothing.
 */
const fromCompactProductsDraft = (
  rows: ProductRefDraft[]
): PaywallProductRef[] | undefined =>
  rows.length ? rows.map(fromProductRefDraft) : undefined;

const fromReviewContentDraft = (content: ReviewContentDraft): PaywallReviewLocaleContent => {
  const result: PaywallReviewLocaleContent = {};
  if (content.title.trim()) result.title = content.title.trim();
  if (content.body.trim()) result.body = content.body.trim();
  return result;
};

/** Always includes `en`; other locales only if they have any content. */
const fromReviewLocalizedContentDraft = (
  content: ReviewLocalizedContentDraft
): PaywallReviewContent => {
  const result = { en: fromReviewContentDraft(content.en) } as PaywallReviewContent;
  PAYWALL_CONFIG_LOCALES.forEach((locale) => {
    if (locale === "en") return;
    if (!isReviewContentEmpty(content[locale])) {
      (result as any)[locale] = fromReviewContentDraft(content[locale]);
    }
  });
  return result;
};

const fromReviewDraft = (review: ReviewDraft): PaywallReview => ({
  name: review.name.trim(),
  avatarUrl: review.avatarUrl.trim() || undefined,
  rating: review.rating.trim() ? Number(review.rating) : undefined,
  content: fromReviewLocalizedContentDraft(review.content),
});

const fromLogicSaleDraft = (row: LogicSaleDraft): PaywallLogicSale => ({
  id: row.id,
  name: row.name.trim(),
  // Stored explicitly rather than only-when-true, same reasoning as every
  // other campaign switch on this page: the JSON should state the intent.
  enabled: row.enabled,
  segmentIds: row.segmentIds.length ? row.segmentIds : undefined,
  // Omitted entirely when empty, same idiom as `compactProducts`/`reviews`
  // above — an empty list still means "staged, never served" to the app
  // whether the key is present-and-empty or absent.
  products: row.products.length ? row.products.map(fromProductRefDraft) : undefined,
  priority: row.priority.trim() ? Number(row.priority) : undefined,
  startAtUtc: row.startAtUtc ?? undefined,
  endAtUtc: row.endAtUtc ?? undefined,
  countdown: row.countdown,
});

export const isLocalizedLineEmpty = (title: LocalizedLineDraft): boolean =>
  PAYWALL_CONFIG_LOCALES.every((locale) => !title[locale].trim());

/** Omitted entirely when every locale is blank -- absent means the app's bundled copy. */
const fromLocalizedLineDraft = (title: LocalizedLineDraft): PaywallLocalizedLine | undefined => {
  if (isLocalizedLineEmpty(title)) return undefined;
  const result = { en: title.en.trim() } as PaywallLocalizedLine;
  PAYWALL_CONFIG_LOCALES.forEach((locale) => {
    if (locale === "en") return;
    if (title[locale].trim()) {
      (result as any)[locale] = title[locale].trim();
    }
  });
  return result;
};

const fromAudienceFlags = (draft: SaleEventDraft): PaywallAudienceSegment[] => {
  const appliesTo: PaywallAudienceSegment[] = [];
  if (draft.appliesToDefaultUser) appliesTo.push("defaultUser");
  return appliesTo;
};

export const fromDraft = (draft: ConfigDraft): PaywallConfig => {
  const defaultUser: PaywallDefaultUser = {
    content: fromLocalizedContentDraft(draft.defaultUser.content),
    products: draft.defaultUser.products.map(fromProductRefDraft),
    compactProducts: fromCompactProductsDraft(draft.defaultUser.compactProducts),
  };

  const saleEventContentEmpty = isLocalizedContentEmpty(draft.saleEvent.content);
  const saleEvent: PaywallSaleEvent = {
    enabled: draft.saleEvent.enabled,
    campaignId: draft.saleEvent.campaignId.trim() || undefined,
    startAtUtc: fromDateTimeInput(draft.saleEvent.startAtUtc),
    endAtUtc: fromDateTimeInput(draft.saleEvent.endAtUtc),
    appliesTo: fromAudienceFlags(draft.saleEvent),
    content: saleEventContentEmpty
      ? undefined
      : fromLocalizedContentDraft(draft.saleEvent.content),
    products: draft.saleEvent.products.length
      ? draft.saleEvent.products.map(fromProductRefDraft)
      : undefined,
    compactProducts: fromCompactProductsDraft(draft.saleEvent.compactProducts),
  };

  const saleStrategy: PaywallSaleStrategy = { defaultUser, saleEvent };

  const autoOpen: PaywallAutoOpen = {
    enabled: draft.autoOpenEnabled,
    sessionRolloutPercent: Number(draft.autoOpenPercent || 0),
  };

  // Sent only when ON. Omitting the block for a disabled gate keeps published
  // JSON free of dead campaigns, and the client reads a missing key as off —
  // the same contract every gate added after v1 uses.
  const winBack: PaywallWinBack | undefined = draft.winBackEnabled
    ? {
        enabled: true,
        delaySeconds: Number(draft.winBackDelaySeconds || 3),
        maxPerSession: Number(draft.winBackMaxPerSession || 1),
      }
    : undefined;

  const dailyKeypointQuota: PaywallDailyKeypointQuota = {
    enabled: draft.dailyQuotaEnabled,
    freeKeypointsPerDay: Number(draft.dailyQuotaFreeKeypointsPerDay || 0),
    afterCards: Number(draft.dailyQuotaAfterCards || 3),
  };

  const inLessonPaywall: PaywallInLesson = {
    enabled: draft.inLessonEnabled,
    keypointOrdinal: Number(draft.inLessonKeypointOrdinal || 0),
    afterCards: Number(draft.inLessonAfterCards || 1),
  };

  const lessonLockCount = draft.lessonLockCount.trim();
  const lessonLock = lessonLockCount ? Number(lessonLockCount) : undefined;

  // Sent in full (all nine keys) rather than only the `compact` ones: the stored
  // JSON then states the intent for every entry point, so reading the config
  // later never requires knowing what the client's default happens to be.
  const entryPointVariants: PaywallEntryPointVariants = Object.fromEntries(
    PAYWALL_ENTRY_POINTS.map((entryPoint) => [
      entryPoint,
      draft.entryPointVariants[entryPoint],
    ])
  );

  const giftWindowDays = draft.giftCampaign.windowDays.trim()
    ? Number(draft.giftCampaign.windowDays)
    : undefined;
  const giftCampaign: PaywallGiftCampaign = {
    enabled: draft.giftCampaign.enabled,
    title: fromLocalizedLineDraft(draft.giftCampaign.title),
    // Blank = don't send, so the app keeps its built-in 7 rather than being
    // pinned to a number nobody chose.
    ...(giftWindowDays != null ? { windowDays: giftWindowDays } : {}),
    triggerOnFirstHabit: draft.giftCampaign.triggerOnFirstHabit,
    triggerOnDailyOpen: draft.giftCampaign.triggerOnDailyOpen,
  };

  // Trống toàn bộ → không gửi field, giữ nguyên tắc field-sau-v1 optional.
  const urgencyLine = fromLocalizedLineDraft(draft.compactPaywall.urgencyLine);
  const compactDiscount = draft.compactPaywall.discountPercent.trim() ? Number(draft.compactPaywall.discountPercent) : undefined;
  // The sheet's countdown is a fixed 24h window owned by the app — no hours
  // field, no shared deadline. Only the headline discount and its urgency line
  // are still authored here.
  const compactPaywall: PaywallCompactPaywall | undefined =
    urgencyLine || compactDiscount != null
      ? {
          ...(compactDiscount != null ? { discountPercent: compactDiscount } : {}),
          ...(urgencyLine ? { urgencyLine } : {}),
        }
      : undefined;

  // Omitted entirely when empty rather than sent as `[]`: both mean "use the
  // app's bundled reviews" to the client, but omitting keeps the stored JSON
  // free of a key that asserts nothing.
  const reviews = draft.reviews.length ? draft.reviews.map(fromReviewDraft) : undefined;

  // Same rule: an old version that never had `logicSales` and a version that
  // has it but emptied the list should both publish as "absent" — round-trip
  // stays byte-compatible instead of injecting `logicSales: []` into configs
  // that never carried the key.
  const logicSales = draft.logicSales.length
    ? draft.logicSales.map(fromLogicSaleDraft)
    : undefined;

  return {
    schemaVersion: Number(draft.schemaVersion || 1),
    enableLessonLock: draft.enableLessonLock,
    lessonLock,
    autoOpen,
    winBack,
    inLessonPaywall,
    dailyKeypointQuota,
    entryPointVariants,
    saleStrategy,
    giftCampaign,
    ...(compactPaywall ? { compactPaywall } : {}),
    // Stored explicitly rather than only-when-false, so the JSON states the
    // intent and reading it never requires knowing the client default.
    showCredibilityBlock: draft.showCredibilityBlock,
    reviews,
    logicSales,
  };
};

// ---------------------------------------------------------------------
// Client-side validation -- mirrors PaywallConfigService.validateShape +
// assertProductsExist field-for-field (same `field` path strings) so this
// still works even though the shared exception filter in meup-api does not
// currently forward structured `errors` arrays back to the client.
// ---------------------------------------------------------------------

const validateProductRefRow = (
  ref: ProductRefDraft,
  field: string,
  productsByPlatform: ProductsByPlatform | null,
  errors: Record<string, string>
) => {
  const apple = ref.appleProductId?.trim();
  const google = ref.googleProductId?.trim();

  if (!apple && !google) {
    errors[field] = `${field}: phải có appleProductId và/hoặc googleProductId`;
    return;
  }

  if (!productsByPlatform) return; // catalog still loading -- skip existence check

  if (apple && !productsByPlatform.apple.some((p) => p.productId === apple)) {
    errors[`${field}.appleProductId`] = `Sản phẩm "${apple}" (apple) không tồn tại hoặc không active trong iap_products`;
  }
  if (google && !productsByPlatform.google.some((p) => p.productId === google)) {
    errors[`${field}.googleProductId`] = `Sản phẩm "${google}" (google) không tồn tại hoặc không active trong iap_products`;
  }
};

const validateProductsNonEmpty = (
  products: ProductRefDraft[],
  field: string,
  productsByPlatform: ProductsByPlatform | null,
  errors: Record<string, string>
) => {
  if (!products.length) {
    errors[field] = `${field}: phải có ít nhất 1 sản phẩm`;
    return;
  }
  products.forEach((ref, index) =>
    validateProductRefRow(ref, `${field}[${index}]`, productsByPlatform, errors)
  );
};

/**
 * Same per-row rule but an empty list is valid: for `compactProducts` that
 * means "dùng danh sách đầy đủ", which is a real choice, not an omission.
 */
const validateOptionalProducts = (
  products: ProductRefDraft[],
  field: string,
  productsByPlatform: ProductsByPlatform | null,
  errors: Record<string, string>
) => {
  if (!products.length) return;
  validateProductsNonEmpty(products, field, productsByPlatform, errors);
};

export const validateDraft = (
  draft: ConfigDraft,
  productsByPlatform: ProductsByPlatform | null
): Record<string, string> => {
  const errors: Record<string, string> = {};

  if (!draft.schemaVersion.trim() || Number(draft.schemaVersion) < 1) {
    errors.schemaVersion = "schemaVersion là bắt buộc và phải >= 1";
  }

  const percent = Number(draft.autoOpenPercent);
  if (
    draft.autoOpenPercent.trim() === "" ||
    Number.isNaN(percent) ||
    percent < 0 ||
    percent > 100
  ) {
    errors["autoOpen.sessionRolloutPercent"] =
      "autoOpen.sessionRolloutPercent là bắt buộc và phải là số từ 0 đến 100";
  }

  // Only meaningful when the gate is on; a disabled block is not sent at all.
  if (draft.winBackEnabled) {
    const delay = Number(draft.winBackDelaySeconds);
    if (
      draft.winBackDelaySeconds.trim() === "" ||
      !Number.isInteger(delay) ||
      delay < 0 ||
      delay > 60
    ) {
      errors["winBack.delaySeconds"] =
        "winBack.delaySeconds phải là số nguyên từ 0 đến 60";
    }

    const cap = Number(draft.winBackMaxPerSession);
    if (
      draft.winBackMaxPerSession.trim() === "" ||
      !Number.isInteger(cap) ||
      cap < 1 ||
      cap > 5
    ) {
      errors["winBack.maxPerSession"] =
        "winBack.maxPerSession phải là số nguyên từ 1 đến 5";
    }

    // Mirrors the server rule: the win-back sheet IS the compact paywall, and
    // the compact paywall takes its single plan from defaultUser.compactProducts.
    // Publishing without them would ship a sheet with no price and a dead CTA.
    if (!draft.defaultUser.compactProducts.length) {
      errors["winBack.enabled"] =
        "Bật win-back cần có gói ở 'Gói rút gọn · Mặc định' — sheet win-back chính là paywall rút gọn";
    }
  }

  // A missing count with the lock ON is what breaks: the client reads the
  // absent field as 0, and 0 locks the course from lesson one -- where the tap
  // is swallowed rather than gated, so the course just looks broken.
  const lessonLockCount = draft.lessonLockCount.trim();
  if (draft.enableLessonLock) {
    if (!lessonLockCount || !Number.isInteger(Number(lessonLockCount))) {
      errors.lessonLock =
        "lessonLock là bắt buộc và phải là số nguyên khi bật khóa bài học";
    }
  } else if (lessonLockCount && !Number.isInteger(Number(lessonLockCount))) {
    errors.lessonLock = "lessonLock phải là số nguyên";
  }

  // defaultUser
  if (isLocalizedContentEmpty(draft.defaultUser.content)) {
    errors["saleStrategy.defaultUser.content"] =
      "saleStrategy.defaultUser.content là bắt buộc";
  }
  validateProductsNonEmpty(
    draft.defaultUser.products,
    "saleStrategy.defaultUser.products",
    productsByPlatform,
    errors
  );
  validateOptionalProducts(
    draft.defaultUser.compactProducts,
    "saleStrategy.defaultUser.compactProducts",
    productsByPlatform,
    errors
  );

  // saleEvent
  if (draft.saleEvent.enabled) {
    validateProductsNonEmpty(
      draft.saleEvent.products,
      "saleStrategy.saleEvent.products",
      productsByPlatform,
      errors
    );
    validateOptionalProducts(
      draft.saleEvent.compactProducts,
      "saleStrategy.saleEvent.compactProducts",
      productsByPlatform,
      errors
    );

    // The client drops a campaign whose window does not fully parse and whose
    // start does not precede its end -- an enabled event missing a bound is not
    // an open-ended event, it is no event at all.
    const startAt = draft.saleEvent.startAtUtc
      ? new Date(draft.saleEvent.startAtUtc).getTime()
      : NaN;
    const endAt = draft.saleEvent.endAtUtc
      ? new Date(draft.saleEvent.endAtUtc).getTime()
      : NaN;
    if (Number.isNaN(startAt)) {
      errors["saleStrategy.saleEvent.startAtUtc"] =
        "saleStrategy.saleEvent.startAtUtc là bắt buộc khi bật sự kiện sale";
    }
    if (Number.isNaN(endAt)) {
      errors["saleStrategy.saleEvent.endAtUtc"] =
        "saleStrategy.saleEvent.endAtUtc là bắt buộc khi bật sự kiện sale";
    }
    if (!Number.isNaN(startAt) && !Number.isNaN(endAt) && startAt >= endAt) {
      errors["saleStrategy.saleEvent.endAtUtc"] =
        "saleStrategy.saleEvent.endAtUtc phải sau startAtUtc (nếu không client bỏ cả chiến dịch)";
    }

    if (!draft.saleEvent.appliesToDefaultUser) {
      errors["saleStrategy.saleEvent.appliesTo"] =
        "saleStrategy.saleEvent.appliesTo phải chọn ít nhất 1 đối tượng khi bật sự kiện sale";
    }
  }

  // compactPaywall — % hiển thị phải là số nguyên 1-99 nếu điền.
  if (draft.compactPaywall.discountPercent.trim()) {
    const pct = Number(draft.compactPaywall.discountPercent);
    if (!Number.isInteger(pct) || pct < 1 || pct > 99) {
      errors["compactPaywall.discountPercent"] = "Phải là số nguyên 1–99.";
    }
  }

  // compactPaywall.urgencyLine — same rule as the gift title: entirely
  // optional, but once any locale is filled EN must be too (API fallback).
  if (!isLocalizedLineEmpty(draft.compactPaywall.urgencyLine) && !draft.compactPaywall.urgencyLine.en.trim()) {
    errors["compactPaywall.urgencyLine.en"] = "Đã điền locale khác thì bắt buộc có tiếng Anh (locale fallback).";
  }

  // giftCampaign — the popup's title is entirely optional (absent uses the
  // app's bundled copy), but the backend's `en` field is a plain required
  // string, not optional: sending some other locale filled in with `en`
  // blank would publish a title object whose i18n fallback is empty text.
  if (!isLocalizedLineEmpty(draft.giftCampaign.title) && !draft.giftCampaign.title.en.trim()) {
    errors["giftCampaign.title.en"] =
      "giftCampaign.title.en là bắt buộc khi đã điền tiêu đề cho ít nhất 1 ngôn ngữ";
  }

  // Blank is legal here (unlike saleStrategy.newUser.windowDays, which gates a
  // whole audience): it means "don't send the field", and the app falls back to
  // its built-in 7. Only a value that IS typed has to be in the range the DTO
  // accepts, so a rejected save is caught here instead of by a 400.
  if (draft.giftCampaign.windowDays.trim()) {
    const giftWindow = Number(draft.giftCampaign.windowDays);
    if (!Number.isInteger(giftWindow) || giftWindow < 1 || giftWindow > 30) {
      errors["giftCampaign.windowDays"] =
        "Số ngày phải là số nguyên từ 1 đến 30, hoặc để trống để dùng mặc định 7";
    }
  }

  // reviews — purely client-side rules (the backend itself only requires
  // `name` and the `content.en` object to exist, not that it be non-empty):
  // a nameless card or one with no English copy at all would still round-trip
  // and publish, but would render broken/blank on every locale that falls
  // back to `en`.
  draft.reviews.forEach((review, index) => {
    const prefix = `reviews[${index}]`;
    if (!review.name.trim()) {
      errors[`${prefix}.name`] = `${prefix}.name là bắt buộc`;
    }
    if (isReviewContentEmpty(review.content.en)) {
      errors[`${prefix}.content.en`] =
        `${prefix}.content.en: cần ít nhất tiêu đề hoặc nội dung tiếng Anh`;
    }
  });

  // logicSales — mirrors the backend's publish-time checks (parseable window,
  // end after start, `countdown: true` requires `endAtUtc`) plus the UI-only
  // cap: the add button already stops at 20, this only catches a config that
  // arrived over that some other way (direct API edit, restored version).
  if (draft.logicSales.length > 20) {
    errors.logicSales = "logicSales: tối đa 20 mục";
  }
  draft.logicSales.forEach((row, index) => {
    const prefix = `logicSales[${index}]`;
    if (!row.name.trim()) {
      errors[`${prefix}.name`] = `${prefix}.name là bắt buộc`;
    }
    if (row.priority.trim() && !Number.isInteger(Number(row.priority))) {
      errors[`${prefix}.priority`] = `${prefix}.priority phải là số nguyên`;
    }
    const startAt = row.startAtUtc ? new Date(row.startAtUtc).getTime() : NaN;
    const endAt = row.endAtUtc ? new Date(row.endAtUtc).getTime() : NaN;
    if (row.startAtUtc && Number.isNaN(startAt)) {
      errors[`${prefix}.startAtUtc`] = `${prefix}.startAtUtc không hợp lệ`;
    }
    if (row.endAtUtc && Number.isNaN(endAt)) {
      errors[`${prefix}.endAtUtc`] = `${prefix}.endAtUtc không hợp lệ`;
    }
    if (
      row.startAtUtc &&
      row.endAtUtc &&
      !Number.isNaN(startAt) &&
      !Number.isNaN(endAt) &&
      startAt >= endAt
    ) {
      errors[`${prefix}.endAtUtc`] = `${prefix}.endAtUtc phải sau startAtUtc`;
    }
    if (row.countdown && !row.endAtUtc) {
      errors[`${prefix}.countdown`] = `${prefix}.countdown cần có endAtUtc`;
    }
    validateOptionalProducts(row.products, `${prefix}.products`, productsByPlatform, errors);
  });

  return errors;
};

export const hasAnyError = (errors: Record<string, string>) =>
  Object.keys(errors).length > 0;

/** All [field, message] pairs whose field is `prefix` or nested under it. */
export const errorsWithPrefix = (
  errors: Record<string, string>,
  prefix: string
): [string, string][] =>
  Object.entries(errors).filter(
    ([field]) =>
      field === prefix || field.startsWith(`${prefix}.`) || field.startsWith(`${prefix}[`)
  );
