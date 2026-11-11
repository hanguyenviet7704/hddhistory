import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { HomeBannerController } from './home-banner.controller';
import { HomeBannerService } from './home-banner.service';
import { HomeBannerConfigRepository } from './repository/home-banner-config.repository';
import {
  HomeBannerConfig,
  HomeBannerConfigSchema,
} from './schema/home-banner-config.schema';
import { PromoStatsModule } from '../promo-stats/promo-stats.module';
import { SegmentModule } from '../segment/segment.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: HomeBannerConfig.name, schema: HomeBannerConfigSchema },
    ]),
    PromoStatsModule,
    SegmentModule,
    forwardRef(() => AuthModule),
  ],
  controllers: [HomeBannerController],
  providers: [HomeBannerService, HomeBannerConfigRepository],
  exports: [HomeBannerService, HomeBannerConfigRepository],
})
export class HomeBannerModule {}
