import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';

import { RequestService } from '@base/service/request.service';

import {
  AffiliateVoucherClient,
  AffiliateVoucherPackage,
} from './affiliate/affiliate-voucher.client';
import { BulkCreateVoucherDto } from './dto/bulk-create-voucher.dto';
import { BulkCreateVoucherResponse } from './dto/bulk-create-voucher.response';
import { CreateVoucherDto } from './dto/create-voucher.dto';
import { GetListVoucherDto } from './dto/get-voucher.dto';
import { UpdateVoucherDto } from './dto/update-voucher.dto';
import { ValidateVoucherDto } from './dto/validate-voucher.dto';
import {
  IVoucherValidateProduct,
  IVoucherValidateResult,
} from './interfaces/voucher.interface';
import { CodeAttributionRepository } from './repositories/code-attribution.repository';
import { VoucherProductMappingRepository } from './repositories/voucher-product-mapping.repository';
import { VoucherRepository } from './repositories/voucher.repository';
import { PaymentPlatform } from '../enum/payment.enum';
import { Product } from '../products/entitys/product.entity';
import { ProductRepository } from '../products/repositories/product.repository';

@Injectable()
export class VoucherService {
  private readonly logger = new Logger(VoucherService.name);

  constructor(
    private readonly voucherRepository: VoucherRepository,
    private readonly mappingRepository: VoucherProductMappingRepository,
    private readonly productRepository: ProductRepository,
    private readonly affiliateClient: AffiliateVoucherClient,
    private readonly requestService: RequestService,
    private readonly codeAttributionRepository: CodeAttributionRepository,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  /**
   * Remember that this user applied this code. Never allowed to fail the
   * validation it rides along with — a bookkeeping write must not be what
   * stops someone redeeming a code.
   */
  private async recordAttribution(code: string): Promise<void> {
    const userId = this.user?.id?.toString();
    if (!userId || !code) return;
    try {
      await this.codeAttributionRepository.record(userId, code);
    } catch (err: any) {
      this.logger.error(
        `Failed to record code attribution (user=${userId}, code=${code}): ${
          err?.message ?? err
        }`,
        err?.stack,
      );
    }
  }

  private normalizeCode(code: string): string {
    return code.trim().toUpperCase();
  }

  /**
   * validFrom/validTo arrive as ISO date-strings on the DTO (validated by
   * @IsDateString) but are persisted as `Date` columns — convert only the
   * keys that were actually sent, leaving the rest of the partial untouched.
   */
  private toEntityDates<T extends { validFrom?: string; validTo?: string }>(
    dto: T,
  ) {
    const data: any = { ...dto };
    if ('validFrom' in dto) {
      data.validFrom = dto.validFrom ? new Date(dto.validFrom) : null;
    }
    if ('validTo' in dto) {
      data.validTo = dto.validTo ? new Date(dto.validTo) : null;
    }
    return data;
  }

  /**
   * A mapping set that covers only one store validates fine there and returns
   * `not_applicable` on the other, so the code silently works on iOS and
   * "doesn't apply" on Android with nothing in the admin explaining why. The
   * mapping editor defaults a new row to Apple, which makes the one-platform
   * set the easy slip rather than a deliberate choice -- so reject it here,
   * where bulk import and any direct API caller are covered too.
   *
   * An empty set is left alone on purpose: it unlocks nothing on either store,
   * which is inert rather than lopsided, and it keeps the create-then-add-
   * mappings flow working.
   */
  private assertMappingsCoverBothPlatforms(
    mappings?: { platform: PaymentPlatform }[],
  ) {
    if (!mappings?.length) return;

    const covered = new Set(mappings.map(mapping => mapping.platform));
    const missing = [PaymentPlatform.APPLE, PaymentPlatform.GOOGLE].filter(
      platform => !covered.has(platform),
    );

    if (missing.length) {
      throw new BadRequestException(
        `Voucher mappings must cover both platforms — no mapping for ${missing.join(
          ', ',
        )}. Add a mapping row per platform, or the code will report "not applicable" on the missing store.`,
      );
    }
  }

  async create(dto: CreateVoucherDto) {
    this.assertMappingsCoverBothPlatforms(dto.mappings);

    const code = this.normalizeCode(dto.code);

    if (await this.voucherRepository.exists({ code })) {
      throw new ConflictException('Voucher code already exists');
    }

    const { mappings, ...voucherData } = dto;
    const voucher = await this.voucherRepository.create(
      { ...this.toEntityDates(voucherData), code },
      this.user?.id,
    );

    if (mappings?.length) {
      await this.mappingRepository.createMany(
        mappings.map((mapping) => ({ ...mapping, voucherId: voucher.id })),
        this.user?.id,
      );
    }

    return this.findOne(voucher.id);
  }

  findAll(dto: GetListVoucherDto) {
    return this.voucherRepository.findOption(dto);
  }

  async findOne(id: string) {
    const voucher = await this.voucherRepository.findById(id);
    if (!voucher) throw new NotFoundException('Voucher not found');

    const mappings = await this.mappingRepository.findByVoucherId(id);
    return { ...voucher, mappings };
  }

  async update(id: string, dto: UpdateVoucherDto) {
    this.assertMappingsCoverBothPlatforms(dto.mappings);

    const voucher = await this.voucherRepository.findById(id);
    if (!voucher) throw new NotFoundException('Voucher not found');

    const { mappings, ...rest } = dto;
    const data: any = this.toEntityDates(rest);

    if (dto.code) {
      const code = this.normalizeCode(dto.code);
      if (code !== voucher.code && (await this.voucherRepository.exists({ code }))) {
        throw new ConflictException('Voucher code already exists');
      }
      data.code = code;
    }

    await this.voucherRepository.updateOne({ id }, data, this.user?.id);

    if (mappings !== undefined) {
      await this.mappingRepository.deleteByVoucherId(id);
      if (mappings.length) {
        await this.mappingRepository.createMany(
          mappings.map((mapping) => ({ ...mapping, voucherId: id })),
          this.user?.id,
        );
      }
    }

    return this.findOne(id);
  }

  async remove(id: string) {
    const voucher = await this.voucherRepository.findById(id);
    if (!voucher) throw new NotFoundException('Voucher not found');

    await this.mappingRepository.deleteByVoucherId(id);
    return this.voucherRepository.deleteOne({ id });
  }

  async bulkCreate(dto: BulkCreateVoucherDto): Promise<BulkCreateVoucherResponse> {
    this.assertMappingsCoverBothPlatforms(dto.mappings);

    const { codes, mappings, ...shared } = dto;
    const normalizedCodes = Array.from(
      new Set(codes.map((code) => this.normalizeCode(code))),
    );

    const existingCodes = new Set(
      await this.voucherRepository.findExistingCodes(normalizedCodes),
    );
    const codesToCreate = normalizedCodes.filter(
      (code) => !existingCodes.has(code),
    );

    if (!codesToCreate.length) {
      return { created: 0, skipped: normalizedCodes.length };
    }

    const sharedData = this.toEntityDates(shared);
    const vouchers = await this.voucherRepository.createMany(
      codesToCreate.map((code) => ({ ...sharedData, code })),
      this.user?.id,
    );

    if (mappings?.length) {
      const mappingRows = vouchers.flatMap((voucher) =>
        mappings.map((mapping) => ({ ...mapping, voucherId: voucher.id })),
      );
      await this.mappingRepository.createMany(mappingRows, this.user?.id);
    }

    return {
      created: vouchers.length,
      skipped: normalizedCodes.length - codesToCreate.length,
    };
  }

  /**
   * Resolves a promo code into the SKU swaps the paywall should render.
   *
   * The affiliate service (voucher.eup.ai) owns a code's entire lifecycle --
   * existence, expiry, usage caps, per-user caps, country rules. HDDhistory asks and
   * trusts the answer. What stays here is store knowledge they do not have:
   * whether the SKU they named is really sellable, and which of the SKUs
   * currently on the paywall it should replace.
   *
   * Their `package_key` IS a HDDhistory product id -- verified live, code HDDHISTORYTES
   * answers `meup_sub_1y_50off` / `meup_sub_1y_30off` -- so the whole mapping
   * comes out of `iap_products`. An earlier draft kept a separate tier table for
   * this; it only ever restated what the catalogue already knew, by hand.
   *
   * The response shape is unchanged from when `iap_vouchers` backed this, so no
   * client release is needed.
   */
  async validate(dto: ValidateVoucherDto): Promise<IVoucherValidateResult> {
    const code = this.normalizeCode(dto.code);

    // Record the attempt HERE, before anything can go wrong downstream. This
    // call is the moment the user applies a code, and until now that was the
    // only place the code existed outside the app's memory -- everything
    // between here and `verify()` (the store sheet, Ask-to-Buy, a failed
    // verify) could lose it. Recorded even when the affiliate service says
    // `not_found`: this is attribution, not entitlement.
    await this.recordAttribution(code);

    const lookup = await this.affiliateClient.get(code, {
      userId: this.user?.id,
      email: this.user?.email,
    });

    if (lookup.failure) {
      // Their 404 cannot tell "no such code" from "no such product id", so a
      // typo and a broken integration both land on `not_found`. Only an
      // outright outage or a rejected body becomes `unavailable`.
      return {
        valid: false,
        reason: lookup.failure === 'unavailable' ? 'unavailable' : 'not_found',
      };
    }
    if (!lookup.packages?.length) {
      return { valid: false, reason: 'not_found' };
    }

    return this.resolveSwaps(code, dto.platform, lookup.packages);
  }

  /**
   * Turns the affiliate's `{package_key, discount}` list into the swap list the
   * client renders.
   *
   * Price ordering is decided by the CATALOGUE (`iap_products.salePercent`),
   * never by the percentage they send. Both numbers are display values, but
   * only the catalogue's is in the same frame of reference as the SKU the user
   * currently sees -- and trusting theirs would let a mismatched number swap a
   * discounted SKU for a dearer one, charging more than before the code.
   */
  private async resolveSwaps(
    code: string,
    platform: PaymentPlatform,
    packages: AffiliateVoucherPackage[],
  ): Promise<IVoucherValidateResult> {
    // Their payload also carries package keys owned by other EUP apps
    // (verified: one product id answered with `pre*` beside `jlct*`). Resolving
    // them as product ids drops those for free -- no allow-list to maintain.
    const targets = await this.productRepository.findActiveByProductIds(
      platform,
      packages.map((entry) => entry.packageKey),
    );
    if (!targets.length) return { valid: false, reason: 'not_applicable' };

    const promisedPercentByProductId = new Map(
      packages.map((entry) => [entry.packageKey, entry.discountPercent]),
    );

    // A plan's family is its full-price SKU plus every discounted sibling
    // pointing at it. `compareAtProductId` names that full-price reference --
    // NOT the SKU on screen, which shifts by cohort and impression (defaultUser
    // sees meup_sub_1y_30off; newUser impression 2 sees apple 20off / google
    // 30off). The client swaps by exact id, so a code has to offer a swap from
    // every member or it silently does nothing for the cohorts it missed.
    const roots = Array.from(
      new Set(
        targets.map((target) => target.compareAtProductId || target.productId),
      ),
    );
    const [rootProducts, siblings] = await Promise.all([
      this.productRepository.findActiveByProductIds(platform, roots),
      this.productRepository.findActiveByCompareAtProductIds(platform, roots),
    ]);

    const familyByRoot = new Map<string, Product[]>();
    for (const product of [...rootProducts, ...siblings]) {
      const root = product.compareAtProductId || product.productId;
      const family = familyByRoot.get(root) ?? [];
      family.push(product);
      familyByRoot.set(root, family);
    }

    // base SKU -> the deepest-discount target allowed to replace it. Keyed by
    // base because the client folds swaps into a `base -> target` Map, where a
    // repeated key means the last entry silently wins: the user could be
    // charged a shallower discount than `discountPercent` reports.
    const bestByBase = new Map<string, { targetProductId: string; percent: number }>();
    let blockedByRunningSale = false;

    for (const target of targets) {
      const targetPercent = target.salePercent ?? 0;
      const promised = promisedPercentByProductId.get(target.productId) ?? 0;

      if (targetPercent <= 0) {
        // Without a catalogue percentage there is no evidence this SKU is
        // cheaper than what the user already sees, and swapping on the
        // affiliate's word alone risks charging MORE. Config fault, not user
        // error, so make it loud.
        this.logger.error(
          `Voucher ${code}: affiliate offers ${target.productId} at ` +
            `${promised}% on ${platform}, but that product has no salePercent ` +
            `in iap_products. Skipped — set its discount % or the code cannot ` +
            `be honoured.`,
        );
        continue;
      }

      if (promised !== targetPercent) {
        this.logger.warn(
          `Voucher ${code}: affiliate says ${promised}% for ` +
            `${target.productId} but the catalogue says ${targetPercent}%. ` +
            `Charging the catalogue SKU; reporting ${targetPercent}%.`,
        );
      }

      const root = target.compareAtProductId || target.productId;
      for (const member of familyByRoot.get(root) ?? []) {
        if (member.productId === target.productId) continue;

        // A code that does not beat what this member already advertises is
        // deliberately not applied -- the user keeps the better running price.
        if (targetPercent <= (member.salePercent ?? 0)) {
          blockedByRunningSale = true;
          continue;
        }

        const incumbent = bestByBase.get(member.productId);
        if (!incumbent || targetPercent > incumbent.percent) {
          bestByBase.set(member.productId, {
            targetProductId: target.productId,
            percent: targetPercent,
          });
        }
      }
    }

    if (!bestByBase.size) {
      return {
        valid: false,
        reason: blockedByRunningSale ? 'not_better' : 'not_applicable',
      };
    }

    const swaps: IVoucherValidateProduct[] = [];
    let effectivePercent = 0;
    for (const [baseProductId, pick] of bestByBase) {
      swaps.push({ baseProductId, targetProductId: pick.targetProductId });
      effectivePercent = Math.max(effectivePercent, pick.percent);
    }

    return {
      valid: true,
      code,
      discountPercent: effectivePercent,
      products: swaps,
    };
  }

  /**
   * Reports a redemption to the affiliate service.
   *
   * `package_key` is just the SKU that was charged: their key space is HDDhistory's
   * product ids, and Part 5's outbound order export already sends
   * `package_key: purchase.productId`, so both directions agree.
   *
   * Called AFTER the purchase row commits, never when the user applies the
   * code -- reporting at apply time would spend a usage slot on every abandoned
   * checkout. Commission is unaffected either way: it settles from
   * POST /purchase/affiliateOrder, which reads the persisted
   * `iap_purchases.voucher_code`.
   *
   * Never throws. The money has already moved by the time this runs.
   */
  async reportRedemption(args: {
    code: string;
    productId: string;
    userId?: string;
    email?: string;
  }): Promise<void> {
    await this.affiliateClient.use({
      code: this.normalizeCode(args.code),
      packageKey: args.productId,
      identity: { userId: args.userId, email: args.email },
    });
  }
}
