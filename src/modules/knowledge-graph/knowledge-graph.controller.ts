import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { GetRelatedEntityDto, SearchEntityDto } from './dto/search-entity.dto';
import { KnowledgeGraphService } from './knowledge-graph.service';

@ApiTags('KNOWLEDGE-GRAPH')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'knowledge-graph', version: '1' })
export class KnowledgeGraphController {
  constructor(private readonly svc: KnowledgeGraphService) {}

  @ApiOperation({
    summary: 'Toàn cảnh đồ thị: các thời kỳ kèm số thực thể và quy mô dữ liệu',
  })
  @Get('overview')
  getOverview() {
    return this.svc.getOverview();
  }

  @ApiOperation({
    summary:
      'Tìm thực thể theo tên hoặc bí danh (gõ không dấu vẫn khớp), lọc theo loại/thời kỳ',
  })
  @Get('entities')
  search(@Query() dto: SearchEntityDto) {
    return this.svc.search(dto);
  }

  @ApiOperation({
    summary:
      'Hồ sơ một thực thể: mô tả, thời kỳ, đã làm gì, được ai nhắc tới, nguồn',
  })
  @Get('entities/:id')
  getProfile(@Param('id') id: string) {
    return this.svc.getProfile(id);
  }

  @ApiOperation({
    summary: 'Thực thể liên quan, tìm theo đường đi ngắn nhất trên đồ thị',
  })
  @Get('entities/:id/related')
  getRelated(@Param('id') id: string, @Query() dto: GetRelatedEntityDto) {
    return this.svc.getRelated(id, dto);
  }
}
