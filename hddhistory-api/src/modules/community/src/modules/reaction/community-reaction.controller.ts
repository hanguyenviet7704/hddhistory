import { Body, Controller, Delete, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { CurrentUser } from '@base/decorator/current-user.decorator';
import { AuthGuard } from '@base/guard/auth.guard';
import { IUser } from 'src/modules/user/src/modules/auth/interface/user.interface';

import { CommunityReactionService } from './community-reaction.service';
import { CommunityReactionDto } from './dto/community-reaction.dto';
import { HideCommunityItemDto } from './dto/hide-community-item.dto';

@ApiTags('COMMUNITY-REACTIONS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'community', version: '1' })
export class CommunityReactionController {
  constructor(private readonly svc: CommunityReactionService) {}

  @Post('reactions')
  react(@Body() dto: CommunityReactionDto, @CurrentUser() user: IUser) {
    return this.svc.react(user.id, dto);
  }

  @Delete('reactions')
  unreact(@Body() dto: CommunityReactionDto, @CurrentUser() user: IUser) {
    return this.svc.unreact(user.id, dto);
  }

  // "Ẩn nội dung này" — hides it for this reader only, so a guest may do it:
  // nothing about it is visible to anyone else or needs to be moderated.
  @Post('hidden')
  hide(@Body() dto: HideCommunityItemDto, @CurrentUser() user: IUser) {
    return this.svc.hide(user.id, dto);
  }
}
