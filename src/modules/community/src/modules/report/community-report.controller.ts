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

import { CommunityReportService } from './community-report.service';
import { CreateCommunityReportDto } from './dto/create-community-report.dto';
import { GetListCommunityReportDto } from './dto/get-list-community-report.dto';
import { ResolveCommunityReportDto } from './dto/resolve-community-report.dto';
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
@ApiTags('COMMUNITY-REPORTS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'community', version: '1' })
export class CommunityReportController {
  constructor(private readonly svc: CommunityReportService) {}

  @Post('reports')
  create(@Body() dto: CreateCommunityReportDto, @CurrentUser() user: IUser) {
    return this.svc.create(user.id, dto);
  }

  // -------------------------------------------------------------- admin

  @Get('admin/reports')
  findAll(@Query() dto: GetListCommunityReportDto) {
    return this.svc.findAll(dto);
  }

  @Patch('admin/reports/:id')
  resolve(
    @Param('id') id: string,
    @Body() dto: ResolveCommunityReportDto,
    @CurrentUser() user: IUser,
  ) {
    return this.svc.resolve(id, dto, user.id, userMeta(user));
  }
}
