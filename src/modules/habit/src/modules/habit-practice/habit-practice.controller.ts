import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { GetListHabitPracticeDto } from './dto/habit-practice.dto';
import { SubmitHabitPracticeAttemptDto } from './dto/submit-habit-practice-attempt.dto';
import { HabitPracticeService } from './habit-practice.service';

/**
 * App-facing practice surface. Everything here answers for the caller: the read
 * returns published practices only, and both attempt routes resolve the adopted
 * habit through `findOneForUser` so one user can never touch another's.
 */
@ApiTags('HABIT-PRACTICES')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'habit-practices', version: '1' })
export class HabitPracticeController {
  constructor(private readonly svc: HabitPracticeService) {}

  @Get('')
  findForHabit(@Query() dto: GetListHabitPracticeDto) {
    return this.svc.findForHabit(dto);
  }

  // Declared before any future `:id` route so the static segment can't be
  // captured as an id.
  @Post('attempts')
  submitAttempt(@Body() dto: SubmitHabitPracticeAttemptDto) {
    return this.svc.submitAttempt(dto);
  }

  @Get('user-habits/:userHabitId/attempts')
  findMyAttempts(@Param('userHabitId') userHabitId: string) {
    return this.svc.findMyAttempts(userHabitId);
  }
}
