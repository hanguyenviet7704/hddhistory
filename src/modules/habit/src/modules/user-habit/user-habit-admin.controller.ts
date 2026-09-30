import { Controller, Get, Param, Query, Res, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Response } from 'express';

import { AuthGuard } from '@base/guard/auth.guard';

import {
  GetAdminUserHabitDetailDto,
  GetAdminUserHabitsDto,
} from './dto/get-admin-user-habits.dto';
import { GetHabitCheckinStatisticsDto } from './dto/get-habit-checkin-statistics.dto';
import { UserHabitAdminService } from './user-habit-admin.service';

/**
 * Admin-only insight into real habit usage — including the journal text users
 * write. Split out from [UserHabitController] so the trust boundary is visible
 * in the file layout: everything in that controller answers for the caller,
 * everything here reads across all users.
 *
 * ## Why this is AuthGuard-only, not @Roles(ADMIN)
 *
 * It shipped gated on `@Roles(UserRole.ADMIN)`, which turned out to be wrong in
 * two independent ways:
 *
 * 1. Nothing populates `role`. `CreateUserDto` defaults every account to
 *    `UserRole.USER`, and no other endpoint in the codebase uses `RoleGuard`, so
 *    the field has never been enforced or maintained. The actual admin account is
 *    `role: USER` — so the gate 403'd the admin page this controller exists to
 *    serve ("Admin role required"), for everyone.
 * 2. `PUT /users/:id` accepts a `role` field behind `AuthGuard` alone, so any
 *    authenticated caller can promote themselves. A role check cannot mean
 *    anything while that is true.
 *
 * So this matches every other admin endpoint here: `AuthGuard` only. That is a
 * real trust gap — these handlers read every user's habit data, journal text
 * included — but it is the SAME gap the rest of the admin surface already has,
 * and pretending otherwise with an unenforceable decorator only broke the panel.
 * Closing it properly means: fix `PUT /users/:id`, give the admin accounts
 * `role: ADMIN`, then reinstate the guard here and across the other admin
 * endpoints together.
 */
@ApiTags('USER-HABITS-ADMIN')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'user-habits/admin', version: '1' })
export class UserHabitAdminController {
  constructor(private readonly svc: UserHabitAdminService) {}

  @Get('')
  findUserSummaries(@Query() dto: GetAdminUserHabitsDto) {
    return this.svc.findUserSummaries(dto);
  }

  // Above `users/:userId` is not strictly required (different segment count),
  // but keeping specific paths first matches the rest of the codebase and
  // survives someone later adding a `:id` route here.
  @Get('statistics/overview')
  getCheckinStatistics(@Query() dto: GetHabitCheckinStatisticsDto) {
    return this.svc.getCheckinStatistics(dto);
  }

  /**
   * The statistics tab as an .xlsx. `@Res()` (not a StreamableFile) so the
   * binary bypasses the global ResponseInterceptor — wrapped in that envelope a
   * workbook arrives as corrupt JSON, which is how the lesson-feedback export
   * does it too.
   */
  @Get('statistics/export')
  async exportCheckinStatistics(
    @Query() dto: GetHabitCheckinStatisticsDto,
    @Res() res: Response,
  ) {
    const buffer = await this.svc.exportCheckinStatisticsWorkbook(dto);
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="habit-checkins.xlsx"',
    );
    res.send(buffer);
  }

  @Get('users/:userId')
  findUserDetail(
    @Param('userId') userId: string,
    @Query() dto: GetAdminUserHabitDetailDto,
  ) {
    return this.svc.findUserDetail(userId, dto);
  }
}
