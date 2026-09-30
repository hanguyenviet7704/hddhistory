import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { OnboardingScenarioBranching } from '../schema/onboarding-scenario-branching';

@Injectable()
export class OnboardingScenarioBranchingRepository extends AbstractRepository<OnboardingScenarioBranching> {
  protected readonly logger = new Logger(
    OnboardingScenarioBranchingRepository.name,
  );

  constructor(
    @InjectModel(OnboardingScenarioBranching.name)
    model: Model<OnboardingScenarioBranching>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }
}
