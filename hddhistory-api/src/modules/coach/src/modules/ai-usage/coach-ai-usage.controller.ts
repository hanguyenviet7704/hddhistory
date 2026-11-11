import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CoachAiUsageService } from './coach-ai-usage.service';
import { GetCoachAiUsageDto } from './dto/coach-ai-usage.dto';

/**
 * What the coach's AI has cost.
 *
 * `AuthGuard`-only for the same reason every other admin controller in this
 * feature is — see the long note on `CoachRatingController`.
 */
@ApiTags('COACH-AI-USAGE')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'coach-ai-usage', version: '1' })
export class CoachAiUsageController {
  constructor(private readonly svc: CoachAiUsageService) {}

  @Get('summary')
  @ApiOperation({
    summary: 'Tiền và token đã tiêu, tách theo loại lệnh gọi, model và ngày.',
    description:
      'Chỉ tính từ lúc tính năng đo được deploy — token của các phiên chạy trước đó không lưu ở đâu nên không dựng lại được.',
  })
  summary(@Query() dto: GetCoachAiUsageDto) {
    return this.svc.summaryForAdmin(dto);
  }
}
