import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { OutputPracticeConversationController } from './output-practice-conversation.controller';
import { OutputPracticeConversationService } from './output-practice-conversation.service';
import { OutputPracticeConversationRepository } from './repository/output-practice-conversation.repository';
import {
  OutputPracticeConversation,
  OutputPracticeConversationSchema,
} from './schema/output-practice-conversation.schema';
import { CourseModule } from '../../course/course.module';
import { CourseVersionModule } from '../../course-version/course-version.module';
import { LearningImportModule } from '../../learning-import/learning-import.module';
import { LessonModule } from '../../lesson/lesson.module';
import { OutputPracticeAiModule } from '../ai/output-practice-ai.module';
import { OutputPracticeMessageModule } from '../message/output-practice-message.module';
import { OutputPracticeUsageModule } from '../usage/output-practice-usage.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      {
        name: OutputPracticeConversation.name,
        schema: OutputPracticeConversationSchema,
      },
    ]),
    forwardRef(() => AuthModule),
    forwardRef(() => CourseModule),
    forwardRef(() => LessonModule),
    // UserLessonPracticeService only — the prompt for a lesson the reader
    // generated. forwardRef because both modules sit under `courses` and the
    // import graph there already loops through CourseModule.
    forwardRef(() => LearningImportModule),
    // ContentSource: AIConfig của bài OUTPUT đọc theo tag đang phát hành.
    // Phải import Ở ĐÂY, không phải ở OutputPracticeModule: module này mới là
    // chỗ khai báo OutputPracticeConversationService, và scope của provider
    // tính theo module khai báo nó.
    forwardRef(() => CourseVersionModule),
    OutputPracticeAiModule,
    OutputPracticeUsageModule,
    forwardRef(() => OutputPracticeMessageModule),
    LoggerModule,
  ],
  controllers: [OutputPracticeConversationController],
  providers: [
    OutputPracticeConversationService,
    OutputPracticeConversationRepository,
  ],
  exports: [
    OutputPracticeConversationService,
    OutputPracticeConversationRepository,
  ],
})
export class OutputPracticeConversationModule {}
