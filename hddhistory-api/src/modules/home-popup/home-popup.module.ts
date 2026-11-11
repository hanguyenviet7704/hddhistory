import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { HomePopupController } from './home-popup.controller';
import { HomePopupService } from './home-popup.service';
import { HomePopupClickRepository } from './repository/home-popup-click.repository';
import { HomePopupConfigRepository } from './repository/home-popup-config.repository';
import {
  HomePopupClick,
  HomePopupClickSchema,
} from './schema/home-popup-click.schema';
import {
  HomePopupConfig,
  HomePopupConfigSchema,
} from './schema/home-popup-config.schema';
import { PromoStatsModule } from '../promo-stats/promo-stats.module';
import { SegmentModule } from '../segment/segment.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: HomePopupConfig.name, schema: HomePopupConfigSchema },
      { name: HomePopupClick.name, schema: HomePopupClickSchema },
    ]),
    PromoStatsModule,
    SegmentModule,
    // Every route here is behind AuthGuard (there is no @Public read), so the
    // guard's dependencies must be resolvable from this module or the whole app
    // crash-loops on boot.
    forwardRef(() => AuthModule),
  ],
  controllers: [HomePopupController],
  providers: [HomePopupService, HomePopupConfigRepository, HomePopupClickRepository],
  exports: [HomePopupService],
})
export class HomePopupModule {}
