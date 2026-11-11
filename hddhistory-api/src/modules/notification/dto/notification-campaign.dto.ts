import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsEnum,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

import { DEFAULT_APP_ENV } from 'src/modules/analytics/constant/dashboard.constant';

import { CAMPAIGN_DEEPLINK_KEYS } from '../constant/campaign-deeplink.constant';
import { NotificationCampaignSendMode } from '../notification.enum';

export class GetNotificationCampaignListDto {
  @ApiPropertyOptional({
    example: DEFAULT_APP_ENV,
    description:
      'Which app builds the CLICK count reads (prod / stg / dev). Only the ' +
      'clicks are scoped by it — sends are this API\'s own bookkeeping and ' +
      'carry no environment — so reading a production campaign with `dev` ' +
      'shows its real send count next to zero clicks. Same default as the ' +
      'monitoring summary, so the two never disagree by accident.',
  })
  @IsOptional()
  @IsString()
  appEnv?: string = DEFAULT_APP_ENV;
}

export class NotificationCampaignCopyDto {
  @ApiProperty({ example: 'vi' })
  @IsString()
  @IsNotEmpty()
  locale: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  body: string;
}

export class CreateNotificationCampaignDto {
  @ApiProperty({ example: 'Nhắc học lại — nhóm ngủ đông 7 ngày' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ type: [NotificationCampaignCopyDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => NotificationCampaignCopyDto)
  copies: NotificationCampaignCopyDto[];

  @ApiPropertyOptional({
    example: 'https://cdn.meup.training/notification/promo-autumn.jpg',
    description:
      'Ảnh kèm noti, dùng chung cho mọi locale. Chuỗi rỗng = xoá ảnh. ' +
      'Android hiện ảnh ở mọi trạng thái app; iOS cần bản app có ' +
      'NotificationService extension, thiếu nó thì noti vẫn về nhưng không có ảnh.',
  })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  /**
   * Khoá màn đích. Nhận cả khoá của danh mục deeplink (`library`, `paywall`,
   * `daily-warm-up`…), không chỉ đích của các loại noti có lịch — xem
   * `CAMPAIGN_DEEPLINK_KEYS` để biết vì sao hai họ khoá cùng được nhận.
   */
  @ApiProperty({ example: 'library', enum: CAMPAIGN_DEEPLINK_KEYS })
  @IsString()
  @IsIn(CAMPAIGN_DEEPLINK_KEYS)
  deeplink: string;

  @ApiPropertyOptional({
    type: Object,
    example: { variant: 'full' },
    description:
      'Tham số tuỳ chọn của đích, theo `params` mà GET /deeplink/destinations ' +
      'khai cho khoá đó (ví dụ `paywall` nhận `variant: full|compact`). Được ' +
      'LỌC theo danh mục khi lưu: tên lạ và giá trị ngoài `options` bị bỏ, nên ' +
      'không gắn được khoá điều khiển của payload push.',
  })
  @IsOptional()
  // CHỈ `@IsObject()`: `each: true` của class-validator chỉ lặp Array/Set/Map,
  // nên đặt `@IsString({ each: true })` lên một Record làm object bị validate
  // NGUYÊN KHỐI như một string — mọi request có field này đều 400, kể cả `{}`.
  // Giá trị không phải string được `sanitizeDeeplinkParams` bỏ đi, cùng cách nó
  // bỏ giá trị ngoài `options`: lọc, không phải chặn.
  @IsObject()
  deeplinkParams?: Record<string, string>;

  @ApiPropertyOptional({
    type: [String],
    description: 'Target segments (OR). Empty = every push-reachable user.',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  segmentIds?: string[];

  @ApiProperty({ enum: NotificationCampaignSendMode })
  @IsEnum(NotificationCampaignSendMode)
  sendMode: NotificationCampaignSendMode;

  @ApiPropertyOptional({ example: 20, minimum: 0, maximum: 23 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(23)
  localHour?: number;

  @ApiPropertyOptional({ example: 0, minimum: 0, maximum: 59 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(59)
  localMinute?: number;

  @ApiPropertyOptional({
    example: '2026-08-20',
    description:
      'Which local day to send on (local-hour mode). Required before queueing.',
  })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'scheduledDate must be YYYY-MM-DD' })
  scheduledDate?: string;
}

export class UpdateNotificationCampaignDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  name?: string;

  @ApiPropertyOptional({ type: [NotificationCampaignCopyDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => NotificationCampaignCopyDto)
  copies?: NotificationCampaignCopyDto[];

  @ApiPropertyOptional({
    example: 'https://cdn.meup.training/notification/promo-autumn.jpg',
    description:
      'Ảnh kèm noti, dùng chung cho mọi locale. Chuỗi rỗng = xoá ảnh. ' +
      'Android hiện ảnh ở mọi trạng thái app; iOS cần bản app có ' +
      'NotificationService extension, thiếu nó thì noti vẫn về nhưng không có ảnh.',
  })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional({ example: 'library', enum: CAMPAIGN_DEEPLINK_KEYS })
  @IsOptional()
  @IsString()
  @IsIn(CAMPAIGN_DEEPLINK_KEYS)
  deeplink?: string;

  @ApiPropertyOptional({
    type: Object,
    example: { variant: 'full' },
    description:
      'Tham số tuỳ chọn của đích, theo `params` mà GET /deeplink/destinations ' +
      'khai cho khoá đó (ví dụ `paywall` nhận `variant: full|compact`). Được ' +
      'LỌC theo danh mục khi lưu: tên lạ và giá trị ngoài `options` bị bỏ, nên ' +
      'không gắn được khoá điều khiển của payload push.',
  })
  @IsOptional()
  // CHỈ `@IsObject()`: `each: true` của class-validator chỉ lặp Array/Set/Map,
  // nên đặt `@IsString({ each: true })` lên một Record làm object bị validate
  // NGUYÊN KHỐI như một string — mọi request có field này đều 400, kể cả `{}`.
  // Giá trị không phải string được `sanitizeDeeplinkParams` bỏ đi, cùng cách nó
  // bỏ giá trị ngoài `options`: lọc, không phải chặn.
  @IsObject()
  deeplinkParams?: Record<string, string>;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  segmentIds?: string[];

  @ApiPropertyOptional({ enum: NotificationCampaignSendMode })
  @IsOptional()
  @IsEnum(NotificationCampaignSendMode)
  sendMode?: NotificationCampaignSendMode;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(23)
  localHour?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(59)
  localMinute?: number;

  @ApiPropertyOptional({ example: '2026-08-20' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'scheduledDate must be YYYY-MM-DD' })
  scheduledDate?: string;
}

/** Preview only needs the targeting — nothing is written. */
export class PreviewNotificationCampaignDto {
  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  segmentIds?: string[];
}
