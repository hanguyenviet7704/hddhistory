import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { InAppSurveyController } from './in-app-survey.controller';
import { InAppSurveyService } from './in-app-survey.service';
import { InAppSurveyConfigRepository } from './repository/in-app-survey-config.repository';
import { InAppSurveyResponseRepository } from './repository/in-app-survey-response.repository';
import { InAppSurveySessionRepository } from './repository/in-app-survey-session.repository';
import {
  InAppSurveyConfig,
  InAppSurveyConfigSchema,
} from './schema/in-app-survey-config.schema';
import {
  InAppSurveyResponse,
  InAppSurveyResponseSchema,
} from './schema/in-app-survey-response.schema';
import {
  InAppSurveySession,
  InAppSurveySessionSchema,
} from './schema/in-app-survey-session.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: InAppSurveyConfig.name, schema: InAppSurveyConfigSchema },
      { name: InAppSurveyResponse.name, schema: InAppSurveyResponseSchema },
      { name: InAppSurveySession.name, schema: InAppSurveySessionSchema },
    ]),
    forwardRef(() => AuthModule),
    LoggerModule,
  ],
  controllers: [InAppSurveyController],
  providers: [
    InAppSurveyService,
    InAppSurveyConfigRepository,
    InAppSurveyResponseRepository,
    InAppSurveySessionRepository,
  ],
  exports: [
    InAppSurveyService,
    InAppSurveyConfigRepository,
    InAppSurveyResponseRepository,
    InAppSurveySessionRepository,
  ],
})
export class InAppSurveyModule {}
