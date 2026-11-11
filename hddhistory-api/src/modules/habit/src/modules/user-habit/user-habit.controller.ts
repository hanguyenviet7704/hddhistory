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

import { CheckInUserHabitDto } from './dto/check-in-user-habit.dto';
import { CreateUserHabitDto } from './dto/create-user-habit.dto';
import { GetCheckinsUserHabitDto } from './dto/get-checkins-user-habit.dto';
import { GetListUserHabitDto } from './dto/get-list-user-habit.dto';
import { UpdateUserHabitDto } from './dto/update-user-habit.dto';
import { UserHabitService } from './user-habit.service';

@ApiTags('USER-HABITS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'user-habits', version: '1' })
export class UserHabitController {
  constructor(private readonly svc: UserHabitService) {}

  @Get('')
  findAll(@Query() dto: GetListUserHabitDto) {
    return this.svc.findAll(dto);
  }

  @Get('summary')
  findSummary() {
    return this.svc.findSummary();
  }

  // Combined Habit-screen payload (config + habits + summary) in one request,
  // so the app makes a single round-trip instead of three concurrent calls.
  // Static segment declared before the `:id` routes so it can't be captured as
  // an id.
  @Get('screen')
  getScreen(@Query() dto: GetListUserHabitDto) {
    return this.svc.getScreenData(dto);
  }

  // Placed before the generic `:id` mutation routes; distinct two-segment
  // pattern (`:id/checkins`) so it never collides with `summary` or a future
  // `:id` GET.
  @Get(':id/checkins')
  getCheckins(
    @Param('id') id: string,
    @Query() dto: GetCheckinsUserHabitDto,
  ) {
    return this.svc.getCheckins(id, dto);
  }

  @Post('')
  adopt(@Body() dto: CreateUserHabitDto) {
    return this.svc.adopt(dto);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateUserHabitDto) {
    return this.svc.update(id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }

  @Post(':id/check-in')
  checkIn(@Param('id') id: string, @Body() dto: CheckInUserHabitDto) {
    return this.svc.checkIn(id, dto);
  }
}
