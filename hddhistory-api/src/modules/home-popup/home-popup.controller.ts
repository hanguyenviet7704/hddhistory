import { Body, Controller, Get, Header, Post, Put, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';

import { AuthGuard } from '@base/guard/auth.guard';
import {
  resolveViewerLanguage,
  resolveViewerMarkets,
} from '@utils/viewer-market.util';

import { ClickHomePopupDto } from './dto/click-home-popup.dto';
import { UpdateHomePopupConfigDto } from './dto/update-home-popup-config.dto';
import { HomePopupService } from './home-popup.service';

/**
 * The promotional popup on Home: one admin-uploaded image, tappable, that stops
 * coming back for a user once they have tapped it.
 *
 * Everything is config so a campaign runs without an app release.
 */
@ApiTags('HOME-POPUP')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'home-popup', version: '1' })
export class HomePopupController {
  constructor(private readonly svc: HomePopupService) {}

  /**
   * The popup as THIS caller should see it.
   *
   * NOT `@Public`, unlike the banner's read: the answer depends on who is asking
   * (have they tapped this campaign?), so there has to be a user. Every app build
   * is authenticated — guests get an anonymous account — so this costs nothing.
   *
   * `private` cache only, and short: the response varies by user, by market and by
   * `lang`, none of which a shared cache keys on.
   */
  @Get('')
  @Header('Cache-Control', 'private, max-age=60')
  getPopup(@Req() req: Request) {
    const viewerMarkets = resolveViewerMarkets({
      cfCountry: req.get('cf-ipcountry'),
      deviceCountry: req.get('x-device-country'),
      appLanguage: req.get('lang'),
    });

    return this.svc.getPopupFor(
      viewerMarkets,
      resolveViewerLanguage(req.get('lang')),
    );
  }

  /**
   * "It was shown to me" — one impression against the campaign's stats.
   * Fire-and-forget like the click; failing must never affect the popup.
   */
  @Post('impression')
  trackImpression(@Body() dto: ClickHomePopupDto) {
    return this.svc.trackImpression(dto);
  }

  /**
   * "I tapped it" — retires the popup for this user and this campaign.
   *
   * The app fires this without waiting for the response and opens the link
   * immediately: making someone watch a spinner before the offer they just tapped
   * would be a worse bug than showing the popup one extra time if this fails.
   */
  @Post('click')
  markClicked(@Body() dto: ClickHomePopupDto) {
    return this.svc.markClicked(dto);
  }

  /**
   * The config exactly as stored -- what the admin panel edits. Separate from the
   * app's route because that one's `visible` is computed for whoever asked.
   */
  @Get('config')
  getRawConfig() {
    return this.svc.getRawConfig();
  }

  @Put('')
  updateConfig(@Body() dto: UpdateHomePopupConfigDto) {
    return this.svc.updateConfig(dto);
  }
}
