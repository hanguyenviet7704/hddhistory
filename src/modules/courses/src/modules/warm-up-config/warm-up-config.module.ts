import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { WarmUpConfigRepository } from './repository/warm-up-config.repository';
import { WarmUpConfig, WarmUpConfigSchema } from './schema/warm-up-config.schema';
import { WarmUpConfigController } from './warm-up-config.controller';
import { WarmUpConfigService } from './warm-up-config.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: WarmUpConfig.name, schema: WarmUpConfigSchema },
    ]),
    forwardRef(() => AuthModule),
  ],
  controllers: [WarmUpConfigController],
  providers: [WarmUpConfigService, WarmUpConfigRepository],
  exports: [WarmUpConfigService, WarmUpConfigRepository],
})
export class WarmUpConfigModule {}
