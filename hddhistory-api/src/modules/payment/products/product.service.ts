import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { I18nContext } from 'nestjs-i18n/dist';

import { RequestService } from '@base/service/request.service';

import { PaymentPlatform } from '../enum/payment.enum';
import { CreateProductDto } from './dto/create-product.dto';
import { GetListProductDto } from './dto/get-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { ProductRepository } from './repositories/product.repository';

@Injectable()
export class ProductService {
  constructor(
    private readonly productRepository: ProductRepository,
    private readonly requestService: RequestService,
  ) {}

  private get user() {
    return this.requestService.user;
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async create(dto: CreateProductDto) {
    const compareAtProductId = await this.resolveCompareAtProductId(
      dto.compareAtProductId,
      { platform: dto.platform, productId: dto.productId },
    );

    return this.productRepository.create(
      { ...dto, compareAtProductId },
      this.user?.id,
    );
  }

  findAll(dto: GetListProductDto) {
    return this.productRepository.findOption(dto);
  }

  async findOne(id: string) {
    const product = await this.productRepository.findById(id);
    if (!product) throw new NotFoundException('Product not found');
    return product;
  }

  async update(id: string, dto: UpdateProductDto) {
    const product = await this.findOne(id);
    const patch: UpdateProductDto = { ...dto };

    if (dto.compareAtProductId !== undefined) {
      patch.compareAtProductId = await this.resolveCompareAtProductId(
        dto.compareAtProductId,
        {
          platform: dto.platform ?? product.platform,
          productId: dto.productId ?? product.productId,
        },
      );
    }

    return await this.productRepository.updateOne(
      { id: String(product.id) },
      patch,
      this.user?.id,
    );
  }

  /**
   * The struck-through paywall price is a SKU reference, not an amount — the
   * app asks the store for this SKU so the number stays localized per
   * storefront. A reference that does not exist just means no struck price is
   * ever shown, so it is rejected here rather than failing silently in the app.
   *
   * Deliberately does NOT require the referenced SKU to be active: the normal
   * setup sells only the discounted SKU and retires the base one in the
   * catalog while it still has a store listing to read the price from.
   */
  private async resolveCompareAtProductId(
    raw: string | undefined,
    owner: { platform: PaymentPlatform; productId: string },
  ): Promise<string> {
    const compareAtProductId = raw?.trim();
    if (!compareAtProductId) return null;

    if (compareAtProductId === owner.productId?.trim()) {
      throw new BadRequestException(
        'compareAtProductId must be a different SKU than productId',
      );
    }

    const reference = await this.productRepository.findOne({
      platform: owner.platform,
      productId: compareAtProductId,
    });

    if (!reference) {
      throw new BadRequestException(
        `compareAtProductId "${compareAtProductId}" does not exist in ` +
          `iap_products for platform ${owner.platform}`,
      );
    }

    return compareAtProductId;
  }

  async remove(id: string) {
    const product = await this.productRepository.findById(id);
    if (!product) throw new NotFoundException('Product not found');
    return await this.productRepository.deleteOne({ id: product.id });
  }
}
