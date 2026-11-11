import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsEnum,
  IsMongoId,
  IsNotEmpty,
  IsNotEmptyObject,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  Matches,
} from 'class-validator';

import { IsMultiLangString } from '@utils/dto/multi-languge';

import { HabitLibraryStatus } from '../enum/habit-library.enum';

export class CreateHabitLibraryDto {
  @ApiProperty({
    type: Object,
    required: true,
    example: { en: 'Take a 2-minute breathing break', vi: 'Hít thở 2 phút để cân bằng lại' },
  })
  @IsObject()
  @IsNotEmptyObject()
  @IsMultiLangString()
  title: Record<string, string>;

  @ApiProperty({ required: true, description: 'Category (category) id' })
  @IsNotEmpty()
  @IsMongoId()
  categoryId: string;

  @ApiPropertyOptional({ enum: HabitLibraryStatus, example: HabitLibraryStatus.PUBLISHED })
  @IsOptional()
  @IsEnum(HabitLibraryStatus)
  status?: HabitLibraryStatus;

  @ApiPropertyOptional({
    example: 'https://cdn.meup.training/habits/breathing-break.png',
    description:
      "The habit's own picture. Absolute CDN url, as returned by POST /cloudflares/upload. Omit to keep showing the category's logo.",
  })
  @IsOptional()
  @IsString()
  image?: string;

  @ApiPropertyOptional({
    type: Object,
    example: {
      vi: 'Để người kia nói hết câu rồi mới đáp — không chen, không đoán trước ý.',
      en: 'Let the other person finish before you answer — no cutting in, no guessing.',
    },
    description:
      'What the habit is, concretely, and when it applies. Grounds the Coach\'s practice scenes.',
  })
  @IsOptional()
  @IsObject()
  @IsMultiLangString()
  description?: Record<string, string>;

  @ApiPropertyOptional({
    type: Object,
    example: {
      vi: 'khi đồng nghiệp trình bày ý trong buổi họp\nkhi người thân kể chuyện lúc ăn tối',
      en: 'when a colleague explains their idea in a meeting\nwhen a family member tells a story over dinner',
    },
    description:
      'Moments the habit comes up, ONE PER LINE per locale. Each Coach scene stands in one of them.',
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

  @ApiPropertyOptional({ example: '08:00', description: 'Default daily reminder time (HH:mm)' })
  @IsOptional()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, { message: 'defaultReminderTime must be HH:mm' })
  defaultReminderTime?: string;

  @ApiPropertyOptional({ example: 0, description: 'Sort order within the library' })
  @IsOptional()
  @IsNumber()
  order?: number;

  @ApiPropertyOptional({
    type: [String],
    example: ['68fe63134a13cd7ab2d5ac5a'],
    description: 'Keypoints this habit can be suggested in (many-to-many)',
  })
  @IsOptional()
  @IsArray()
  @IsMongoId({ each: true })
  keypointIds?: string[];
}
