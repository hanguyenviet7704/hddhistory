import { Controller, Get, Param, Put, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CoachRatingService } from './coach-rating.service';
import { GetCoachRatingsDto } from './dto/coach-rating.dto';

/**
 * The thumb-down queue.
 *
 * Every one of them, unsampled. This feature talks to people about difficult
 * things and the volume is low enough that a person can read all of it — the
 * day that stops being true is the day to add sampling, not before.
 *
 * ## Why this is AuthGuard-only, not @Roles(ADMIN)
 *
 * The same reason every other admin controller here is — see
 * `user-habit-admin.controller.ts` for the long version. Nothing populates
 * `user.role` (the real admin account is `role: USER`), and `PUT /users/:id`
 * lets any caller set their own role behind `AuthGuard` alone, so the decorator
 * would 403 the admin panel and secure nothing. It is a real trust gap — this
 * one reads other people's words — but it is the SAME gap the whole admin
 * surface has, and closing it means fixing `PUT /users/:id` and the role data
 * first, then reinstating the guard everywhere at once.
 */
@ApiTags('COACH-RATINGS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'coach-ratings', version: '1' })
export class CoachRatingController {
  constructor(private readonly svc: CoachRatingService) {}

  @Get('')
  findAll(@Query() dto: GetCoachRatingsDto) {
    return this.svc.findForAdmin(dto);
  }

  @Put(':id/reviewed')
  @ApiOperation({ summary: 'Take a row off the queue once somebody has read it.' })
  markReviewed(@Param('id') id: string) {
    return this.svc.markReviewed(id);
  }
}
