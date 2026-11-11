import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { CurrentUser } from '@base/decorator/current-user.decorator';
import { AuthGuard } from '@base/guard/auth.guard';
import { IUser } from 'src/modules/user/src/modules/auth/interface/user.interface';

import { CommunityOfficialProfileService } from './community-official-profile.service';
import { UpsertCommunityOfficialProfileDto } from './dto/upsert-community-official-profile.dto';
import { userMeta } from '../../helper/community-reader.helper';

/**
 * The team's forum identity — name and picture.
 *
 * Admin-only: readers never fetch this, they get the name and avatar already
 * attached to every official post's author object.
 *
 * `AuthGuard`-only, for the reason written up on CommunityCommentController:
 * nothing populates `role` yet, so a @Roles check 403s the whole panel.
 */
@ApiTags('COMMUNITY-OFFICIAL-PROFILE')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'community', version: '1' })
export class CommunityOfficialProfileController {
  constructor(private readonly svc: CommunityOfficialProfileService) {}

  @Get('admin/official-profile')
  get() {
    return this.svc.get();
  }

  @Put('admin/official-profile')
  upsert(
    @Body() dto: UpsertCommunityOfficialProfileDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.upsert(dto, userMeta(user));
  }
}
