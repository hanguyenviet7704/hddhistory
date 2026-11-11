import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CoachConfigService } from './coach-config.service';
import { UpdateCoachConfigDto } from './dto/update-coach-config.dto';

/**
 * The Coach's master switch and its crisis lines.
 *
 * ## Why this is AuthGuard-only, not @Roles(ADMIN)
 *
 * The same reason every other admin controller here is — see
 * `user-habit-admin.controller.ts` for the long version. Nothing populates
 * `user.role` (the real admin account is `role: USER`), and `PUT /users/:id`
 * lets any caller set their own role behind `AuthGuard` alone, so the decorator
 * would 403 the admin panel and secure nothing. It is a real trust gap — this
 * one reads other people's words — but it is the SAME gap the whole admin
 * surface has, and closing it means fixing `PUT /users/:id` and the role data
 * first, then reinstating the guard everywhere at once.
 */
@ApiTags('COACH-CONFIG')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'coach-config', version: '1' })
export class CoachConfigController {
  constructor(private readonly svc: CoachConfigService) {}

  @Get('')
  get() {
    return this.svc.get();
  }

  @Put('')
  update(@Body() dto: UpdateCoachConfigDto) {
    return this.svc.update(dto);
  }
}
