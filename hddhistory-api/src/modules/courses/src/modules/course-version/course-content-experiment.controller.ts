import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';
import { CurrentUser } from '@base/decorator/current-user.decorator';
import { AuthGuard } from '@base/guard/auth.guard';

import { CourseContentExperimentService } from './course-content-experiment.service';
import {
  CreateContentExperimentDto,
  SetExperimentEnabledDto,
} from './dto/course-content-experiment.dto';

/**
 * A/B nội dung khoá học. Path riêng chứ không nhét dưới `courses/`: đường
 * `courses/content-experiments` sẽ khớp vào `@Get(':id')` sẵn có của
 * CourseController với `id = 'content-experiments'`.
 *
 * `AuthGuard` only — cùng lựa chọn với mọi controller admin khác ở đây, và
 * cùng lý do: không có gì populate `user.role`, tài khoản admin thật có
 * `role: USER`, và `@Roles(UserRole.ADMIN)` đã 403 cả panel ba lần.
 */
@ApiTags('COURSE-CONTENT-EXPERIMENTS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'course-content-experiments', version: '1' })
export class CourseContentExperimentController {
  constructor(private readonly svc: CourseContentExperimentService) {}

  @Get('')
  @ApiOperation({ summary: 'Danh sách đợt, mới nhất trước.' })
  list() {
    return this.svc.list();
  }

  @Post('')
  @ApiOperation({
    summary:
      'Tạo đợt. Luôn ở trạng thái TẮT — bật trước khi app biết đóng dấu nhánh là phục vụ hai bản khác nhau mà không đo được gì.',
  })
  create(
    @Body() dto: CreateContentExperimentDto,
    @CurrentUser() user: IUserMeta,
  ) {
    return this.svc.create(dto, user);
  }

  @Put(':id/enabled')
  @ApiOperation({
    summary:
      'Bật/tắt đợt. Bật thì kiểm lại hai nhánh còn tra được tag; có hiệu lực ngay (dọn cache khoá-trong-đợt).',
  })
  setEnabled(@Param('id') id: string, @Body() dto: SetExperimentEnabledDto) {
    return this.svc.setEnabled(id, dto.enabled);
  }

  @Get(':key/stats')
  @ApiOperation({
    summary:
      'Phễu theo NGƯỜI của một đợt, lọc theo key nên không trộn hai đợt trùng cửa sổ thời gian.',
  })
  stats(@Param('key') key: string, @Query('env') env?: string) {
    return this.svc.stats(key, env || 'dev');
  }
}
