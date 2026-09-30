import { Controller, Get, Header, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import {
  DEEPLINK_DESTINATIONS,
  DeeplinkDestinationDef,
} from './deeplink.catalog';

/**
 * Danh mục màn cho trang "Link vào màn" của admin.
 *
 * Không dựng URL ở đây: admin dựng, giống `buildDownloadLinkUrl` -- entitlement
 * iOS là `applinks:meup.training` không wildcard, nên chỉ có một host được phép
 * xuất hiện và việc dựng link thuộc về phía client.
 */
@ApiTags('DEEPLINK')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'deeplink', version: '1' })
export class DeeplinkController {
  // Hằng số, nên cache được. 5 phút: thêm một màn thì admin thấy trong vòng một
  // lần refresh, mà không phải mỗi lần mở trang một request.
  @Get('destinations')
  @Header('Cache-Control', 'private, max-age=300')
  getDestinations(): DeeplinkDestinationDef[] {
    return DEEPLINK_DESTINATIONS;
  }
}
