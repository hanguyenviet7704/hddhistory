export interface RevenueStatisticsResponse {
  items: RevenueStatisticsItem[];
}

export interface RevenueStatisticsItem {
  currency: string | null;
  totalRevenue: number;
  refundedRevenue: number;
  totalPurchases: number;
}
