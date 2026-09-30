import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { LearningItemController } from './learning-item.controller';
import { LearningItemService } from './learning-item.service';
import { LearningItemRepository } from './repository/learning-item.repository';
import { RoleplayColorTemplateController } from './roleplay-color-template.controller';
import { RoleplayColorTemplateService } from './roleplay-color-template.service';
import {
  LearningItem,
  LearningItemSchema,
} from './schema/learning-item.schema';
import { AvatarModule } from '../avatar/avatar.module';
import { KeypointModule } from '../keypoint/keypoint.module';
import { LessonModule } from '../lesson/lesson.module';
import { TagModule } from '../tags/tag.module';
import { RoleplayColorTemplateRepository } from './repository/color-template.repository';
import {
  RoleplayColorTemplate,
  RoleplayColorTemplateSchema,
} from './schema/color-template.schema';
import { CourseVersionModule } from '../course-version/course-version.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: LearningItem.name, schema: LearningItemSchema },
      { name: RoleplayColorTemplate.name, schema: RoleplayColorTemplateSchema },
    ]),
    forwardRef(() => AuthModule),
    // ContentSource: đọc nội dung theo tag đang phát hành thay vì bản
    // đang sửa. forwardRef vì CourseVersionModule import lại module này.
    forwardRef(() => CourseVersionModule),
    LoggerModule,
    forwardRef(() => TagModule),
    forwardRef(() => KeypointModule),
    forwardRef(() => AvatarModule),
    forwardRef(() => LessonModule),
  ],
  controllers: [LearningItemController, RoleplayColorTemplateController],
  providers: [
    LearningItemService,
    LearningItemRepository,
    RoleplayColorTemplateRepository,
    RoleplayColorTemplateService,
  ],
  exports: [LearningItemService, LearningItemRepository],
})
export class LearningItemModule {}
