import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { StreakConfigRepository } from './repository/streak-config.repository';
import {
  StreakConfig,
  StreakConfigSchema,
} from './schema/streak-config.schema';
import { StreakConfigController } from './streak-config.controller';
import { StreakConfigService } from './streak-config.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: StreakConfig.name, schema: StreakConfigSchema },
    ]),
    forwardRef(() => AuthModule),
  ],
  controllers: [StreakConfigController],
  providers: [StreakConfigService, StreakConfigRepository],
  exports: [StreakConfigService, StreakConfigRepository],
})
export class StreakConfigModule {}
