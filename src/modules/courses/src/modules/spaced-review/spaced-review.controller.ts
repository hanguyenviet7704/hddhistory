import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { SubmitSpacedReviewDto } from './dto/spaced-review.dto';
import { SpacedReviewService } from './spaced-review.service';

@ApiTags('COURSES-SPACED-REVIEW')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'spaced-review', version: '1' })
export class SpacedReviewController {
  constructor(private readonly spacedReviewService: SpacedReviewService) {}

  @Get('today')
  getToday() {
    return this.spacedReviewService.getToday();
  }

  @Post('answers')
  submit(@Body() dto: SubmitSpacedReviewDto) {
    return this.spacedReviewService.submit(dto);
  }
}
