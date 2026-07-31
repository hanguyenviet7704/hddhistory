import {
  PaymentCurrency,
  PaymentPlatform,
  ProductType,
} from "../../enum/payment.enum";
import { BaseQuery } from "../common.interface";

export interface IProduct {
  id: string;
  platform: PaymentPlatform;
  productId: string;
  type: ProductType;
  title: string;
  description?: string;
  currency: PaymentCurrency;
  rawPrice?: number;
  price?: string;
  salePrice?: number;
  salePercent?: number | null;
  /**
   * SKU on the same platform whose real store price the app strikes through
   * above this one's selling price. A reference, never an amount — the app
   * asks the store for it, so the struck number stays localized per country.
   */
  compareAtProductId?: string | null;
  isActive: boolean;
  bestDeal: boolean;
}

export class ProductListQuery extends BaseQuery {
  platform?: PaymentPlatform;
  type?: ProductType;
  isActive?: boolean;
  isAll?: boolean;

  constructor(init?: Partial<ProductListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());
    if (this.platform) params.set("platform", this.platform);
    if (this.type) params.set("type", this.type);
    if (typeof this.isActive === "boolean") {
      params.set("isActive", String(this.isActive));
    }
    if (typeof this.isAll === "boolean") {
      params.set("isAll", String(this.isAll));
    }

    return params.toString();
  }
}
