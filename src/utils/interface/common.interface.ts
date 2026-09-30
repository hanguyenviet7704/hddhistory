export interface ITranslation {
  en?: string;
  vi?: string;
  zh?: string;
  ja?: string;
  ko?: string;
}

export interface IPrice {
  currency: string;
  originalPrice: number;
  salePrice?: number;
  isFree?: boolean;
}
