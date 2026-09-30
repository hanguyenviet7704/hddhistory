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

import { CommunityTopicService } from './community-topic.service';
import { CreateCommunityTopicDto } from './dto/create-community-topic.dto';
import { GetListCommunityTopicDto } from './dto/get-list-community-topic.dto';
import { GetReaderTopicsDto } from './dto/get-reader-topics.dto';
import { UpdateCommunityTopicDto } from './dto/update-community-topic.dto';
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
@ApiTags('COMMUNITY-TOPICS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'community', version: '1' })
export class CommunityTopicController {
  constructor(private readonly svc: CommunityTopicService) {}

  @Get('topics')
  list(@CurrentUser() user: IUser, @ReaderLocale() locale: string, @Query() dto: GetReaderTopicsDto) {
    return this.svc.listForReader(user.id, locale, dto.tzOffset ?? 0);
  }

  @Get('topics/:id')
  findOne(
    @Param('id') id: string,
    @CurrentUser() user: IUser,
    @ReaderLocale() locale: string,
    @Query() dto: GetReaderTopicsDto,
  ) {
    return this.svc.findOneForReader(id, user.id, locale, dto.tzOffset ?? 0);
  }

  @Post('topics/:id/follow')
  follow(@Param('id') id: string, @CurrentUser() user: IUser, @ReaderLocale() locale: string) {
    return this.svc.follow(id, user.id, locale);
  }

  @Delete('topics/:id/follow')
  unfollow(@Param('id') id: string, @CurrentUser() user: IUser, @ReaderLocale() locale: string) {
    return this.svc.unfollow(id, user.id, locale);
  }

  // -------------------------------------------------------------- admin

  @Get('admin/topics')
  findAll(@Query() dto: GetListCommunityTopicDto) {
    return this.svc.findAll(dto);
  }

  @Get('admin/topics/:id')
  findOneAdmin(@Param('id') id: string) {
    return this.svc.findOne(id);
  }

  @Post('admin/topics')
  create(
    @Body() dto: CreateCommunityTopicDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.create(dto, userMeta(user));
  }

  @Patch('admin/topics/:id')
  update(
    @Param('id') id: string,
    @Body() dto: UpdateCommunityTopicDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.update(id, dto, userMeta(user));
  }

  // Deactivates rather than deletes: posts keep pointing at the topic.
  @Delete('admin/topics/:id')
  deactivate(@Param('id') id: string, @CurrentUser() user: IUser) {
    return this.svc.deactivate(id, userMeta(user));
  }
}
