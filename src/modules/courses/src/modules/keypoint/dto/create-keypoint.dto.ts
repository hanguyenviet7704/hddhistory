import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsNumber,
  Min,
  IsNotEmptyObject,
  IsObject,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';

import { IsMultiLangString } from '@utils/dto/multi-languge';

class KeypointAudioDto {
  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: {
      en: 'https://example.com/keypoint-en.mp3',
      vi: 'https://example.com/keypoint-vi.mp3',
    },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  url?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: {
      en: 'This is the audio text for the keypoint.',
      vi: 'Day la noi dung van ban cua audio cho keypoint.',
    },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  text?: Record<string, string>;
}

export class CreateKeypointDto {
  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Keypoint Title', vi: 'Tiêu đề keypoint' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  title: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: 'Keypoint Description', vi: 'Mô tả keypoint' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  description: Record<string, string>;

  @ApiPropertyOptional({
    type: KeypointAudioDto,
    required: false,
  })
  @IsObject()
  @IsOptional()
  @ValidateNested()
  @Type(() => KeypointAudioDto)
  audio?: KeypointAudioDto;

  @ApiPropertyOptional({
    type: Object,
    required: false,
    example: { en: '1 hours', vi: '1 giờ' },
  })
  @IsObject()
  @IsOptional()
  @IsMultiLangString()
  estimateCompleTime: Record<string, string>;

  @ApiPropertyOptional({
    required: false,
    example: 8,
    description:
      'Estimated completion time in minutes. Used as source-of-truth for calculations.',
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  estimateCompleTimeNumber: number;

  @IsArray()
  @ApiPropertyOptional({
    type: [String],
    required: false,
    example: ['68fe63134a13cd7ab2d5ac5a', '68fe63134a13cd7ab2d5ac5a'],
    description: 'Array of tag ids',
  })
  @IsOptional()
  @IsString({ each: true })
  tag: string[];

  @ApiPropertyOptional({ required: false, example: 'https://example.com' })
  @IsString()
  @IsOptional()
  image: string;
}
