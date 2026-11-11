import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsIn,
  IsNotEmptyObject,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';

import { IsMultiLangString } from '@utils/dto/multi-languge';

export class HabitImportRow {
  @ApiPropertyOptional({
    description: 'Existing habit _id, to update that exact record in place',
  })
  @IsOptional()
  @IsString()
  id?: string;

  @ApiProperty({
    description:
      'Course _id. The key rows are matched on — an exact match, no title lookup.',
  })
  @IsString()
  courseId: string;

  @ApiPropertyOptional({
    description:
      'Course title, carried for the import report only. Never used to match: two courses can share a title, and renaming one used to silently move its habits.',
  })
  @IsOptional()
  @IsString()
  course?: string;

  @ApiProperty({ example: 1, description: '1-based roadmap section (node) index' })
  @IsNumber()
  section: number;

  @ApiProperty({ example: 1, description: '1-based keypoint position within the section' })
  @IsNumber()
  keypoint: number;

  @ApiProperty({ example: 1, description: '1-based order among the keypoint habits' })
  @IsNumber()
  habitIndex: number;

  @ApiPropertyOptional({
    example: 'https://cdn.meup.training/habits/breathing-break.png',
    description:
      "The habit's own picture, absolute CDN url. Blank clears whatever the habit currently has — the sheet is the whole truth for a replace import.",
  })
  @IsOptional()
  @IsString()
  image?: string;

  @ApiProperty({
    type: Object,
    example: { en: 'When emotions rise, pause and breathe before reacting', vi: 'Cảm xúc nóng lên, dừng một nhịp và hít thở trước khi phản ứng' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  title: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    description: 'What the habit is and when it applies, per locale. Blank on every row leaves the stored value alone.',
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  description?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    description: 'Moments the habit comes up, one per line, per locale. Blank on every row leaves the stored value alone.',
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  contexts?: Record<string, string>;

  @ApiPropertyOptional({
    example: {
      vi: 'clarity | Noi ro minh khong muon hay khong the\nboundary | Giu ranh gioi khi bi gay ap luc',
      en: 'clarity | Says plainly what they will not do\nboundary | Holds the line under pressure',
    },
    description:
      "The skill's rubric, ONE `key | label` criterion per line per locale (4-5 lines). The key keeps a reader's scores comparable when a label is reworded. Omit to leave this habit's scenes unscored.",
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  rubric?: Record<string, string>;

  @ApiPropertyOptional({
    example: {
      vi: '1 | Nhan ra thoi thuc khi chua co gi can\n4 | Doi phuong kich them lan thu hai',
      en: '1 | Notices the pull when nothing pushes back\n4 | The other person pushes a second time',
    },
    description:
      "The skill's difficulty ladder, ONE `<level> | <situation shape>` rung per line per locale (5 lines, 1..5). Generation builds each scene from the rung its level lands on. Omit for generic escalation.",
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  ladder?: Record<string, string>;
}

export class ImportHabitLibraryDto {
  @ApiPropertyOptional({ enum: ['replace'], default: 'replace' })
  @IsOptional()
  @IsIn(['replace'])
  mode?: 'replace';

  @ApiProperty({ type: [HabitImportRow] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => HabitImportRow)
  rows: HabitImportRow[];
}
