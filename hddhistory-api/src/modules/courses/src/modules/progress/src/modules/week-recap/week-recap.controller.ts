import { Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import {
  GetCurrentWeekRecapDto,
  GetWeekRecapArchiveDto,
} from './dto/week-recap.dto';
import { WeekRecapService } from './week-recap.service';

/**
 * "Hành trình tuần qua" and the "Sổ tay" it is filed into.
 *
 * Every route is the caller's own week — there is no id-based access to
 * anyone else's, and the service narrows by user rather than trusting the path.
 */
@ApiTags('COURSES-USER-PROGRESS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-user-progress', version: '1' })
export class WeekRecapController {
  constructor(private readonly svc: WeekRecapService) {}

  /** Last week's poster, plus whether the learner has any recap at all. */
  @Get('/week-recap/current')
  getCurrent(@Query() dto: GetCurrentWeekRecapDto) {
    return this.svc.getCurrent(dto);
  }

  @Get('/week-recap')
  getArchive(@Query() dto: GetWeekRecapArchiveDto) {
    return this.svc.getArchive(dto);
  }

  @Get('/week-recap/:id')
  getById(@Param('id') id: string) {
    return this.svc.getById(id);
  }

  /** "Xem hành trình" — the learner opened their week. */
  @Post('/week-recap/:id/viewed')
  markViewed(@Param('id') id: string) {
    return this.svc.markInteracted(id, 'viewedAt');
  }

  /** "Để sau" — silences the popup without claiming they looked. */
  @Post('/week-recap/:id/dismissed')
  markDismissed(@Param('id') id: string) {
    return this.svc.markInteracted(id, 'dismissedAt');
  }
}
