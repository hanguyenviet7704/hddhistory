import {
  Controller,
  Body,
  Get,
  Param,
  Put,
  Post,
  UseGuards,
  Query,
  Delete,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { DeleteUserProgressDto } from './dto/delete-user-progress.dto';
import {
  GetCourseDropOffDto,
  GetDropOffOverviewDto,
} from './dto/get-course-drop-off.dto';
import {
  GetUserProgressDto,
  GetListMyCourseDto,
  GetProgressOfUserDto,
  GetSuggestCoursesWidgetDto,
} from './dto/get-list-user-progress.dto';
import { StatisticsUsersLearningCoursesDto } from './dto/statistics-users-learning-courses.dto';
import {
  UpdateCompletedLevelAdditionalContentRequestDto,
  UpdateExerciseResultDto,
  UpdateKeypointResultDto,
  UpdateLessonResultDto,
} from './dto/user-progress.dto';
import { GradeResultType } from './enum/user-progress.enum';
import { UserProgressService } from './user-progress.service';

@ApiTags('COURSES-USER-PROGRESS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-user-progress', version: '1' })
export class UserProgressController {
  constructor(private readonly svc: UserProgressService) {}

  @Put('/lesson/:lessonId')
  updateLessonResult(
    @Param('lessonId') lessonId: string,
    @Body() dto: UpdateLessonResultDto,
  ) {
    return this.svc.updateUserProgressResult(GradeResultType.LESSON, {
      ...dto,
      lessonId,
    });
  }

  @Put('/keypoints')
  updateKeypointResult(@Body() dto: UpdateKeypointResultDto) {
    return this.svc.updateUserProgressResult(GradeResultType.KEYPOINT, {
      ...dto,
    });
  }

  @Put('/exercises')
  updateKeypointExercises(@Body() dto: UpdateExerciseResultDto) {
    return this.svc.updateUserProgressResult(GradeResultType.EXERCISE, {
      ...dto,
    });
  }

  @Put('/completed-level/additional-content-request')
  updateCompletedLevelAdditionalContentRequest(
    @Body() dto: UpdateCompletedLevelAdditionalContentRequestDto,
  ) {
    return this.svc.updateCompletedLevelAdditionalContentRequest(dto);
  }

  @Delete('')
  deleteUserProgress(@Query() dto: DeleteUserProgressDto) {
    return this.svc.deleteUserProgress(dto);
  }

  @Get('')
  getUserProgress(@Query() dto: GetUserProgressDto) {
    return this.svc.getUserProgress(dto);
  }

  @Get('/my-course')
  getMyCourse(@Query() dto: GetListMyCourseDto) {
    return this.svc.getMyCourse(dto);
  }

  @Get('/widget/in-progress')
  getInProgressWidget() {
    return this.svc.getInProgressWidget();
  }

  @Get('/widget/suggest-course')
  getSuggestCourseWidget() {
    return this.svc.getSuggestCourseWidget();
  }

  @Get('/suggest-courses')
  getSuggestCourses(@Query() dto: GetSuggestCoursesWidgetDto) {
    return this.svc.getSuggestCourses(dto.limit ?? 6);
  }

  @Get('/daily-warm-up')
  getDailyWarmUp() {
    return this.svc.getDailyWarmUp();
  }

  @Get('/users/:userId')
  getProgressOfUser(
    @Param('userId') userId: string,
    @Query() dto: GetProgressOfUserDto,
  ) {
    return this.svc.getProgressOfUser(userId, dto);
  }

  @Get('/users/:userId/courses/:courseId')
  getCourseProgressDetailOfUser(
    @Param('courseId') courseId: string,
    @Param('userId') userId: string,
  ) {
    return this.svc.getCourseProgressDetailOfUser(courseId, userId);
  }

  @Get('/achievements')
  getAchievements() {
    return this.svc.getAchievements();
  }

  @Get('/badge-progress/:courseId')
  getBadgeProgress(@Param('courseId') courseId: string) {
    return this.svc.getBadgeProgress(courseId);
  }

  @Post('/export')
  requestExport() {
    return this.svc.requestExportAllUserProgress();
  }

  @Get('/statistics-users-learning-courses')
  statisticsUsersLearningCourses(
    @Query() dto: StatisticsUsersLearningCoursesDto,
  ) {
    return this.svc.statisticsUsersLearningCourses(dto);
  }

  /**
   * Where this course's readers are stuck, counted per keypoint — the admin
   * "Điểm dừng khoá học" panel. Aggregates `stopAt` across ALL users, so no
   * new client event was needed: the field the resume-lesson push already
   * trusts is the same one this counts.
   */
  @Get('/drop-off')
  courseDropOff(@Query() dto: GetCourseDropOffDto) {
    return this.svc.getCourseDropOff(dto);
  }

  /** Mọi khoá kèm số kẹt — danh sách + xếp hạng của trang drop-off. */
  @Get('/drop-off-overview')
  dropOffOverview(@Query() dto: GetDropOffOverviewDto) {
    return this.svc.getDropOffOverview(dto);
  }
}
