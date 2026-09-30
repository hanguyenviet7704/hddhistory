import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { CurrentUser } from '@base/decorator/current-user.decorator';
import { AuthGuard } from '@base/guard/auth.guard';
import { IUser } from 'src/modules/user/src/modules/auth/interface/user.interface';

import { CommunityRoomSuggestionService } from './community-room-suggestion.service';
import { CreateCommunityRoomSuggestionDto } from './dto/create-community-room-suggestion.dto';
import { GetListCommunityRoomSuggestionDto } from './dto/get-list-community-room-suggestion.dto';
import {
  ApproveCommunityRoomSuggestionDto,
  DeclineCommunityRoomSuggestionDto,
} from './dto/review-community-room-suggestion.dto';
import { ReaderLocale, userMeta } from '../../helper/community-reader.helper';

/**
 * "Đề xuất phòng mới" — readers asking for a room, and moderators answering.
 *
 * The admin handlers are `AuthGuard`-only for the same documented reason as the
 * rest of the community module: nothing populates `role` yet, so a role check
 * would 403 the panel for everyone. See CommunityTopicController for the full
 * write-up and the three-step fix.
 */
@ApiTags('COMMUNITY-ROOM-SUGGESTIONS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'community', version: '1' })
export class CommunityRoomSuggestionController {
  constructor(private readonly svc: CommunityRoomSuggestionService) {}

  @Get('room-suggestions')
  list(@CurrentUser() user: IUser, @ReaderLocale() locale: string) {
    return this.svc.listForReader(user.id, locale);
  }

  @Post('room-suggestions')
  create(
    @Body() dto: CreateCommunityRoomSuggestionDto,
    @CurrentUser() user: IUser,
    @ReaderLocale() locale: string,
  ) {
    return this.svc.create(user.id, locale, dto, userMeta(user));
  }

  @Post('room-suggestions/:id/vote')
  vote(@Param('id') id: string, @CurrentUser() user: IUser) {
    return this.svc.vote(id, user.id);
  }

  // -------------------------------------------------------------- admin

  @Get('admin/room-suggestions')
  findAll(@Query() dto: GetListCommunityRoomSuggestionDto) {
    return this.svc.findAllForAdmin(dto);
  }

  @Patch('admin/room-suggestions/:id/approve')
  approve(
    @Param('id') id: string,
    @Body() dto: ApproveCommunityRoomSuggestionDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.approve(id, user.id, dto);
  }

  @Patch('admin/room-suggestions/:id/decline')
  decline(
    @Param('id') id: string,
    @Body() dto: DeclineCommunityRoomSuggestionDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.decline(id, user.id, dto);
  }
}
