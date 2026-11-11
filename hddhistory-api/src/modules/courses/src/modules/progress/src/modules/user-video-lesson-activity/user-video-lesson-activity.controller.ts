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
  CreateUserVideoLessonNoteDto,
  GetListUserVideoLessonActivityDto,
  UpdateUserVideoLessonNoteDto,
} from './dto/user-video-lesson-activity.dto';
import { UserVideoLessonActivityService } from './user-video-lesson-activity.service';

@ApiTags('COURSES-USER-VIDEO-LESSON-ACTIVITY')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-user-video-lesson-activity', version: '1' })
export class UserVideoLessonActivityController {
  constructor(private readonly svc: UserVideoLessonActivityService) {}

  @Get()
  findAll(@Query() dto: GetListUserVideoLessonActivityDto) {
    return this.svc.findAll(dto);
  }

  @Post()
  register(@Body() dto: CreateUserVideoLessonNoteDto) {
    return this.svc.addNote(dto);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.svc.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateUserVideoLessonNoteDto) {
    return this.svc.updateNote(id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.svc.deleteNote(id);
  }
}
