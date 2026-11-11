import { PartialType } from '@nestjs/swagger';

import { CreateOnboardingConfigDto } from './create-onboarding-config.dto';

export class UpdateOnboardingConfigDto extends PartialType(
  CreateOnboardingConfigDto,
) {}
