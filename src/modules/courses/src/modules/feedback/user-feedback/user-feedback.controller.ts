import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Put,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Response } from 'express';

import { AuthGuard } from '@base/guard/auth.guard';

import { UpsertUserFeedbackDto } from './dto/upsert-user-feedback.dto';
import {
  GetUserFeedbackCommentsDto,
  GetUserFeedbackStatisticsDto,
} from './dto/user-feedback-statistics.dto';
import { FeedbackService } from './user-feedback.service';

@ApiTags('COURSES-FEEDBACK')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-feedback', version: '1' })
export class FeedbackController {
  constructor(private readonly svc: FeedbackService) {}

  @Put('')
  upsert(@Body() dto: UpsertUserFeedbackDto) {
    return this.svc.upsert(dto);
  }

  @Get('/me')
  myFeedback() {
    return this.svc.myFeedback();
  }

  // MUST stay above `@Get(':userId')`: Nest matches in declaration order, so a
  // statistics route declared after it arrives as userId="statistics".
  @Get('statistics/overview')
  getStatisticsOverview(@Query() dto: GetUserFeedbackStatisticsDto) {
    return this.svc.getStatisticsOverview(dto);
  }

  @Get('statistics/export')
  async exportStatistics(
    @Query() dto: GetUserFeedbackStatisticsDto,
    @Res() res: Response,
  ) {
    const buffer = await this.svc.exportStatisticsWorkbook(dto);
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="lesson-feedback.xlsx"',
    );
    res.send(buffer);
  }

  @Get('statistics/comments')
  getStatisticsComments(@Query() dto: GetUserFeedbackCommentsDto) {
    return this.svc.getStatisticsComments(dto);
  }

  @Get(':userId')
  getByUserId(@Param('userId') userId: string) {
    return this.svc.getFeedbackByUserId(userId);
  }

  @Delete(':userId')
  deleteByUserId(@Param('userId') userId: string) {
    return this.svc.deleteByUserId(userId);
  }
}
