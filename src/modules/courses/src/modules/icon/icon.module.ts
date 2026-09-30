import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { IconController } from './icon.controller';
import { IconService } from './icon.service';
import { IconRepository } from './repository/icon.repository';
import { Icon, IconSchema } from './schema/icon.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Icon.name, schema: IconSchema }]),
    forwardRef(() => AuthModule),
    LoggerModule,
  ],
  controllers: [IconController],
  providers: [IconService, IconRepository],
  exports: [IconService, IconRepository],
})
export class IconModule {}
