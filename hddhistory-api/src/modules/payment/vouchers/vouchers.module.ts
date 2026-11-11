import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { ProductsModule } from '../products/products.module';
import { AffiliateVoucherClient } from './affiliate/affiliate-voucher.client';
import { CodeAttribution } from './entitys/code-attribution.entity';
import { VoucherProductMapping } from './entitys/voucher-product-mapping.entity';
import { Voucher } from './entitys/voucher.entity';
import { CodeAttributionRepository } from './repositories/code-attribution.repository';
import { VoucherProductMappingRepository } from './repositories/voucher-product-mapping.repository';
import { VoucherRepository } from './repositories/voucher.repository';
import { VoucherController } from './voucher.controller';
import { VoucherService } from './voucher.service';

// `Purchase` + its own `PurchaseRepository` used to be registered here so
// VoucherService could enforce Voucher.perUserLimit without a VouchersModule
// <-> PurchasesModule circular import. Both are gone: per-user limits now live
// on the affiliate side (voucher.eup.ai), so nothing in this module reads
// purchases any more. The import edge still has to stay one-directional --
// PurchasesModule imports VouchersModule to reuse VoucherService at verify
// time -- so do not import PurchasesModule here if that need comes back;
// register the entity + repository directly again instead.
@Module({
  imports: [
    TypeOrmModule.forFeature([Voucher, VoucherProductMapping, CodeAttribution]),
    ProductsModule,
    AuthModule,
  ],
  controllers: [VoucherController],
  providers: [
    VoucherService,
    VoucherRepository,
    VoucherProductMappingRepository,
    CodeAttributionRepository,
    AffiliateVoucherClient,
  ],
  exports: [
    VoucherService,
    VoucherRepository,
    VoucherProductMappingRepository,
    // PurchasesModule reads this at verify time to recover a code the app
    // could no longer hand over.
    CodeAttributionRepository,
  ],
})
export class VouchersModule {}
