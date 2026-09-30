import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { CurrentUser } from '@base/decorator/current-user.decorator';
import { AuthGuard } from '@base/guard/auth.guard';
import { IUser } from 'src/modules/user/src/modules/auth/interface/user.interface';

import { CommunityChatGuideService } from './community-chat-guide.service';
import { UpsertCommunityChatGuideDto } from './dto/upsert-community-chat-guide.dto';
import { ReaderLocale, userMeta } from '../../helper/community-reader.helper';
import { CommunityLocale } from '../../interface/community.interface';

/**
 * "Hướng dẫn & nội quy nhóm" (design `S-03c`) — the sheet behind the info
 * button in the chat header.
 */
@ApiTags('COMMUNITY-CHAT')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'community', version: '1' })
export class CommunityChatGuideController {
  constructor(private readonly svc: CommunityChatGuideService) {}

  @Get('chat/guide')
  @ApiOperation({
    summary: 'The room rules in the reader’s language.',
    description:
      'Null when nothing has been written in any language, which the app ' +
      'reads as "hide the info button" rather than opening an empty sheet.',
  })
  guide(@ReaderLocale() locale: CommunityLocale) {
    return this.svc.forReader(locale);
  }

  // -------------------------------------------------------------- admin
  //
  // `AuthGuard`-only, like every other community admin surface — see the note
  // on CommunityCommentController for why `@Roles(ADMIN)` is not used here.

  @Get('admin/chat/guides')
  findAllAdmin() {
    return this.svc.listForAdmin();
  }

  @Post('admin/chat/guides')
  upsert(
    @Body() dto: UpsertCommunityChatGuideDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.upsert(dto, userMeta(user));
  }
}
