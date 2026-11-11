import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsNotEmpty,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';

export class SpacedReviewResultDto {
  @ApiProperty({
    description: 'Keypoint vừa được ôn',
    example: '6650f1c2a1b2c3d4e5f60718',
  })
  @IsNotEmpty()
  @IsString()
  @MaxLength(64)
  keypointId: string;

  @ApiProperty({
    description:
      'true khi mọi câu của keypoint này trong phiên đều đúng; một câu sai là false',
    example: true,
  })
  @IsBoolean()
  correct: boolean;
}

export class SubmitSpacedReviewDto {
  @ApiProperty({
    description: 'Kết quả theo từng keypoint của phiên ôn vừa xong',
    type: [SpacedReviewResultDto],
  })
  @IsArray()
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => SpacedReviewResultDto)
  results: SpacedReviewResultDto[];
}
