import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsMongoId, IsNotEmpty } from 'class-validator';

import {
  CommunityReactionKind,
  CommunityTargetType,
} from '../../../enum/community.enum';

export class CommunityReactionDto {
  @ApiProperty({ enum: CommunityTargetType })
  @IsEnum(CommunityTargetType)
  targetType: CommunityTargetType;

  @ApiProperty()
  @IsNotEmpty()
  @IsMongoId()
  targetId: string;

  @ApiProperty({ enum: CommunityReactionKind })
  @IsEnum(CommunityReactionKind)
  kind: CommunityReactionKind;
}
