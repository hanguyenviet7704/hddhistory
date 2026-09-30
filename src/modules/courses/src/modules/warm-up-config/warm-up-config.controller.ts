import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { UpdateWarmUpConfigDto } from './dto/update-warm-up-config.dto';
import { WarmUpConfigService } from './warm-up-config.service';

@ApiTags('COURSES-WARM-UP-CONFIG')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'warm-up-config', version: '1' })
export class WarmUpConfigController {
  constructor(private readonly warmUpConfigService: WarmUpConfigService) {}

  @Get('')
  getConfig() {
    return this.warmUpConfigService.getConfig();
  }

  @Put('')
  updateConfig(@Body() dto: UpdateWarmUpConfigDto) {
    return this.warmUpConfigService.updateConfig(dto);
  }
}
