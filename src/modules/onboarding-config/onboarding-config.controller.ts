import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { Public } from '@base/decorator/public';
import { AuthGuard } from '@base/guard/auth.guard';

import { UpdateOnboardingConfigDto } from './dto/update-onboarding-config.dto';
import { OnboardingConfigService } from './onboarding-config.service';

@ApiTags('ONBOARDING-CONFIG')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'onboarding-config', version: '1' })
export class OnboardingConfigController {
  constructor(
    private readonly onboardingConfigService: OnboardingConfigService,
  ) {}

  // Public: the mobile app reads onboarding content during onboarding, before
  // an (anonymous) session token is guaranteed to be attached. PUT stays guarded.
  @Public()
  @Get('')
  getConfig() {
    return this.onboardingConfigService.getConfig();
  }

  @Put('')
  updateConfig(@Body() dto: UpdateOnboardingConfigDto) {
    return this.onboardingConfigService.updateConfig(dto);
  }
}
