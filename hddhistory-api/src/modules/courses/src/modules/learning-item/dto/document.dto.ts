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
  Validate,
  ValidationArguments,
  ValidateNested,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';

import { IsMultiLangString } from '@utils/dto/multi-languge';

import { DocumentType } from '../enum/learning-item.enum';

@ValidatorConstraint({ name: 'documentDataByType', async: false })
class DocumentDataByTypeConstraint implements ValidatorConstraintInterface {
  validate(data: DocumentDataDto, args: ValidationArguments) {
    if (!data || typeof data !== 'object') return false;

    const document = args.object as DocumentDto;
    const isExplanation = document.type === DocumentType.EXPLANATION;
    const hasOptions = Array.isArray(data.options) && data.options.length > 0;

    if (isExplanation) {
      return hasOptions;
    }

    return data.options === undefined;
  }

  defaultMessage(args: ValidationArguments) {
    const document = args.object as DocumentDto;

    if (document.type === DocumentType.EXPLANATION) {
      return 'Explanation documents require a non-empty data.options array';
    }

    return 'data.options is only allowed when type is explanation';
  }
}

export class ExplanationOptionDto {
  @ApiProperty({ required: true, example: 1 })
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @ApiProperty({
    required: false,
    nullable: true,
    example: 'https://example.com/icon.png',
  })
  @IsOptional()
  @IsString()
  icon?: string | null;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Content of option', vi: 'Noi dung lua chon' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  value: Record<string, string>;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Content of explanation', vi: 'Noi dung giai thich' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  explanation: Record<string, string>;
}

export class DocumentDataDto {
  @ApiProperty({
    type: Object,
    required: false,
    example: { en: 'Content of document', vi: 'Nội dung của tài liệu' },
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
  url: Record<string, string>;

  @ApiPropertyOptional({ required: false, example: 'http://example.com' })
  @IsOptional()
  @IsString()
  thumbnail: string;

  @IsArray()
  @ApiPropertyOptional({
    type: [ExplanationOptionDto],
    required: false,
    example: ExplanationOptionDto,
  })
  @IsOptional()
  @ArrayNotEmpty()
  @Type(() => ExplanationOptionDto)
  @ValidateNested({ each: true })
  options?: ExplanationOptionDto[];
}

export class DocumentDto {
  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  id: number;

  @ApiProperty({
    enum: DocumentType,
    required: true,
    example: DocumentType.TEXT,
  })
  @IsNotEmpty()
  @IsEnum(DocumentType)
  type: DocumentType;

  @IsObject()
  @ApiProperty({
    type: DocumentDataDto,
    example: DocumentDataDto,
    required: true,
  })
  @IsNotEmptyObject()
  @ValidateNested()
  @Type(() => DocumentDataDto)
  @Validate(DocumentDataByTypeConstraint)
  data: DocumentDataDto;
}
