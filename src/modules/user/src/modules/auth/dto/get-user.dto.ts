import {
  ApiProperty,
  ApiPropertyOptional,
  IntersectionType,
} from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
} from 'class-validator';

import { PageOptionsDto } from '@utils/dto/paging/page.dto';

import { UserRole, UserStatus } from '../enum/user.enum';

export class GetListUserDto extends IntersectionType(PageOptionsDto) {
  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  page: number;

  @ApiProperty({ required: true })
  @IsNotEmpty()
  @IsNumber()
  take: number;

  @ApiPropertyOptional({ enum: UserStatus })
  @IsOptional()
  @IsEnum(UserStatus)
  status?: UserStatus;

  @ApiPropertyOptional({ enum: UserRole, default: UserRole.USER })
  @IsOptional()
  @IsEnum(UserRole)
  role: UserRole;

  @ApiPropertyOptional({ type: Boolean })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === true || value === 'true' || value === 1)
  anonymous: boolean;
}
