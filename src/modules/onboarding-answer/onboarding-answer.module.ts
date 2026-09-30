import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { CourseModule } from 'src/modules/courses/src/modules/course/course.module';
import { NotificationModule } from 'src/modules/notification/notification.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { OnboardingAnswerController } from './onboarding-answer.controller';
import { OnboardingAnswerService } from './onboarding-answer.service';
import { OnboardingStudyReminderDispatcher } from './onboarding-study-reminder.dispatcher';
import { OnboardingAnswerRepository } from './repository/onboarding-answer.repository';
import {
  OnboardingAnswer,
  OnboardingAnswerSchema,
} from './schema/onboarding-answer.schema';
import { OnboardingTaxonomyModule } from '../onboarding-taxonomy/onboarding-taxonomy.module';
import { SegmentModule } from '../segment/segment.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: OnboardingAnswer.name, schema: OnboardingAnswerSchema },
    ]),
    forwardRef(() => AuthModule),
    forwardRef(() => CourseModule),
    OnboardingTaxonomyModule,
    // Plain import: NotificationModule does not import back into this module.
    NotificationModule,
    // forwardRef: SegmentModule reaches back into AuthModule, which this module
    // is already tangled with — see NotificationModule's own note on the same
    // import.
    forwardRef(() => SegmentModule),
  ],
  controllers: [OnboardingAnswerController],
  providers: [
    OnboardingAnswerRepository,
    OnboardingAnswerService,
    OnboardingStudyReminderDispatcher,
  ],
  exports: [OnboardingAnswerRepository, OnboardingAnswerService],
})
export class OnboardingAnswerModule {}
