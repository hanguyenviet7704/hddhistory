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

import { UpsertSegmentDto } from './dto/upsert-segment.dto';
import { SegmentService } from './segment.service';

/**
 * Audience segments — created and read by the ADMIN panel only, which is why
 * nothing here is `@Public`. The app never asks about segments: the banner
 * and popup reads apply them server-side.
 */
@ApiTags('SEGMENT')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'segments', version: '1' })
export class SegmentController {
  constructor(private readonly svc: SegmentService) {}

  @Get('')
  list() {
    return this.svc.list();
  }

  /**
   * |A|, |B| and |A∩B| for the Venn view. Declared BEFORE the :id routes so
   * "overlap" is never captured as a segment id.
   */
  @Get('overlap')
  overlap(@Query('a') a: string, @Query('b') b: string) {
    return this.svc.overlap(a, b);
  }

  @Post('')
  create(@Body() dto: UpsertSegmentDto) {
    return this.svc.create(dto);
  }

  /** Live member count + snapshot history (last 90 days) for the charts. */
  @Get(':id/stats')
  stats(@Param('id') id: string) {
    return this.svc.statsFor(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpsertSegmentDto) {
    return this.svc.update(id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}
