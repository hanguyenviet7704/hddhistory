import {
  Body,
  Controller,
  Delete,
  Get,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { RecordCourseViewDto } from './dto/recently-viewed.dto';
import { RecentlyViewedService } from './recently-viewed.service';

@ApiTags('COURSES-RECENTLY-VIEWED')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-recently-viewed', version: '1' })
export class RecentlyViewedController {
  constructor(private readonly svc: RecentlyViewedService) {}

  @Get()
  getRecent(@Req() req: any) {
    return this.svc.getRecent(req.user?.id);
  }

  @Post()
  recordView(@Req() req: any, @Body() dto: RecordCourseViewDto) {
    return this.svc.recordView(req.user?.id, dto);
  }

  @Delete()
  clearAll(@Req() req: any) {
    return this.svc.clearAll(req.user?.id);
  }
}
