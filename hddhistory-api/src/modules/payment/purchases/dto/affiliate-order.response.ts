import { ApiProperty } from '@nestjs/swagger';

/**
 * Response contract for `POST /purchase/affiliateOrder` (Part 5). snake_case
 * on purpose -- external, fixed contract. Returned via `res.json()` directly
 * (bypassing the global `ResponseInterceptor` envelope) so the body matches
 * this shape exactly, with no `{ statusCode, message, data }` wrapper.
 */
export class AffiliateOrderItem {
  @ApiProperty({ nullable: true, example: 'SUMMER50' })
  code: string | null;

  @ApiProperty({ example: 50, description: '0 when no voucher was applied' })
  discount: number;

  @ApiProperty({ example: 'meup_sub_1m_70off' })
  package_key: string;

  @ApiProperty({ nullable: true, example: '1 Month Subscription' })
  package: string | null;

  @ApiProperty({ example: 1, description: '1 = paid, 0 = anything else' })
  status: number;

  @ApiProperty({ nullable: true, example: 'VN' })
  country: string | null;

  @ApiProperty({ nullable: true, example: 'vi' })
  language: string | null;

  @ApiProperty({ nullable: true, example: 1732000000000 })
  order_date_ms: number | null;

  @ApiProperty({ nullable: true, example: '2000000123456789' })
  order_id: string | null;

  @ApiProperty({ example: '64f1c2b3a1b2c3d4e5f6a7b8' })
  user_id: string;

  @ApiProperty({ nullable: true, example: 'user@example.com' })
  email: string | null;

  @ApiProperty({ nullable: true, example: 'Jane Doe' })
  user_name: string | null;

  @ApiProperty({ example: 'ios', enum: ['ios', 'android'] })
  user_platform: string;

  @ApiProperty({ example: 'apple', enum: ['apple', 'google'] })
  payment_platform: string;

  @ApiProperty({ nullable: true, example: 2.99 })
  price: number | null;

  @ApiProperty({ nullable: true, example: 'USD' })
  currency: string | null;
}

export class AffiliateOrderResponse {
  @ApiProperty({ type: [AffiliateOrderItem] })
  orders: AffiliateOrderItem[];
}
