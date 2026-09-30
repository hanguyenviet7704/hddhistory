import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class CompressImagesDto {
  @ApiPropertyOptional({
    default: 'images/',
    description: 'Only process objects under this key prefix.',
  })
  @IsOptional()
  @IsString()
  prefix?: string;

  @ApiPropertyOptional({
    default: false,
    description: 'false = dry-run (report only, no writes). true = overwrite.',
  })
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  @IsBoolean()
  apply?: boolean;

  @ApiPropertyOptional({
    default: 1080,
    description: 'Longest edge in px; larger images are downscaled to fit.',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(64)
  @Max(4096)
  maxEdge?: number;

  @ApiPropertyOptional({ default: 80, description: 'WebP quality (1-100).' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  quality?: number;

  @ApiPropertyOptional({
    default: 20480,
    description: 'Skip files smaller than this many bytes.',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  minBytes?: number;

  @ApiPropertyOptional({
    default: 100,
    description: 'Objects to scan per call (drives pagination).',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(500)
  batchSize?: number;

  @ApiPropertyOptional({
    description: 'Continuation token from a previous call to fetch the next page.',
  })
  @IsOptional()
  @IsString()
  continuationToken?: string;

  @ApiPropertyOptional({
    default: 'originals-backup',
    description: 'Key prefix where untouched originals are copied before overwrite.',
  })
  @IsOptional()
  @IsString()
  backupPrefix?: string;
}
