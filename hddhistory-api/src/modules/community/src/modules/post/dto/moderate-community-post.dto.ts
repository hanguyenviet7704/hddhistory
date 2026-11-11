import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

import {
  COMMUNITY_POST_MAX_IMAGES,
  COMMUNITY_POST_MAX_LENGTH,
  COMMUNITY_POST_MAX_SUBJECT_LENGTH,
} from './create-community-post.dto';
import { CommunityContentStatus } from '../../../enum/community.enum';

export class ModerateCommunityPostDto {
  @ApiPropertyOptional({ enum: CommunityContentStatus })
  @IsOptional()
  @IsEnum(CommunityContentStatus)
  status?: CommunityContentStatus;

  @ApiPropertyOptional({
    description: 'Shown to the author in their notification when a post is hidden',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  hiddenReason?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPinned?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  commentsLocked?: boolean;

  /**
   * Sửa nội dung tại chỗ -- xoá lời tục, sửa lỗi chính tả, gỡ một tấm ảnh --
   * không đi qua ẩn/hiện. Ba trường dưới đây đều là "omit để giữ nguyên": có
   * mặt trong body request là ghi đè, kể cả với chuỗi rỗng hay mảng rỗng.
   *
   * Cùng giới hạn với lúc VIẾT bài (`CreateCommunityPostDto`) -- một bài đã
   * qua sửa vẫn phải nằm trong khung mà app cho phép tạo ra nó, không thì
   * app tự sinh ra thứ chính API của nó từ chối nhận.
   */
  @ApiPropertyOptional({
    maxLength: COMMUNITY_POST_MAX_SUBJECT_LENGTH,
    description: 'Sửa tiêu đề. Chuỗi rỗng xoá hẳn tiêu đề',
  })
  @IsOptional()
  @IsString()
  @MaxLength(COMMUNITY_POST_MAX_SUBJECT_LENGTH)
  subject?: string;

  @ApiPropertyOptional({
    maxLength: COMMUNITY_POST_MAX_LENGTH,
    description: 'Sửa nội dung bài. Không được rỗng -- một bài luôn phải có thân bài',
  })
  @IsOptional()
  @IsNotEmpty()
  @IsString()
  @MaxLength(COMMUNITY_POST_MAX_LENGTH)
  body?: string;

  @ApiPropertyOptional({
    type: [String],
    maxItems: COMMUNITY_POST_MAX_IMAGES,
    description: 'Thay HẲN danh sách ảnh. Mảng rỗng gỡ mọi ảnh',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(COMMUNITY_POST_MAX_IMAGES)
  @IsString({ each: true })
  images?: string[];
}
