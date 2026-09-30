import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsNotEmpty,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';

export class ColorStyleDto {
  @ApiProperty({ required: true, example: '#FFFFFF' })
  @IsNotEmpty()
  @IsString()
  backgroundColor: string;

  @ApiProperty({ required: true, example: '#000000' })
  @IsNotEmpty()
  @IsString()
  textColor: string;
}

export class ConversationColorDto {
  @ApiProperty({ type: ColorStyleDto, example: ColorStyleDto, required: true })
  @IsNotEmpty()
  @ValidateNested()
  @Type(() => ColorStyleDto)
  left: ColorStyleDto;

  @ApiProperty({ type: ColorStyleDto, example: ColorStyleDto, required: true })
  @IsNotEmpty()
  @ValidateNested()
  @Type(() => ColorStyleDto)
  right: ColorStyleDto;
}

export class RoleplayColorTemplateDto {
  @ApiProperty({ required: true, example: 'Section Color Template' })
  @IsNotEmpty()
  @IsString()
  title: string;

  @ApiProperty({ type: ConversationColorDto })
  @IsNotEmpty()
  @ValidateNested()
  @Type(() => ConversationColorDto)
  conversation: ConversationColorDto;

  @ApiProperty({ type: ColorStyleDto })
  @IsNotEmpty()
  @ValidateNested()
  @Type(() => ColorStyleDto)
  leadingText: ColorStyleDto;

  @ApiProperty({ type: ColorStyleDto })
  @IsNotEmpty()
  @ValidateNested()
  @Type(() => ColorStyleDto)
  transition: ColorStyleDto;

  @ApiPropertyOptional({ type: ColorStyleDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => ColorStyleDto)
  resultsOfAnsweringTheQuestion?: ColorStyleDto;
}
