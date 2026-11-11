import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsDate, IsMongoId, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateCommunitySanctionDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsMongoId()
  userId: string;

  @ApiPropertyOptional({
    description: 'Omit for an indefinite mute',
  })
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  mutedUntil?: Date;

  @ApiProperty({ description: 'Shown to the reader when they try to post' })
  @IsNotEmpty()
  @IsString()
  @MaxLength(500)
  reason: string;
}
