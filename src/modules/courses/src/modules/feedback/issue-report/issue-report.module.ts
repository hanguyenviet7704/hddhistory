import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { IssueReportController } from './issue-report.controller';
import { IssueReportService } from './issue-report.service';
import { IssueReportRepository } from './repository/issue-report.repository';
import {
  IssueReport,
  IssueReportSchema,
} from './schema/issue-report.schema';
import { Course, CourseSchema } from '../../course/schema/course.schema';
import { Keypoint, KeypointSchema } from '../../keypoint/schema/keypoint.schema';
import { Lesson, LessonSchema } from '../../lesson/schema/lesson.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: IssueReport.name, schema: IssueReportSchema },
      { name: Course.name, schema: CourseSchema },
      { name: Keypoint.name, schema: KeypointSchema },
      { name: Lesson.name, schema: LessonSchema },
    ]),
    forwardRef(() => AuthModule),
    LoggerModule,
  ],
  controllers: [IssueReportController],
  providers: [IssueReportService, IssueReportRepository],
  exports: [IssueReportService, IssueReportRepository],
})
export class IssueReportModule {}
