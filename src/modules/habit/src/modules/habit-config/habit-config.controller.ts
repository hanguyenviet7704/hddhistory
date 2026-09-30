import { Body, Controller, Get, Put, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';

import { AuthGuard } from '@base/guard/auth.guard';
import { IUser } from 'src/modules/user/src/modules/auth/interface/user.interface';

import { UpdateHabitConfigDto } from './dto/update-habit-config.dto';
import { HabitConfigService } from './habit-config.service';

@ApiTags('HABIT-CONFIG')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'habit-config', version: '1' })
export class HabitConfigController {
  constructor(private readonly habitConfigService: HabitConfigService) {}

  @Get('')
  getConfig() {
    return this.habitConfigService.getConfig();
  }

  @Put('')
  updateConfig(
    @Body() dto: UpdateHabitConfigDto,
    @Req() req: Request & { user?: IUser },
  ) {
    return this.habitConfigService.updateConfig(dto, req.user);
  }
}
