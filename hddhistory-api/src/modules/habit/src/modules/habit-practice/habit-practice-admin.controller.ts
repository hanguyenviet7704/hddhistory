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

import { AuthGuard } from '@base/guard/auth.guard';

import {
  CreateHabitPracticeDto,
  GetListHabitPracticeDto,
  UpdateHabitPracticeDto,
} from './dto/habit-practice.dto';
import { HabitPracticeService } from './habit-practice.service';

/**
 * Admin surface for wiring a habit to the authored content it practises. Split
 * from [HabitPracticeController] so the trust boundary shows in the file layout.
 *
 * AuthGuard-only, for the same reason as [UserHabitAdminController] — see the
 * note there. Short version: `@Roles(UserRole.ADMIN)` shipped here and 403'd the
 * admin panel, because nothing populates `role` (every account defaults to
 * `USER`, no other endpoint uses `RoleGuard`) and `PUT /users/:id` lets any
 * authenticated caller set their own role anyway.
 */
@ApiTags('HABIT-PRACTICES-ADMIN')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'habit-practices/admin', version: '1' })
export class HabitPracticeAdminController {
  constructor(private readonly svc: HabitPracticeService) {}

  @Get('')
  findAll(@Query() dto: GetListHabitPracticeDto) {
    return this.svc.findAllForHabitAdmin(dto);
  }

  @Post('')
  create(@Body() dto: CreateHabitPracticeDto) {
    return this.svc.create(dto);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateHabitPracticeDto) {
    return this.svc.update(id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}
