import { Module } from '@nestjs/common';

import { NotificationModule } from 'src/modules/notification/notification.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { CoachPlanReminderDispatcher } from './coach-plan-reminder.dispatcher';
import { CoachConfigModule } from '../config/coach-config.module';
import { CoachPlanModule } from '../plan/coach-plan.module';

@Module({
  imports: [CoachPlanModule, CoachConfigModule, NotificationModule, AuthModule],
  providers: [CoachPlanReminderDispatcher],
  exports: [CoachPlanReminderDispatcher],
})
export class CoachReminderModule {}
