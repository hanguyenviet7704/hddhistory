import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Vietnamese speech synthesis through Vbee (https://api-docs.vbee.vn).
 *
 * Unlike [TtsService]'s Edge endpoint this one is PAID and billed per
 * character, so every decision in this file leans towards spending nothing by
 * accident: an unconfigured provider refuses instead of falling back, a
 * permanent rejection is never retried, and the caller is expected to have
 * counted the characters first (see `VoiceoverService.estimateCourse`).
 *
 * The API is asynchronous even for one short card — there is a `mode: 'sync'`
 * Realtime variant, but it caps input at 300 characters, which a theory card
 * clears several times over. So the flow is: submit, poll, download.
 */

const VBEE_TTS_URL = 'https://api.vbee.vn/v1/tts';
const VBEE_REQUEST_URL = 'https://api.vbee.vn/v1/tts/requests';
const VBEE_VOICES_URL = 'https://vbee.vn/api/public/v1/voices';

/**
 * `webhookUrl` is mandatory in the Batch API's body, but nothing here reads a
 * callback: this service polls instead, so that a dub can run from a laptop or
 * a private container with no publicly reachable endpoint. Verified against the
 * live API — a request submitted with this placeholder completes normally and
 * the result is readable from the GET below.
 */
const WEBHOOK_PLACEHOLDER = 'https://meup.training/vbee-noop';

/** Total attempts per synthesis, including the first. Mirrors `TtsService`. */
const MAX_SYNTH_ATTEMPTS = 3;

/// How long to keep polling one request before giving up. Short cards come back
/// COMPLETED on the very first poll; this ceiling is for the tail, not the norm.
const POLL_TIMEOUT_MS = 120_000;
const POLL_INTERVAL_MS = 700;

/// Every HTTP call gets a deadline. `fetch` has none by default, and one hung
/// request would otherwise stall a whole dub run behind it.
const HTTP_TIMEOUT_MS = 30_000;

/// The Batch API's own input ceiling. A card never approaches it; asserted so a
/// future caller that concatenates text finds out here rather than from a 400.
const MAX_TEXT_CHARS = 100_000;

/** The `audio.voices[lang]` prefix that marks a clip as Vbee's rather than Edge's. */
export const VBEE_VOICE_PREFIX = 'vbee:';

/** `vbee:<code>` → `<code>`; anything else → null (an Edge voice name). */
export function parseVbeeVoice(voiceName?: string): string | null {
  if (!voiceName?.startsWith(VBEE_VOICE_PREFIX)) return null;
  return voiceName.slice(VBEE_VOICE_PREFIX.length) || null;
}

/** `<code>` → `vbee:<code>`, the form stored on the keypoint. */
export function toVbeeVoiceName(voiceCode: string): string {
  return `${VBEE_VOICE_PREFIX}${voiceCode}`;
}

/**
 * A failure Vbee will give again for the same input — a bad token, a voice code
 * that does not exist, an empty balance. Retrying one of these buys nothing and
 * (for the balance case) hammers an account that is already out of credit, so
 * [synthesizeMp3] gives up on it immediately.
 */
export class VbeePermanentError extends Error {}

/**
 * Who owns a voice. The picker shows Vbee's own catalogue; the other two exist
 * for [VbeeTtsService.findVoice], which has to be able to confirm a code an
 * admin pasted by hand — those are exactly the ones not in the picker.
 */
export type VbeeVoiceOwnership = 'VBEE' | 'COMMUNITY' | 'PERSONAL';

const VOICE_OWNERSHIPS: VbeeVoiceOwnership[] = [
  'VBEE',
  'COMMUNITY',
  'PERSONAL',
];

/** One voice as the admin picker needs it. */
export interface VbeeVoice {
  code: string;
  name: string;
  gender: string;
  languageCode: string;
  /** Characters billed per character read. 1 for the standard voices, 2 for
   *  "nâng cao (Beta)", 3 for the "2.0" ones — the picker shows it because it
   *  is the difference between a run costing X and 3X. */
  creditFactor: number;
  /** Vbee-hosted sample, so a narrator can be chosen by ear in the browser. */
  demo: string;
}

@Injectable()
export class VbeeTtsService {
  private readonly logger = new Logger(VbeeTtsService.name);

  constructor(private readonly configService: ConfigService) {}

  private get appId(): string {
    return this.configService.get<string>('VBEE_APP_ID') ?? '';
  }

  private get token(): string {
    return this.configService.get<string>('VBEE_TOKEN') ?? '';
  }

  /**
   * Whether credentials are present at all.
   *
   * Checked before a course can be switched to Vbee and again before a dub
   * runs, so a missing key surfaces as a refusal at the toggle rather than as
   * five hundred identical 401s spread across a catalogue run.
   */
  get isConfigured(): boolean {
    return Boolean(this.appId && this.token);
  }

  /** Narrator used when the admin has not picked one. */
  get defaultVoiceCode(): string {
    return (
      this.configService.get<string>('VBEE_VOICE_CODE') ||
      'hn_female_ngochuyen_full_48k-fhg'
    );
  }

  get concurrency(): number {
    const configured = Number(this.configService.get<string>('VBEE_CONCURRENCY'));
    return Number.isFinite(configured) && configured > 0
      ? Math.floor(configured)
      : 3;
  }

  /** Characters a single run may spend. 0 or unset = no ceiling. */
  get maxCharsPerRun(): number {
    const configured = Number(
      this.configService.get<string>('VBEE_MAX_CHARS_PER_RUN'),
    );
    return Number.isFinite(configured) && configured > 0
      ? Math.floor(configured)
      : 0;
  }

  private get bitrate(): number {
    const configured = Number(this.configService.get<string>('VBEE_BITRATE'));
    // Only the values the API accepts; anything else is a 400 at synthesis time.
    return [8, 16, 32, 64, 128].includes(configured) ? configured : 64;
  }

  /**
   * Output sample rate, or `undefined` to let Vbee pick.
   *
   * Undefined is the DEFAULT and the right answer almost always. Each voice
   * supports its own set of rates — measured: Ngọc Huyền accepts 24000 while
   * another voice answers `BAD_REQUEST: This voice only support sample rate of
   * [8000,16000,22050]` — so any single hardcoded value is wrong for some
   * voice, and the failure only surfaces once the job has already run. Sending
   * nothing makes Vbee use the highest rate that voice supports.
   *
   * It costs nothing to give this up: an MP3's size is set by its BITRATE, not
   * its sample rate, so a 44.1kHz clip at 64kbps is exactly as big as a 24kHz
   * one. Consistency for the `-c copy` concat still holds, because the rate is
   * deterministic per voice and changing the voice already forces a full
   * re-dub of the language.
   *
   * Setting it explicitly is therefore a pin, not a default — and pinning a new
   * value once clips already exist mixes two rates inside one language, which
   * `-c copy` cannot splice. Force a re-dub of `vi` if you change it.
   */
  private get sampleRate(): number | undefined {
    const raw = this.configService.get<string>('VBEE_SAMPLE_RATE');
    if (!raw) return undefined;

    const configured = Number(raw);
    if ([8000, 16000, 22050, 24000, 32000, 44100, 48000].includes(configured)) {
      return configured;
    }
    this.logger.warn(
      `Ignoring VBEE_SAMPLE_RATE="${raw}" — not a rate Vbee accepts; letting Vbee choose`,
    );
    return undefined;
  }

  private get speed(): number {
    const configured = Number(this.configService.get<string>('VBEE_SPEED'));
    return Number.isFinite(configured) && configured >= 0.25 && configured <= 1.9
      ? configured
      : 1.0;
  }

  private headers(): Record<string, string> {
    return {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${this.token}`,
      'App-Id': this.appId,
    };
  }

  /**
   * Synthesise `text` with `voiceCode` and return the MP3 bytes.
   *
   * Retries the transient failures (429 past the concurrency ceiling, 5xx,
   * network) and gives up at once on [VbeePermanentError]. The caller records
   * whatever comes out per language exactly as it does for Edge — a failure
   * here is a normal outcome, not an exception that should abandon a run.
   */
  async synthesizeMp3(text: string, voiceCode: string): Promise<Buffer> {
    const clean = text.trim();
    if (!clean) throw new Error('Cannot synthesise empty text');
    if (clean.length > MAX_TEXT_CHARS) {
      throw new VbeePermanentError(
        `Text is ${clean.length} chars, over Vbee's ${MAX_TEXT_CHARS} limit`,
      );
    }
    if (!this.isConfigured) {
      throw new VbeePermanentError(
        'Vbee is not configured (VBEE_APP_ID / VBEE_TOKEN)',
      );
    }

    let lastError = new Error('synthesis never ran');
    for (let attempt = 1; attempt <= MAX_SYNTH_ATTEMPTS; attempt++) {
      try {
        return await this.synthesizeOnce(clean, voiceCode);
      } catch (error) {
        // A rejection Vbee will repeat verbatim. Stop now: a retry cannot
        // change the answer, and for "not enough credit" it is actively rude.
        if (error instanceof VbeePermanentError) throw error;
        lastError = error as Error;
        if (attempt === MAX_SYNTH_ATTEMPTS) break;
        this.logger.warn(
          `Retrying Vbee synthesis (attempt ${attempt + 1}/${MAX_SYNTH_ATTEMPTS}, voice=${voiceCode}): ${lastError.message}`,
        );
        await this.backoff(attempt);
      }
    }

    throw new Error(
      `vbee failed after ${MAX_SYNTH_ATTEMPTS} attempts (voice=${voiceCode}): ${lastError.message}`,
    );
  }

  /// Exponential backoff with jitter, for the same reason `TtsService` has one:
  /// a batch run trips a concurrency limit in bursts, and retrying the whole
  /// burst at the same instant just reproduces it.
  private async backoff(attempt: number): Promise<void> {
    const base = 800 * 2 ** (attempt - 1);
    const jitter = Math.floor(Math.random() * 400);
    await new Promise((resolve) => setTimeout(resolve, base + jitter));
  }

  private async synthesizeOnce(
    text: string,
    voiceCode: string,
  ): Promise<Buffer> {
    const requestId = await this.submit(text, voiceCode);
    const audioLink = await this.pollForAudio(requestId);
    return this.download(audioLink);
  }

  /** POST the job; returns the id to poll. */
  private async submit(text: string, voiceCode: string): Promise<string> {
    const res = await fetch(VBEE_TTS_URL, {
      method: 'POST',
      headers: this.headers(),
      body: JSON.stringify({
        text,
        voiceCode,
        mode: 'async',
        outputFormat: 'mp3',
        bitrate: this.bitrate,
        // Omitted entirely when unpinned — see [sampleRate]. A `sampleRate:
        // undefined` would be dropped by JSON.stringify anyway, but spelling it
        // out keeps the "we deliberately send nothing" intent readable.
        ...(this.sampleRate ? { sampleRate: this.sampleRate } : {}),
        speed: this.speed,
        webhookUrl: WEBHOOK_PLACEHOLDER,
      }),
      signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
    });

    const body = await this.readJson(res);
    if (!res.ok) throw this.classify(res.status, body);

    const requestId = body?.requestId;
    if (!requestId) {
      throw new Error(`Vbee returned no requestId (HTTP ${res.status})`);
    }
    return String(requestId);
  }

  /**
   * Poll until the request reports COMPLETED, then hand back its audio link.
   *
   * The link is short-lived (Vbee expires it after three minutes, though the
   * audio itself is kept for three days), which is why the download below
   * happens immediately rather than being handed further up.
   */
  private async pollForAudio(requestId: string): Promise<string> {
    const deadline = Date.now() + POLL_TIMEOUT_MS;

    for (;;) {
      const res = await fetch(`${VBEE_REQUEST_URL}/${requestId}`, {
        method: 'GET',
        headers: this.headers(),
        signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
      });
      const body = await this.readJson(res);
      if (!res.ok) throw this.classify(res.status, body);

      const status = String(body?.status ?? '').toUpperCase();
      if (status === 'COMPLETED') {
        const link = body?.audioLink;
        if (!link) {
          throw new Error(`Vbee request ${requestId} completed with no audioLink`);
        }
        return String(link);
      }
      // FAILED is Vbee's own verdict on this input. Another attempt at the same
      // text would spend credit to be told the same thing.
      if (status === 'FAILED') {
        throw new VbeePermanentError(
          `Vbee request ${requestId} failed: ${body?.error?.message ?? 'no reason given'}`,
        );
      }

      if (Date.now() >= deadline) {
        throw new Error(
          `Vbee request ${requestId} still ${status || 'PROCESSING'} after ${POLL_TIMEOUT_MS}ms`,
        );
      }
      await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS));
    }
  }

  /**
   * Fetch the finished clip.
   *
   * `audioLink` is a `vbee.vn/s/...` shortlink that 302s to a presigned S3 URL,
   * so redirects MUST be followed — Node's fetch does by default, and this
   * comment exists so nobody "hardens" it to `redirect: 'manual'` and gets an
   * empty 302 body saved as an MP3.
   */
  private async download(audioLink: string): Promise<Buffer> {
    const res = await fetch(audioLink, {
      redirect: 'follow',
      signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
    });
    if (!res.ok) {
      throw new Error(`Vbee audio download HTTP ${res.status}`);
    }
    const buffer = Buffer.from(await res.arrayBuffer());
    if (!buffer.length) throw new Error('Vbee returned empty audio');
    return buffer;
  }

  /**
   * Find one voice by code across every ownership the account can reach.
   *
   * Exists because the picker only lists Vbee's own catalogue, while a
   * `voiceCode` pasted by hand may well be a COMMUNITY voice or the account's
   * own PERSONAL (cloned) one — and rejecting those would make the paste box
   * useless for the case it was added for.
   *
   * Returns null when no ownership has it. That is NOT proof the code is
   * invalid, only that this lookup could not confirm it, so the caller warns
   * rather than refuses.
   */
  async findVoice(
    code: string,
    languageCode = 'vi-VN',
  ): Promise<VbeeVoice | null> {
    for (const ownership of VOICE_OWNERSHIPS) {
      try {
        const voices = await this.listVoices(languageCode, ownership);
        const match = voices.find((voice) => voice.code === code);
        if (match) return match;
      } catch (error) {
        // One unreadable ownership must not hide a voice the next one has.
        this.logger.warn(
          `Vbee voice lookup failed for ownership=${ownership}: ${(error as Error).message}`,
        );
      }
    }
    return null;
  }

  /**
   * The voices the account may synthesise with, for the admin picker.
   *
   * Paged by cursor on Vbee's side; this walks every page so the picker gets
   * one complete list (a little over thirty voices for `vi-VN`, so the walk is
   * two requests, not a crawl).
   */
  async listVoices(
    languageCode = 'vi-VN',
    ownership: VbeeVoiceOwnership = 'VBEE',
  ): Promise<VbeeVoice[]> {
    if (!this.isConfigured) {
      throw new VbeePermanentError(
        'Vbee is not configured (VBEE_APP_ID / VBEE_TOKEN)',
      );
    }

    const voices: VbeeVoice[] = [];
    let cursor = '';
    // Bounded rather than `while (hasNext)`: a server that always reports
    // another page must not spin this forever.
    for (let page = 0; page < 20; page++) {
      const url = new URL(VBEE_VOICES_URL);
      url.searchParams.set('voiceOwnership', ownership);
      url.searchParams.set('languageCode', languageCode);
      url.searchParams.set('limit', '100');
      if (cursor) url.searchParams.set('cursor', cursor);

      const res = await fetch(url.toString(), {
        method: 'GET',
        headers: this.headers(),
        signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
      });
      const body = await this.readJson(res);
      if (!res.ok) throw this.classify(res.status, body);

      for (const voice of body?.result?.voices ?? []) {
        voices.push({
          code: String(voice.code ?? ''),
          name: String(voice.name ?? voice.code ?? ''),
          gender: String(voice.gender ?? ''),
          languageCode: String(voice.language_code ?? languageCode),
          creditFactor: Number(voice.credit_factor ?? 1) || 1,
          demo: String(voice.demo ?? ''),
        });
      }

      const pagination = body?.result?.pagination;
      if (!pagination?.has_next_page || !pagination?.next_cursor) break;
      cursor = String(pagination.next_cursor);
    }

    return voices.filter((voice) => voice.code);
  }

  /** Vbee answers JSON on every path except a successful audio download. */
  private async readJson(res: Response): Promise<any> {
    try {
      return await res.json();
    } catch {
      return null;
    }
  }

  /**
   * Turn an HTTP failure into either a permanent or a retryable error.
   *
   * 401 (bad token) and 400 (bad body, unknown voice code, **no credit left**)
   * are all things that will be true again in a second. 429 is the concurrency
   * ceiling and 5xx is Vbee's own hiccup — both worth another go.
   */
  private classify(status: number, body: any): Error {
    const code = body?.error?.code ?? '';
    const message = body?.error?.message ?? `HTTP ${status}`;
    const detail = code ? `${code}: ${message}` : message;

    if (status === 401 || status === 400) {
      return new VbeePermanentError(`Vbee rejected the request — ${detail}`);
    }
    return new Error(`Vbee error — ${detail}`);
  }
}
