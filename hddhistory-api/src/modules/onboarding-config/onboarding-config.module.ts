import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { OnboardingConfigController } from './onboarding-config.controller';
import { OnboardingConfigService } from './onboarding-config.service';
import { OnboardingConfigRepository } from './repository/onboarding-config.repository';
import {
  OnboardingConfig,
  OnboardingConfigSchema,
} from './schema/onboarding-config.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: OnboardingConfig.name, schema: OnboardingConfigSchema },
    ]),
    forwardRef(() => AuthModule),
  ],
  controllers: [OnboardingConfigController],
  providers: [OnboardingConfigService, OnboardingConfigRepository],
  exports: [OnboardingConfigService, OnboardingConfigRepository],
})
export class OnboardingConfigModule {}
