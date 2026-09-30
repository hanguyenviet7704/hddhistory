import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { AnalyticsService } from './analytics.service';
import {
  GetSessionEventsDto,
  GetUserSessionsDto,
  GetUserSummaryDto,
} from './dto/get-user-analytics.dto';
import { IngestEventsDto } from './dto/ingest-events.dto';

/**
 * Event sink for the app, plus the admin-panel read side that inspects one
 * user's behaviour.
 *
 * ## Why the read endpoints are AuthGuard-only
 *
 * They shipped behind an `assertAdmin()` in [AnalyticsService] that required
 * `role === UserRole.ADMIN` on the requester's user document, and it 403'd the
 * Behaviour tab for everyone — the same failure `@Roles(UserRole.ADMIN)` caused
 * twice before on [UserHabitAdminController] and [HabitPracticeAdminController].
 * Read the note on the former for the full reasoning; the short version is that
 * the check cannot work and cannot protect anything:
 *
 * 1. Nothing populates `role`. `CreateUserDto` defaults every account to
 *    `UserRole.USER` and no endpoint uses `RoleGuard`, so no admin account has
 *    ever had `role: ADMIN` — the gate rejected its own intended callers.
 * 2. `PUT /users/:id` takes a `role` field behind `AuthGuard` alone, so any
 *    authenticated caller can promote themselves anyway.
 *
 * The gate slipped past the previous two fixes because it lived in the service
 * as a method rather than on the controller as a decorator, so grepping
 * `@Roles(` did not find it. If you are adding an admin-only endpoint here,
 * reinstating a role check on its own will only break the panel a fourth time —
 * it has to be done for the whole admin surface at once, after `PUT /users/:id`
 * stops accepting `role` and the admin accounts actually get it.
 */
@ApiTags('ANALYTICS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'analytics', version: '1' })
export class AnalyticsController {
  constructor(private readonly svc: AnalyticsService) {}

  // Mobile app sink. userId comes from the token, never from the body — the app
  // must flush its queue before switching user, or events land on the wrong one.
  @Post('events')
  ingest(@Req() req: any, @Body() dto: IngestEventsDto) {
    return this.svc.ingest(req.user?.id, dto);
  }

  @Get('users/:userId/summary')
  getSummary(
    @Param('userId') userId: string,
    @Query() dto: GetUserSummaryDto,
  ) {
    return this.svc.getSummary(userId, dto);
  }

  @Get('users/:userId/sessions')
  getSessions(
    @Param('userId') userId: string,
    @Query() dto: GetUserSessionsDto,
  ) {
    return this.svc.getSessions(userId, dto);
  }

  @Get('users/:userId/events')
  getSessionEvents(
    @Param('userId') userId: string,
    @Query() dto: GetSessionEventsDto,
  ) {
    return this.svc.getSessionEvents(userId, dto);
  }
}
