import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { DeleteSubscriptionDto } from './dto/delete-subscription.dto';
import { GetListSubscriptionDto } from './dto/get-subscription.dto';
import { ManualSubscriptionDto } from './dto/manual-subscription.dto';
import { UpdateManualSubscriptionDto } from './dto/update-manual-subscription.dto';
import { SubscriptionService } from './subscription.service';

@ApiTags('PAYMENT-SUBSCRIPTIONS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'payment/subscriptions', version: '1' })
export class SubscriptionController {
  constructor(private readonly svc: SubscriptionService) {}

  @Get()
  findAll(@Query() dto: GetListSubscriptionDto) {
    return this.svc.findAll(dto);
  }

  @Get('/users/:userId/active-premium')
  findActivePremiumForUser(@Param('userId') userId: string) {
    return this.svc.findActivePremiumForUser(userId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.svc.findOne(id);
  }

  @Post('/manual')
  createManual(@Body() dto: ManualSubscriptionDto) {
    return this.svc.createManual(dto);
  }

  @Put(':id/manual')
  updateManual(
    @Param('id') id: string,
    @Body() dto: UpdateManualSubscriptionDto,
  ) {
    return this.svc.updateManual(id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @Body() dto: DeleteSubscriptionDto) {
    return this.svc.remove(id, dto);
  }
}
