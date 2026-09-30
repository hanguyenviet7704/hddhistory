import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsMongoId, IsOptional } from 'class-validator';

export class MarkCommunityNotificationReadDto {
  @ApiPropertyOptional({
    type: [String],
    description: 'Omit to mark every unread notification as read',
  })
  @IsOptional()
  @IsArray()
  @IsMongoId({ each: true })
  ids?: string[];
}
