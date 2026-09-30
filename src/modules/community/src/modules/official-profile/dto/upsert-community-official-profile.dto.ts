import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class UpsertCommunityOfficialProfileDto {
  @ApiPropertyOptional({
    description:
      'Leave empty to keep the app\'s own localised wording ("Đội ngũ HDDhistory").',
  })
  @IsOptional()
  @IsString()
  @MaxLength(60)
  name?: string;

  @ApiPropertyOptional({ description: 'Public image URL, R2 or otherwise.' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  avatar?: string;
}
