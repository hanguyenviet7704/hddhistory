import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';

import { IsMultiLangString } from '@utils/dto/multi-languge';

import {
  RoleplayContentType,
  RoleplayConversationPosition,
} from '../../enum/learning-item.enum';
import { ExerciseDragDropDto } from '../excercises/drag-drop.dto';
import { ExerciseMultipleChoiceDto } from '../excercises/multiple-choice.dto';
import { ExerciseRecordDto } from '../excercises/record.dto';
import { ExerciseSingleChoiceNoCorrectAnswerDto } from '../excercises/single-choice-no-correct-answer.dto';
import { ExerciseSingleChoiceDto } from '../excercises/single-choice.dto';

export class RoleplayConversationDto {
  @ApiProperty({ required: true, example: '691a96f89fee38c816d672e6' })
  @IsNotEmpty()
  @IsString()
  avatarId: string;

  @ApiProperty({
    enum: RoleplayConversationPosition,
    example: RoleplayConversationPosition.LEFT,
    required: true,
  })
  @IsOptional()
  @IsEnum(RoleplayConversationPosition)
  position: string;

  @ApiProperty({ required: false, example: '#47645' })
  @IsOptional()
  @IsString()
  backgroundColor: string;

  @ApiProperty({ required: true, example: '#76588' })
  @IsOptional()
  @IsString()
  textColor: string;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'http://example.com', vi: 'http://example.com' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  audio: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: {
      en: 'Content of conversation',
      vi: 'Nội dung của cuộc hội thoại',
    },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  content: Record<string, string>;
}

export class RoleplayLeadingTextDto {
  @ApiProperty({ required: true, example: '#d87r57' })
  @IsNotEmpty()
  @IsString()
  backgroundColor: string;

  @ApiProperty({ required: true, example: '#76588' })
  @IsOptional()
  @IsString()
  textColor: string;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'Content of leading text', vi: 'Nội dung leading text' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  content: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'http://example.com', vi: 'http://example.com' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  audio: Record<string, string>;
}

export class RoleplayTransitionDto {
  @ApiProperty({ required: true, example: '#76588' })
  @IsOptional()
  @IsString()
  textColor: string;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'Content of transition', vi: 'Nội dung của transition' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  content: Record<string, string>;
}

export class MissionDto {
  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'Content of mission', vi: 'Nội dung của mission' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  content: Record<string, string>;
}

export class RoleplayContentDto {
  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @ApiProperty({
    enum: RoleplayContentType,
    example: RoleplayContentType.CONVERSATION,
    required: true,
  })
  @IsOptional()
  @IsEnum(RoleplayContentType)
  type: RoleplayContentType;

  @IsObject()
  @ApiPropertyOptional({
    type: RoleplayConversationDto,
    example: RoleplayConversationDto,
    required: false,
  })
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => RoleplayConversationDto)
  conversation: RoleplayConversationDto;

  @IsObject()
  @ApiPropertyOptional({
    type: RoleplayLeadingTextDto,
    example: RoleplayLeadingTextDto,
    required: false,
  })
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => RoleplayLeadingTextDto)
  leadingText: RoleplayLeadingTextDto;

  @IsObject()
  @ApiPropertyOptional({
    type: RoleplayTransitionDto,
    example: RoleplayTransitionDto,
    required: false,
  })
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => RoleplayTransitionDto)
  transition: RoleplayTransitionDto;

  @IsObject()
  @ApiPropertyOptional({
    type: ExerciseDragDropDto,
    example: ExerciseDragDropDto,
    required: false,
  })
  @Type(
    () =>
      ExerciseDragDropDto ||
      ExerciseSingleChoiceDto ||
      ExerciseMultipleChoiceDto ||
      ExerciseSingleChoiceNoCorrectAnswerDto ||
      ExerciseRecordDto,
  )
  @IsOptional()
  // @ValidateNested({ each: true })
  exercise:
    | ExerciseDragDropDto
    | ExerciseSingleChoiceDto
    | ExerciseMultipleChoiceDto
    | ExerciseSingleChoiceNoCorrectAnswerDto
    | ExerciseRecordDto;
}

export class RoleplayDto {
  @ApiProperty({ required: true, example: 'https://example.com' })
  @IsOptional()
  @IsString()
  image: string;

  @IsArray()
  @ApiPropertyOptional({
    type: [RoleplayContentDto],
    example: RoleplayContentDto,
    required: false,
  })
  @Type(() => RoleplayContentDto)
  @IsOptional()
  @ValidateNested({ each: true })
  contents: RoleplayContentDto[];

  @IsArray()
  @ApiPropertyOptional({
    type: [MissionDto],
    example: MissionDto,
    required: false,
  })
  @Type(() => MissionDto)
  @IsOptional()
  @ValidateNested({ each: true })
  missions: MissionDto[];

  @ApiProperty({ required: false, example: '691d7d9ebf638100fb75361b' })
  @IsOptional()
  @IsString()
  colorTemplateId: string;
}
