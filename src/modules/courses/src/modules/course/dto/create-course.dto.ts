import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsDate,
  IsEnum,
  IsInt,
  IsNotEmptyObject,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

import { PriceDto } from '@utils/dto/common.dto';
import { IsMultiLangString } from '@utils/dto/multi-languge';
import { OnboardingSymptom } from '@utils/enum/course.enum';

import { CourseStatus } from '../enum/course.enum';

export class CreateCourseDto {
  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Course Title', vi: 'Tiêu đề khóa học' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  title: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'Course Description', vi: 'Mô tả khóa học' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  description: Record<string, string>;

  @ApiPropertyOptional({ example: 'image1', required: false })
  @IsString()
  @IsOptional()
  image: string;

  @ApiPropertyOptional({ example: 'skillsetId', required: false })
  @IsString()
  @IsOptional()
  skillsetId: string;

  @ApiPropertyOptional({
    type: [String],
    enum: OnboardingSymptom,
    example: [OnboardingSymptom.MOTIVATION_DISAPPEARS],
    required: false,
    nullable: true,
    description: 'Onboarding symptoms used to match the course.',
  })
  @IsOptional()
  @IsArray()
  @IsEnum(OnboardingSymptom, { each: true })
  onboardingSymptoms?: OnboardingSymptom[] | null;

  @ApiPropertyOptional({ type: [String], example: ['CX01', 'CX03'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  onboardingLabelCodes?: string[];

  @ApiPropertyOptional({ type: [String], example: ['CX-1'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  onboardingDesireCodes?: string[];

  @ApiPropertyOptional({
    enum: CourseStatus,
    example: CourseStatus.DRAFT,
    required: false,
  })
  @IsOptional()
  @IsEnum(CourseStatus)
  status?: CourseStatus;

  @ApiPropertyOptional({
    type: String,
    format: 'date-time',
    required: false,
    nullable: true,
    example: '2026-07-01T00:00:00.000Z',
    description: 'Scheduled publish time (ISO 8601) for Coming Soon courses.',
  })
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  publishAt?: Date | null;

  @ApiPropertyOptional({
    type: Number,
    required: false,
    nullable: true,
    example: 7,
    description:
      'Days the "New course" badge stays after the course publishes (Coming Soon flow).',
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  newDurationDays?: number | null;

  @IsArray()
  @ApiPropertyOptional({
    type: [PriceDto],
    example: PriceDto,
    required: false,
  })
  @IsOptional()
  @Type(() => PriceDto)
  @ValidateNested({ each: true })
  prices: PriceDto[];

  @ApiPropertyOptional({ example: false, required: false })
  @IsOptional()
  @IsBoolean()
  isNew?: boolean;

  @ApiPropertyOptional({
    example: 'Sara Kim',
    description:
      'Author credit shown on the app\'s "New today" card. Free text, not ' +
      "translated — a person's name reads the same in every locale. Leave " +
      'empty to hide the credit.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  author?: string | null;

  @ApiPropertyOptional({
    example: 6300,
    description:
      'Reach figure shown next to the author. Curated here, never counted ' +
      'from progress data. Store the raw number — the app abbreviates 6300 ' +
      'to "6.3k". Leave empty to hide it.',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  viewCount?: number | null;

  @ApiPropertyOptional({
    type: [String],
    example: ['VN', 'JP'],
    description:
      'Markets this course is published to (ISO-3166 alpha-2). LEAVE EMPTY ' +
      'to publish everywhere — that is the default and what every existing ' +
      'course has. Normalised on write (upper-cased, de-duplicated, ' +
      'non-two-letter codes dropped), and matched against every market signal ' +
      'the viewer resolves to: IP country, device region, and app language — ' +
      'so VN also reaches a Vietnamese reader abroad. Hides the course from ' +
      'discovery only; it does not revoke a course already saved or in ' +
      'progress.',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  countries?: string[];
}
