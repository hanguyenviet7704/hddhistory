import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { CurrentUser } from '@base/decorator/current-user.decorator';
import { AuthGuard } from '@base/guard/auth.guard';
import { IUser } from 'src/modules/user/src/modules/auth/interface/user.interface';

import { CommunityChatService } from './community-chat.service';
import { GetCommunityChatDto } from './dto/get-community-chat.dto';
import { GetListCommunityChatDto } from './dto/get-list-community-chat.dto';
import { ModerateCommunityChatDto } from './dto/moderate-community-chat.dto';
import { SendCommunityChatDto } from './dto/send-community-chat.dto';
import { UpsertCommunityChatRoomDto } from './dto/upsert-community-chat-room.dto';
import { userMeta } from '../../helper/community-reader.helper';

/**
 * A group chat room (design `S-03 · Hội bàn tròn`).
 *
 * Rooms are addressed by slug OR id, so the app opens the one shipping room by
 * name instead of carrying its ObjectId. Reading and writing are both open to
 * anyone the AuthGuard lets through, guests included; the service then checks
 * the mute and the flood ceiling the same way a post or a comment does.
 */
@ApiTags('COMMUNITY-CHAT')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'community', version: '1' })
export class CommunityChatController {
  constructor(private readonly svc: CommunityChatService) {}

  @Get('chat/rooms/:room')
  room(@Param('room') room: string, @CurrentUser() user: IUser) {
    return this.svc.room(room, user.id);
  }

  @Get('chat/rooms/:room/messages')
  messages(
    @Param('room') room: string,
    @Query() dto: GetCommunityChatDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.messages(room, user.id, dto);
  }

  @Post('chat/rooms/:room/messages')
  send(
    @Param('room') room: string,
    @Body() dto: SendCommunityChatDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.send(room, user.id, dto, userMeta(user));
  }

  @Post('chat/messages/:id/like')
  like(@Param('id') id: string, @CurrentUser() user: IUser) {
    return this.svc.toggleLike(id, user.id);
  }

  @Get('chat/rooms/:room/messages/:id/context')
  @ApiOperation({
    summary: 'The slice of transcript around one message.',
    description:
      'What a tap on a pinned line lands in. The pin may be hundreds of ' +
      'messages back, outside the page the screen holds, so there is nothing ' +
      'to scroll to — this returns a window centred on it instead. `hasNewer` ' +
      'false means the window reaches the live bottom.',
  })
  context(
    @Param('room') room: string,
    @Param('id') id: string,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.context(room, id, user.id);
  }


  // -------------------------------------------------------------- admin
  //
  // `AuthGuard`-only, for the reason written up on CommunityCommentController:
  // nothing populates `role` yet, so a @Roles check 403s the whole panel.

  @Post('admin/chat/messages/:id/pin')
  @ApiOperation({
    summary: 'Pin a message to the top of its room.',
    description:
      'A panel action. There is no reader-facing counterpart on purpose: the ' +
      'app draws pins, it does not make them.',
  })
  pin(@Param('id') id: string, @CurrentUser() user: IUser) {
    return this.svc.pin(id, user.id);
  }

  @Delete('admin/chat/messages/:id/pin')
  @ApiOperation({ summary: 'Unpin a message.' })
  unpin(@Param('id') id: string) {
    return this.svc.unpin(id);
  }

  @Get('admin/chat/rooms')
  findRoomsAdmin() {
    return this.svc.listRoomsForAdmin();
  }

  @Post('admin/chat/rooms')
  upsertRoom(
    @Body() dto: UpsertCommunityChatRoomDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.upsertRoom(dto, userMeta(user));
  }

  @Post('admin/chat/rooms/:room/messages')
  sendOfficial(
    @Param('room') room: string,
    @Body() dto: SendCommunityChatDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.sendOfficial(room, dto, user.id, userMeta(user));
  }

  @Get('admin/chat/messages')
  findAllAdmin(@Query() dto: GetListCommunityChatDto) {
    return this.svc.findAllForAdmin(dto);
  }

  @Patch('admin/chat/messages/:id')
  moderate(
    @Param('id') id: string,
    @Body() dto: ModerateCommunityChatDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.moderate(id, dto, user.id, userMeta(user));
  }
}
