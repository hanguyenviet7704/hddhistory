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

import { BulkCreateVoucherDto } from './dto/bulk-create-voucher.dto';
import { CreateVoucherDto } from './dto/create-voucher.dto';
import { GetListVoucherDto } from './dto/get-voucher.dto';
import { UpdateVoucherDto } from './dto/update-voucher.dto';
import { ValidateVoucherDto } from './dto/validate-voucher.dto';
import { VoucherService } from './voucher.service';

@ApiTags('PAYMENT-VOUCHERS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'payment/vouchers', version: '1' })
export class VoucherController {
  constructor(private readonly svc: VoucherService) {}

  @Post()
  create(@Body() dto: CreateVoucherDto) {
    return this.svc.create(dto);
  }

  @Get()
  findAll(@Query() dto: GetListVoucherDto) {
    return this.svc.findAll(dto);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.svc.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateVoucherDto) {
    return this.svc.update(id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }

  @Post('bulk')
  bulkCreate(@Body() dto: BulkCreateVoucherDto) {
    return this.svc.bulkCreate(dto);
  }

  @Post('validate')
  validate(@Body() dto: ValidateVoucherDto) {
    return this.svc.validate(dto);
  }
}
