import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

// Mirrors the 5 locales the Flutter app ships (assets/i18n/{en,ja,ko,vi,zh}).
export const PAYWALL_CONFIG_LOCALES = ['en', 'vi', 'zh', 'ja', 'ko'] as const;

export type PaywallConfigLocale = (typeof PAYWALL_CONFIG_LOCALES)[number];

/**
 * Which of a strategy's two SKU lists the paywall renders.
 *
 * `full` = that strategy's `products`; `compact` = its `compactProducts` (the
 * reduced set shown where a single choice converts better -- see
 * `plans/260803-paywall-entry-point-variants/design.md`). The strategy still
 * owns the copy either way; this only picks between its SKU lists.
 */
export enum PaywallProductVariant {
  FULL = 'full',
  COMPACT = 'compact',
}

/** Audience a sale event may target. Mirrors Flutter's `PaywallAudienceSegment`. */
export enum PaywallAudienceSegment {
  DEFAULT_USER = 'defaultUser',
  NEW_USER = 'newUser',
}

/**
 * Every place the app can open the paywall from. Mirrors Flutter's
 * `PaywallEntryPoint` (`iap_state.dart`) -- the JSON keys are exactly the Dart
 * enum's `.name` values, which is how the client looks a variant up.
 */
export const PAYWALL_ENTRY_POINTS = [
  'inLesson',
  'courseRoadmap',
  // The daily-quota wall, "Create a lesson" in My lessons, and the
  // post-onboarding open. All three existed in the app's `PaywallEntryPoint`
  // for a while without a row here, so `variantForEntryPoint` never found them
  // and they silently rendered `full` whatever admin chose.
  //
  // `winBack` is deliberately NOT here: that flow names its own surface through
  // `forcePaywallVariant`, which now wins over this table outright, so a row for
  // it would be a control that does nothing.
  'keypointLocked',
  'learningImport',
  'onboarding',
  'home',
  'autoOpen',
  'profile',
  'settingPre',
  'manageSubscription',
  'habit',
  'theme',
  'other',
] as const;

export class PaywallBenefitDto {
  @ApiProperty({ example: 'sparkle' })
  @IsString()
  icon: string;

  @ApiProperty({ example: 'Unlimited lessons' })
  @IsString()
  title: string;
}

/**
 * Which body the paywall renders between the header and the plan cards.
 *
 * `benefits` is the shipped feature list (design `6b · Premium` Version 1);
 * `comparison` swaps it for the Free-vs-Premium table (Version 2). The two are
 * ALTERNATIVES, not additions -- the design gates them on mutually exclusive
 * branches, and showing both would say the same thing twice on one screen.
 */
export enum PaywallBodyVariant {
  BENEFITS = 'benefits',
  COMPARISON = 'comparison',
}

/**
 * Splits viewers between the two bodies so the choice can be measured instead
 * of argued about. Deliberately one-off and not a general experiment framework:
 * a second test would want its own metric and its own readout, and a framework
 * built for one test is a framework designed against one example.
 *
 * The assignment itself is NOT stored -- it is recomputed from
 * `hash(key + viewerId)` on every resolve, so it is stable for a viewer without
 * a row per viewer, and re-deriving it later (in a query, in a support ticket)
 * needs nothing but the key and the id. That is also why `key` must change when
 * a new run starts: reusing it would hand every viewer the arm they were in
 * last time, quietly turning a fresh test into a continuation of the old one.
 */
export class PaywallBodyExperimentDto {
  @ApiProperty({
    example: 'paywall_body_2026_08',
    description:
      'Stable key identifying this run. Part of the bucketing hash and ' +
      'stamped on events and purchases. NEVER reuse a key for a new run.',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  key: string;

  @ApiProperty({ example: true })
  @IsBoolean()
  enabled: boolean;

  /**
   * Share of eligible viewers that get `comparison`; the rest get `benefits`.
   * 50 is the even split; 0 and 100 are legal so a run can be wound down to one
   * arm without deleting the block (and losing the key that the already-stamped
   * purchases refer to).
   */
  @ApiProperty({ example: 50, minimum: 0, maximum: 100 })
  @IsInt()
  @Min(0)
  @Max(100)
  comparisonPercent: number;
}

/** One row of the Free-vs-Premium table. */
export class PaywallComparisonRowDto {
  @ApiProperty({ example: 'Lessons' })
  @IsString()
  label: string;

  @ApiProperty({ example: '1 / day' })
  @IsString()
  free: string;

  @ApiProperty({ example: 'Unlimited' })
  @IsString()
  premium: string;

  /**
   * Whether the Premium cell shows the tick badge before its text.
   *
   * Optional, defaulting to ON at the client: every row in the design has the
   * tick, so a row saved without the field must look like the design rather
   * than lose its tick. The flag exists for the row where the Premium side is
   * not an upgrade to tick (a theme NAME, say).
   */
  @ApiPropertyOptional({ example: true, default: true })
  @IsOptional()
  @IsBoolean()
  hasCheck?: boolean;
}

/** One locale's worth of paywall copy (already in that locale, not multi-lang). */
export class PaywallLocaleContentDto {
  @ApiPropertyOptional({ example: 'Limited time offer' })
  @IsOptional()
  @IsString()
  subheading?: string;

  @ApiPropertyOptional({ example: 'Unlock everything' })
  @IsOptional()
  @IsString()
  heading?: string;

  @ApiPropertyOptional({ type: [PaywallBenefitDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PaywallBenefitDto)
  benefits?: PaywallBenefitDto[];

  /**
   * Rows of the Free-vs-Premium table, read only when `bodyVariant` is
   * `comparison`. Per locale like `benefits`, because every cell is prose.
   *
   * Absent or empty is not an error and not an empty table: the client falls
   * back to the benefits list. That is what lets the variant be switched on
   * before this locale's rows are written, instead of showing a headed table
   * with nothing under it.
   */
  @ApiPropertyOptional({ type: [PaywallComparisonRowDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PaywallComparisonRowDto)
  comparison?: PaywallComparisonRowDto[];
}

/**
 * `en` is required (it is the i18n fallback locale for the whole API --
 * see `I18nModule.forRoot({ fallbackLanguage: 'en' })` in app.module.ts);
 * the other 4 are optional so a strategy can be published before every
 * locale's copy is ready without blocking on the rest.
 */
export class PaywallLocalizedContentDto {
  @ApiProperty({ type: PaywallLocaleContentDto })
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallLocaleContentDto)
  en: PaywallLocaleContentDto;

  @ApiPropertyOptional({ type: PaywallLocaleContentDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallLocaleContentDto)
  vi?: PaywallLocaleContentDto;

  @ApiPropertyOptional({ type: PaywallLocaleContentDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallLocaleContentDto)
  zh?: PaywallLocaleContentDto;

  @ApiPropertyOptional({ type: PaywallLocaleContentDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallLocaleContentDto)
  ja?: PaywallLocaleContentDto;

  @ApiPropertyOptional({ type: PaywallLocaleContentDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallLocaleContentDto)
  ko?: PaywallLocaleContentDto;
}

/** One locale's worth of one review card (already in that locale). */
export class PaywallReviewLocaleDto {
  @ApiPropertyOptional({ example: 'I needed this' })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional({ example: 'Using this app has helped me stay ahead.' })
  @IsOptional()
  @IsString()
  body?: string;
}

/** Same locale contract as [PaywallLocalizedContentDto]: en required, rest optional. */
export class PaywallReviewLocalizedDto {
  @ApiProperty({ type: PaywallReviewLocaleDto })
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallReviewLocaleDto)
  en: PaywallReviewLocaleDto;

  @ApiPropertyOptional({ type: PaywallReviewLocaleDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallReviewLocaleDto)
  vi?: PaywallReviewLocaleDto;

  @ApiPropertyOptional({ type: PaywallReviewLocaleDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallReviewLocaleDto)
  zh?: PaywallReviewLocaleDto;

  @ApiPropertyOptional({ type: PaywallReviewLocaleDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallReviewLocaleDto)
  ja?: PaywallReviewLocaleDto;

  @ApiPropertyOptional({ type: PaywallReviewLocaleDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallReviewLocaleDto)
  ko?: PaywallReviewLocaleDto;
}

/**
 * One card of the paywall's "What people say" carousel. Name and avatar are
 * shown as-is in every locale (a reviewer's name is not translated); only the
 * card's text is per-locale.
 */
export class PaywallReviewDto {
  @ApiProperty({ example: 'Bete Noir' })
  @IsString()
  name: string;

  @ApiPropertyOptional({
    example: 'https://cdn-dev.meup.training/paywall/reviews/bete.png',
    description: 'Absolute image URL (upload via the file module / R2). Absent renders an initial-letter placeholder.',
  })
  @IsOptional()
  @IsString()
  avatarUrl?: string;

  @ApiPropertyOptional({ example: 5, description: '1–5 stars. Absent means 5.' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  rating?: number;

  @ApiProperty({ type: PaywallReviewLocalizedDto })
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallReviewLocalizedDto)
  content: PaywallReviewLocalizedDto;
}

/**
 * A SKU pair the paywall can show. At least one of the two ids must be set
 * (mixed-platform configs are fine -- a product only needs to exist for the
 * platform it is actually sold on); the "at least one" rule and the
 * existence/active check against `iap_products` are enforced in
 * `PaywallConfigService`, not here, because they need the product repository
 * and produce field-level messages rather than a generic 400.
 */
export class PaywallProductRefDto {
  @ApiPropertyOptional({ example: 'meup_sub_1y_30off' })
  @IsOptional()
  @IsString()
  appleProductId?: string;

  @ApiPropertyOptional({ example: 'meup_sub_1y_30off' })
  @IsOptional()
  @IsString()
  googleProductId?: string;
}

/**
 * The reduced SKU list an entry point mapped to `compact` renders instead of
 * `products`.
 *
 * Optional everywhere on purpose: absent or empty means the client falls back
 * to `products`, so a config published before this field existed keeps behaving
 * exactly as it did. Only ever narrows *which SKUs* are offered -- the copy
 * still comes from the same strategy.
 */
const COMPACT_PRODUCTS_API_PROPERTY = {
  type: [PaywallProductRefDto],
  description:
    'Reduced SKU list for entry points mapped to the "compact" variant. ' +
    'Absent or empty falls back to `products`.',
};

export class PaywallDefaultUserDto {
  @ApiProperty({ type: PaywallLocalizedContentDto })
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallLocalizedContentDto)
  content: PaywallLocalizedContentDto;

  @ApiProperty({ type: [PaywallProductRefDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PaywallProductRefDto)
  products: PaywallProductRefDto[];

  @ApiPropertyOptional(COMPACT_PRODUCTS_API_PROPERTY)
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PaywallProductRefDto)
  compactProducts?: PaywallProductRefDto[];
}

export class PaywallSaleEventDto {
  @ApiProperty({ example: false })
  @IsBoolean()
  enabled: boolean;

  @ApiPropertyOptional({ example: 'black-friday-2026' })
  @IsOptional()
  @IsString()
  campaignId?: string;

  @ApiPropertyOptional({ example: '2026-11-27T00:00:00.000Z' })
  @IsOptional()
  @IsString()
  startAtUtc?: string;

  @ApiPropertyOptional({ example: '2026-12-01T00:00:00.000Z' })
  @IsOptional()
  @IsString()
  endAtUtc?: string;

  // Was `unknown`, "passed through as-is" -- which let the admin panel save the
  // bare word `all` (this DTO's own former example). The client parses this as a
  // LIST of segment names and drops anything else, so such a value silently
  // meant "targets nobody": the sale event could be enabled, in date, fully
  // priced, and still never render. Typed to the enum the client actually reads.
  @ApiPropertyOptional({
    enum: PaywallAudienceSegment,
    isArray: true,
    example: [PaywallAudienceSegment.DEFAULT_USER, PaywallAudienceSegment.NEW_USER],
    description:
      'Audiences the campaign targets. Must be non-empty when `enabled` -- an ' +
      'empty list targets nobody.',
  })
  @IsOptional()
  @IsArray()
  @IsEnum(PaywallAudienceSegment, { each: true })
  appliesTo?: PaywallAudienceSegment[];

  @ApiPropertyOptional({ type: PaywallLocalizedContentDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallLocalizedContentDto)
  content?: PaywallLocalizedContentDto;

  @ApiPropertyOptional({ type: [PaywallProductRefDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PaywallProductRefDto)
  products?: PaywallProductRefDto[];

  @ApiPropertyOptional(COMPACT_PRODUCTS_API_PROPERTY)
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PaywallProductRefDto)
  compactProducts?: PaywallProductRefDto[];
}

/**
 * One LogicSale: a plan roster offered to a SEGMENT for a window, with an
 * optional countdown. The generalized, per-user sibling of `saleEvent`
 * (which targets only the client-side defaultUser/newUser split): segments
 * are evaluated SERVER-side, so the app asks `GET /paywall-config/logic-sale`
 * for the one campaign that applies to its viewer instead of parsing these
 * rows itself.
 *
 * `id` is the attribution key: the app echoes it into verify() and the
 * statistics count purchases by it — so it must stay STABLE for the life of
 * the campaign (editing plans or dates keeps the id; a new campaign gets a
 * new id).
 */
export class PaywallLogicSaleDto {
  @ApiProperty({
    example: 'ls-tet-2027',
    description:
      'Stable campaign id, echoed by the app into purchase verify for the ' +
      'statistics. Never reuse an old id for a new campaign.',
  })
  @IsString()
  @MaxLength(64)
  id: string;

  @ApiProperty({ example: 'Tết 2027 - user mới VN' })
  @IsString()
  @MaxLength(200)
  name: string;

  @ApiProperty({ example: false })
  @IsBoolean()
  enabled: boolean;

  @ApiPropertyOptional({
    type: [String],
    description:
      'Segment allow-list (segment ids from /segments). LEAVE EMPTY for ' +
      'everyone; matching ANY listed segment is enough.',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  segmentIds?: string[];

  @ApiPropertyOptional({
    type: [PaywallProductRefDto],
    description:
      'The plans this LogicSale offers ("chọn gói bán"). Replaces the ' +
      "strategy's SKU list while this campaign applies. Empty keeps the " +
      'campaign staged but never served.',
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PaywallProductRefDto)
  products?: PaywallProductRefDto[];

  @ApiPropertyOptional({
    example: 0,
    description:
      'Higher wins when several LogicSales apply to the same viewer; ties ' +
      'keep the list order.',
  })
  @IsOptional()
  @IsInt()
  @Min(-1000)
  @Max(1000)
  priority?: number;

  @ApiPropertyOptional({ example: '2027-02-01T00:00:00.000Z' })
  @IsOptional()
  @IsString()
  startAtUtc?: string;

  @ApiPropertyOptional({ example: '2027-02-20T00:00:00.000Z' })
  @IsOptional()
  @IsString()
  endAtUtc?: string;

  @ApiPropertyOptional({
    example: false,
    description:
      'Show a countdown to endAtUtc on the paywall. Requires endAtUtc.',
  })
  @IsOptional()
  @IsBoolean()
  countdown?: boolean;
}

export class PaywallSaleStrategyDto {
  @ApiProperty({ type: PaywallDefaultUserDto })
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallDefaultUserDto)
  defaultUser: PaywallDefaultUserDto;

  @ApiProperty({ type: PaywallSaleEventDto })
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallSaleEventDto)
  saleEvent: PaywallSaleEventDto;
}

export class PaywallAutoOpenDto {
  @ApiProperty({ example: true })
  @IsBoolean()
  enabled: boolean;

  // `@IsInt`, not `@IsNumber`: the client requires this to be a whole number
  // (`rawPercent is int` in `_PaywallConfigParser._autoOpen`) and treats
  // anything else as "auto-open disabled". A saved `50.5` therefore turned the
  // feature off with no error anywhere.
  @ApiProperty({ example: 50, minimum: 0, maximum: 100 })
  @IsInt()
  @Min(0)
  @Max(100)
  sessionRolloutPercent: number;
}

/**
 * Win-back: the reader opened the FULL paywall, closed it without buying, and
 * gets the gift popup a few seconds later — accepting the gift is what opens
 * the compact discount sheet.
 *
 * Sits beside `autoOpen` because both are app-initiated opens rather than a tap,
 * but it is a separate gate: `autoOpen` fires on entering Home, this one fires
 * on leaving the paywall.
 */
export class PaywallWinBackDto {
  @ApiProperty({ example: true })
  @IsBoolean()
  enabled: boolean;

  // Seconds between the paywall closing and the gift popup opening. Capped
  // at 60 because anything longer outlives the moment the reader was in — and
  // `@IsInt` for the same reason `sessionRolloutPercent` is: the client parses
  // this as an int and would read a fractional value as "off".
  @ApiProperty({ example: 3, minimum: 0, maximum: 60 })
  @IsInt()
  @Min(0)
  @Max(60)
  delaySeconds: number;

  // How many times per app session this may fire. Bounded rather than free so a
  // config cannot turn the app into a loop that re-sells on every dismissal.
  @ApiProperty({ example: 1, minimum: 1, maximum: 5 })
  @IsInt()
  @Min(1)
  @Max(5)
  maxPerSession: number;
}

/**
 * Maps each entry point to the SKU-list variant the paywall shows when opened
 * from there. Every field is optional and a missing one means `full`, so the
 * whole object can be absent (every published config before this feature) and
 * nothing changes.
 *
 * Spelled out as explicit fields rather than a free-form record so the
 * global `whitelist: true` pipe strips typo'd keys instead of storing them
 * where they would silently never match, and so Swagger documents the set.
 */
export class PaywallEntryPointVariantsDto {
  @ApiPropertyOptional({ enum: PaywallProductVariant })
  @IsOptional()
  @IsEnum(PaywallProductVariant)
  inLesson?: PaywallProductVariant;

  @ApiPropertyOptional({ enum: PaywallProductVariant })
  @IsOptional()
  @IsEnum(PaywallProductVariant)
  courseRoadmap?: PaywallProductVariant;

  @ApiPropertyOptional({ enum: PaywallProductVariant })
  @IsOptional()
  @IsEnum(PaywallProductVariant)
  autoOpen?: PaywallProductVariant;

  @ApiPropertyOptional({ enum: PaywallProductVariant })
  @IsOptional()
  @IsEnum(PaywallProductVariant)
  profile?: PaywallProductVariant;

  @ApiPropertyOptional({ enum: PaywallProductVariant })
  @IsOptional()
  @IsEnum(PaywallProductVariant)
  settingPre?: PaywallProductVariant;

  @ApiPropertyOptional({ enum: PaywallProductVariant })
  @IsOptional()
  @IsEnum(PaywallProductVariant)
  manageSubscription?: PaywallProductVariant;

  @ApiPropertyOptional({ enum: PaywallProductVariant })
  @IsOptional()
  @IsEnum(PaywallProductVariant)
  habit?: PaywallProductVariant;

  @ApiPropertyOptional({ enum: PaywallProductVariant })
  @IsOptional()
  @IsEnum(PaywallProductVariant)
  theme?: PaywallProductVariant;

  @ApiPropertyOptional({ enum: PaywallProductVariant })
  @IsOptional()
  @IsEnum(PaywallProductVariant)
  home?: PaywallProductVariant;

  @ApiPropertyOptional({ enum: PaywallProductVariant })
  @IsOptional()
  @IsEnum(PaywallProductVariant)
  keypointLocked?: PaywallProductVariant;

  @ApiPropertyOptional({ enum: PaywallProductVariant })
  @IsOptional()
  @IsEnum(PaywallProductVariant)
  learningImport?: PaywallProductVariant;

  @ApiPropertyOptional({ enum: PaywallProductVariant })
  @IsOptional()
  @IsEnum(PaywallProductVariant)
  onboarding?: PaywallProductVariant;

  @ApiPropertyOptional({ enum: PaywallProductVariant })
  @IsOptional()
  @IsEnum(PaywallProductVariant)
  other?: PaywallProductVariant;
}

/**
 * Opens the paywall from INSIDE a keypoint, at the moment the reader swipes off
 * the first card onto the next one — the point where they have tasted the
 * content and are still in motion. Distinct from both other gates:
 * `enableLessonLock`/`lessonLock` block a lesson before it opens, and `autoOpen`
 * fires on Home/Course, never mid-lesson.
 */
export class PaywallInLessonDto {
  @ApiProperty({ example: false })
  @IsBoolean()
  enabled: boolean;

  /**
   * Which keypoint arms the trigger, 1-based over the course's keypoints in
   * roadmap order (lesson by lesson, keypoints within each lesson in order).
   * 0 means every keypoint.
   *
   * This counts KEYPOINTS. It previously counted lessons on the client despite
   * the name, so a stored value's meaning changed when that was fixed — see
   * `plans/260803-paywall-entry-point-variants/design.md`. It is deliberately
   * NOT the same ordering `lessonLock` counts in.
   */
  @ApiPropertyOptional({ example: 2, description: '1-based keypoint position in the course; 0 = every keypoint.' })
  @IsOptional()
  @IsInt()
  @Min(0)
  keypointOrdinal?: number;

  /**
   * Cards the reader may pass before the paywall appears. 1 = it opens as they
   * move from card 1 to card 2.
   */
  @ApiPropertyOptional({ example: 1, description: 'Cards passed before the paywall opens (1 = leaving the first card).' })
  @IsOptional()
  @IsInt()
  @Min(1)
  afterCards?: number;
}

/**
 * Free-tier daily reading quota: one keypoint a day, read in full.
 *
 * Replaces `inLessonPaywall` rather than joining it (product call, 2026-08-12).
 * The two ask different questions -- that one asks where a keypoint sits in the
 * course, this one asks how much the reader has already read today -- and running
 * both leaves a lock nobody can explain: the same "first keypoint of the day" is
 * fully readable in one course and two cards deep in another.
 *
 * Unlike every other block here, this one is NOT enforceable on the client: it
 * depends on the reader's own history, which only the server holds. See
 * `plans/260812-daily-keypoint-quota/README.md`.
 */
export class PaywallDailyKeypointQuotaDto {
  @ApiProperty({ example: false })
  @IsBoolean()
  enabled: boolean;

  /**
   * Keypoints a non-premium reader may FINISH per day. 1 in the design.
   *
   * A ticket is spent by completing a keypoint (2026-08-21), not by opening one
   * and not by passing `afterCards`: reading part of a keypoint and leaving costs
   * nothing, and re-reading a keypoint already completed on an earlier day is free
   * and spends nothing. While the day still has room every keypoint opens in full.
   */
  @ApiPropertyOptional({ example: 1, description: 'Keypoints a non-premium reader may FINISH per day.' })
  @IsOptional()
  @IsInt()
  @Min(0)
  freeKeypointsPerDay?: number;

  /**
   * Cards readable in a keypoint once the day's keypoints are done. 3 = cards 1
   * and 2 are open and the paywall stands at card 3. Applies only after the
   * allowance is used up; before that nothing is capped.
   */
  @ApiPropertyOptional({ example: 3, description: 'Card the lock stands at once the day is used up (3 = two cards readable).' })
  @IsOptional()
  @IsInt()
  @Min(1)
  afterCards?: number;
}

/** Full request/response shape of the `paywall_config` Remote Config value. */
/**
 * The gift popup: its only job is to open the COMPACT paywall on the spec
 * sheet's schedule (first habit on day 0, first open of each day 1-7, coded in
 * the app). Everything the reader sees after the tap belongs to the compact
 * paywall's own config, so the ONLY thing configurable here is the popup's
 * title line; absent falls back to the app's bundled copy.
 */
export class PaywallLocalizedLineDto {
  @ApiProperty({ example: 'A special gift for you!' })
  @IsString()
  en: string;

  @ApiPropertyOptional({ example: 'Một món quà đặc biệt dành cho bạn!' })
  @IsOptional()
  @IsString()
  vi?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  zh?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  ja?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  ko?: string;
}

/**
 * How often the app-open trigger is allowed to fire. Refines
 * `triggerOnDailyOpen` -- it does not replace it: the toggle still says whether
 * the app-open popup runs at all, this says how often.
 *
 * `oncePerDay` is the original behaviour (first open of each day, days
 * 1..windowDays, only after the first habit). `everyOpen` drops the day-zero
 * requirement — it is meant for readers who have adopted no habit — but keeps
 * a window: every non-premium reader, on every resume, throttled by
 * `minGapMinutes`, until `windowDays` after the day they signed up.
 *
 * The window arrived later (2026-09-16, owner). Without it the mode ran
 * indefinitely, which made it a permanent tax on everyone who had not paid
 * rather than a welcome offer.
 *
 * Absent reads as `oncePerDay`, so every config published before this field --
 * and every app build that predates it -- behaves exactly as it does today.
 */
export enum PaywallGiftOpenFrequency {
  ONCE_PER_DAY = 'oncePerDay',
  EVERY_OPEN = 'everyOpen',
}

export class PaywallGiftCampaignDto {
  @ApiProperty({ example: false })
  @IsBoolean()
  enabled: boolean;

  @ApiPropertyOptional({ type: PaywallLocalizedLineDto, description: "Popup title per locale. Absent uses the app's bundled copy." })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallLocalizedLineDto)
  title?: PaywallLocalizedLineDto;

  /**
   * How many days the app-open popup keeps running.
   *
   * Counted from the FIRST HABIT in `oncePerDay` (days 1..windowDays — the
   * signup day itself already fired the habit popup), and from the ACCOUNT'S
   * SIGNUP DAY in `everyOpen`, that day included (days 0..windowDays). Same
   * end date either way; the extra day at the front is deliberate, because
   * nothing else fires on it and the day somebody arrives is when an
   * introductory offer is worth the most.
   *
   * Was a constant in the app, which made "run it for five days this month"
   * a code change, a release and a store review — for a number that is purely
   * a marketing decision. Absent or out of range falls back to the app's 7, so
   * a config written before this field, and an app build that predates it,
   * both behave exactly as they do today.
   */
  @ApiPropertyOptional({ example: 7, minimum: 1, maximum: 30 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(30)
  windowDays?: number;

  /**
   * The two triggers, switchable independently. Turning one off is not the same
   * as turning the campaign off: a run can want the day-0 moment without the
   * daily reminder, or the reverse. Absent reads as ON for both, which is what
   * the app did before they existed.
   */
  @ApiPropertyOptional({ example: true, description: 'Show when the reader adopts their first habit (day 0).' })
  @IsOptional()
  @IsBoolean()
  triggerOnFirstHabit?: boolean;

  @ApiPropertyOptional({ example: true, description: 'Show on app open inside the window. How often is `openFrequency`.' })
  @IsOptional()
  @IsBoolean()
  triggerOnDailyOpen?: boolean;

  /** See `PaywallGiftOpenFrequency`. Absent = `oncePerDay`. */
  @ApiPropertyOptional({ enum: PaywallGiftOpenFrequency, example: PaywallGiftOpenFrequency.ONCE_PER_DAY })
  @IsOptional()
  @IsEnum(PaywallGiftOpenFrequency)
  openFrequency?: PaywallGiftOpenFrequency;

  /**
   * Minutes that must pass since the popup last went up before the `everyOpen`
   * mode may show it again. Read ONLY in that mode; `oncePerDay` has the
   * calendar day as its own gap.
   *
   * The throttle exists because the app-open check runs on every `resumed`
   * lifecycle event, not just a cold start -- without it, a reader who leaves
   * the app for ten seconds to answer a message comes back to a paywall popup.
   * 0 means literally every resume; absent falls back to the app's 30.
   */
  @ApiPropertyOptional({ example: 30, minimum: 0, maximum: 1440 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(1440)
  minGapMinutes?: number;
}

/**
 * Config owned by the COMPACT paywall itself (the "33% OFF"-style sheet).
 * SKUs stay per-strategy (`compactProducts`) and the discount/countdown come
 * from the sale event -- this only carries the copy that belongs to the sheet.
 */
export class PaywallCompactDto {
  // Display only, like the old gift discount: the charge is whatever the
  // compact SKU costs. Sale events do NOT touch this sheet (full paywall
  // only, per the spec owner), so this is the single source of its headline.
  @ApiPropertyOptional({ example: 33, description: 'Headline "N% OFF". Display only; sale events never affect the compact sheet.' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(99)
  discountPercent?: number;

  @ApiPropertyOptional({
    type: PaywallLocalizedLineDto,
    description: 'The urgency line under the discount headline. Absent uses bundled copy; shown only while discountPercent is set.',
  })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallLocalizedLineDto)
  urgencyLine?: PaywallLocalizedLineDto;
}

export class PaywallConfigDto {
  @ApiProperty({ example: 1 })
  @IsInt()
  @Min(1)
  schemaVersion: number;

  @ApiProperty({ example: true })
  @IsBoolean()
  enableLessonLock: boolean;

  // How many lessons stay free before the gate. A COUNT, not an object: the
  // live Remote Config value is `"lessonLock": 1`, and the client treats it as a
  // number throughout (`PaywallConfigEntity.lessonLock` is an `int`, compared
  // against lesson counts in `roadmap_entity.dart`). Validating it as an object
  // — as this DTO first did, guessing from the design doc's abridged JSON —
  // rejected every publish with `400 lessonLock must be an object`, so the
  // paywall config could be read but never saved.
  @ApiPropertyOptional({ example: 1, description: 'Lessons left unlocked before the paywall gate.' })
  @IsOptional()
  @IsInt()
  @Min(0)
  lessonLock?: number;

  @ApiProperty({ type: PaywallAutoOpenDto })
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallAutoOpenDto)
  autoOpen: PaywallAutoOpenDto;

  // Optional so every already-published version stays valid: the global pipe
  // runs with `whitelist: true`, and a required field here would reject a
  // restore of any version saved before this gate existed.
  @ApiPropertyOptional({ type: PaywallInLessonDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallInLessonDto)
  inLessonPaywall?: PaywallInLessonDto;

  /**
   * The free tier's daily reading quota. Absent means off, which is what keeps
   * every config written before it existed behaving exactly as it did.
   */
  @ApiPropertyOptional({ type: PaywallDailyKeypointQuotaDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => PaywallDailyKeypointQuotaDto)
  dailyKeypointQuota?: PaywallDailyKeypointQuotaDto;

  // Optional for the same reason as `inLessonPaywall`: absent means every entry
  // point renders the `full` variant, which is exactly what every config
  // published before this feature already does.
  @ApiPropertyOptional({ type: PaywallEntryPointVariantsDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallEntryPointVariantsDto)
  entryPointVariants?: PaywallEntryPointVariantsDto;

  /**
   * Which body the paywall renders (see [[PaywallBodyVariant]]).
   *
   * Top-level rather than per-locale: it is a LAYOUT choice, and a config where
   * Vietnamese showed a table while English showed a list would be a bug nobody
   * asked for. Absent means `benefits`, so every version published before this
   * field existed renders exactly as it does today -- including a restore of
   * one, which the global `whitelist: true` pipe would otherwise reject.
   */
  @ApiPropertyOptional({ enum: PaywallBodyVariant, example: PaywallBodyVariant.BENEFITS })
  @IsOptional()
  @IsEnum(PaywallBodyVariant)
  bodyVariant?: PaywallBodyVariant;

  /**
   * The body A/B test. Absent or disabled means `bodyVariant` above decides
   * for everyone, exactly as before this field existed.
   */
  @ApiPropertyOptional({ type: PaywallBodyExperimentDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallBodyExperimentDto)
  bodyExperiment?: PaywallBodyExperimentDto;

  @ApiProperty({ type: PaywallSaleStrategyDto })
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallSaleStrategyDto)
  saleStrategy: PaywallSaleStrategyDto;

  // Optional for the same reason as `inLessonPaywall` and `entryPointVariants`:
  // the global pipe runs with `whitelist: true`, so a required field here would
  // reject restoring any version published before this campaign existed.
  @ApiPropertyOptional({ type: PaywallCompactDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallCompactDto)
  compactPaywall?: PaywallCompactDto;

  @ApiPropertyOptional({ type: PaywallGiftCampaignDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallGiftCampaignDto)
  giftCampaign?: PaywallGiftCampaignDto;

  // Optional for the same reason as every other gate added after v1: the global
  // pipe runs with `whitelist: true`, so requiring it here would reject a
  // restore of any version published before win-back existed. Absent means off.
  @ApiPropertyOptional({ type: PaywallWinBackDto })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PaywallWinBackDto)
  winBack?: PaywallWinBackDto;

  // The laurel + store-rating strip under the plans. A claim about MIT and
  // Harvard is a marketing statement that may not hold in every market, so it
  // ships behind a switch rather than baked into the screen. Absent = shown,
  // matching the build that introduced it.
  @ApiPropertyOptional({
    example: true,
    description: 'Show the laurel + store-rating credibility strip. Absent means shown.',
  })
  @IsOptional()
  @IsBoolean()
  showCredibilityBlock?: boolean;

  // Optional like every field added after v1 (whitelist: true + old versions
  // must stay restorable). Absent = the app's bundled reviews keep showing.
  @ApiPropertyOptional({ type: [PaywallReviewDto], description: 'The "What people say" carousel. Absent falls back to the app\'s bundled reviews.' })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PaywallReviewDto)
  reviews?: PaywallReviewDto[];

  /**
   * The LogicSale roster. Lives in the versioned config JSON like everything
   * else (staging, history and restore for free), but the app never reads it
   * from `/mobile` — segments are server-side, so the app asks
   * `GET /paywall-config/logic-sale` for the one campaign that applies.
   * Optional like every post-v1 field: absent keeps old versions restorable.
   */
  @ApiPropertyOptional({ type: [PaywallLogicSaleDto] })
  @IsOptional()
  @IsArray()
  // Far above any real roster; bounds a JSON column read on every resolve.
  @ArrayMaxSize(20)
  @ValidateNested({ each: true })
  @Type(() => PaywallLogicSaleDto)
  logicSales?: PaywallLogicSaleDto[];
}
