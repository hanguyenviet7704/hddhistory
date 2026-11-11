import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AnalyticsModule } from 'src/modules/analytics/analytics.module';
import { CourseModule } from 'src/modules/courses/src/modules/course/course.module';
import { UserProgressModule } from 'src/modules/courses/src/modules/progress/src/modules/user-progress/user-progress.module';
import { WeekRecapModule } from 'src/modules/courses/src/modules/progress/src/modules/week-recap/week-recap.module';
import { QuoteModule } from 'src/modules/courses/src/modules/quotes/quote.module';
import { CategoryModule } from 'src/modules/courses/src/modules/category/category.module';
import { UserHabitModule } from 'src/modules/habit/src/modules/user-habit/user-habit.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { NotificationCampaignService } from './notification-campaign.service';
import { NotificationDispatchService } from './notification-dispatch.service';
import { NotificationLogService } from './notification-log.service';
import { NotificationTemplateService } from './notification-template.service';
import { NotificationController } from './notification.controller';
import { NotificationScheduler } from './notification.scheduler';
import { NotificationCampaignSendRepository } from './repository/notification-campaign-send.repository';
import { NotificationCampaignRepository } from './repository/notification-campaign.repository';
import { NotificationLogRepository } from './repository/notification-log.repository';
import {
  NotificationCampaignSend,
  NotificationCampaignSendSchema,
} from './schema/notification-campaign-send.schema';
import {
  NotificationCampaign,
  NotificationCampaignSchema,
} from './schema/notification-campaign.schema';
import { SegmentModule } from '../segment/segment.module';
import { NotificationTemplateRepository } from './repository/notification-template.repository';
import {
  NotificationLog,
  NotificationLogSchema,
} from './schema/notification-log.schema';
import {
  NotificationTemplate,
  NotificationTemplateSchema,
} from './schema/notification-template.schema';

/**
 * Scheduled notifications (daily remind, unfinished lesson, new course, habit
 * check-in).
 *
 * Reads other features through their exported repositories rather than owning
 * their collections — progress, courses, habits, quotes and users each stay the
 * single writer of their own data.
 */
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: NotificationTemplate.name, schema: NotificationTemplateSchema },
      { name: NotificationLog.name, schema: NotificationLogSchema },
      {
        name: NotificationCampaign.name,
        schema: NotificationCampaignSchema,
      },
      {
        name: NotificationCampaignSend.name,
        schema: NotificationCampaignSendSchema,
      },
    ]),
    // AuthModule also exports the shared FirebaseService instance — providing
    // FirebaseService here again would call admin.initializeApp() twice.
    forwardRef(() => AuthModule),
    UserProgressModule,
    WeekRecapModule,
    CourseModule,
    // Only for `{topic_name}`: the category title behind the course a
    // notification names. forwardRef because CategoryModule reaches back to
    // CourseModule, which this module also imports.
    forwardRef(() => CategoryModule),
    UserHabitModule,
    QuoteModule,
    // Segment targeting per notification type. forwardRef because SegmentModule
    // reaches back into AuthModule, which this module is already tangled with —
    // a plain import here is the kind of cycle Nest only reports at boot, never
    // at compile time.
    forwardRef(() => SegmentModule),
    // Only for the click count on the monitoring screen: it reads the app's
    // `noti_tap` events out of `user_events` through the exported
    // UserEventRepository. A PLAIN import, not forwardRef, on purpose —
    // AnalyticsModule does not reach back here, so there is no cycle to break,
    // and a forwardRef that isn't needed only hides a real one later.
    AnalyticsModule,
  ],
  controllers: [NotificationController],
  providers: [
    NotificationTemplateRepository,
    NotificationLogRepository,
    NotificationCampaignRepository,
    NotificationCampaignSendRepository,
    NotificationCampaignService,
    NotificationTemplateService,
    NotificationLogService,
    NotificationDispatchService,
    NotificationScheduler,
  ],
  exports: [NotificationTemplateService, NotificationDispatchService],
})
export class NotificationModule {}
