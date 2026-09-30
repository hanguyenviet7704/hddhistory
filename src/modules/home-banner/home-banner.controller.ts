import {
  Body,
  Controller,
  Get,
  Header,
  Post,
  Put,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';

import { Public } from '@base/decorator/public';
import { AuthGuard } from '@base/guard/auth.guard';
import { JwtUtil } from '@utils/jwt';
import {
  resolveViewerLanguage,
  resolveViewerMarkets,
} from '@utils/viewer-market.util';

import { TrackHomeBannerDto } from './dto/track-home-banner.dto';
import { UpdateHomeBannerConfigDto } from './dto/update-home-banner-config.dto';
import { HomeBannerService } from './home-banner.service';

/**
 * The promotional banner slot on the Home screen (design `2 · Home`): a
 * full-width image between "Today's new course" and "Jump back in". Image,
 * tap destination, and visibility are all admin config so a campaign can run
 * without an app release.
 */
@ApiTags('HOME-BANNER')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'home-banner', version: '1' })
export class HomeBannerController {
  constructor(
    private readonly svc: HomeBannerService,
    private readonly jwt: JwtUtil,
  ) {}

  /**
   * The banner as THIS caller should see it.
   *
   * `private`, not `public`. The response varies per viewer, and this route sits
   * behind Cloudflare: a shared cache would happily hand a Vietnam-targeted
   * banner to someone in Japan, with no error and nothing in the logs — it would
   * surface only as a confused report from abroad. `private` keeps the
   * device-side cache (which absorbs repeat Home opens) and gives up the shared
   * one, which is the half that could be wrong. Note the response now varies by
   * `lang` too, and `lang` is not in any cache key — another reason the shared
   * cache stays off.
   *
   * Reading the headers is transport work, so it happens here; the service is
   * handed the resolved markets and decides.
   */
  @Public()
  @Get('')
  @Header('Cache-Control', 'private, max-age=60')
  getConfig(@Req() req: Request) {
    const viewerMarkets = resolveViewerMarkets({
      // Set by Cloudflare on every request that reaches us through it. Same
      // header `download-link` already records click countries from. Where the
      // phone IS.
      cfCountry: req.get('cf-ipcountry'),
      // The device's own region. Also the only country signal on requests that
      // never went through Cloudflare — in practice, local development.
      deviceCountry: req.get('x-device-country'),
      // The language the reader chose in the app. What reaches a diaspora: a
      // Vietnamese in Japan has a JP address and often a JP region, but reads
      // in Vietnamese.
      appLanguage: req.get('lang'),
    });

    return this.svc.getConfigFor(
      viewerMarkets,
      resolveViewerLanguage(req.get('lang')),
      this.viewerIdOf(req),
    );
  }

  /**
   * Best-effort viewer identity for a @Public route.
   *
   * The guard returns early on @Public and never attaches a user, but every
   * app build sends its token anyway — and segment targeting needs to know
   * WHO is asking. Decode-if-present, never reject: an absent or invalid
   * token just means segment-targeted slides are hidden, exactly like a
   * viewer we could place in no market.
   */
  private viewerIdOf(req: Request): string {
    const token = (req.headers['authorization'] ?? '').split(' ')[1];
    if (!token) return '';

    return this.jwt.verify<{ id?: string }>(token)?.id ?? '';
  }

  /**
   * One slide was SHOWN. Fire-and-forget from the app, `@Public` like the GET
   * so a guest's impression counts too -- CTR computed over signed-in eyes only
   * would flatter every campaign.
   */
  @Public()
  @Post('impression')
  trackImpression(@Body() dto: TrackHomeBannerDto) {
    return this.svc.track(dto.campaignKey, 'impressions');
  }

  /** One slide was TAPPED. Same contract as the impression event. */
  @Public()
  @Post('click')
  trackClick(@Body() dto: TrackHomeBannerDto) {
    return this.svc.track(dto.campaignKey, 'clicks');
  }

  /**
   * The config exactly as stored -- what the admin panel edits.
   *
   * A separate route from the app's, not a flag on it: the app's response
   * filters slides to the caller's own markets, and an operator in Vietnam
   * opening the page would find a Japan-only slide simply absent. Behind
   * `AuthGuard` (no `@Public`), like the PUT.
   */
  @Get('config')
  getRawConfig() {
    return this.svc.getRawConfig();
  }

  @Put('')
  updateConfig(@Body() dto: UpdateHomeBannerConfigDto) {
    return this.svc.updateConfig(dto);
  }
}
