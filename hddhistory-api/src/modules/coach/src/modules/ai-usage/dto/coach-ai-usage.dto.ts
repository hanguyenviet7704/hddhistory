import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, Matches } from 'class-validator';

export class GetCoachAiUsageDto {
  @ApiPropertyOptional({
    example: '2026-08-01',
    description:
      'Ngày bắt đầu (server time), YYYY-MM-DD. Bỏ trống = 29 ngày trước hôm nay.',
  })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'from must be YYYY-MM-DD' })
  from?: string;

  @ApiPropertyOptional({
    example: '2026-08-28',
    description: 'Ngày kết thúc (server time), YYYY-MM-DD. Bỏ trống = hôm nay.',
  })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'to must be YYYY-MM-DD' })
  to?: string;
}
