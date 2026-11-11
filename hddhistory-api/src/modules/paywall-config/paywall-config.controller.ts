import {
  Body,
  Controller,
  Get,
  Header,
  Param,
  ParseIntPipe,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';

import { Public } from '@base/decorator/public';
import { AuthGuard } from '@base/guard/auth.guard';
import { JwtUtil } from '@utils/jwt';

import { PaywallConfigDto } from './dto/paywall-config.dto';
import { GetPaywallExperimentStatsDto } from './dto/paywall-experiment-stats.dto';
import { PaywallConfigService } from './paywall-config.service';

/**
 * Lets the admin panel edit `paywall_config` (the config the Flutter paywall
 * reads) with MySQL as the source of truth -- each environment's API talks to
 * its own database, so dev/prod separation is the deployment topology, not a
 * Remote Config condition. See `PaywallConfigService` for the append-only
 * versioning and the first-read Remote Config seed.
 */
@ApiTags('PAYWALL-CONFIG')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'paywall-config', version: '1' })
export class PaywallConfigController {
  constructor(
    private readonly svc: PaywallConfigService,
    private readonly jwt: JwtUtil,
  ) {}

  @Get()
  getConfig() {
    return this.svc.getConfig();
  }

  @Put()
  updateConfig(@Body() dto: PaywallConfigDto) {
    return this.svc.updateConfig(dto);
  }

  @Get('versions')
  getVersions() {
    return this.svc.getVersions();
  }

  @Post('restore/:version')
  restore(@Param('version', ParseIntPipe) version: number) {
    return this.svc.restore(version);
  }

  // Public: the app may need this before an (anonymous) session token is
  // guaranteed to be attached, and it carries no user data. Short cache so a
  // freshly published change reaches the app quickly without every launch
  // hitting the database.
  @Public()
  @Get('mobile')
  @Header('Cache-Control', 'public, max-age=60')
  getMobileConfig() {
    return this.svc.getMobileConfig();
  }

  /**
   * The one LogicSale that applies to THIS viewer — asked when the paywall
   * opens. `@Public` like `/mobile` (the paywall must never 401 into a blank
   * screen), with the viewer decoded best-effort from the token the app sends
   * anyway; an unknown viewer simply never matches a segment-targeted
   * campaign. `private` cache: the answer varies per user.
   */
  @Public()
  @Get('logic-sale')
  @Header('Cache-Control', 'private, max-age=60')
  getLogicSale(@Req() req: Request) {
    return this.svc.resolveLogicSaleFor(this.viewerIdOf(req), this.langOf(req));
  }

  /** Orders + revenue per plan for one LogicSale — the admin's stats block. */
  @Get('logic-sales/:id/stats')
  getLogicSaleStats(@Param('id') id: string) {
    return this.svc.logicSaleStats(id);
  }

  /**
   * The body A/B readout for the run on the CURRENT version: funnel per arm
   * from the app's events, orders and revenue per arm from verified purchases.
   *
   * The window defaults to the last 30 days and `appEnv` to `prod` — the two
   * answers an admin opening this screen wants without typing anything. Both
   * are query params because reading a finished run back (or checking a dev
   * build's events) is the same question over a different window.
   */
  @Get('experiment/stats')
  getBodyExperimentStats(@Query() dto: GetPaywallExperimentStatsDto) {
    return this.svc.bodyExperimentStats(dto.resolve());
  }

  /** Best-effort viewer identity on a @Public route — same move as the Home
   * banner's: decode-if-present, never reject. */
  private viewerIdOf(req: Request): string {
    const token = (req.headers['authorization'] ?? '').split(' ')[1];
    if (!token) return '';

    return this.jwt.verify<{ id?: string }>(token)?.id ?? '';
  }

  /**
   * The viewer's UI language, from the `lang` header the app sets on every
   * request (`AppInterceptor`). Only the body experiment reads it, to keep a
   * viewer whose locale has no comparison rows out of the test rather than
   * showing them an English table.
   */
  private langOf(req: Request): string {
    const raw = req.headers['lang'];

    return (Array.isArray(raw) ? raw[0] : raw) ?? '';
  }
}
