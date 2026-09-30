import { Injectable } from '@nestjs/common';

import { IUserMeta } from '@base/database/mongodb/abstract.interface';

import { UpsertCommunityChatGuideDto } from './dto/upsert-community-chat-guide.dto';
import { CommunityChatGuideRepository } from './repository/community-chat-guide.repository';
import { CommunityChatGuide } from './schema/community-chat-guide.schema';
import {
  CommunityLocale,
  DEFAULT_COMMUNITY_LOCALE,
} from '../../interface/community.interface';

@Injectable()
export class CommunityChatGuideService {
  constructor(private readonly repository: CommunityChatGuideRepository) {}

  /**
   * The house rules in the reader's language.
   *
   * Falls back to the default locale when this language has not been written
   * yet — house rules half-translated are still rules, and showing nothing
   * because nobody has got to Korean yet is the worse failure.
   *
   * Returns null when there is no guide at ALL, which the app reads as "hide
   * the info button": an empty sheet is worse than no button.
   */
  async forReader(locale: CommunityLocale) {
    const own = await this.repository.findByLocale(locale);
    const guide =
      own && this.hasContent(own)
        ? own
        : await this.repository.findByLocale(DEFAULT_COMMUNITY_LOCALE);

    if (!guide || !this.hasContent(guide)) return null;

    return this.toView(guide);
  }

  async listForAdmin() {
    const rows = await this.repository.findAll();

    return rows.map((row) => ({ ...this.toView(row), locale: row.locale }));
  }

  async upsert(dto: UpsertCommunityChatGuideDto, user?: IUserMeta) {
    const saved = await this.repository.upsert(
      dto.locale,
      {
        title: dto.title ?? '',
        intro: dto.intro ?? '',
        // Blank lines are dropped rather than refused: an empty row is what
        // "add another" leaves behind when the writer changes their mind.
        dos: clean(dto.dos),
        donts: clean(dto.donts),
        starters: clean(dto.starters),
      },
      user,
    );

    return saved ? { ...this.toView(saved), locale: saved.locale } : null;
  }

  // A row with a locale and nothing else is what an accidental save leaves
  // behind; it must not count as "this language is done".
  private hasContent(guide: CommunityChatGuide) {
    return !!(
      guide.title?.trim() ||
      guide.dos?.length ||
      guide.donts?.length ||
      guide.starters?.length
    );
  }

  private toView(guide: CommunityChatGuide) {
    return {
      title: guide.title ?? '',
      intro: guide.intro ?? '',
      dos: guide.dos ?? [],
      donts: guide.donts ?? [],
      starters: guide.starters ?? [],
    };
  }
}

const clean = (lines?: string[]) =>
  (lines ?? []).map((line) => line.trim()).filter(Boolean);
