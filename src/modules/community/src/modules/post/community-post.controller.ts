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

import { CommunityPostService } from './community-post.service';
import { CreateCommunityPostDto } from './dto/create-community-post.dto';
import { CreateOfficialPostDto } from './dto/create-official-post.dto';
import { GetCommunityFeedDto } from './dto/get-community-feed.dto';
import { GetListCommunityPostDto } from './dto/get-list-community-post.dto';
import { ModerateCommunityPostDto } from './dto/moderate-community-post.dto';
import { UpsertWeeklyQuestionDto } from './dto/upsert-weekly-question.dto';
import { ReaderLocale, userMeta } from '../../helper/community-reader.helper';

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
@ApiTags('COMMUNITY-POSTS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'community', version: '1' })
export class CommunityPostController {
  constructor(private readonly svc: CommunityPostService) {}

  @Get('feed')
  feed(@Query() dto: GetCommunityFeedDto, @CurrentUser() user: IUser, @ReaderLocale() locale: string) {
    return this.svc.feed(user.id, locale, dto);
  }

  @Get('saved')
  saved(@Query() dto: GetCommunityFeedDto, @CurrentUser() user: IUser, @ReaderLocale() locale: string) {
    return this.svc.savedPosts(user.id, locale, dto.page, dto.take);
  }

  @Get('weekly')
  weekly(@CurrentUser() user: IUser, @ReaderLocale() locale: string) {
    return this.svc.weekly(locale);
  }

  @Get('posts/:id')
  findOne(@Param('id') id: string, @CurrentUser() user: IUser, @ReaderLocale() locale: string) {
    return this.svc.findOneForReader(id, user.id, locale);
  }

  @Post('posts')
  create(@Body() dto: CreateCommunityPostDto, @CurrentUser() user: IUser, @ReaderLocale() locale: string) {
    return this.svc.create(user.id, locale, dto, userMeta(user));
  }

  @Delete('posts/:id')
  remove(@Param('id') id: string, @CurrentUser() user: IUser) {
    return this.svc.removeOwn(id, user.id);
  }

  // -------------------------------------------------------------- admin

  @Get('admin/posts')
  findAllAdmin(@Query() dto: GetListCommunityPostDto) {
    return this.svc.findAllForAdmin(dto);
  }

  @Patch('admin/posts/:id')
  moderate(
    @Param('id') id: string,
    @Body() dto: ModerateCommunityPostDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.moderate(id, dto, user.id, userMeta(user));
  }

  @Post('admin/posts/official')
  createOfficial(
    @Body() dto: CreateOfficialPostDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.createOfficial(dto, user.id, userMeta(user));
  }

  @Get('admin/weekly')
  listWeekly(@Query() dto: GetListCommunityPostDto) {
    return this.svc.listWeeklyForAdmin(dto);
  }

  @Post('admin/weekly')
  createWeekly(
    @Body() dto: UpsertWeeklyQuestionDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.createWeekly(dto, user.id, userMeta(user));
  }

  @Patch('admin/weekly/:id')
  updateWeekly(
    @Param('id') id: string,
    @Body() dto: UpsertWeeklyQuestionDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.updateWeekly(id, dto, userMeta(user));
  }
}
