import { Body, Controller, Post, Res, UseGuards } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Response } from 'express';

import { Public } from '@base/decorator/public';

import { AffiliateOrderRequestDto } from './dto/affiliate-order-request.dto';
import { AffiliateKeyGuard } from './guards/affiliate-key.guard';
import { PurchaseService } from './purchase.service';

// Deliberately OUTSIDE the `payment/` prefix -- the external affiliate spec
// fixes this exact path (`/api/v1/purchase/affiliateOrder`).
@ApiTags('PURCHASE-AFFILIATE')
@Controller({ path: 'purchase', version: '1' })
export class AffiliateOrderController {
  constructor(private readonly svc: PurchaseService) {}

  @Public()
  @UseGuards(AffiliateKeyGuard)
  @Post('affiliateOrder')
  async getAffiliateOrders(
    @Body() dto: AffiliateOrderRequestDto,
    @Res() res: Response,
  ): Promise<void> {
    // @Res() bypasses the global ResponseInterceptor envelope so the body is
    // exactly `{ orders: [...] }`, per the external contract.
    const result = await this.svc.getAffiliateOrders(dto);
    res.status(200).json(result);
  }
}
