import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { ProductPrice } from './entitys/product-price.entity';
import { PriceController } from './price.controller';
import { PriceService } from './price.service';
import { ProductPriceSyncScheduler } from './product-price-sync.scheduler';
import { ProductPriceRepository } from './repositories/product-price.repository';
import { ProductsModule } from '../products/products.module';

@Module({
  imports: [TypeOrmModule.forFeature([ProductPrice]), ProductsModule, AuthModule],
  controllers: [PriceController],
  providers: [PriceService, ProductPriceRepository, ProductPriceSyncScheduler],
  exports: [PriceService, ProductPriceRepository],
})
export class PricesModule {}
