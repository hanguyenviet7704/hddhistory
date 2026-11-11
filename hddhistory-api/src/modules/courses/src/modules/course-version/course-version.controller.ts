import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { CurrentUser } from '@base/decorator/current-user.decorator';
import { AuthGuard } from '@base/guard/auth.guard';

import { CourseVersionService } from './course-version.service';
import {
  CreateCourseVersionDto,
  SetCurrentVersionDto,
} from './dto/create-course-version.dto';

/**
 * Content tags for one course. Admin surface, `AuthGuard` only -- the same
 * choice every other admin controller here makes, and for the same reason:
 * nothing populates `user.role`, the real admin account is `role: USER`, and
 * `@Roles(UserRole.ADMIN)` has already 403'd the panel three times. See the
 * note on [UserHabitAdminController].
 *
 * See `plans/260907-course-content-versions/README.md` section 5.
 */
@ApiTags('COURSE-VERSIONS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses', version: '1' })
export class CourseVersionController {
  constructor(private readonly courseVersionService: CourseVersionService) {}

  /**
   * Declared before `:courseId/versions` for readability; the two cannot
   * actually collide, since that route needs a literal `versions` in the third
   * segment and this one has `backfill` there.
   */
  @Post('versions/backfill')
  @ApiOperation({
    summary:
      'Give every untagged course a v1.0.0 of what it serves today and point it there. Idempotent; run once per environment.',
  })
  backfill() {
    return this.courseVersionService.backfill();
  }

  @Get(':courseId/versions')
  @ApiOperation({
    summary:
      'Tag history, the tag being served, the next patch name to offer, and the working-tree changes not in any tag yet.',
  })
  list(@Param('courseId') courseId: string) {
    return this.courseVersionService.listVersions(courseId);
  }

  @Post(':courseId/versions')
  @ApiOperation({
    summary:
      'Freeze the working tree under a tag. Does not publish unless setCurrent is true.',
  })
  create(
    @Param('courseId') courseId: string,
    @Body() dto: CreateCourseVersionDto,
    @CurrentUser() user: IUserMeta,
  ) {
    // The one tagging path with a person behind it, so the one that waits for
    // audio — see `createTag`'s `opts`.
    return this.courseVersionService.createTag(courseId, dto, user, {
      enforceAudio: true,
    });
  }

  @Put(':courseId/current-version')
  @ApiOperation({
    summary:
      'Publish an existing tag — this is also how a rollback is done. One field write; no content is rewritten.',
  })
  setCurrent(
    @Param('courseId') courseId: string,
    @Body() dto: SetCurrentVersionDto,
  ) {
    return this.courseVersionService.setCurrent(courseId, dto.tag);
  }

  @Get(':courseId/versions/:tag/audio-coverage')
  @ApiOperation({
    summary:
      "Audio coverage of ONE tag: keypoint × language, judged against that tag's own text. `complete: false` is what blocks publishing it.",
  })
  audioCoverage(
    @Param('courseId') courseId: string,
    @Param('tag') tag: string,
  ) {
    return this.courseVersionService.audioCoverageOf(courseId, tag);
  }

  @Post(':courseId/versions/:tag/dub-missing')
  @ApiOperation({
    summary:
      "Record every card this tag is missing, reading the tag's own text. Runs in the background; poll dub-status.",
  })
  dubMissing(@Param('courseId') courseId: string, @Param('tag') tag: string) {
    return this.courseVersionService.dubMissingOf(courseId, tag);
  }

  @Get('versions/dub-status')
  @ApiOperation({ summary: 'Progress of the version dub run, if one is going.' })
  dubStatus() {
    return this.courseVersionService.dubStatus();
  }

  @Delete(':courseId/versions/:tag')
  @ApiOperation({
    summary:
      'Delete a tag and its frozen content. Refused for the tag the course is currently serving.',
  })
  remove(@Param('courseId') courseId: string, @Param('tag') tag: string) {
    return this.courseVersionService.deleteTag(courseId, tag);
  }
}
