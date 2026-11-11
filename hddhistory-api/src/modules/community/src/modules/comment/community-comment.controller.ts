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
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { CurrentUser } from '@base/decorator/current-user.decorator';
import { AuthGuard } from '@base/guard/auth.guard';
import { IUser } from 'src/modules/user/src/modules/auth/interface/user.interface';

import { CommunityCommentService } from './community-comment.service';
import { CreateCommunityCommentDto } from './dto/create-community-comment.dto';
import { CreateOfficialCommentDto } from './dto/create-official-comment.dto';
import { GetListCommunityCommentDto } from './dto/get-list-community-comment.dto';
import { ModerateCommunityCommentDto } from './dto/moderate-community-comment.dto';
import { userMeta } from '../../helper/community-reader.helper';

/**
 * Admin handlers here are `AuthGuard`-only, deliberately.
 *
 * They shipped behind `@Roles(UserRole.ADMIN)` and 403'd the panel for
 * everyone, for the reason already written up on `UserHabitAdminController`:
 * nothing populates `role` (every account defaults to `USER`, and the real
 * admin account is `role: USER`), and `PUT /users/:id` lets any authenticated
 * caller set their own role — so a role check cannot mean anything yet.
 *
 * This is a real trust gap, and a wider one here than on the other admin
 * surfaces: these handlers hide and delete other people's posts and suspend
 * accounts. Closing it means fixing `PUT /users/:id`, marking the admin
 * accounts `role: ADMIN`, then reinstating the guard across every admin
 * endpoint at once — not on this one module alone, which is what broke the
 * panel.
 */
@ApiTags('COMMUNITY-COMMENTS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'community', version: '1' })
export class CommunityCommentController {
  constructor(private readonly svc: CommunityCommentService) {}

  @Get('posts/:postId/comments')
  thread(
    @Param('postId') postId: string,
    @Query() dto: GetListCommunityCommentDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.thread(postId, user.id, dto);
  }

  @Post('posts/:postId/comments')
  create(
    @Param('postId') postId: string,
    @Body() dto: CreateCommunityCommentDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.create(postId, user.id, dto, userMeta(user));
  }

  @Delete('comments/:id')
  remove(@Param('id') id: string, @CurrentUser() user: IUser) {
    return this.svc.removeOwn(id, user.id);
  }

  // -------------------------------------------------------------- admin

  @Post('admin/posts/:postId/comments')
  createOfficial(
    @Param('postId') postId: string,
    @Body() dto: CreateOfficialCommentDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.createOfficial(postId, dto, user.id, userMeta(user));
  }

  @Get('admin/comments')
  findAllAdmin(@Query() dto: GetListCommunityCommentDto) {
    return this.svc.findAllForAdmin(dto);
  }

  @Patch('admin/comments/:id')
  moderate(
    @Param('id') id: string,
    @Body() dto: ModerateCommunityCommentDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.moderate(id, dto, user.id, userMeta(user));
  }
}
