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

import { CreateProductDto } from './dto/create-product.dto';
import { GetListProductDto } from './dto/get-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { ProductService } from './product.service';

@ApiTags('PAYMENT-PRODUCTS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'payment/products', version: '1' })
export class ProductController {
  constructor(private readonly svc: ProductService) {}

  @Post()
  create(@Body() dto: CreateProductDto) {
    return this.svc.create(dto);
  }

  @Get()
  findAll(@Query() dto: GetListProductDto) {
    return this.svc.findAll(dto);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.svc.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateProductDto) {
    return this.svc.update(id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}
