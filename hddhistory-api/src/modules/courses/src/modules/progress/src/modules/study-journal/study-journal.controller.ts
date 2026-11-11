import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { GetStudyJournalDayDto, GetStudyJournalDto } from './dto/study-journal.dto';
import { StudyJournalService } from './study-journal.service';

/**
 * The Profile screen's "Nhật ký học tập" calendar: which days the learner
 * studied, how much, and what they studied on a given day.
 */
@ApiTags('COURSES-USER-PROGRESS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-user-progress', version: '1' })
export class StudyJournalController {
  constructor(private readonly svc: StudyJournalService) {}

  @Get('/study-journal')
  getMonth(@Query() dto: GetStudyJournalDto) {
    return this.svc.getMonth(dto);
  }

  @Get('/study-journal/day')
  getDay(@Query() dto: GetStudyJournalDayDto) {
    return this.svc.getDay(dto);
  }
}
