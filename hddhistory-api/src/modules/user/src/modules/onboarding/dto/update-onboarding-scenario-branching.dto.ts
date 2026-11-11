import { PartialType } from '@nestjs/swagger';

import { CreateOnboardingScenarioBranchingDto } from './create-onboarding-scenario-branching.dto';

export class UpdateOnboardingScenarioBranchingDto extends PartialType(
  CreateOnboardingScenarioBranchingDto,
) {}
