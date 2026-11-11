import { Injectable } from '@nestjs/common';

import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import { CommunityAuthorType } from '../enum/community.enum';
import { ICommunityAuthor } from '../interface/community.interface';
import { CommunityOfficialProfileRepository } from '../modules/official-profile/repository/community-official-profile.repository';

// Fallback for a post or comment written from the admin panel before anyone set
// a team profile. The team has no row in the users collection, so its identity
// is configured rather than looked up. Just the brand name: with no name stored,
// the app turns authorType OFFICIAL into "Đội ngũ HDDhistory" / "HDDhistory Team" in the
// reader's own language and adds the team badge.
export const OFFICIAL_AUTHOR_NAME = 'HDDhistory';

/**
 * How long the team's profile is trusted before it is re-read.
 *
 * It is one document read by every list in the forum, and it changes when
 * somebody edits it in the panel — perhaps twice a year. A minute means the
 * panel's own preview is fresh enough to feel immediate while the feed does not
 * pay for a second query per page.
 */
const OFFICIAL_PROFILE_TTL_MS = 60 * 1000;

@Injectable()
export class CommunityAuthorService {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly officialProfileRepository: CommunityOfficialProfileRepository,
  ) {}

  private officialProfile = { name: '', avatar: '' };
  private officialProfileAt = 0;

  /**
   * Resolve author identity for a page of posts or comments in one query.
   *
   * Names and avatars are deliberately NOT copied onto posts at write time:
   * doing so freezes them, and a reader who fixes their name would still see
   * the old one on everything they had already written.
   */
  async resolve(
    authorIds: string[],
  ): Promise<Map<string, ICommunityAuthor>> {
    const unique = [...new Set(authorIds.filter(Boolean))];
    // Primed here, not in `official()`: that one is sync and called per row,
    // while this runs exactly once per page — and every flow that renders an
    // author calls it before picking one.
    const [users] = await Promise.all([
      this.userRepository.findIdentitiesByIds(unique),
      this.refreshOfficialProfile(),
    ]);

    return new Map(
      users.map((user) => {
        const id = String(user._id);
        return [
          id,
          {
            id,
            name: user.name,
            avatar: user.avatar,
            authorType: CommunityAuthorType.USER,
          },
        ];
      }),
    );
  }

  official(authorId: string): ICommunityAuthor {
    return {
      id: authorId,
      name: this.officialProfile.name || OFFICIAL_AUTHOR_NAME,
      // Empty rather than absent when nobody set one: the app draws its own "M"
      // disc for an official author with no picture.
      avatar: this.officialProfile.avatar || undefined,
      authorType: CommunityAuthorType.OFFICIAL,
    };
  }

  private async refreshOfficialProfile() {
    if (Date.now() - this.officialProfileAt < OFFICIAL_PROFILE_TTL_MS) return;

    const profile = await this.officialProfileRepository.get();
    this.officialProfile = {
      name: profile?.name ?? '',
      avatar: profile?.avatar ?? '',
    };
    this.officialProfileAt = Date.now();
  }

  /**
   * Identity for one author, falling back to an empty name.
   *
   * A deleted account still has posts in the collection. The name is left empty
   * rather than filled with a placeholder here: the app ships five languages
   * and picks its own localised wording — a Vietnamese string baked into the
   * API would reach a Korean reader untranslated.
   *
   * An ANONYMOUS post loses BOTH the name and the id: leaking the id would let
   * a reader match two anonymous posts to the same person, which is the whole
   * thing anonymity is for. Pass `reveal` — only the admin views do — to get
   * the real account back for moderation.
   */
  pick(
    authors: Map<string, ICommunityAuthor>,
    authorId: string,
    authorType: CommunityAuthorType = CommunityAuthorType.USER,
    reveal = false,
  ): ICommunityAuthor {
    if (authorType === CommunityAuthorType.OFFICIAL) {
      return this.official(authorId);
    }

    if (authorType === CommunityAuthorType.ANONYMOUS && !reveal) {
      return { id: '', name: '', authorType: CommunityAuthorType.ANONYMOUS };
    }

    const identity = authors.get(authorId) ?? {
      id: authorId,
      name: '',
      authorType: CommunityAuthorType.USER,
    };

    // Revealed to a moderator: keep the real name, but say it was written
    // anonymously so the queue can show that the reader could not see it.
    return authorType === CommunityAuthorType.ANONYMOUS
      ? { ...identity, authorType: CommunityAuthorType.ANONYMOUS }
      : identity;
  }
}
