import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { GetProductPriceDto } from './dto/get-product-price.dto';
import { SyncProductPriceDto } from './dto/sync-product-price.dto';
import { PriceService } from './price.service';

@ApiTags('PAYMENT-PRODUCT-PRICES')
@ApiBearerAuth()
@UseGuards(AuthGuard)
// NOT nested under `payment/products`: ProductController owns
// `payment/products/:id`, and Nest matches routes in module-registration
// order, so `payment/products/prices` was being swallowed as `:id = "prices"`
// and answered with "Product not found". A sibling path is immune to that
// regardless of module order.
@Controller({ path: 'payment/product-prices', version: '1' })
export class PriceController {
  constructor(private readonly svc: PriceService) {}

  @Get()
  findAll(@Query() dto: GetProductPriceDto) {
    return this.svc.findAll(dto);
  }

  @Post('sync')
  sync(@Body() dto: SyncProductPriceDto) {
    return this.svc.sync(dto);
  }
}
