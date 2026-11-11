
import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
  NotFoundException,
} from '@nestjs/common';

import { RequestService } from '@base/service/request.service';
import { experimentBucket } from '@utils/experiment-bucket.util';
import { UserEventRepository } from 'src/modules/analytics/repository/user-event.repository';
import { PaymentPlatform } from 'src/modules/payment/enum/payment.enum';
import { ProductRepository } from 'src/modules/payment/products/repositories/product.repository';
import { PurchaseRepository } from 'src/modules/payment/purchases/repositories/purchase.repository';
import { SegmentService } from 'src/modules/segment/segment.service';

import {
  PaywallConfigResponseDto,
  PaywallConfigVersionDto,
} from './dto/paywall-config-response.dto';
import {
  PAYWALL_CONFIG_LOCALES,
  PaywallAudienceSegment,
  PaywallBodyVariant,
  PaywallComparisonRowDto,
  PaywallConfigDto,
  PaywallConfigLocale,
  PaywallLocalizedContentDto,
  PaywallLogicSaleDto,
  PaywallProductRefDto,
  PaywallSaleEventDto,
} from './dto/paywall-config.dto';
import { PaywallConfig } from './entity/paywall-config.entity';
import {
  PAYWALL_CONFIG_PARAMETER_KEY,
  PAYWALL_EXPERIMENT_EVENTS,
  PAYWALL_EXPERIMENT_KEY_PARAM,
  PAYWALL_EXPERIMENT_PARAM,
  REMOTE_CONFIG_SEED_PUBLISHED_BY,
} from './paywall-config.constants';
import { PaywallConfigRepository } from './repository/paywall-config.repository';

export interface PaywallConfigValidationError {
  field: string;
  message: string;
}

/**
 * The body A/B assignment handed to one viewer. `inExperiment: false` means
 * "render this, but do not count me" -- `reason` says which exclusion applied.
 */
export interface PaywallBodyExperimentAssignment {
  key: string;
  variant: PaywallBodyVariant;
  inExperiment: boolean;
  reason?: 'no_run' | 'anonymous_viewer' | 'locale_without_comparison';
}

interface ProductRefLocation {
  field: string;
  ref: PaywallProductRefDto;
}

@Injectable()
export class PaywallConfigService {
  private readonly logger = new Logger(PaywallConfigService.name);

  constructor(
    private readonly paywallConfigRepository: PaywallConfigRepository,
    private readonly productRepository: ProductRepository,
    private readonly purchaseRepository: PurchaseRepository,
    private readonly segmentService: SegmentService,
    private readonly userEventRepository: UserEventRepository,
    private readonly requestService: RequestService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  /** Admin id/email to stamp on a newly published row. */
  private get publishedByCurrentUser(): string | undefined {
    return this.user?.email ?? this.user?.id;
  }

  async getConfig(): Promise<PaywallConfigResponseDto> {
    const current = await this.getCurrentOrSeed();
    return this.mapToResponseDto(current);
  }

  /**
   * `GET /paywall-config/mobile` -- returns the raw config JSON (no admin
   * envelope) in exactly the shape the Flutter client already parses.
   */
  async getMobileConfig(): Promise<PaywallConfigDto> {
    const current = await this.getCurrentOrSeed();
    return current.config;
  }

  /**
   * The one LogicSale that applies to THIS viewer right now, or inactive.
   *
   * Server-resolved because segments are server-side facts — the `/mobile`
   * blob is public and per-user-blind, so it cannot carry the answer. The
   * winner is the highest-priority enabled campaign whose window contains
   * now and whose segments (if any) the viewer belongs to; ties keep the
   * admin's list order. `nowUtc` rides along so the app's countdown never
   * trusts the device clock.
   */
  async resolveLogicSaleFor(
    viewerId: string,
    lang?: string,
  ): Promise<{
    active: boolean;
    nowUtc: string;
    id?: string;
    name?: string;
    products?: PaywallProductRefDto[];
    countdown?: boolean;
    startAtUtc?: string;
    endAtUtc?: string;
    experiment: PaywallBodyExperimentAssignment;
  }> {
    const now = new Date();
    const current = await this.getCurrentOrSeed();
    const roster = current.config?.logicSales ?? [];
    // Rides along on the call the paywall already makes when it opens: this is
    // the only per-viewer, uncached paywall endpoint, and the client already
    // threads its answer into the purchase verify (`logicSaleId`), which is the
    // exact rail the assignment needs for attribution.
    const experiment = this.assignBodyVariant(current.config, viewerId, lang);

    const inWindow = (sale: PaywallLogicSaleDto): boolean => {
      if (sale.startAtUtc && now < new Date(sale.startAtUtc)) return false;
      if (sale.endAtUtc && now > new Date(sale.endAtUtc)) return false;
      return true;
    };

    const eligible = roster
      .filter(sale => sale.enabled)
      .filter(sale => (sale.products ?? []).length > 0)
      .filter(inWindow);

    // Segment targeting runs on the survivors only; an unidentifiable viewer
    // is hidden from targeted campaigns, same contract as the Home banner.
    const allowed = await this.segmentService.filterItemsForViewer(
      eligible,
      viewerId,
    );

    const [winner] = [...allowed].sort(
      (a, b) => (b.priority ?? 0) - (a.priority ?? 0),
    );
    if (!winner) {
      return { active: false, nowUtc: now.toISOString(), experiment };
    }

    return {
      active: true,
      nowUtc: now.toISOString(),
      id: winner.id,
      name: winner.name,
      products: winner.products,
      countdown: Boolean(winner.countdown && winner.endAtUtc),
      startAtUtc: winner.startAtUtc,
      endAtUtc: winner.endAtUtc,
      experiment,
    };
  }

  /**
   * Which body THIS viewer sees, and whether they count towards the test.
   *
   * Deterministic: the same (key, viewerId) always lands in the same arm, so a
   * viewer never sees the layout change under them between sessions and no
   * assignment table has to exist. Nothing is written here -- a resolve is a
   * pure function of the config plus who is asking.
   *
   * Three ways to be OUT of the test, all of them rendering `benefits` and
   * reported with a reason so the admin can see how much traffic each one eats:
   *
   * - no run configured (or `enabled: false`);
   * - an unidentifiable viewer, who has no stable id to hash and therefore
   *   cannot be kept in one arm across sessions;
   * - a locale with no comparison rows of its own. `BaseMultiLanguage.text`
   *   falls back to English, so such a viewer would be shown an ENGLISH table
   *   -- a third treatment wearing the comparison arm's name, which is worse
   *   for the result than simply leaving them out.
   */
  private assignBodyVariant(
    config: PaywallConfigDto | undefined,
    viewerId: string,
    lang?: string,
  ): PaywallBodyExperimentAssignment {
    const fallback = config?.bodyVariant ?? PaywallBodyVariant.BENEFITS;
    const run = config?.bodyExperiment;

    if (!run?.enabled || !run.key?.trim()) {
      return { key: '', variant: fallback, inExperiment: false, reason: 'no_run' };
    }
    if (!viewerId) {
      return {
        key: run.key,
        variant: PaywallBodyVariant.BENEFITS,
        inExperiment: false,
        reason: 'anonymous_viewer',
      };
    }
    if (!this.hasComparisonRowsFor(config, lang)) {
      return {
        key: run.key,
        variant: PaywallBodyVariant.BENEFITS,
        inExperiment: false,
        reason: 'locale_without_comparison',
      };
    }

    const bucket = experimentBucket(run.key, viewerId);
    return {
      key: run.key,
      variant:
        bucket < run.comparisonPercent
          ? PaywallBodyVariant.COMPARISON
          : PaywallBodyVariant.BENEFITS,
      inExperiment: true,
    };
  }


  /** Whether any locale of this content block carries a usable table row. */
  private hasComparisonRows(content?: PaywallLocalizedContentDto): boolean {
    return PAYWALL_CONFIG_LOCALES.some(locale =>
      this.localeHasComparisonRows(content?.[locale]?.comparison),
    );
  }

  /**
   * Whether the paywall body would be a table IN THIS VIEWER'S OWN LANGUAGE.
   *
   * Read off `defaultUser`, the content every viewer gets outside a sale event;
   * a sale event replacing it wholesale is blocked at publish time instead
   * (see `validateShape`), because whether one is running depends on the clock
   * and cannot be settled here once and for all.
   */
  private hasComparisonRowsFor(
    config: PaywallConfigDto | undefined,
    lang?: string,
  ): boolean {
    const locale = (lang ?? '').trim().toLowerCase();
    if (!PAYWALL_CONFIG_LOCALES.includes(locale as PaywallConfigLocale)) {
      return false;
    }

    return this.localeHasComparisonRows(
      config?.saleStrategy?.defaultUser?.content?.[locale as PaywallConfigLocale]
        ?.comparison,
    );
  }

  /** A row counts only if at least one of its three cells has text. */
  private localeHasComparisonRows(rows?: PaywallComparisonRowDto[]): boolean {
    return (rows ?? []).some(row =>
      [row?.label, row?.free, row?.premium].some(
        cell => (cell ?? '').trim().length > 0,
      ),
    );
  }

  /**
   * Orders and revenue attributed to one LogicSale, per plan and currency —
   * the "Statistics" block on the admin row. Works for retired campaigns
   * too: attribution lives on the purchase rows, not in the config, so a
   * LogicSale deleted from the roster still answers here by its id.
   */
  async logicSaleStats(id: string): Promise<{
    id: string;
    totalOrders: number;
    byProduct: Array<{
      productId: string;
      currency: string | null;
      orders: number;
      paidRevenue: number;
      refundedRevenue: number;
      netRevenue: number;
    }>;
  }> {
    const trimmed = (id ?? '').trim();
    if (!trimmed) {
      throw new BadRequestException('LogicSale id is required');
    }

    const rows = await this.purchaseRepository.logicSaleStats(trimmed);

    return {
      id: trimmed,
      totalOrders: rows.reduce((sum, row) => sum + row.orders, 0),
      byProduct: rows.map(row => ({
        ...row,
        netRevenue: row.paidRevenue - row.refundedRevenue,
      })),
    };
  }

  /**
   * The A/B readout: one row per arm, funnel counted in PEOPLE from the app's
   * own events, orders and revenue counted from VERIFIED purchases.
   *
   * The two halves come from different stores on purpose. Client events are the
   * only place that knows who SAW a paywall, but they also report purchases
   * that were cancelled, failed or later refunded; `iap_purchases` is the
   * store-verified truth about money. Mixing them per arm is what makes the
   * conversion rate mean "of the people we showed this to, this many actually
   * paid" -- and why `viewers` (distinct users) is the denominator rather than
   * paywall opens.
   *
   * Currency stays split. Summing revenue across currencies would produce a
   * single number that is not an amount of anything.
   */
  async bodyExperimentStats(params: {
    appEnv: string;
    from: Date;
    to: Date;
  }): Promise<{
    key: string;
    enabled: boolean;
    comparisonPercent: number;
    appEnv: string;
    from: string;
    to: string;
    arms: Array<{
      variant: string;
      viewers: number;
      planClickers: number;
      upgradeClickers: number;
      buyers: number;
      orders: number;
      conversionRate: number;
      revenue: Array<{
        currency: string | null;
        paidRevenue: number;
        refundedRevenue: number;
        netRevenue: number;
      }>;
    }>;
  }> {
    const current = await this.getCurrentOrSeed();
    const run = current.config?.bodyExperiment;
    const key = run?.key?.trim() ?? '';
    if (!key) {
      throw new BadRequestException(
        'No paywall body experiment is configured on the current version',
      );
    }

    // Scoped to THIS run's key: the arm names are the same strings in every
    // run, so a window that overlaps an earlier one would pool their viewers
    // into this one's funnel while the purchase side stayed keyed -- two
    // different denominators feeding one conversion rate.
    const window = {
      appEnv: params.appEnv,
      from: params.from,
      to: params.to,
      whereParams: { [PAYWALL_EXPERIMENT_KEY_PARAM]: key },
    };
    const [views, planClicks, upgradeClicks, purchaseRows] = await Promise.all([
      this.userEventRepository.countUsersByParam({
        ...window,
        name: PAYWALL_EXPERIMENT_EVENTS.view,
        paramKey: PAYWALL_EXPERIMENT_PARAM,
      }),
      this.userEventRepository.countUsersByParam({
        ...window,
        name: PAYWALL_EXPERIMENT_EVENTS.planClick,
        paramKey: PAYWALL_EXPERIMENT_PARAM,
      }),
      this.userEventRepository.countUsersByParam({
        ...window,
        name: PAYWALL_EXPERIMENT_EVENTS.upgradeClick,
        paramKey: PAYWALL_EXPERIMENT_PARAM,
      }),
      this.purchaseRepository.paywallExperimentStats(key),
    ]);

    // Both arms always appear, including at zero: an arm missing from the
    // screen reads as "no data yet" when it can equally mean the assignment
    // never reached anyone, and those need different fixes.
    const arms = [PaywallBodyVariant.BENEFITS, PaywallBodyVariant.COMPARISON].map(
      variant => {
        const rows = purchaseRows.filter(row => row.variant === variant);
        const viewers = views[variant] ?? 0;
        // Buyers are DISTINCT per currency row, so an arm's buyer count is the
        // largest row rather than the sum -- one person buying in one currency
        // must not be counted once per currency they did not use.
        const buyers = rows.reduce((max, row) => Math.max(max, row.buyers), 0);

        return {
          variant,
          viewers,
          planClickers: planClicks[variant] ?? 0,
          upgradeClickers: upgradeClicks[variant] ?? 0,
          buyers,
          orders: rows.reduce((sum, row) => sum + row.orders, 0),
          conversionRate: viewers > 0 ? buyers / viewers : 0,
          revenue: rows.map(row => ({
            currency: row.currency,
            paidRevenue: row.paidRevenue,
            refundedRevenue: row.refundedRevenue,
            netRevenue: row.paidRevenue - row.refundedRevenue,
          })),
        };
      },
    );

    return {
      key,
      enabled: Boolean(run?.enabled),
      comparisonPercent: run?.comparisonPercent ?? 0,
      appEnv: params.appEnv,
      from: params.from.toISOString(),
      to: params.to.toISOString(),
      arms,
    };
  }

  async getVersions(): Promise<PaywallConfigVersionDto[]> {
    const rows = await this.paywallConfigRepository.findAllVersions();
    return rows.map(row => ({
      ...this.mapToResponseDto(row),
      isCurrent: Boolean(row.isCurrent),
    }));
  }

  /**
   * Validates then publishes a brand new version (append-only -- see
   * `PaywallConfigRepository.publishNewVersion`). Unlike the old Remote
   * Config flow there is no separate dev/prod write target: this API
   * instance only ever writes to its own environment's database.
   */
  async updateConfig(dto: PaywallConfigDto): Promise<PaywallConfigResponseDto> {
    const shapeErrors = this.validateShape(dto);
    if (shapeErrors.length) {
      throw new BadRequestException({
        message: 'paywall_config failed shape validation',
        errors: shapeErrors,
      });
    }

    await this.assertProductsExist(dto);

    const published = await this.paywallConfigRepository.publishNewVersion(
      dto,
      this.publishedByCurrentUser,
    );
    await this.mirrorToRemoteConfig(dto);

    return this.mapToResponseDto(published);
  }

  /**
   * TRANSITIONAL: keeps Remote Config in step with what we just published.
   *
   * Already-installed apps read Remote Config and will until the release that
   * switches to `GET /paywall-config/mobile` is adopted. Skipping this would
   * mean a publish reports success while changing nothing for any live user.
   *
   * Best-effort on purpose: MySQL is the source of truth, so a Firebase
   * outage (or a service account without Remote Config Admin) must not fail a
   * publish that already succeeded — it is logged loudly instead.
   *
   * Remove once the old app versions are drained.
   */
  private async mirrorToRemoteConfig(config: PaywallConfigDto): Promise<void> {
    try {
      await this.paywallConfigRepository.mirrorToRemoteConfig(
        PAYWALL_CONFIG_PARAMETER_KEY,
        config,
      );
    } catch (error) {
      this.logger.error(
        'Published to paywall_configs but FAILED to mirror into Remote ' +
          'Config. Users on app versions older than the API-config release ' +
          'will keep seeing the previous paywall until this is resolved.',
        error as Error,
      );
    }
  }

  /**
   * Re-publishes an earlier version's config as a new, later version (never
   * mutates the old row -- history stays append-only). Re-runs the same
   * shape/product-existence validation as a normal publish: a version that
   * was valid when first written can reference a product that has since
   * been deactivated or deleted, and restoring it live should not bypass
   * that guard.
   */
  async restore(version: number): Promise<PaywallConfigResponseDto> {
    const target = await this.paywallConfigRepository.findByVersion(version);
    if (!target) {
      throw new NotFoundException(
        `paywall_config version ${version} does not exist`,
      );
    }

    const shapeErrors = this.validateShape(target.config);
    if (shapeErrors.length) {
      throw new BadRequestException({
        message: `paywall_config version ${version} failed shape validation`,
        errors: shapeErrors,
      });
    }

    await this.assertProductsExist(target.config);

    const published = await this.paywallConfigRepository.publishNewVersion(
      target.config,
      this.publishedByCurrentUser,
    );
    // Restore changes what is live, so it needs the same transitional mirror
    // a normal publish gets.
    await this.mirrorToRemoteConfig(target.config);

    return this.mapToResponseDto(published);
  }

  // ---------------------------------------------------------------------
  // First-read cutover seed -- see paywall-config.constants.ts. Runs at most
  // once per environment: after the first successful seed, `findCurrent()`
  // always finds a row and this path is never taken again.
  // ---------------------------------------------------------------------

  private async getCurrentOrSeed(): Promise<PaywallConfig> {
    const current = await this.paywallConfigRepository.findCurrent();
    if (current) return current;

    const rowCount = await this.paywallConfigRepository.countAll();
    if (rowCount > 0) {
      // Should never happen given publishNewVersion's invariant (exactly one
      // row is ever marked current) -- fail loudly rather than silently
      // reseeding from Remote Config over real, already-published history.
      throw new InternalServerErrorException(
        'paywall_configs has rows but none is marked current',
      );
    }

    return this.seedFromRemoteConfig();
  }

  private async seedFromRemoteConfig(): Promise<PaywallConfig> {
    const template = await this.paywallConfigRepository.getRemoteConfigTemplate();
    const parameter = template.parameters?.[PAYWALL_CONFIG_PARAMETER_KEY];
    const defaultValue = parameter?.defaultValue;
    const rawValue =
      defaultValue && 'value' in defaultValue ? defaultValue.value : undefined;

    if (!rawValue) {
      throw new NotFoundException(
        'paywall_configs is empty and Remote Config has no ' +
          `"${PAYWALL_CONFIG_PARAMETER_KEY}" value to seed from`,
      );
    }

    let config: PaywallConfigDto;
    try {
      config = JSON.parse(rawValue);
    } catch {
      throw new BadRequestException(
        'Remote Config paywall_config value is not valid JSON, cannot seed',
      );
    }

    this.logger.log(
      'paywall_configs was empty -- seeding version 1 from the live Firebase ' +
        'Remote Config "paywall_config" parameter to preserve the current ' +
        'paywall through the MySQL cutover',
    );

    // Intentionally skips validateShape/assertProductsExist: the whole point
    // of this seed is to carry forward whatever is live today verbatim, even
    // if it would fail today's (possibly stricter) validation -- see
    // paywall-config.constants.ts.
    return this.paywallConfigRepository.publishNewVersion(
      config,
      REMOTE_CONFIG_SEED_PUBLISHED_BY,
    );
  }

  private mapToResponseDto(row: PaywallConfig): PaywallConfigResponseDto {
    return {
      config: row.config,
      version: row.version,
      publishedAt: row.publishedAt,
      publishedBy: row.publishedBy,
    };
  }

  // ---------------------------------------------------------------------
  // Shape validation -- required keys, non-empty products per strategy,
  // fromImpression >= 1. Done by hand (rather than relying solely on the
  // global BaseValidationPipe) so every offending field is reported at
  // once instead of just the first one found. UNCHANGED from the Remote
  // Config version of this service.
  // ---------------------------------------------------------------------

  validateShape(dto: PaywallConfigDto): PaywallConfigValidationError[] {
    const errors: PaywallConfigValidationError[] = [];

    if (dto?.schemaVersion == null) {
      errors.push({
        field: 'schemaVersion',
        message: 'schemaVersion is required',
      });
    }
    if (typeof dto?.enableLessonLock !== 'boolean') {
      errors.push({
        field: 'enableLessonLock',
        message: 'enableLessonLock is required and must be a boolean',
      });
    }

    // A missing count with the lock ON is the dangerous combination, not a
    // harmless omission: the client reads the absent field as 0, and 0 locks
    // the course from its very first lesson -- which, being `notStarted`,
    // swallows the tap entirely instead of opening the paywall. The whole
    // course then looks broken rather than gated.
    if (dto?.enableLessonLock === true && !Number.isInteger(dto?.lessonLock)) {
      errors.push({
        field: 'lessonLock',
        message:
          'lessonLock is required and must be an integer when enableLessonLock is true ' +
          '(it is the number of lessons left free before the gate; 0 locks the whole course)',
      });
    }

    if (!dto?.autoOpen) {
      errors.push({ field: 'autoOpen', message: 'autoOpen is required' });
    } else {
      if (typeof dto.autoOpen.enabled !== 'boolean') {
        errors.push({
          field: 'autoOpen.enabled',
          message: 'autoOpen.enabled is required and must be a boolean',
        });
      }
      if (
        typeof dto.autoOpen.sessionRolloutPercent !== 'number' ||
        dto.autoOpen.sessionRolloutPercent < 0 ||
        dto.autoOpen.sessionRolloutPercent > 100
      ) {
        errors.push({
          field: 'autoOpen.sessionRolloutPercent',
          message:
            'autoOpen.sessionRolloutPercent is required and must be a number between 0 and 100',
        });
      }
    }

    // The body A/B run only makes sense if the comparison arm can actually
    // render a table. Both checks below block a publish that would silently
    // serve the benefits list to viewers counted in the comparison arm --
    // contamination that is invisible in the numbers afterwards.
    if (dto?.bodyExperiment?.enabled) {
      if (!dto.bodyExperiment.key?.trim()) {
        errors.push({
          field: 'bodyExperiment.key',
          message: 'bodyExperiment.key is required while the run is enabled',
        });
      }
      if (!this.hasComparisonRows(dto.saleStrategy?.defaultUser?.content)) {
        errors.push({
          field: 'bodyExperiment.enabled',
          message:
            'saleStrategy.defaultUser.content has no comparison rows, so the ' +
            'comparison arm would show the benefits list to everyone',
        });
      }
      // An active sale event replaces the content wholesale on the full
      // paywall (`ResolvePaywallStrategyUsecase`: `content: event.content`,
      // with no fall back to defaultUser), so its own rows have to exist too.
      if (
        dto.saleStrategy?.saleEvent?.enabled &&
        dto.saleStrategy.saleEvent.content &&
        !this.hasComparisonRows(dto.saleStrategy.saleEvent.content)
      ) {
        errors.push({
          field: 'saleStrategy.saleEvent.content',
          message:
            'the sale event supplies its own content but no comparison rows; ' +
            'while bodyExperiment is enabled its viewers would fall back to ' +
            'the benefits list inside the comparison arm',
        });
      }
    }

    if (!dto?.saleStrategy) {
      errors.push({
        field: 'saleStrategy',
        message: 'saleStrategy is required',
      });
      return errors;
    }

    const { defaultUser, saleEvent } = dto.saleStrategy;

    if (!defaultUser) {
      errors.push({
        field: 'saleStrategy.defaultUser',
        message: 'saleStrategy.defaultUser is required',
      });
    } else {
      if (!defaultUser.content) {
        errors.push({
          field: 'saleStrategy.defaultUser.content',
          message: 'saleStrategy.defaultUser.content is required',
        });
      }
      errors.push(
        ...this.validateProductsNonEmpty(
          defaultUser.products,
          'saleStrategy.defaultUser.products',
        ),
        ...this.validateOptionalProducts(
          defaultUser.compactProducts,
          'saleStrategy.defaultUser.compactProducts',
        ),
      );
    }

    if (!saleEvent) {
      errors.push({
        field: 'saleStrategy.saleEvent',
        message: 'saleStrategy.saleEvent is required',
      });
    } else {
      if (typeof saleEvent.enabled !== 'boolean') {
        errors.push({
          field: 'saleStrategy.saleEvent.enabled',
          message:
            'saleStrategy.saleEvent.enabled is required and must be a boolean',
        });
      }
      if (saleEvent.enabled) {
        errors.push(
          ...this.validateProductsNonEmpty(
            saleEvent.products,
            'saleStrategy.saleEvent.products',
          ),
          ...this.validateOptionalProducts(
            saleEvent.compactProducts,
            'saleStrategy.saleEvent.compactProducts',
          ),
          ...this.validateCampaignWindow(
            saleEvent,
            'saleStrategy.saleEvent',
            'saleEvent',
          ),
        );

        // An empty audience list targets nobody. The client checks
        // `appliesTo.contains(segment)` before anything else, so an enabled,
        // in-date, fully priced campaign with no audience never renders --
        // the exact failure the old free-text `appliesTo` produced.
        if (!saleEvent.appliesTo?.length) {
          errors.push({
            field: 'saleStrategy.saleEvent.appliesTo',
            message:
              'saleStrategy.saleEvent.appliesTo must list at least one audience ' +
              `(${Object.values(PaywallAudienceSegment).join(' | ')}) when saleEvent is enabled`,
          });
        }
      }
    }

    // giftCampaign carries an on/off switch, a title line, and the schedule
    // knobs (windowDays, the two trigger toggles, and the app-open frequency
    // pair openFrequency + minGapMinutes) -- the popup opens the compact
    // paywall, whose own strategy is validated above. Nothing to validate
    // beyond what the DTO already enforces: the ranges are `@Min`/`@Max`, a
    // campaign with both triggers off is a legitimate way to stage one before
    // turning it on, and minGapMinutes left over from an `everyOpen` run is
    // simply unread once the mode goes back to `oncePerDay` -- not an error
    // worth blocking a publish over.

    errors.push(...this.validateLogicSales(dto.logicSales));

    // Win-back opens the COMPACT sheet, and that sheet fills its single plan
    // from `saleStrategy.defaultUser.compactProducts`. Enabled with that list
    // empty is not a milder campaign, it is a sheet with no price and a dead
    // CTA -- the same silent breakage the compact entry points hit before
    // `e02936ab`. Refuse the publish instead of shipping a dead sheet.
    if (dto?.winBack?.enabled === true) {
      const compactProducts = dto?.saleStrategy?.defaultUser?.compactProducts;
      if (!Array.isArray(compactProducts) || compactProducts.length === 0) {
        errors.push({
          field: 'winBack.enabled',
          message:
            'winBack requires saleStrategy.defaultUser.compactProducts — the win-back sheet IS the compact paywall, which has no plan without it',
        });
      }
    }

    return errors;
  }

  /**
   * LogicSale rows are looser than saleEvent on purpose — dates are OPTIONAL
   * open bounds (the server resolves them; there is no client parser to drop
   * a dateless campaign) and an empty plan list is a legitimate staged row.
   * What IS enforced: ids present and unique (they anchor purchase
   * attribution, and a duplicate would merge two campaigns' statistics
   * irreversibly), any present dates parseable and ordered, and a countdown
   * only ever pointed at a real end date.
   */
  private validateLogicSales(
    logicSales: PaywallLogicSaleDto[] | undefined,
  ): PaywallConfigValidationError[] {
    if (!logicSales?.length) return [];

    const errors: PaywallConfigValidationError[] = [];
    const seenIds = new Set<string>();

    logicSales.forEach((sale, index) => {
      const field = `logicSales[${index}]`;
      const id = (sale.id ?? '').trim();

      if (!id) {
        errors.push({ field: `${field}.id`, message: `${field}.id is required` });
      } else if (seenIds.has(id)) {
        errors.push({
          field: `${field}.id`,
          message: `${field}.id "${id}" is duplicated — ids anchor purchase attribution and must be unique`,
        });
      } else {
        seenIds.add(id);
      }

      if (!(sale.name ?? '').trim()) {
        errors.push({
          field: `${field}.name`,
          message: `${field}.name is required`,
        });
      }

      errors.push(
        ...this.validateOptionalProducts(sale.products, `${field}.products`),
      );

      const parseAt = (value: string | undefined, dateField: string) => {
        if (!value) return undefined;
        const time = new Date(value).getTime();
        if (Number.isNaN(time)) {
          errors.push({
            field: dateField,
            message: `${dateField} must be a parseable ISO-8601 date-time`,
          });
          return undefined;
        }
        return time;
      };
      const startAt = parseAt(sale.startAtUtc, `${field}.startAtUtc`);
      const endAt = parseAt(sale.endAtUtc, `${field}.endAtUtc`);
      if (startAt !== undefined && endAt !== undefined && startAt >= endAt) {
        errors.push({
          field: `${field}.endAtUtc`,
          message: `${field}.endAtUtc must be after startAtUtc`,
        });
      }

      if (sale.countdown && !sale.endAtUtc) {
        errors.push({
          field: `${field}.countdown`,
          message: `${field}.countdown requires endAtUtc — a countdown needs something to count to`,
        });
      }
    });

    return errors;
  }

  /**
   * A campaign with no window is dropped wholesale by the client (both
   * `_saleEvent` and `_giftCampaign` in the parser return null unless BOTH
   * bounds parse and start precedes end), so an enabled campaign missing a
   * date is not "a campaign without an end" -- it is no campaign at all.
   *
   * Shared by saleEvent and giftCampaign; `fieldPrefix`/`label` keep the error
   * paths pointing at whichever of the two failed.
   */
  private validateCampaignWindow(
    window: { startAtUtc?: string; endAtUtc?: string },
    fieldPrefix: string,
    label: string,
  ): PaywallConfigValidationError[] {
    const errors: PaywallConfigValidationError[] = [];
    const parse = (
      value: string | undefined,
      field: string,
    ): number | undefined => {
      if (!value) {
        errors.push({
          field,
          message: `${field} is required when ${label} is enabled`,
        });
        return undefined;
      }
      const time = new Date(value).getTime();
      if (Number.isNaN(time)) {
        errors.push({
          field,
          message: `${field} must be a parseable ISO-8601 date-time`,
        });
        return undefined;
      }
      return time;
    };

    const startAt = parse(window.startAtUtc, `${fieldPrefix}.startAtUtc`);
    const endAt = parse(window.endAtUtc, `${fieldPrefix}.endAtUtc`);

    if (startAt !== undefined && endAt !== undefined && startAt >= endAt) {
      errors.push({
        field: `${fieldPrefix}.endAtUtc`,
        message:
          `${fieldPrefix}.endAtUtc must be after startAtUtc ` +
          '(the client drops the whole campaign otherwise)',
      });
    }

    return errors;
  }

  /**
   * Same per-row rule as [validateProductsNonEmpty] but tolerates the list
   * being absent or empty, which for `compactProducts` is a valid,
   * meaningful state: the client falls back to `products`. Only a row that
   * exists and names no SKU is an error.
   */
  private validateOptionalProducts(
    products: PaywallProductRefDto[] | undefined,
    field: string,
  ): PaywallConfigValidationError[] {
    if (!products?.length) return [];
    return this.validateProductsNonEmpty(products, field);
  }

  private validateProductsNonEmpty(
    products: PaywallProductRefDto[] | undefined,
    field: string,
  ): PaywallConfigValidationError[] {
    if (!products?.length) {
      return [{ field, message: `${field} must be a non-empty array` }];
    }

    return products.reduce<PaywallConfigValidationError[]>(
      (errors, product, index) => {
        if (!product?.appleProductId && !product?.googleProductId) {
          errors.push({
            field: `${field}[${index}]`,
            message: `${field}[${index}] must set appleProductId and/or googleProductId`,
          });
        }
        return errors;
      },
      [],
    );
  }

  // ---------------------------------------------------------------------
  // The point of the whole feature: every referenced product id must exist
  // and be active in `iap_products` for its platform, or the Flutter
  // paywall throws and renders blank (StateError('Configured store product
  // is missing')). UNCHANGED from the Remote Config version of this service.
  // ---------------------------------------------------------------------

  /**
   * Every product reference in the config, `compactProducts` included -- a SKU
   * only shown to one entry point still blanks that entry point's paywall if it
   * is missing from `iap_products`, so it earns the same guard as `products`.
   */
  private collectProductRefs(dto: PaywallConfigDto): ProductRefLocation[] {
    const refs: ProductRefLocation[] = [];
    const { defaultUser, saleEvent } = dto.saleStrategy ?? {};

    const collect = (
      products: PaywallProductRefDto[] | undefined,
      fieldPrefix: string,
    ) =>
      (products ?? []).forEach((ref, index) =>
        refs.push({ field: `${fieldPrefix}[${index}]`, ref }),
      );

    collect(defaultUser?.products, 'saleStrategy.defaultUser.products');
    collect(
      defaultUser?.compactProducts,
      'saleStrategy.defaultUser.compactProducts',
    );

    if (saleEvent?.enabled) {
      collect(saleEvent.products, 'saleStrategy.saleEvent.products');
      collect(
        saleEvent.compactProducts,
        'saleStrategy.saleEvent.compactProducts',
      );
    }

    // Staged rows included (unlike saleEvent's enabled-only check): a
    // LogicSale is usually authored ahead of its window, and a dead SKU is
    // cheaper to hear about at publish time than at go-live.
    (dto.logicSales ?? []).forEach((sale, index) =>
      collect(sale.products, `logicSales[${index}].products`),
    );

    return refs;
  }

  private async assertProductsExist(dto: PaywallConfigDto): Promise<void> {
    const refs = this.collectProductRefs(dto);

    // Dedup (platform, productId) pairs -- the same SKU is often referenced
    // from multiple places (e.g. defaultUser AND an impression rule), and
    // each pair only needs one DB lookup.
    const pairs = new Map<
      string,
      { platform: PaymentPlatform; productId: string; fields: string[] }
    >();

    for (const { field, ref } of refs) {
      if (ref?.appleProductId) {
        const key = `${PaymentPlatform.APPLE}:${ref.appleProductId}`;
        const entry = pairs.get(key) ?? {
          platform: PaymentPlatform.APPLE,
          productId: ref.appleProductId,
          fields: [],
        };
        entry.fields.push(`${field}.appleProductId`);
        pairs.set(key, entry);
      }
      if (ref?.googleProductId) {
        const key = `${PaymentPlatform.GOOGLE}:${ref.googleProductId}`;
        const entry = pairs.get(key) ?? {
          platform: PaymentPlatform.GOOGLE,
          productId: ref.googleProductId,
          fields: [],
        };
        entry.fields.push(`${field}.googleProductId`);
        pairs.set(key, entry);
      }
    }

    const errors: PaywallConfigValidationError[] = [];

    for (const { platform, productId, fields } of pairs.values()) {
      const product = await this.productRepository.findOne({
        platform,
        productId,
      });

      if (!product) {
        fields.forEach(field =>
          errors.push({
            field,
            message: `product "${productId}" (${platform}) does not exist in iap_products`,
          }),
        );
      } else if (!product.isActive) {
        fields.forEach(field =>
          errors.push({
            field,
            message: `product "${productId}" (${platform}) exists but is not active`,
          }),
        );
      }
    }

    if (errors.length) {
      throw new BadRequestException({
        message:
          'One or more referenced products are missing or inactive in iap_products',
        errors,
      });
    }
  }
}
