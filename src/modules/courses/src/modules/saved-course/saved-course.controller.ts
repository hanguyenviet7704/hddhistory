import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { GetSavedCoursesDto, SaveCourseDto } from './dto/saved-course.dto';
import { SavedCourseService } from './saved-course.service';

@ApiTags('COURSES-SAVED-COURSE')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'saved-courses', version: '1' })
export class SavedCourseController {
  constructor(private readonly svc: SavedCourseService) {}

  @Get()
  getSaved(@Req() req: any, @Query() dto: GetSavedCoursesDto) {
    return this.svc.getSaved(req.user?.id, dto);
  }

  @Get('/ids')
  getSavedIds(@Req() req: any) {
    return this.svc.getSavedIds(req.user?.id);
  }

  @Post()
  save(@Req() req: any, @Body() dto: SaveCourseDto) {
    return this.svc.save(req.user?.id, dto);
  }

  @Delete('/:courseId')
  remove(@Req() req: any, @Param('courseId') courseId: string) {
    return this.svc.remove(req.user?.id, courseId);
  }
}
