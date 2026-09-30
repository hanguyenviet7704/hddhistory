import { BadRequestException, Injectable } from '@nestjs/common';

import { RequestService } from '@base/service/request.service';

import { VoiceoverSettingsRepository } from './repository/voiceover-settings.repository';
import { VbeeTtsService, VbeeVoice } from './vbee-tts.service';

/** What the admin needs to render the narrator panel in one call. */
export interface VoiceoverSettingsView {
  /** The Vbee voice Vietnamese is dubbed with, already resolved: never empty. */
  vbeeVoiceCode: string;
  /** False when VBEE_APP_ID / VBEE_TOKEN are missing — the toggle stays off. */
  vbeeConfigured: boolean;
  /**
   * Set when the stored code could not be found in any Vbee catalogue. Not an
   * error — see [VoiceoverSettingsService.updateVbeeVoice] — but the admin
   * shows it, because the alternative is finding out one dub run later.
   */
  warning?: string;
}

@Injectable()
export class VoiceoverSettingsService {
  constructor(
    private readonly settingsRepository: VoiceoverSettingsRepository,
    private readonly vbee: VbeeTtsService,
    private readonly requestService: RequestService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  /**
   * The Vbee voice code to dub Vietnamese with.
   *
   * Falls back to `VBEE_VOICE_CODE` when the admin has never picked one, so a
   * fresh environment dubs with a sane narrator instead of failing on an empty
   * voice code. Read on the dub path, so it stays a single indexed lookup.
   */
  async resolveVbeeVoiceCode(): Promise<string> {
    const settings = await this.settingsRepository.findOrCreateDefault();
    return settings?.vbeeVoiceCode || this.vbee.defaultVoiceCode;
  }

  async getSettings(): Promise<VoiceoverSettingsView> {
    return {
      vbeeVoiceCode: await this.resolveVbeeVoiceCode(),
      vbeeConfigured: this.vbee.isConfigured,
    };
  }

  /**
   * Change the Vbee narrator.
   *
   * Accepts any non-empty code, and only WARNS when the lookup cannot place it.
   * That asymmetry is deliberate. The picker lists Vbee's own catalogue, but a
   * code pasted by hand is most often one that is NOT in it — a COMMUNITY voice
   * or the account's own cloned PERSONAL one — so refusing everything unlisted
   * would break the paste box for its main use.
   *
   * The failure mode of accepting a genuinely wrong code is mild and contained:
   * Vbee answers 400 BEFORE synthesising, which this treats as permanent, so
   * the run spends no credit, destroys no existing audio (each card keeps its
   * previous clip) and reports the reason per language. A wasted run beats
   * blocking a legitimate voice.
   */
  async updateVbeeVoice(voiceCode: string): Promise<VoiceoverSettingsView> {
    const code = voiceCode?.trim();
    if (!code) throw new BadRequestException('voiceCode is required');

    const known = await this.vbee.findVoice(code);

    await this.settingsRepository.upsertSettings(
      { vbeeVoiceCode: code },
      this.user,
    );

    const settings = await this.getSettings();
    return known
      ? settings
      : {
          ...settings,
          warning:
            `Không tìm thấy mã "${code}" trong danh mục Vbee của tài khoản này. ` +
            'Nếu đây là giọng cộng đồng hoặc giọng riêng thì vẫn dùng được; ' +
            'nếu gõ sai thì cả lượt dub sẽ lỗi mà không tốn điểm.',
        };
  }

  /** The picker feed: every Vietnamese voice this account may synthesise with. */
  async listVbeeVoices(): Promise<VbeeVoice[]> {
    return this.vbee.listVoices();
  }
}
