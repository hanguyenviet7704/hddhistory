import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

import { NotificationDeeplink, NotificationType } from '../notification.enum';

export class NotificationCopyDto {
  @ApiProperty({ example: 'en', description: 'Locale code (en, vi, ko, zh, ja, id, ms, fil)' })
  @IsString()
  @IsNotEmpty()
  locale: string;

  @ApiProperty({ example: "👀 Don't be afraid to go slowly - just don't stand still." })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({
    example: '🌱 Hey {user_name}, "{course_name}" is waiting for you.',
    description:
      'Supports {user_name}, {course_name}, {topic_name} (the course skillset) and {quote}. {lesson_name} still resolves (to the course name) for copy saved before the rename.',
  })
  @IsString()
  @IsNotEmpty()
  body: string;
}

export class NotificationVariantDto {
  @ApiPropertyOptional({
    example: 'v3',
    description:
      'Omit for a new variant — the server assigns the next free key. Send the existing key to edit a variant in place: the per-user "not the same wording as the last three days" memory is keyed by it.',
  })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  key?: string;

  @ApiProperty({ type: [NotificationCopyDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => NotificationCopyDto)
  copies: NotificationCopyDto[];
}

export class UpdateNotificationTemplateDto {
  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @ApiPropertyOptional({ example: 14, minimum: 0, maximum: 23 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(23)
  localHour?: number;

  @ApiPropertyOptional({ example: 30, minimum: 0, maximum: 59 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(59)
  localMinute?: number;

  @ApiPropertyOptional({
    example: 1,
    minimum: 1,
    maximum: 7,
    description:
      'ISO weekday (1 = Monday … 7 = Sunday) the template fires on, in each ' +
      'reader\'s own zone. null clears it back to every day.',
    nullable: true,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(7)
  localWeekday?: number | null;

  @ApiPropertyOptional({ enum: NotificationDeeplink })
  @IsOptional()
  @IsEnum(NotificationDeeplink)
  deeplink?: NotificationDeeplink;

  @ApiPropertyOptional({
    example: 'https://cdn.meup.training/notification/streak-reminder.jpg',
    description:
      'Ảnh kèm noti, dùng chung cho mọi locale và mọi variant của type này. ' +
      'Chuỗi rỗng = xoá ảnh. Android hiện ảnh ở mọi trạng thái app; iOS cần bản ' +
      'app có NotificationService extension, thiếu nó thì noti vẫn về nhưng ' +
      'không có ảnh.',
  })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  /** Legacy single-wording form. Ignored when [variants] is sent. */
  @ApiPropertyOptional({ type: [NotificationCopyDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => NotificationCopyDto)
  copies?: NotificationCopyDto[];

  @ApiPropertyOptional({
    type: [NotificationVariantDto],
    description:
      'Replaces the whole list — a variant left out is deleted, which is how the admin screen removes one.',
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => NotificationVariantDto)
  variants?: NotificationVariantDto[];

  @ApiPropertyOptional({
    type: [String],
    description:
      'Target segments (OR). Empty array clears targeting and sends to everybody.',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  segmentIds?: string[];
}

export class ImportNotificationTemplateItemDto {
  @ApiProperty({ enum: NotificationType })
  @IsEnum(NotificationType)
  type: NotificationType;

  /**
   * Optional so a content-only file cannot switch a live notification off. Left
   * out, the stored flag is kept — turning one on or off stays a deliberate act
   * on the admin screen.
   */
  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @ApiProperty({ example: 14 })
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(23)
  localHour: number;

  /** Optional so an export taken before this field existed still imports. */
  @ApiPropertyOptional({ example: 30, minimum: 0, maximum: 59 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(59)
  localMinute?: number;

  /** Optional for the same reason: pre-weekday exports still import as daily. */
  @ApiPropertyOptional({ example: 1, minimum: 1, maximum: 7 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(7)
  localWeekday?: number;

  @ApiProperty({ enum: NotificationDeeplink })
  @IsEnum(NotificationDeeplink)
  deeplink: NotificationDeeplink;

  /**
   * Optional for the same reason as the fields above: a file exported before
   * images existed must import without wiping the image off a live template.
   * Send `''` to deliberately clear one.
   */
  @ApiPropertyOptional({
    example: 'https://cdn.meup.training/notification/streak-reminder.jpg',
  })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  /**
   * Optional so a file exported before variants existed still imports, and so a
   * variants-only file does not have to repeat the first wording twice.
   */
  @ApiPropertyOptional({ type: [NotificationCopyDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => NotificationCopyDto)
  copies?: NotificationCopyDto[];

  @ApiPropertyOptional({ type: [NotificationVariantDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => NotificationVariantDto)
  variants?: NotificationVariantDto[];

  @ApiPropertyOptional({
    type: [String],
    description:
      'Target segments (OR). Empty array clears targeting and sends to everybody.',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  segmentIds?: string[];
}

/**
 * Whole-file import from the admin screen — the same shape `GET /export` returns,
 * so an export can be edited and pushed straight back.
 */
export class ImportNotificationTemplateDto {
  @ApiProperty({ type: [ImportNotificationTemplateItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ImportNotificationTemplateItemDto)
  templates: ImportNotificationTemplateItemDto[];
}

/** Fires one notification at a chosen user, ignoring schedule and caps. */
export class SendTestNotificationDto {
  @ApiProperty({ enum: NotificationType })
  @IsEnum(NotificationType)
  type: NotificationType;

  @ApiProperty({ example: '66f0c2...' })
  @IsString()
  @IsNotEmpty()
  userId: string;

  @ApiPropertyOptional({
    example: 'v3',
    description:
      'Which wording to send. Omit to let the dispatcher pick as it would in production; the response reports which variant went out.',
  })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  variantKey?: string;
}
