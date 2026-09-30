import {
  Controller,
  Delete,
  Get,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CoachContentService } from './coach-content.service';
import {
  DeleteCoachContentDto,
  GetCoachContentsDto,
  GetCoachContentUsersDto,
  GetCoachThreadDto,
} from './dto/coach-content.dto';

/**
 * Everything readers have typed into the coach, in one feed.
 *
 * `AuthGuard`-only for the same reason every other admin controller in this
 * feature is — see the long note on `CoachRatingController`. That note matters
 * more here than anywhere else in the product: this endpoint returns people's
 * own words about difficult things.
 */
@ApiTags('COACH-CONTENTS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'coach-contents', version: '1' })
export class CoachContentController {
  constructor(private readonly svc: CoachContentService) {}

  @Get('users/:userId/thread')
  @ApiOperation({
    summary: 'Toàn bộ lịch sử Coach của một user, đã dựng thành hội thoại.',
    description:
      'Mỗi phiên trả về kèm `source`: `transcript` là đọc nguyên văn từ `coach_sessions.turns` (phiên còn trong hạn `COACH_SESSION_TTL_HOURS`), `derived` là dựng lại từ các bản ghi bền vì phiên đã bị xoá — khi đó chữ user là thật còn lời Coach chỉ có với câu hỏi tình huống. Tin nhắn Coach `text: null` nghĩa là câu cố định, client tự điền theo `kind` và phải đánh dấu là tái dựng.',
  })
  findThread(
    @Param('userId') userId: string,
    @Query() dto: GetCoachThreadDto,
  ) {
    return this.svc.findThreadForAdmin({ ...dto, userId });
  }

  @Get('users')
  @ApiOperation({
    summary: 'Danh sách user có viết, mới viết gần nhất lên đầu.',
    description:
      'Cùng bộ lọc với feed. `lastAt` là mốc sắp xếp; `byKind` đếm đủ sáu loại kể cả 0. Lưu ý loại `dip` đọc từ phiên nên chỉ có dữ liệu trong `COACH_SESSION_TTL_HOURS` giờ gần nhất.',
  })
  findUsers(@Query() dto: GetCoachContentUsersDto) {
    return this.svc.findUsersForAdmin(dto);
  }

  @Get('')
  @ApiOperation({
    summary: 'Chữ do user tự viết: câu kể, vấn đề thật, ghi nhanh, rào cản, câu trả lời tình huống, dịp.',
    description:
      'KHÔNG có hội thoại đầy đủ: lời Coach nói chỉ nằm trong phiên (`coach_sessions.turns`) và Mongo xoá phiên sau `COACH_SESSION_TTL_HOURS` giờ. Riêng câu trả lời tình huống có kèm `meta.situationPrompt` — chữ của biên tập viên nên còn lâu dài. Mỗi nguồn bị chặn ở `limit` rồi trộn lại, nên `truncated: true` nghĩa là còn dữ liệu chưa hiện: thu hẹp khoảng ngày hoặc lọc theo loại.',
  })
  findAll(@Query() dto: GetCoachContentsDto) {
    return this.svc.findForAdmin(dto);
  }

  @Delete(':kind/:id')
  @ApiOperation({
    summary: 'Xoá hẳn một dòng nội dung.',
    description:
      'Xoá cứng, không hoàn tác. Loại quyết định nguồn: `evidence`, `situation_answer` và ba loại statement là xoá document; `dip` là field trên phiên nên chỉ `$unset` field đó, phiên và transcript giữ nguyên — id của dịp mang hậu tố `:dip` đúng như feed phát ra. Không trúng dòng nào thì 404 chứ không báo thành công.',
  })
  remove(@Param() dto: DeleteCoachContentDto) {
    return this.svc.removeForAdmin(dto.kind, dto.id);
  }
}
