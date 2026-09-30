import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { TagRepository } from './repository/tag.repository';
import { Tag, TagSchema } from './schema/tag.schema';
import { TagController } from './tag.controller';
import { TagService } from './tag.service';
import { LearningItemModule } from '../learning-item/learning-item.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Tag.name, schema: TagSchema }]),
    forwardRef(() => AuthModule),
    LoggerModule,
    forwardRef(() => LearningItemModule),
  ],
  controllers: [TagController],
  providers: [TagService, TagRepository],
  exports: [TagService, TagRepository],
})
export class TagModule {}
