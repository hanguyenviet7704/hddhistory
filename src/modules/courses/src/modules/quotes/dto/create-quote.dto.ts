import { ApiProperty } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsNotEmptyObject,
  IsObject,
  IsOptional,
  IsString,
} from 'class-validator';

import { IsMultiLangString } from '@utils/dto/multi-languge';

export class CreateQuoteDto {
  @ApiProperty()
  @IsOptional()
  @IsString()
  _id: string;

  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Keep moving forward', vi: 'Khong dung tien buoc' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  content: Record<string, string>;

  @ApiProperty({
    required: true,
    example: '#FFFFFF',
  })
  @IsString()
  @IsNotEmpty()
  backgroundColor: string;

  @ApiProperty({
    required: true,
    example: '#000000',
  })
  @IsString()
  @IsNotEmpty()
  textColor: string;
}
