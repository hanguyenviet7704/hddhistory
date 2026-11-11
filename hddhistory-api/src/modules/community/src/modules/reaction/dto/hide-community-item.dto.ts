import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsMongoId, IsNotEmpty } from 'class-validator';

import { CommunityTargetType } from '../../../enum/community.enum';

export class HideCommunityItemDto {
  @ApiProperty({ enum: CommunityTargetType })
  @IsEnum(CommunityTargetType)
  targetType: CommunityTargetType;

  @ApiProperty()
  @IsNotEmpty()
  @IsMongoId()
  targetId: string;
}
