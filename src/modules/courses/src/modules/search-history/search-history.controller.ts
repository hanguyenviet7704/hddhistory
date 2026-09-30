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

import { SaveSearchHistoryDto } from './dto/search-history.dto';
import { SearchHistoryService } from './search-history.service';

@ApiTags('COURSES-SEARCH-HISTORY')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-search-history', version: '1' })
export class SearchHistoryController {
  constructor(private readonly svc: SearchHistoryService) {}

  @Get()
  getRecent(@Req() req: any) {
    return this.svc.getRecent(req.user?.id);
  }

  @Post()
  saveQuery(@Req() req: any, @Body() dto: SaveSearchHistoryDto) {
    return this.svc.saveQuery(req.user?.id, dto);
  }

  @Delete()
  clearAll(@Req() req: any) {
    return this.svc.clearAll(req.user?.id);
  }
}
