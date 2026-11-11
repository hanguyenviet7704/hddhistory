import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CourseVersionAnalyticsService } from './course-version-analytics.service';

/**
 * Bảng so sánh phiên bản nội dung của một khoá.
 *
 * Path riêng, KHÔNG nhét dưới `courses/`: `courses/version-analytics` sẽ khớp
 * vào `@Get(':id')` sẵn có của CourseController với `id = 'version-analytics'`
 * — cùng cái bẫy đã bắt `course-content-experiments`.
 *
 * Hai route đều đặt tên literal (`courses`, `compare/:courseId`) thay vì để
 * một route `:courseId` đứng cạnh route `courses`, để thứ tự khai báo không
 * phải là thứ giữ cho chúng không đụng nhau.
 *
 * `AuthGuard` only — `user.role` không được populate ở đâu cả, tài khoản admin
 * thật có `role: USER`, nên `@Roles(UserRole.ADMIN)` sẽ 403 cả trang.
 */
@ApiTags('COURSE-VERSION-ANALYTICS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'course-version-analytics', version: '1' })
export class CourseVersionAnalyticsController {
  constructor(private readonly svc: CourseVersionAnalyticsService) {}

  @Get('courses')
  @ApiOperation({
    summary: 'Khoá có thể so sánh — khoá đã có ít nhất một tag nội dung.',
  })
  courses() {
    return this.svc.comparableCourses();
  }

  @Get('compare/:courseId')
  @ApiOperation({
    summary:
      'Số của MỌI phiên bản của khoá: 7 chỉ số, đường giữ chân và độ sâu theo bài. Trả hết để trang tự chọn bản mốc và tự tính chênh lệch mà không phải gọi lại.',
  })
  compare(@Param('courseId') courseId: string, @Query('env') env?: string) {
    return this.svc.compare(courseId, env || 'dev');
  }
}
