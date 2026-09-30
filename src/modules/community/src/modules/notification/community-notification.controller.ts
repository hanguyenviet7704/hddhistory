import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { CurrentUser } from '@base/decorator/current-user.decorator';
import { AuthGuard } from '@base/guard/auth.guard';
import { PageOptionsDto } from '@utils/dto/paging/page.dto';
import { IUser } from 'src/modules/user/src/modules/auth/interface/user.interface';

import { CommunityNotificationService } from './community-notification.service';
import { MarkCommunityNotificationReadDto } from './dto/mark-community-notification-read.dto';

@ApiTags('COMMUNITY-NOTIFICATIONS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'community', version: '1' })
export class CommunityNotificationController {
  constructor(private readonly svc: CommunityNotificationService) {}

  @Get('notifications')
  list(@Query() dto: PageOptionsDto, @CurrentUser() user: IUser) {
    return this.svc.list(user.id, dto.page, dto.take);
  }

  // Drives the red dot on the community header.
  @Get('notifications/unread-count')
  unreadCount(@CurrentUser() user: IUser) {
    return this.svc.unreadCount(user.id).then((count) => ({ count }));
  }

  @Post('notifications/read')
  markRead(
    @Body() dto: MarkCommunityNotificationReadDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.markRead(user.id, dto);
  }
}
