import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { KeypointController } from './keypoint.controller';
import { KeypointService } from './keypoint.service';
import { KeypointRepository } from './repository/keypoint.repository';
import { Keypoint, KeypointSchema } from './schema/keypoint.schema';
import { CourseVersionModule } from '../course-version/course-version.module';
import { LearningItemModule } from '../learning-item/learning-item.module';
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Keypoint.name, schema: KeypointSchema },
    ]),
    forwardRef(() => AuthModule),
    // ContentSource: đọc nội dung theo tag đang phát hành thay vì bản
    // đang sửa. forwardRef vì CourseVersionModule import lại module này.
    forwardRef(() => CourseVersionModule),
    LoggerModule,
    LearningItemModule,
  ],
  controllers: [KeypointController],
  providers: [KeypointService, KeypointRepository],
  exports: [KeypointService, KeypointRepository],
})
export class KeypointModule {}
