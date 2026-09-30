import {
  Body,
  Controller,
  Get,
  Param,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { ListLearningImportAdminDto } from './dto/list-learning-import.dto';
import { UpdateLearningImportConfigDto } from './dto/update-learning-import-config.dto';
import { LearningImportConfigService } from './learning-import-config.service';
import { LearningImportStatsService } from './learning-import-stats.service';
import { LearningImportService } from './learning-import.service';

/**
 * Read-only feed of every user import, for the admin panel.
 *
 * Two jobs: judging whether the generated lessons are any good (which needs the
 * lesson body, not just a status), and seeing what people actually bring to the
 * feature.
 *
 * `AuthGuard` only, like every other admin-facing route in this codebase.
 * `@Roles(ADMIN)` is not usable here: nothing populates `user.role`, `RoleGuard`
 * is wired nowhere, and applying it has taken the admin panel down before -- see
 * the docblock on `analytics.controller.ts`. That is a pre-existing gap across
 * the whole API rather than something this feature introduces, and closing it is
 * its own piece of work. Nothing here exposes the uploaded file itself.
 */
@ApiTags('LEARNING-IMPORTS-ADMIN')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'admin/learning-imports', version: '1' })
export class LearningImportAdminController {
  constructor(
    private readonly svc: LearningImportService,
    private readonly statsService: LearningImportStatsService,
    private readonly configService: LearningImportConfigService,
  ) {}

  @ApiOperation({
    summary: 'Every import, newest first',
    description:
      'Filter by `status`, or search across filename / video title / URL.',
  })
  @Get('')
  list(@Query() dto: ListLearningImportAdminDto) {
    return this.svc.listJobsForAdmin(dto);
  }

  // Declared BEFORE `:jobId`. Nest matches routes in declaration order, so a
  // wildcard param above these would swallow /stats and /config and hand them to
  // `findOne` as job ids.
  @ApiOperation({
    summary: 'Totals for the admin dashboard',
    description:
      'Counts, cost and failure breakdown, read straight off the job collection.',
  })
  @Get('stats')
  stats() {
    return this.statsService.getStats();
  }

  @ApiOperation({
    summary: 'The feature switch',
    description:
      'Created with `enabled: true` on first read, so an empty collection behaves exactly as the feature did before the switch existed.',
  })
  @Get('config')
  getConfig() {
    return this.configService.getConfig();
  }

  @ApiOperation({
    summary: 'Turn lesson generation on or off',
    description:
      'Closes the CREATE path only: lessons already generated stay readable and running jobs finish.',
  })
  @Put('config')
  updateConfig(@Body() dto: UpdateLearningImportConfigDto) {
    return this.configService.updateConfig(dto);
  }

  @ApiOperation({
    summary: 'One import plus the full lesson it generated',
    description:
      'The lesson body is the point of this endpoint -- it is how prompt quality gets judged.',
  })
  @Get(':jobId')
  findOne(@Param('jobId') jobId: string) {
    return this.svc.getJobForAdmin(jobId);
  }
}
