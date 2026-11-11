import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CoachMetricService } from './coach-metric.service';
import { GetCoachMetricsDto } from './dto/coach-metric.dto';

/**
 * The Coach's own counters, read side.
 *
 * These have been written since the Coach shipped and nothing has ever been
 * able to read them — the module had a service and a repository but no way out.
 * They answer what the app's event stream cannot: whether the MODEL is
 * misbehaving (banned questions, echoed lines, rejected drafts), which is
 * invisible from the client because the client only sees what got through.
 *
 * Weekly and with no user attached, by design — a rate, never a record.
 *
 * ## Why this is AuthGuard-only, not @Roles(ADMIN)
 *
 * Same reason as every other admin controller here; see
 * `coach-rating.controller.ts` for the long version. Nothing populates
 * `user.role`, so the decorator would 403 the admin panel and secure nothing.
 */
@ApiTags('COACH-METRICS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'coach-metrics', version: '1' })
export class CoachMetricController {
  constructor(private readonly svc: CoachMetricService) {}

  @Get('')
  @ApiOperation({
    summary: 'One ISO week of Coach counters, labelled, plus the weeks on file',
  })
  findForAdmin(@Query() dto: GetCoachMetricsDto) {
    return this.svc.findForAdmin(dto);
  }
}
