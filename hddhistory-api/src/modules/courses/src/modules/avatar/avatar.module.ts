import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { AvatarController } from './avatar.controller';
import { AvatarService } from './avatar.service';
import { AvatarRepository } from './repository/avatar.repository';
import { Avatar, AvatarSchema } from './schema/avatar.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Avatar.name, schema: AvatarSchema }]),
    forwardRef(() => AuthModule),
    LoggerModule,
  ],
  controllers: [AvatarController],
  providers: [AvatarService, AvatarRepository],
  exports: [AvatarService, AvatarRepository],
})
export class AvatarModule {}
