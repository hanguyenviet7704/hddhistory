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
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import {
  ListUserLessonDto,
  UpdateUserLessonProgressDto,
} from './dto/list-learning-import.dto';
import { UserLessonService } from './user-lesson.service';

/**
 * The lessons a user generated from their own material.
 *
 * Every route here is scoped to the caller at the repository layer -- this
 * content was built from documents users uploaded themselves and is never
 * visible to anyone else through this controller.
 */
@ApiTags('USER-LESSONS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'user-lessons', version: '1' })
export class UserLessonController {
  constructor(private readonly svc: UserLessonService) {}

  @ApiOperation({
    summary: "The caller's generated lessons",
    description: 'Cards only -- the lesson body is not included in the list.',
  })
  @Get('')
  list(@Query() dto: ListUserLessonDto) {
    return this.svc.list(dto);
  }

  @ApiOperation({ summary: 'One lesson, including every section' })
  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.svc.findOne(id);
  }

  @ApiOperation({
    summary: 'Remember how far the reader got',
    description:
      'Clamped to the lesson length server-side; an out-of-range index is stored at the last section rather than rejected.',
  })
  @Patch(':id/progress')
  updateProgress(
    @Param('id') id: string,
    @Body() dto: UpdateUserLessonProgressDto,
  ) {
    return this.svc.updateProgress(id, dto);
  }

  @ApiOperation({
    summary: 'Ask for more content on a finished lesson',
    description:
      'Records the wish only -- nothing is generated and no import quota is spent. 400 while the lesson is unread; calling twice keeps the first date and answers the same way.',
  })
  @Post(':id/additional-content-request')
  requestAdditionalContent(@Param('id') id: string) {
    return this.svc.requestAdditionalContent(id);
  }

  @ApiOperation({ summary: 'Delete a generated lesson' })
  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}
