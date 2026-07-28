import { PaymentPlatform } from "../../enum/payment.enum";
import { BaseQuery } from "../common.interface";

export interface IVoucherProductMapping {
  id?: string;
  voucherId?: string;
  platform: PaymentPlatform;
  baseProductId: string;
  targetProductId: string;
}

export interface IVoucher {
  id: string;
  code: string;
  owner?: string;
  // Display/reporting only - the real discount is whatever the target SKU
  // costs on the store. Never treat this as a live price calculation.
  discountPercent?: number;
  validFrom?: string;
  validTo?: string;
  maxUses?: number;
  usedCount: number;
  // Stored but not yet enforced by the backend.
  perUserLimit?: number;
  // Stored but not yet enforced by the backend.
  countries?: string[];
  isActive: boolean;
  mappings?: IVoucherProductMapping[];
  createdAt?: string;
  updatedAt?: string;
}

export interface IVoucherMappingInput {
  platform: PaymentPlatform;
  baseProductId: string;
  targetProductId: string;
}

// Shape accepted by both create (with `code`) and update (all optional,
// PartialType on the backend) - `mappings`, when present, REPLACES the
// voucher's full mapping set.
export interface IVoucherPayload {
  code?: string;
  owner?: string;
  discountPercent?: number;
  validFrom?: string;
  validTo?: string;
  maxUses?: number;
  perUserLimit?: number;
  countries?: string[];
  isActive?: boolean;
  mappings?: IVoucherMappingInput[];
}

export interface IVoucherBulkCreatePayload
  extends Omit<IVoucherPayload, "code"> {
  codes: string[];
}

export interface IVoucherBulkCreateResponse {
  created: number;
  skipped: number;
}

export class VoucherListQuery extends BaseQuery {
  isActive?: boolean;

  constructor(init?: Partial<VoucherListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());
    if (typeof this.isActive === "boolean") {
      params.set("isActive", String(this.isActive));
    }
    return params.toString();
  }
}
