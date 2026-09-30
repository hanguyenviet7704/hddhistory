import { Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { UserStreakService } from './user-streak.service';

@ApiTags('COURSES-USER-PROGRESS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-user-progress', version: '1' })
export class UserStreakController {
  constructor(private readonly userStreakService: UserStreakService) {}

  @Get('/streak')
  getStreak() {
    return this.userStreakService.getStreak();
  }

  /**
   * Marks today as a day the user showed up. The app calls this once a day,
   * after the reader has had it in the foreground for the number of seconds
   * configured in `streak-config`.
   *
   * Idempotent, so the app may safely retry: a second call the same day changes
   * nothing. Returns the updated streak, so the app can draw its toast from
   * this response instead of following up with a GET.
   */
  @Post('/streak/check-in')
  checkIn() {
    return this.userStreakService.markPresence();
  }
}
