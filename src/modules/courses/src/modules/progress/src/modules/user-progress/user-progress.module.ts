import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { FileModule } from 'src/modules/file/file.module';
import { KeypointQuotaLedgerModule } from 'src/modules/keypoint-access/keypoint-quota-ledger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { UserProgressExportRepository } from './repository/user-progress-export.repository';
import { UserProgressRepository } from './repository/user-progress.repository';
import {
  UserProgressExport,
  UserProgressExportSchema,
} from './schema/user-progress-export.schema';
import {
  UserProgress,
  UserProgressSchema,
} from './schema/user-progress.schema';
import { UserProgressController } from './user-progress.controller';
import { UserProgressService } from './user-progress.service';
import { CourseModule } from '../../../../course/course.module';
import { CourseVersionModule } from '../../../../course-version/course-version.module';
import { FeedbackModule } from '../../../../feedback/user-feedback/user-feedback.module';
import { KeypointModule } from '../../../../keypoint/keypoint.module';
import { LearningItemModule } from '../../../../learning-item/learning-item.module';
import { LessonModule } from '../../../../lesson/lesson.module';
import { SkillsetRepository } from '../../../../skillset/repository/skillset.repository';
import {
  Skillset,
  SkillsetSchema,
} from '../../../../skillset/schema/skillset.schema';
import { UserStreakModule } from '../user-streak/user-streak.module';

@Module({
  imports: [
    // ContentSource: đọc nội dung theo tag đang phát hành.
    forwardRef(() => CourseVersionModule),
    MongooseModule.forFeature([
      { name: UserProgress.name, schema: UserProgressSchema },
      { name: UserProgressExport.name, schema: UserProgressExportSchema },
      { name: Skillset.name, schema: SkillsetSchema },
    ]),
    forwardRef(() => AuthModule),
    forwardRef(() => FileModule),
    LoggerModule,
    forwardRef(() => CourseModule),
    forwardRef(() => KeypointModule),
    forwardRef(() => LearningItemModule),
    forwardRef(() => LessonModule),
    FeedbackModule,
    UserStreakModule,
    // Finishing a keypoint is what spends the daily free-keypoint ticket, so the
    // ledger is written from here. The LEDGER module, never the access module:
    // access imports this module, and the ledger is a leaf precisely so this
    // import cannot close a cycle.
    KeypointQuotaLedgerModule,
  ],
  controllers: [UserProgressController],
  providers: [
    UserProgressService,
    UserProgressRepository,
    UserProgressExportRepository,
    SkillsetRepository,
  ],
  exports: [UserProgressService, UserProgressRepository],
})
export class UserProgressModule {}
