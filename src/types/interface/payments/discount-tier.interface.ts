import { PaymentPlatform } from "../../enum/payment.enum";
import { BaseQuery } from "../common.interface";

// A discount tier maps one affiliate discount % (per package + platform) to a
// concrete SKU swap the store will actually honor - IAP only charges by a
// registered SKU, never by an arbitrary percentage. Declared ONCE per
// (packageKey, platform, discountPercent) tuple, never per individual code;
// the affiliate (voucher.eup.ai) is the only place codes are issued now.
export interface IDiscountTier {
  id: string;
  packageKey: string;
  platform: PaymentPlatform;
  discountPercent: number;
  baseProductId: string;
  targetProductId: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface IDiscountTierPayload {
  packageKey?: string;
  platform?: PaymentPlatform;
  discountPercent?: number;
  baseProductId?: string;
  targetProductId?: string;
}

export class DiscountTierListQuery extends BaseQuery {
  platform?: PaymentPlatform;
  packageKey?: string;

  constructor(init?: Partial<DiscountTierListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());
    if (this.platform) params.set("platform", this.platform);
    if (this.packageKey) params.set("packageKey", this.packageKey);
    return params.toString();
  }
}
