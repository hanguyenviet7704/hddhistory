import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { WarmUpService } from './warm-up.service';

@ApiTags('COURSES-WARM-UP')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'warm-up', version: '1' })
export class WarmUpController {
  constructor(private readonly warmUpService: WarmUpService) {}

  @Get('for-course/:courseId')
  getForCourse(@Param('courseId') courseId: string) {
    return this.warmUpService.getForCourse(courseId);
  }
}
