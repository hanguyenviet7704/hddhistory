import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';

import { ITranslation } from '@utils/interface/common.interface';

export class TaxonomyBranchDto {
  @ApiProperty({ example: 'CX' })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiProperty({ example: { vi: 'Cảm xúc & tinh thần' } })
  @IsObject()
  label: ITranslation;

  @ApiPropertyOptional()
  @IsOptional()
  @IsObject()
  subtitle?: ITranslation;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  iconUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  order?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isSelectable?: boolean;

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsString()
  skillsetId?: string | null;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class TaxonomyPackageDto {
  @ApiProperty({ example: 'CX-1' })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiProperty({ example: 'CX' })
  @IsString()
  branchCode: string;

  @ApiProperty()
  @IsObject()
  problemLabel: ITranslation;

  @ApiProperty()
  @IsObject()
  desireLabel: ITranslation;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  order?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class TaxonomyLabelDto {
  @ApiProperty({ example: 'CX01' })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiProperty({ example: 'CX-1' })
  @IsString()
  packageCode: string;

  @ApiProperty()
  @IsObject()
  label: ITranslation;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  order?: number;
}

export class SaveOnboardingTaxonomyDto {
  @ApiProperty({ type: [TaxonomyBranchDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => TaxonomyBranchDto)
  branches: TaxonomyBranchDto[];

  @ApiProperty({ type: [TaxonomyPackageDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => TaxonomyPackageDto)
  packages: TaxonomyPackageDto[];

  @ApiProperty({ type: [TaxonomyLabelDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => TaxonomyLabelDto)
  labels: TaxonomyLabelDto[];
}
