import {
  PaymentCurrency,
  PaymentPlatform,
  ProductType,
} from '../../enum/payment.enum';

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
  isActive: boolean;
  bestDeal: boolean;
}
