import { ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { IsNumber, IsOptional } from 'class-validator';

import { CreateSkillsetDto } from './create-skillset.dto';

export class UpdateSkillsetDto extends PartialType(CreateSkillsetDto) {
  @ApiPropertyOptional({ example: 1, required: false })
  @IsOptional()
  @IsNumber()
  index?: number;
}
