import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { ExploreService } from './explore.service';

/**
 * Path is `courses-explore`, not `courses/explore`, to match the sibling
 * surfaces (`courses-recently-viewed`) and because a `courses/:id` route in
 * another module would otherwise be free to swallow the literal segment
 * depending on registration order.
 */
@ApiTags('COURSES-EXPLORE')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-explore', version: '1' })
export class ExploreController {
  constructor(private readonly svc: ExploreService) {}

  @Get('')
  getExplore(@Req() req: any) {
    return this.svc.getExplore(req.user?.id, req.headers);
  }
}
