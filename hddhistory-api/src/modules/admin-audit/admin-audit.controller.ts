import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { AdminAuditService } from './admin-audit.service';
import { GetAdminAuditDto } from './dto/admin-audit.dto';

@ApiTags('ADMIN-AUDIT')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'admin-audit', version: '1' })
export class AdminAuditController {
  constructor(private readonly svc: AdminAuditService) {}

  @Get('')
  @ApiOperation({
    summary: 'Nhật ký thao tác của admin: ai làm gì, lúc nào, gửi lên cái gì.',
    description:
      'Chỉ ghi thao tác GHI (POST/PUT/PATCH/DELETE) của tài khoản có vai trò ADMIN, và chỉ tính từ lúc tính năng này được deploy — thao tác trước đó không lưu ở đâu nên không dựng lại được.',
  })
  list(@Query() dto: GetAdminAuditDto) {
    return this.svc.list(dto);
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Một thao tác, kèm danh sách trường đã đổi so với lần lưu trước.',
    description:
      '`changes: null` nghĩa là KHÔNG so được (chưa có lần lưu nào trước đó ở khu vực này, hoặc nội dung đã bị cắt vì quá dài). `changes: []` nghĩa là có bấm lưu nhưng không đổi gì.',
  })
  detail(@Param('id') id: string) {
    return this.svc.detail(id);
  }
}
