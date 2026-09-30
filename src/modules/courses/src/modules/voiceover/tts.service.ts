import { Injectable, Logger } from '@nestjs/common';
import { MsEdgeTTS, OUTPUT_FORMAT, Voice } from 'msedge-tts';

import { parseVbeeVoice, VbeeTtsService } from './vbee-tts.service';

// Free, no-key neural voices via the Microsoft Edge "Read Aloud" endpoint.
//
// Google Cloud Chirp3-HD sounded better in an A/B listen and was tried twice.
// Both times it was reverted, the second time after failing 1634 of 2395
// (keypoint × language) cells outright — it bills per character and needs a key
// with billing enabled, and dubbing the whole catalogue in five languages is a
// lot of characters. This endpoint costs nothing and needs no key.
//
// The trade-off to know about: it is undocumented and has no SLA, so a synth
// failure is a normal outcome the caller must tolerate — it does (see
// `VoiceoverService`, which keeps a card's previous clip on failure and records
// the error for the coverage report), and [MAX_SYNTH_ATTEMPTS] retries the blips
// before it comes to that.
const VOICEOVER_LOCALE_MAP: Record<string, string> = {
  vi: 'vi-VN',
  en: 'en-US',
  zh: 'zh-CN',
  ja: 'ja-JP',
  ko: 'ko-KR',
};

export const VOICEOVER_LANGS = Object.keys(VOICEOVER_LOCALE_MAP);

/// The narrator for each locale — one verified female voice, and the only voice
/// this service will ever synthesise with. There is no per-run override and no
/// admin picker: the catalogue is dubbed in one voice per language, deliberately.
///
/// Also the fallback when the endpoint's own voice list can't be fetched: these
/// names were READ from that list and are stable, so a dub run survives the
/// catalogue being briefly unreachable instead of failing every language. That
/// is the one thing a hardcoded name here is allowed to be — a fallback, never
/// the source: a name invented rather than read is how every Chinese keypoint
/// once failed with "Voice does not exist". [resolveVoiceName] therefore still
/// checks each name against the live catalogue and moves to another FEMALE voice
/// if Microsoft ever retires one, rather than trusting this list blindly.
const DEFAULT_VOICES: Record<string, string> = {
  vi: 'vi-VN-HoaiMyNeural',
  en: 'en-US-AriaNeural',
  zh: 'zh-CN-XiaoxiaoNeural',
  ja: 'ja-JP-NanamiNeural',
  ko: 'ko-KR-SunHiNeural',
};

/// Total attempts per synthesis, including the first. The endpoint drops
/// WebSockets under load and a dub run is hundreds of consecutive calls, so one
/// retry pass turns most of those blips into a normal result.
const MAX_SYNTH_ATTEMPTS = 3;

/// One entry of the endpoint's catalogue, narrowed to what [resolveVoiceName]
/// needs to confirm a narrator still exists and to find a replacement if not.
interface VoiceoverVoiceOption {
  /// Full voice name to synthesise with, e.g. `vi-VN-HoaiMyNeural`.
  name: string;
  /// `FEMALE` / `MALE`, straight from the catalogue.
  gender: string;
}

@Injectable()
export class TtsService {
  private readonly logger = new Logger(TtsService.name);

  // The one paid provider, reached only through a `vbee:` voice name (see
  // [synthesizeMp3]). Injected rather than resolved per call so the routing
  // stays a property of the voice, not of the caller.
  constructor(private readonly vbee: VbeeTtsService) {}

  /// The endpoint's whole voice list, fetched at most once per process (it
  /// changes on Microsoft's release schedule, not ours). Held as the in-flight
  /// PROMISE, so the concurrent first calls of a dub run share one fetch instead
  /// of each starting their own.
  private catalogue?: Promise<Voice[]>;

  hasVoice(lang: string): boolean {
    return Boolean(VOICEOVER_LOCALE_MAP[lang]);
  }

  private allVoices(): Promise<Voice[]> {
    // A FAILED fetch must not stay cached, or one blip leaves every later call
    // in the process with no catalogue at all.
    this.catalogue ??= new MsEdgeTTS().getVoices().catch((error) => {
      this.catalogue = undefined;
      throw error;
    });
    return this.catalogue;
  }

  /// Voices the endpoint offers for `lang`.
  private async voiceOptions(lang: string): Promise<VoiceoverVoiceOption[]> {
    const locale = VOICEOVER_LOCALE_MAP[lang];
    if (!locale) throw new Error(`No TTS locale configured for lang "${lang}"`);

    const voices = await this.allVoices();
    return voices
      .filter((voice) => voice.Locale === locale && Boolean(voice.ShortName))
      .map<VoiceoverVoiceOption>((voice) => ({
        name: voice.ShortName,
        gender: (voice.Gender ?? '').toUpperCase() || 'UNSPECIFIED',
      }));
  }

  /**
   * The one narrator this locale is dubbed with.
   *
   * Takes no argument on purpose: there is no per-run or per-language override
   * any more, so every clip of a language is the same female voice and a re-dub
   * can never quietly change narrator mid-catalogue.
   *
   * Still resolved against the live catalogue rather than returned straight from
   * [DEFAULT_VOICES], for the one case that list cannot cover: if Microsoft
   * retires a name, this moves to another FEMALE voice for the locale instead of
   * synthesising against a name the endpoint no longer has ("Voice does not
   * exist" — how every Chinese keypoint once failed). When the catalogue itself
   * is unreachable the hardcoded name is used, since it is far likelier to still
   * be valid than not.
   */
  async resolveVoiceName(lang: string): Promise<string> {
    const fallback = DEFAULT_VOICES[lang];
    if (!fallback) throw new Error(`No TTS voice configured for lang "${lang}"`);

    let options: VoiceoverVoiceOption[] = [];
    try {
      options = await this.voiceOptions(lang);
    } catch (error) {
      this.logger.warn(
        `Voice list unavailable for "${lang}" (${(error as Error).message}) — using ${fallback}`,
      );
      return fallback;
    }
    if (!options.length) return fallback;

    const preferred = options.find((option) => option.name === fallback);
    if (preferred) return preferred.name;

    const female = options.find((option) => option.gender === 'FEMALE');
    this.logger.warn(
      `Narrator ${fallback} is no longer offered for "${lang}" — falling back to ${female?.name ?? options[0].name}`,
    );
    return (female ?? options[0]).name;
  }

  /**
   * Synthesise `text` to an MP3 buffer with a neural voice for `lang`.
   *
   * `rate` is a ProsodyOptions rate string (e.g. '-8%' to slow down slightly for
   * learners); omit for the natural pace. `voiceName` should be an
   * already-resolved name from [resolveVoiceName]; omit it and this resolves the
   * locale's default itself.
   *
   * **The voice name is what picks the provider.** A `vbee:<code>` name routes
   * to the paid Vietnamese provider; anything else is an Edge short name. This
   * indirection is deliberate: `audio.voices[lang]` already travels with every
   * clip and is already compared on re-dub (`sameVoice`) and hashed into the
   * merged file, so encoding the provider in it makes a provider switch behave
   * exactly like a narrator switch — the whole language gets re-dubbed, and
   * clips of two different bitrates can never end up concatenated together.
   *
   * Runs against a public endpoint either way, so the server needs outbound
   * internet — intended for batch pre-generation, never a user's request path.
   */
  async synthesizeMp3(
    text: string,
    lang: string,
    rate?: string,
    voiceName?: string,
  ): Promise<Buffer> {
    const clean = text.trim();
    if (!clean) throw new Error('Cannot synthesise empty text');

    // `rate` is an SSML prosody string and has no Vbee equivalent (its speed
    // lives in the request body, from VBEE_SPEED). Nothing passes one today;
    // warn rather than silently read at a pace the caller did not ask for.
    const vbeeVoice = parseVbeeVoice(voiceName);
    if (vbeeVoice) {
      if (rate) {
        this.logger.warn(
          `Ignoring rate "${rate}" — Vbee has no prosody rate; set VBEE_SPEED instead`,
        );
      }
      return this.vbee.synthesizeMp3(clean, vbeeVoice);
    }

    const voice = voiceName ?? (await this.resolveVoiceName(lang));

    // Every failure here is retried: unlike an HTTP API there is no status to
    // classify by, and the one permanent failure (a voice name the endpoint
    // doesn't have) is already excluded by resolving names from its own list.
    let lastError = new Error('synthesis never ran');
    for (let attempt = 1; attempt <= MAX_SYNTH_ATTEMPTS; attempt++) {
      try {
        return await this.synthesizeOnce(clean, voice, rate);
      } catch (error) {
        lastError = error as Error;
        if (attempt === MAX_SYNTH_ATTEMPTS) break;
        this.logger.warn(
          `Retrying synthesis (attempt ${attempt + 1}/${MAX_SYNTH_ATTEMPTS}, lang=${lang}, voice=${voice}): ${lastError.message}`,
        );
        await this.backoff(attempt);
      }
    }

    throw new Error(
      `edge-tts failed after ${MAX_SYNTH_ATTEMPTS} attempts (voice=${voice}): ${lastError.message}`,
    );
  }

  /// Exponential backoff with jitter. The jitter matters: a batch run trips the
  /// endpoint's limits in bursts, and retrying every card of that burst at the
  /// same instant just reproduces it.
  private async backoff(attempt: number): Promise<void> {
    const base = 500 * 2 ** (attempt - 1);
    const jitter = Math.floor(Math.random() * 250);
    await new Promise((resolve) => setTimeout(resolve, base + jitter));
  }

  private async synthesizeOnce(
    text: string,
    voiceName: string,
    rate?: string,
  ): Promise<Buffer> {
    // A fresh instance per call: setMetadata opens a WebSocket, toStream uses
    // it, close() tears it down. Reusing one instance across concurrent calls
    // would interleave streams.
    const tts = new MsEdgeTTS();
    try {
      await tts.setMetadata(
        voiceName,
        OUTPUT_FORMAT.AUDIO_24KHZ_48KBITRATE_MONO_MP3,
      );
      const { audioStream } = tts.toStream(text, rate ? { rate } : undefined);
      const chunks: Buffer[] = [];
      await new Promise<void>((resolve, reject) => {
        audioStream.on('data', (chunk: Buffer) =>
          chunks.push(Buffer.from(chunk)),
        );
        audioStream.on('end', () => resolve());
        audioStream.on('error', (err: Error) => reject(err));
      });
      const buffer = Buffer.concat(chunks);
      if (!buffer.length) {
        throw new Error(`edge-tts returned empty audio (voice=${voiceName})`);
      }
      return buffer;
    } finally {
      try {
        tts.close();
      } catch {
        // ignore close errors
      }
    }
  }
}
