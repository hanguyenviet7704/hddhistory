import * as fs from 'fs';
import * as path from 'path';

import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { ScheduleModule } from '@nestjs/schedule';
import { HeaderResolver, I18nModule } from 'nestjs-i18n/dist';

import { ConfigurationProvider } from '@base/config/configuration.provider';
import { MongoDbModule } from '@base/database/mongodb/mongodb.module';
import { LoggerModule } from '@base/logging/logger.module';
import { RequestContextMiddleware } from '@base/middleware/request-context.middleware';
import { GlobalModule } from '@base/service/global.module';

import { AdminAuditInterceptor } from './modules/admin-audit/admin-audit.interceptor';
import { AdminAuditModule } from './modules/admin-audit/admin-audit.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { ChatModule } from './modules/chat/chat.module';
import { CoachModule } from './modules/coach/coach.module';
import { CommunityModule } from './modules/community/community.module';
import { CoursesModule } from './modules/courses/src/modules/courses.module';
import { DeeplinkModule } from './modules/deeplink/deeplink.module';
import { DownloadLinkModule } from './modules/download-link/download-link.module';
import { FileModule } from './modules/file/file.module';
import { HabitModule } from './modules/habit/habit.module';
import { HomeBannerModule } from './modules/home-banner/home-banner.module';
import { HomePopupModule } from './modules/home-popup/home-popup.module';
import { KeypointAccessModule } from './modules/keypoint-access/keypoint-access.module';
import { KnowledgeGraphModule } from './modules/knowledge-graph/knowledge-graph.module';
import { NotificationModule } from './modules/notification/notification.module';
import { OnboardingAnswerModule } from './modules/onboarding-answer/onboarding-answer.module';
import { OnboardingConfigModule } from './modules/onboarding-config/onboarding-config.module';
import { OnboardingTaxonomyModule } from './modules/onboarding-taxonomy/onboarding-taxonomy.module';
import { PaymentModule } from './modules/payment/payment.module';
import { PaywallConfigModule } from './modules/paywall-config/paywall-config.module';
import { SegmentModule } from './modules/segment/segment.module';
import { SocketModule } from './modules/socket/socket.module';
import { StreakConfigModule } from './modules/streak-config/streak-config.module';
import { StudyThemeModule } from './modules/study-theme/study-theme.module';
import { UserModule } from './modules/user/user.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    ScheduleModule.forRoot(),
    I18nModule.forRoot({
      fallbackLanguage: 'en',
      loaderOptions: {
        path: fs.existsSync(path.join(__dirname, 'base', 'i18n'))
          ? path.join(__dirname, 'base', 'i18n') // chạy trong dist (Docker, prod)
          : path.join(process.cwd(), 'src', 'base', 'i18n'), // chạy dev
        watch: true,
      },
      resolvers: [new HeaderResolver(['lang'])],
    }),
    MongoDbModule,
    UserModule,
    ChatModule,
    SocketModule,
    GlobalModule,
    CoursesModule,
    FileModule,
    PaymentModule,
    HabitModule,
    CoachModule,
    OnboardingConfigModule,
    OnboardingTaxonomyModule,
    OnboardingAnswerModule,
    PaywallConfigModule,
    DownloadLinkModule,
    DeeplinkModule,
    HomeBannerModule,
    HomePopupModule,
    SegmentModule,
    KeypointAccessModule,
    KnowledgeGraphModule,
    StreakConfigModule,
    NotificationModule,
    StudyThemeModule,
    CommunityModule,
    AnalyticsModule,
    AdminAuditModule,
    LoggerModule,
  ],
  providers: [
    ConfigurationProvider,
    /**
     * Nhật ký thao tác admin, gắn toàn cục.
     *
     * Đăng ký ở ĐÂY chứ không ở `main.ts`: chỗ đó dựng interceptor bằng `new`
     * nên không tiêm được repository. `APP_INTERCEPTOR` là đường duy nhất cho
     * một interceptor toàn cục có phụ thuộc.
     */
    { provide: APP_INTERCEPTOR, useClass: AdminAuditInterceptor },
  ],
  exports: [ConfigurationProvider],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(RequestContextMiddleware).forRoutes('*');
  }
}
