import {
  ApiProperty,
  ApiPropertyOptional,
  OmitType,
  PickType,
} from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  IsArray,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
} from 'class-validator';

import { CoachContentKind } from '../coach-content.enum';

export class GetCoachContentsDto {
  @ApiPropertyOptional({ description: 'Chỉ của một user.' })
  @IsOptional()
  @IsString()
  userId?: string;

  @ApiPropertyOptional({ description: 'Chỉ của một habit.' })
  @IsOptional()
  @IsString()
  habitId?: string;

  @ApiPropertyOptional({
    isArray: true,
    enum: CoachContentKind,
    description: 'Bỏ trống = mọi loại.',
  })
  @IsOptional()
  @IsArray()
  @IsEnum(CoachContentKind, { each: true })
  // A single `?kinds=evidence` arrives as a string, not an array, and would fail
  // `@IsArray` before the enum check ever ran. `undefined` has to pass straight
  // through: class-transformer runs this even when the param is absent, and
  // wrapping that into `[undefined]` would 400 every request that omits it.
  @Transform(({ value }) =>
    value === undefined ? undefined : Array.isArray(value) ? value : [value],
  )
  kinds?: CoachContentKind[];

  @ApiPropertyOptional({ example: '2026-08-01', description: 'YYYY-MM-DD.' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'from must be YYYY-MM-DD' })
  from?: string;

  @ApiPropertyOptional({ example: '2026-08-28', description: 'YYYY-MM-DD.' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'to must be YYYY-MM-DD' })
  to?: string;

  @ApiPropertyOptional({
    description: 'Tìm trong chính chữ user viết, không phân biệt hoa thường.',
  })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ example: 200, minimum: 1, maximum: 500, default: 200 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(500)
  limit?: number;
}

/**
 * The per-user roll-up takes the same window and the same filters as the
 * reading list, minus the one that would make it a list of one.
 */
export class GetCoachContentUsersDto extends OmitType(GetCoachContentsDto, [
  'userId',
] as const) {}

/**
 * The thread takes the window and nothing else: a kind filter would punch holes
 * in a conversation, and the user is already named in the path.
 */
export class GetCoachThreadDto extends PickType(GetCoachContentsDto, [
  'from',
  'to',
  'limit',
] as const) {}

/**
 * Một dòng cần xoá: loại nói nó nằm ở nguồn nào, id nói nó là dòng nào.
 *
 * `id` chặn ngay tại biên bằng regex thay vì để Mongoose ném `CastError` thành
 * 500: một id rác phải trả về 400 chứ không phải "lỗi máy chủ". Hậu tố `:dip`
 * được chấp nhận vì dịp là field trên phiên nên feed phát id ghép — xem
 * `CoachContentService.removeForAdmin`.
 */
export class DeleteCoachContentDto {
  @ApiProperty({ enum: CoachContentKind })
  @IsEnum(CoachContentKind)
  kind: CoachContentKind;

  @ApiProperty({ example: '66c0f0a1b2c3d4e5f6a7b8c9' })
  @Matches(/^[a-f\d]{24}(:dip)?$/i, { message: 'id is not a coach content id' })
  id: string;
}
