import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { DownloadLinkService } from './download-link.service';
import { CreateDownloadLinkDto } from './dto/create-download-link.dto';
import {
  GetDownloadLinkStatsDto,
  GetListDownloadLinkDto,
} from './dto/get-download-link.dto';
import { UpdateDownloadLinkDto } from './dto/update-download-link.dto';

/**
 * Admin CRUD for shareable download links. The public side -- the redirect
 * visitors actually hit -- lives in `DownloadLinkRedirectController` on its
 * own `/r` path.
 */
@ApiTags('DOWNLOAD-LINKS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'download-links', version: '1' })
export class DownloadLinkController {
  constructor(private readonly svc: DownloadLinkService) {}

  @Get()
  findAll(@Query() dto: GetListDownloadLinkDto) {
    return this.svc.findAll(dto);
  }

  // Declared before `:id` on purpose. Nest matches routes in declaration
  // order, so a bare `:id` registered first would swallow `:id/stats`.
  @Get(':id/stats')
  stats(@Param('id') id: string, @Query() dto: GetDownloadLinkStatsDto) {
    return this.svc.stats(id, dto);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.svc.findOne(id);
  }

  @Post()
  create(@Body() dto: CreateDownloadLinkDto) {
    return this.svc.create(dto);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateDownloadLinkDto) {
    return this.svc.update(id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}
