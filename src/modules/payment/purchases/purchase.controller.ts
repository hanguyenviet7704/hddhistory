import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { GetListPurchaseDto } from './dto/get-purchase.dto';
import { GetRevenueListDto } from './dto/get-revenue-list.dto';
import { UpdatePurchaseStatusDto } from './dto/update-purchase-status.dto';
import { VerifyPurchaseDto } from './dto/verify-purchase.dto';
import { PurchaseService } from './purchase.service';

@ApiTags('PAYMENT-PURCHASES')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'payment/purchases', version: '1' })
export class PurchaseController {
  constructor(private readonly svc: PurchaseService) {}

  @Get()
  findAll(@Query() dto: GetListPurchaseDto) {
    return this.svc.findAll(dto);
  }

  @Get('/revenue/statistics')
  getRevenueStatistics(@Query() dto: GetRevenueListDto) {
    return this.svc.getRevenueStatistics(dto);
  }

  @Get('/revenue/entries')
  getRevenueEntries(@Query() dto: GetRevenueListDto) {
    return this.svc.getRevenueEntries(dto);
  }

  @Get('/subscriptions/:id')
  findBySubscription(@Param('id') id: string) {
    return this.svc.findBySubscriptionId(id);
  }

  @Get(':id/history')
  getHistory(@Param('id') id: string) {
    return this.svc.getHistory(id);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.svc.findOne(id);
  }

  @Get(':id/webhooks')
  getWebhooksByPurchaseId(@Param('id') id: string) {
    return this.svc.getWebhooksByPurchaseId(id);
  }

  @Post('/verify')
  verify(@Req() req: any, @Body() dto: VerifyPurchaseDto) {
    return this.svc.verify(req.user?.id, dto);
  }

  @Patch(':id')
  updateStatus(@Param('id') id: string, @Body() dto: UpdatePurchaseStatusDto) {
    return this.svc.updateStatus(id, dto);
  }

  @Get('/users/:userId')
  findByUser(@Param('userId') userId: string) {
    return this.svc.findByUser(userId);
  }

}
