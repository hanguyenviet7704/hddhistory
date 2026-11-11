import { Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';

import { AuthGuard } from '@base/guard/auth.guard';

import { KeypointAccessService } from './keypoint-access.service';
import { resolveTimezoneOffsetMinutes } from './keypoint-access.util';

/**
 * How much of a keypoint this reader may read, and the one call that spends their
 * daily free ticket.
 *
 * Authenticated by definition: the answer is a fact about the caller's own history,
 * so there is nothing to say without knowing who they are.
 *
 * Never cached, not even privately. A 60-second cache here would keep saying
 * "locked" for a minute after the reader spent their ticket, or "open" after it ran
 * out — and this response decides whether paid content is shown.
 */
@ApiTags('KEYPOINT-ACCESS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'keypoint-access', version: '1' })
export class KeypointAccessController {
  constructor(private readonly svc: KeypointAccessService) {}

  /**
   * Read-only: what the app should cap this keypoint at. Called on keypoint entry,
   * spends nothing.
   */
  @Get(':keypointId')
  getAccess(@Param('keypointId') keypointId: string, @Req() req: Request) {
    return this.svc.getAccess(
      keypointId,
      // The reader's own day decides which ticket applies -- same header the
      // learning streak buckets by.
      resolveTimezoneOffsetMinutes(req.get('x-timezone-offset')),
    );
  }

  /**
   * Spends today's ticket on this keypoint. Called when the reader tries to move
   * past the lock, so opening a keypoint and leaving costs nothing.
   *
   * Idempotent for the SAME keypoint (they already hold the ticket, so they get it
   * again); refused for a second, different keypoint the same day.
   */
  @Post(':keypointId/claim')
  claim(@Param('keypointId') keypointId: string, @Req() req: Request) {
    return this.svc.claim(
      keypointId,
      resolveTimezoneOffsetMinutes(req.get('x-timezone-offset')),
    );
  }
}
