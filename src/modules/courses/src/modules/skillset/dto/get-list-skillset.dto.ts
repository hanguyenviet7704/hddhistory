import {
  ApiProperty,
  ApiPropertyOptional,
  IntersectionType,
} from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

import { ToBoolean } from '@utils/boolean.utils';
import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import {
  SkillsetOnboardingIntroduce,
  SkillsetStatus,
} from '../enum/skillset.enum';

export class GetListSkillsetDto extends IntersectionType(PageOptionsDto) {
  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  page: number;

  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  take: number;

  @ApiPropertyOptional({ enum: SkillsetStatus })
  @IsOptional()
  @IsEnum(SkillsetStatus)
  status?: SkillsetStatus = SkillsetStatus.PUBLISHED;

  @ApiPropertyOptional({
    type: [String],
    example: [SkillsetOnboardingIntroduce.MY_FEELINGS_FEEL_LOUD],
    description:
      'Filter skillsets by one or more onboarding introduce options.',
  })
  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined || value === null || value === '') return undefined;
    return Array.isArray(value) ? value : [value];
  })
  @IsArray()
  @IsString({ each: true })
  onboardingIntroduces?: string[];

  @ApiProperty({ type: Boolean, example: true, required: false })
  @IsOptional()
  @IsBoolean()
  @ToBoolean()
  isAll: boolean;
}
