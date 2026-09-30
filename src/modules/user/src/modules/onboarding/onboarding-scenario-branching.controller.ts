import { Body, Controller, Get, Param, Put } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { UpdateOnboardingScenarioBranchingDto } from './dto/update-onboarding-scenario-branching.dto';
import { OnboardingService } from './onboarding.service';

@ApiTags('ONBOARDINGS')
@Controller({ path: 'onboardings', version: '2' })
export class OnboardingScenarioBranchingController {
  constructor(private readonly svc: OnboardingService) {}

  @Put(':id')
  update(
    @Param('id') id: string,
    @Body() dto: UpdateOnboardingScenarioBranchingDto,
  ) {
    return this.svc.updateScenarioBranching(id, dto);
  }

  @Get('')
  find() {
    return this.svc.findScenarioBranching();
  }
}
