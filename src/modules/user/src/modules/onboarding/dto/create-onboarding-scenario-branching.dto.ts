import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsEnum,
  IsNotEmpty,
  IsNotEmptyObject,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  ValidateIf,
  ValidateNested,
} from 'class-validator';

import { LabelDto } from '@utils/dto/common.dto';
import { IsMultiLangString } from '@utils/dto/multi-languge';

import { OnboardingContentType } from '../interface/onboarding-scenario-branching.interface';

export class OnboardingScenarioBranchOptionDto {
  @ApiProperty({ example: 1 })
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Option A', vi: 'Lựa chọn A' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  label: Record<string, string>;

  @ApiProperty({ required: true, example: 'https://example.com/icon.png' })
  @IsOptional()
  @IsString()
  icon: string;

  @ApiPropertyOptional({ example: 'scene_2' })
  @IsOptional()
  @IsString()
  nextSceneId?: string;

  @IsArray()
  @IsOptional()
  @ApiPropertyOptional({
    type: [String],
    required: false,
    description: 'Courses for entry scene option only.',
  })
  @IsString({ each: true })
  courses?: string[];
}

export class OnboardingScenarioBranchDto {
  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Sub question', vi: 'Câu hỏi phụ' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  subQuestion: Record<string, string>;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'What will you do?', vi: 'Bạn sẽ làm gì?' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  question: Record<string, string>;

  @IsArray()
  @ArrayNotEmpty()
  @ApiProperty({
    type: [OnboardingScenarioBranchOptionDto],
    required: true,
  })
  @ValidateNested({ each: true })
  @Type(() => OnboardingScenarioBranchOptionDto)
  options: OnboardingScenarioBranchOptionDto[];
}

export class OnboardingScenarioFixedBranchDto {
  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Sub question', vi: 'Câu hỏi phụ' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  subQuestion: Record<string, string>;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'What will you do?', vi: 'Bạn sẽ làm gì?' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  question: Record<string, string>;

  @IsArray()
  @ArrayNotEmpty()
  @ApiProperty({
    type: [LabelDto],
    required: true,
  })
  @ValidateNested({ each: true })
  @Type(() => LabelDto)
  options: LabelDto[];
}

export class OnboardingScenarioPersonOptionDto {
  @ApiPropertyOptional({
    required: false,
    example: 'https://example.com/avatar.png',
  })
  @IsOptional()
  @IsString()
  image?: string;

  @ApiProperty({ required: true, example: 'Steve Jobs' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Co-founder of Apple', vi: 'Đồng sáng lập Apple' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  title: Record<string, string>;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Innovation and product mindset', vi: 'Tư duy sản phẩm' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  subTitle: Record<string, string>;
}

export class OnboardingScenarioPersonAdmireDto {
  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Sub question', vi: 'Câu hỏi phụ' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  subQuestion: Record<string, string>;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Who do you admire?', vi: 'Bạn ngưỡng mộ ai?' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  question: Record<string, string>;

  @IsArray()
  @ArrayNotEmpty()
  @ApiProperty({
    type: [OnboardingScenarioPersonOptionDto],
    required: true,
  })
  @ValidateNested({ each: true })
  @Type(() => OnboardingScenarioPersonOptionDto)
  options: OnboardingScenarioPersonOptionDto[];
}

export class OnboardingScenarioActivationContentDto {
  @ApiProperty({ required: true, example: 'https://example.com/icon.png' })
  @IsOptional()
  @IsString()
  icon: string;

  @IsArray()
  @ArrayNotEmpty()
  @ApiProperty({
    type: [LabelDto],
    required: true,
  })
  @ValidateNested({ each: true })
  @Type(() => LabelDto)
  labels: LabelDto[];
}

export class OnboardingScenarioActivationDto {
  @ApiProperty({ example: 1 })
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'Title', vi: 'Tiêu đề' },
  })
  @IsOptional()
  @IsObject()
  // @IsNotEmptyObject()
  @IsMultiLangString()
  title?: Record<string, string>;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Description', vi: 'Mô tả' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  description: Record<string, string>;

  @IsObject()
  @ApiProperty({ type: OnboardingScenarioActivationContentDto, required: true })
  @ValidateNested({ each: true })
  @Type(() => OnboardingScenarioActivationContentDto)
  content: OnboardingScenarioActivationContentDto;
}

export class OnboardingScenarioContentItemDto {
  @ApiProperty({ example: 1 })
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @ApiProperty({ enum: OnboardingContentType, required: true })
  @IsNotEmpty()
  @IsEnum(OnboardingContentType)
  type: OnboardingContentType;

  @ValidateIf(o => o.type === OnboardingContentType.FACT)
  @IsObject()
  @ApiPropertyOptional({ type: LabelDto, required: false })
  @ValidateNested({ each: true })
  @Type(() => LabelDto)
  fact?: LabelDto;

  @ValidateIf(o => o.type === OnboardingContentType.ACTIVATION)
  @IsObject()
  @ApiPropertyOptional({
    type: OnboardingScenarioActivationDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => OnboardingScenarioActivationDto)
  activation?: OnboardingScenarioActivationDto;

  @ValidateIf(o => o.type === OnboardingContentType.BRANCH)
  @IsObject()
  @ApiPropertyOptional({
    type: OnboardingScenarioBranchDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => OnboardingScenarioBranchDto)
  branch?: OnboardingScenarioBranchDto;

  @ValidateIf(o => o.type === OnboardingContentType.FIXED)
  @IsObject()
  @ApiPropertyOptional({
    type: OnboardingScenarioFixedBranchDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => OnboardingScenarioFixedBranchDto)
  fixed?: OnboardingScenarioFixedBranchDto;

  @ValidateIf(o => o.type === OnboardingContentType.PERSON_ADMIRE)
  @IsObject()
  @ApiPropertyOptional({
    type: OnboardingScenarioPersonAdmireDto,
    required: false,
  })
  @ValidateNested({ each: true })
  @Type(() => OnboardingScenarioPersonAdmireDto)
  personAdmire?: OnboardingScenarioPersonAdmireDto;
}

export class OnboardingScenarioSceneDto {
  @ApiProperty({ example: 'scene_1' })
  @IsNotEmpty()
  @IsString()
  id: string;

  @IsArray()
  @IsOptional()
  @ApiProperty({
    type: [OnboardingScenarioContentItemDto],
    required: true,
  })
  @ValidateNested({ each: true })
  @Type(() => OnboardingScenarioContentItemDto)
  contents: OnboardingScenarioContentItemDto[];
}

export class CreateOnboardingScenarioBranchingDto {
  @ApiProperty({ example: 'scene_1' })
  @IsOptional()
  @IsString()
  entrySceneId: string;

  @IsArray()
  @IsOptional()
  @ApiProperty({ type: [OnboardingScenarioSceneDto], required: true })
  @ValidateNested({ each: true })
  @Type(() => OnboardingScenarioSceneDto)
  scenes: OnboardingScenarioSceneDto[];
}
