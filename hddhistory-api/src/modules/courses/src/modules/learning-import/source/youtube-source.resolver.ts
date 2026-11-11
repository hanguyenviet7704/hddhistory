import { Injectable, Logger } from '@nestjs/common';

import { ResolvedSource } from '../ai/lesson-generation.types';
import { ImportErrorCode } from '../enum/learning-import.enum';
import { LEARNING_IMPORT_CONFIG } from '../learning-import.config';
import { SourceResolutionError } from './source-resolution.error';

const FETCH_TIMEOUT_MS = 15_000;

const BROWSER_HEADERS = {
  'User-Agent':
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Safari/537.36',
  'Accept-Language': 'en-US,en;q=0.9',
};

export interface YoutubeResolution {
  source: ResolvedSource;
  videoTitle: string;
  durationSeconds: number;
}

/**
 * Turns a YouTube link into something the model can learn from.
 *
 * It hands the URL straight to the provider and lets IT fetch the video. The
 * previous version scraped the watch page for a caption track and transcribed
 * it, which worked on a laptop and never worked on the server: YouTube strips
 * the caption list from player responses it does not trust, and a datacenter
 * address is not trusted. The same video that listed 14 caption tracks from a
 * home connection listed none from api-dev, so every YouTube import failed with
 * "this video has no captions" -- about a video that plainly had them.
 *
 * Handing over the URL removes our address from the question entirely, and has a
 * second benefit that the transcript route could never have: videos with NO
 * captions work, because the model watches and listens instead of reading.
 *
 * The cost is real and worth knowing: a 15-minute talk measured ~80k input
 * tokens, roughly twenty times what its transcript would have been, and took 25
 * seconds just to answer one question. Hence the much shorter duration cap in
 * `LEARNING_IMPORT_CONFIG` — and the monthly quota, which is what actually
 * bounds total spend.
 */
@Injectable()
export class YoutubeSourceResolver {
  private readonly logger = new Logger(YoutubeSourceResolver.name);

  /**
   * Video id from any of the URL shapes users actually paste.
   *
   * Exported behaviour, not a detail: the create endpoint calls this to reject a
   * bad link before a job exists, so the user is told immediately instead of
   * waiting for a job to fail.
   */
  static parseVideoId(rawUrl: string): string | null {
    let url: URL;
    try {
      url = new URL(rawUrl.trim());
    } catch {
      return null;
    }

    const host = url.hostname.replace(/^www\./, '').replace(/^m\./, '');
    const id =
      host === 'youtu.be'
        ? url.pathname.slice(1)
        : (url.searchParams.get('v') ??
          // /shorts/ID, /embed/ID, /live/ID all put the id in the last segment.
          (/^\/(shorts|embed|live|v)\/([^/?]+)/.exec(url.pathname)?.[2] ?? ''));

    // Ids are exactly 11 URL-safe characters. Checking the shape here stops a
    // malformed link from becoming an outbound request to an arbitrary path.
    return /^[\w-]{11}$/.test(id) ? id : null;
  }

  async resolve(rawUrl: string): Promise<YoutubeResolution> {
    const videoId = YoutubeSourceResolver.parseVideoId(rawUrl);
    if (!videoId) {
      throw new SourceResolutionError(
        ImportErrorCode.YOUTUBE_UNAVAILABLE,
        'Not a valid YouTube link',
      );
    }

    // Canonical form rather than whatever the user pasted: share links carry
    // `?si=` tracking parameters, and youtu.be shortlinks are a different host.
    const uri = `https://www.youtube.com/watch?v=${videoId}`;

    const title = await this.fetchTitle(videoId);
    const durationSeconds = await this.fetchDurationSeconds(videoId);

    // Both bounds are only enforced when we actually learned the duration.
    // Failing closed on an unknown duration would put the feature straight
    // back where it was -- blocked by a best-effort scrape -- and the weekly
    // quota is the real ceiling on spend regardless.
    if (
      durationSeconds > 0 &&
      durationSeconds > LEARNING_IMPORT_CONFIG.maxVideoSeconds
    ) {
      throw new SourceResolutionError(
        ImportErrorCode.YOUTUBE_TOO_LONG,
        `Video is longer than the ${Math.round(
          LEARNING_IMPORT_CONFIG.maxVideoSeconds / 3600,
        )}-hour limit`,
      );
    }
    // A floor as well: a clip this short rarely supports a lesson, and saying
    // so NOW beats burning a generation to find out (CONTENT_TOO_SHORT) later.
    if (
      durationSeconds > 0 &&
      durationSeconds < LEARNING_IMPORT_CONFIG.minVideoSeconds
    ) {
      throw new SourceResolutionError(
        ImportErrorCode.YOUTUBE_TOO_SHORT,
        `Video is shorter than the ${Math.round(
          LEARNING_IMPORT_CONFIG.minVideoSeconds / 60,
        )}-minute minimum`,
      );
    }

    return {
      source: { kind: 'remoteUri', uri, title },
      videoTitle: title,
      durationSeconds,
    };
  }

  /**
   * Title via oEmbed — a documented, public endpoint, unlike the watch page.
   *
   * Doubles as the availability check: oEmbed 404s for a video that is private,
   * deleted or otherwise not viewable, which is the one thing worth failing
   * early for. A video the provider cannot open would otherwise burn a minute of
   * generation before saying so.
   */
  private async fetchTitle(videoId: string): Promise<string> {
    const url =
      'https://www.youtube.com/oembed?format=json&url=' +
      encodeURIComponent(`https://www.youtube.com/watch?v=${videoId}`);

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
    try {
      const response = await fetch(url, { signal: controller.signal });
      if (response.status === 401 || response.status === 403 || response.status === 404) {
        throw new SourceResolutionError(
          ImportErrorCode.YOUTUBE_UNAVAILABLE,
          'This video cannot be opened',
        );
      }
      if (!response.ok) return '';

      const payload = (await response.json()) as { title?: string };

      return payload?.title ?? '';
    } catch (error: any) {
      if (error instanceof SourceResolutionError) throw error;
      // A title is decoration; the import works without one.
      this.logger.warn(`oEmbed failed for ${videoId}: ${error?.message}`);

      return '';
    } finally {
      clearTimeout(timeoutId);
    }
  }

  /**
   * Duration, best effort, from the watch page's embedded player blob.
   *
   * This is the only thing left of the old scraper, and it is now allowed to
   * fail: 0 means "unknown", and the caller skips the length check rather than
   * refusing the import. Keeping it load-bearing is exactly what broke the
   * feature before.
   */
  private async fetchDurationSeconds(videoId: string): Promise<number> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
    try {
      const response = await fetch(
        `https://www.youtube.com/watch?v=${videoId}`,
        { headers: BROWSER_HEADERS, signal: controller.signal },
      );
      if (!response.ok) return 0;

      const html = await response.text();
      // One field out of a megabyte of JSON, so a targeted match beats parsing
      // the whole blob just to read a number.
      const match = /"lengthSeconds":"(\d+)"/.exec(html);

      return match ? Number(match[1]) : 0;
    } catch (error: any) {
      this.logger.warn(
        `Could not read duration for ${videoId}: ${error?.message}`,
      );

      return 0;
    } finally {
      clearTimeout(timeoutId);
    }
  }
}
