import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { LoggerModule } from '@base/logging/logger.module';

import { OnboardingScenarioBranchingController } from './onboarding-scenario-branching.controller';
import { OnboardingController } from './onboarding.controller';
import { OnboardingService } from './onboarding.service';
import { OnboardingScenarioBranchingRepository } from './repository/onboarding-scenario-branching.repository';
import { OnboardingRepository } from './repository/onboarding.repository';
import { Onboarding, OnboardingSchema } from './schema/onboarding';
import {
  OnboardingScenarioBranching,
  OnboardingScenarioBranchingSchema,
} from './schema/onboarding-scenario-branching';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Onboarding.name, schema: OnboardingSchema },
      {
        name: OnboardingScenarioBranching.name,
        schema: OnboardingScenarioBranchingSchema,
      },
    ]),
    LoggerModule,
  ],
  controllers: [OnboardingController, OnboardingScenarioBranchingController],
  providers: [
    OnboardingService,
    OnboardingRepository,
    OnboardingScenarioBranchingRepository,
  ],
  exports: [
    OnboardingService,
    OnboardingRepository,
    OnboardingScenarioBranchingRepository,
  ],
})
export class OnboardingsModule {}
