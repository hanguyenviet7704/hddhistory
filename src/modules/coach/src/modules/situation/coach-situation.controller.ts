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
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { CoachSituationService } from './coach-situation.service';
import {
  GetCoachSituationsDto,
  ImportCoachSituationsDto,
  UpdateCoachSituationDto,
} from './dto/coach-situation.dto';

/**
 * Admin's window onto the situation cache.
 *
 * Not an authoring surface — there is no create. Rows appear when a reader
 * first needs them; this exists so a bad one can be fixed or thrown away after
 * the fact, which is the whole review model this feature chose.
 */
@ApiTags('COACH-SITUATIONS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'coach-situations', version: '1' })
export class CoachSituationController {
  constructor(private readonly svc: CoachSituationService) {}

  @Get('')
  findAll(@Query() dto: GetCoachSituationsDto) {
    return this.svc.findForAdmin(dto);
  }

  @Post('import')
  @ApiOperation({
    summary: 'Bulk-insert hand-authored scenes + scripts.',
    description:
      'Appends pre-written scenes into each key pool WITHOUT calling the model. Rows are marked EDITED so generation never overwrites them. The seed path for warming pools with variety at no provider cost.',
  })
  import(@Body() dto: ImportCoachSituationsDto) {
    return this.svc.importScenes(dto.items);
  }

  @Put(':id')
  @ApiOperation({
    summary: 'Rewrite a scene and its script.',
    description:
      'Edits the scene, its samples, and its script (beats / takeaway / goodMove). Marks the row EDITED so generation never overwrites the fix again. Fields left out are kept as generated.',
  })
  update(@Param('id') id: string, @Body() dto: UpdateCoachSituationDto) {
    return this.svc.updateScript(id, dto);
  }

  @Delete('habit/:habitId')
  @ApiOperation({
    summary: "Rebuild a habit's scene pool.",
    description:
      "Deletes every GENERATED scene of the habit so the next session generates from its current description and contexts. Scenes edited by hand are kept. Call after changing a habit's description or contexts.",
  })
  removeGeneratedForHabit(@Param('habitId') habitId: string) {
    return this.svc.removeGeneratedForHabit(habitId);
  }

  @Delete(':id')
  @ApiOperation({
    summary: 'Throw a scene away so the next reader regenerates it.',
  })
  remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}
