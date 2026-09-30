import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';
import {
  User,
  UserSchema,
} from 'src/modules/user/src/modules/auth/schema/user.schema';

import { AnalyticsDashboardController } from './analytics-dashboard.controller';
import { AnalyticsDashboardService } from './analytics-dashboard.service';
import { AnalyticsRollupService } from './analytics-rollup.service';
import { AnalyticsController } from './analytics.controller';
import { AnalyticsService } from './analytics.service';
import { CoachDashboardService } from './coach-dashboard.service';
import { AnalyticsDailyRepository } from './repository/analytics-daily.repository';
import { AnalyticsDashboardRepository } from './repository/analytics-dashboard.repository';
import { CoachDashboardRepository } from './repository/coach-dashboard.repository';
import { UserEventRepository } from './repository/user-event.repository';
import {
  AnalyticsDaily,
  AnalyticsDailySchema,
} from './schema/analytics-daily.schema';
import { UserEvent, UserEventSchema } from './schema/user-event.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: UserEvent.name, schema: UserEventSchema },
      { name: AnalyticsDaily.name, schema: AnalyticsDailySchema },
      // The dashboard's user counts and retention cohorts are anchored on
      // `users.createdAt`, so this module reads the users collection directly
      // rather than routing every cohort query through the auth module.
      { name: User.name, schema: UserSchema },
    ]),
    forwardRef(() => AuthModule),
    LoggerModule,
  ],
  controllers: [AnalyticsController, AnalyticsDashboardController],
  providers: [
    AnalyticsService,
    AnalyticsDashboardService,
    AnalyticsRollupService,
    CoachDashboardService,
    UserEventRepository,
    AnalyticsDashboardRepository,
    AnalyticsDailyRepository,
    CoachDashboardRepository,
  ],
  exports: [AnalyticsService, UserEventRepository, AnalyticsRollupService],
})
export class AnalyticsModule {}
