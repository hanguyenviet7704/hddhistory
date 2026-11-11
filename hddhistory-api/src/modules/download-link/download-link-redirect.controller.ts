import { Controller, Get, Header, Param, Req, Res } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';
import { Request, Response } from 'express';

import { Public } from '@base/decorator/public';

import { DownloadLinkService } from './download-link.service';

/**
 * The public side of a download link: `https://meup.training/r/<slug>`.
 *
 * nginx on meup.training proxies `/r/` here rather than the app serving the
 * link itself, because `Runner.entitlements` declares `applinks:meup.training`
 * with no wildcard -- a link on api.meup.training would stop opening the app
 * for people who already have it.
 *
 * Counting happens server-side on purpose. A JS beacon on a static page is
 * blocked by ad blockers, skipped when scripts are off, and races the
 * redirect; a 302 from here is counted before the browser is told where to go,
 * and works even inside the Zalo and Facebook webviews most links travel
 * through.
 */
@ApiExcludeController()
@Controller({ path: 'r', version: '1' })
export class DownloadLinkRedirectController {
  constructor(private readonly svc: DownloadLinkService) {}

  @Public()
  @Get(':slug')
  // Without no-store, Cloudflare caches the 302 and later clicks never reach
  // this server -- the counter would simply stop moving, with nothing broken
  // enough to notice.
  @Header('Cache-Control', 'no-store, no-cache, must-revalidate')
  async redirect(
    @Param('slug') slug: string,
    @Req() req: Request,
    @Res() res: Response,
  ): Promise<void> {
    const result = await this.svc.resolveAndRecord(slug, {
      userAgent: req.get('user-agent'),
      // Cloudflare sets both. CF-Connecting-IP is the real client; req.ip
      // would be Cloudflare's edge node.
      ip: (req.get('cf-connecting-ip') || req.ip) ?? undefined,
      country: req.get('cf-ipcountry') ?? undefined,
      referer: req.get('referer') ?? undefined,
    });

    // Link-preview crawlers get a page of OG tags instead of a redirect --
    // it is the only way each link can carry its own share card. Everything
    // the crawler needs is inline, so 200 + text/html ends its journey here.
    if (result.kind === 'preview') {
      res.type('text/html; charset=utf-8').send(result.html);
      return;
    }

    // 302, not 301: a permanent redirect would be cached by the browser and
    // every later click from that device would never be counted.
    res.redirect(302, result.url);
  }
}
