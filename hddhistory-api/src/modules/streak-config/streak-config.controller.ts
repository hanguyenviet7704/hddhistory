import { Body, Controller, Get, Header, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { Public } from '@base/decorator/public';
import { AuthGuard } from '@base/guard/auth.guard';

import { UpdateStreakConfigDto } from './dto/update-streak-config.dto';
import { StreakConfigService } from './streak-config.service';

/**
 * Controls when the streak popup appears in the app. The trigger used to be
 * hard-coded to "finished a keypoint"; it is now a configurable amount of
 * time spent in the app, so the timing can be tuned without an app release.
 */
@ApiTags('STREAK-CONFIG')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'streak-config', version: '1' })
export class StreakConfigController {
  constructor(private readonly svc: StreakConfigService) {}

  // Public: the app reads this on launch, before an anonymous session token
  // is guaranteed to be attached. It carries no user data. Short cache so a
  // change reaches the app quickly without every launch hitting Mongo.
  @Public()
  @Get('')
  @Header('Cache-Control', 'public, max-age=60')
  getConfig() {
    return this.svc.getConfig();
  }

  @Put('')
  updateConfig(@Body() dto: UpdateStreakConfigDto) {
    return this.svc.updateConfig(dto);
  }
}
