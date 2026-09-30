import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { CourseContentTransferController } from './controller/course-content-transfer.controller';
import { CourseImportJobController } from './controller/course-import-job.controller';
import { CourseContentTransferService } from './course-content-transfer.service';
import { CourseImportJobService } from './course-import-job.service';
import { DriveContentSyncService } from './drive-content-sync.service';
import { CourseImportJobRepository } from './repository/course-import-job.repository';
import {
  CourseImportJob,
  CourseImportJobSchema,
} from './schema/course-import-job.schema';
import { CourseModule } from '../course/course.module';
import { CourseVersionModule } from '../course-version/course-version.module';
import { KeypointModule } from '../keypoint/keypoint.module';
import { LearningItemModule } from '../learning-item/learning-item.module';
import { LessonModule } from '../lesson/lesson.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CourseImportJob.name, schema: CourseImportJobSchema },
    ]),
    forwardRef(() => AuthModule),
    forwardRef(() => LearningItemModule),
    forwardRef(() => CourseModule),
    // ContentSource + CourseVersionService + PublishedContentRepository: the
    // tag export and the autoTag publish step.
    forwardRef(() => CourseVersionModule),
    forwardRef(() => LessonModule),
    forwardRef(() => KeypointModule),
  ],
  controllers: [CourseImportJobController, CourseContentTransferController],
  providers: [
    CourseImportJobService,
    CourseImportJobRepository,
    CourseContentTransferService,
    DriveContentSyncService,
  ],
  exports: [
    CourseImportJobService,
    CourseImportJobRepository,
    CourseContentTransferService,
    DriveContentSyncService,
  ],
})
export class CourseImportModule {}
