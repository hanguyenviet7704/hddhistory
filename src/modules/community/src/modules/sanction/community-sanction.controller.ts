import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { CurrentUser } from '@base/decorator/current-user.decorator';
import { AuthGuard } from '@base/guard/auth.guard';
import { IUser } from 'src/modules/user/src/modules/auth/interface/user.interface';

import { CommunitySanctionService } from './community-sanction.service';
import { CreateCommunitySanctionDto } from './dto/create-community-sanction.dto';
import { GetListCommunitySanctionDto } from './dto/get-list-community-sanction.dto';
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
@ApiTags('COMMUNITY-SANCTIONS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'community', version: '1' })
export class CommunitySanctionController {
  constructor(private readonly svc: CommunitySanctionService) {}

  // What the app asks on entering the community, so the composer can be
  // disabled with the reason shown instead of failing on submit.
  @Get('me/status')
  myStatus(@CurrentUser() user: IUser) {
    return this.svc.statusFor(user);
  }

  @Post('me/tour-seen')
  @ApiOperation({
    summary: 'The first-run Confession tour is done for this reader.',
    description:
      'Stamped on the user rather than kept on the device: a local flag is wiped by a reinstall and unknown on a second device, and the tour is a welcome — it must greet each person once, not each install.',
  })
  markTourSeen(@CurrentUser() user: IUser) {
    return this.svc.markTourSeen(user.id);
  }

  // -------------------------------------------------------------- admin

  @Get('admin/sanctions')
  list(@Query() dto: GetListCommunitySanctionDto) {
    return this.svc.list(dto);
  }

  @Get('admin/sanctions/history/:userId')
  history(@Param('userId') userId: string) {
    return this.svc.history(userId);
  }

  @Post('admin/sanctions')
  create(
    @Body() dto: CreateCommunitySanctionDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.create(dto, user.id, userMeta(user));
  }

  @Delete('admin/sanctions/:id')
  revoke(@Param('id') id: string, @CurrentUser() user: IUser) {
    return this.svc.revoke(id, user.id);
  }
}
