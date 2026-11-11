import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { AnalyticsDashboardService } from './analytics-dashboard.service';
import { CoachDashboardService } from './coach-dashboard.service';
import { GetDashboardDto } from './dto/get-dashboard.dto';

/**
 * Read side of the admin product dashboard — one route per sidebar entry, so
 * moving between pages fetches only what that page shows.
 *
 * Guarded by `AuthGuard` alone, matching the rest of the admin surface. See the
 * docblock on [AnalyticsController] for why a role check here would break the
 * panel rather than protect it.
 */
@ApiTags('ANALYTICS DASHBOARD')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'analytics/dashboard', version: '1' })
export class AnalyticsDashboardController {
  constructor(
    private readonly svc: AnalyticsDashboardService,
    private readonly coach: CoachDashboardService,
  ) {}

  @Get('overview')
  @ApiOperation({ summary: 'Weekly report: one headline number per area' })
  getOverview(@Query() dto: GetDashboardDto) {
    return this.svc.getOverview(dto);
  }

  @Get('users')
  @ApiOperation({ summary: 'Active / new / returning users and D1-D7 retention' })
  getUsers(@Query() dto: GetDashboardDto) {
    return this.svc.getUsers(dto);
  }

  @Get('sessions')
  @ApiOperation({ summary: 'Sessions, engagement rate, depth and peak hours' })
  getSessions(@Query() dto: GetDashboardDto) {
    return this.svc.getSessions(dto);
  }

  @Get('onboarding')
  @ApiOperation({ summary: 'Onboarding funnel by distinct users, step by step' })
  getOnboarding(@Query() dto: GetDashboardDto) {
    return this.svc.getOnboarding(dto);
  }

  @Get('learning')
  @ApiOperation({ summary: 'Learning milestones plus top courses and categories' })
  getLearning(@Query() dto: GetDashboardDto) {
    return this.svc.getLearning(dto);
  }

  /**
   * Lives here rather than under `coach/` because the numbers come from
   * `user_events` — the app's tracking stream, which the analytics module owns
   * and indexes. The Coach's own collections answer a different question.
   */
  @Get('coach')
  @ApiOperation({
    summary: 'AI Coach: doors, in-session turns, how sessions end, surfaces',
  })
  getCoach(@Query() dto: GetDashboardDto) {
    return this.coach.getStats(dto);
  }
}
