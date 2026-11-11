import { Injectable, NotFoundException } from '@nestjs/common';

import {
  ImportNotificationTemplateDto,
  NotificationCopyDto,
  NotificationVariantDto,
  UpdateNotificationTemplateDto,
} from './dto/notification-template.dto';
import { normalizeNotificationImageUrl } from './notification-image.helper';
import {
  highestVariantSeq,
  variantsOf,
} from './notification-variant.helper';
import { DEFAULT_NOTIFICATION_TEMPLATES } from './notification.defaults';
import { NotificationType } from './notification.enum';
import { NotificationTemplateRepository } from './repository/notification-template.repository';
import {
  INotificationCopy,
  INotificationVariant,
} from './schema/notification-template.schema';

/** The stored fields a variant save has to write together. */
interface IVariantWrite {
  variants: INotificationVariant[];
  /** Kept in step with the first variant so the legacy field is never stale. */
  copies: Record<string, INotificationCopy>;
  variantSeq: number;
}

@Injectable()
export class NotificationTemplateService {
  constructor(
    private readonly templateRepository: NotificationTemplateRepository,
  ) {}

  /**
   * Creates any missing type from [DEFAULT_NOTIFICATION_TEMPLATES] with
   * `$setOnInsert`, so an existing document — including its edited copy and its
   * enabled flag — is never touched.
   *
   * Which is also why an environment that already runs this feature does not
   * gain the new variants from a deploy: import the file in
   * `plans/260804-notification-variants-new-course/` from the admin screen.
   */
  async seedMissing() {
    for (const seed of DEFAULT_NOTIFICATION_TEMPLATES) {
      await this.templateRepository.upsertByType(seed.type, {
        $setOnInsert: {
          type: seed.type,
          enabled: seed.enabled,
          localHour: seed.localHour,
          localMinute: seed.localMinute ?? 0,
          ...(seed.localWeekday !== undefined
            ? { localWeekday: seed.localWeekday }
            : {}),
          deeplink: seed.deeplink,
          variants: seed.variants,
          copies: seed.variants[0]?.copies ?? {},
          variantSeq: highestVariantSeq(seed.variants),
        },
      });
    }
  }

  async findAll() {
    await this.seedMissing();
    return this.templateRepository.findAllTemplates();
  }

  async findEnabled() {
    return this.templateRepository.findEnabled();
  }

  async update(type: NotificationType, dto: UpdateNotificationTemplateDto) {
    const existing = await this.templateRepository.findByType(type);
    if (!existing) throw new NotFoundException(`Unknown template: ${type}`);

    const set: Record<string, unknown> = {};
    if (dto.enabled !== undefined) set.enabled = dto.enabled;
    if (dto.localHour !== undefined) set.localHour = dto.localHour;
    if (dto.localMinute !== undefined) set.localMinute = dto.localMinute;
    // null is meaningful here — it clears the weekday back to "every day".
    if (dto.localWeekday !== undefined) set.localWeekday = dto.localWeekday;
    if (dto.deeplink !== undefined) set.deeplink = dto.deeplink;
    // Chuỗi rỗng là cách người vận hành xoá ảnh, nên `undefined` (không gửi
    // field) và `''` (bấm Xoá ảnh) phải là hai chuyện khác nhau ở đây.
    if (dto.imageUrl !== undefined) {
      set.imageUrl = normalizeNotificationImageUrl(dto.imageUrl);
    }
    // `undefined` leaves targeting alone; `[]` is how the screen clears it and
    // goes back to sending to everybody, so it must reach the write.
    if (dto.segmentIds !== undefined) {
      set.segmentIds = dto.segmentIds.map(id => id.trim()).filter(Boolean);
    }

    // Variants are replaced wholesale, not merged: a merge would leave a wording
    // an editor deliberately deleted still live in the rotation.
    if (dto.variants) {
      Object.assign(set, this.toVariantWrite(dto.variants, existing));
    } else if (dto.copies) {
      // The pre-variants shape, still accepted. It edits the FIRST wording in
      // place and leaves the rest of the rotation alone — dropping the others
      // would silently delete copy the caller never mentioned.
      Object.assign(set, this.toLegacyCopyWrite(dto.copies, existing));
    }

    return this.templateRepository.upsertByType(type, { $set: set });
  }

  /**
   * Replaces the templates named in the payload. Types absent from the file are
   * left alone rather than deleted — a partial export edited and re-imported
   * must not silently switch off the types it does not mention.
   */
  async import(dto: ImportNotificationTemplateDto) {
    const imported: NotificationType[] = [];
    for (const item of dto.templates) {
      const existing = await this.templateRepository.findByType(item.type);
      const write = item.variants?.length
        ? this.toVariantWrite(item.variants, existing)
        : this.toVariantWrite(
            // A file exported before variants existed carries one wording.
            [{ copies: item.copies ?? [] }],
            existing,
          );

      await this.templateRepository.upsertByType(item.type, {
        $set: {
          type: item.type,
          // Only when the file says so — see the DTO: a content-only file must
          // not switch a running notification off.
          ...(item.enabled === undefined
            ? { enabled: existing?.enabled ?? false }
            : { enabled: item.enabled }),
          localHour: item.localHour,
          localMinute: item.localMinute ?? 0,
          // Same rule as `enabled`: a pre-weekday file must not strip the
          // weekly-recap pair back to daily.
          ...(item.localWeekday === undefined
            ? { localWeekday: existing?.localWeekday ?? null }
            : { localWeekday: item.localWeekday }),
          deeplink: item.deeplink,
          // Same rule as `enabled`: a file exported before images existed must
          // not strip the artwork off a live template.
          ...(item.imageUrl === undefined
            ? { imageUrl: existing?.imageUrl ?? null }
            : { imageUrl: normalizeNotificationImageUrl(item.imageUrl) }),
          // Same rule as `enabled`: a file written before targeting existed
          // must not silently un-target a live notification.
          ...(item.segmentIds === undefined
            ? { segmentIds: existing?.segmentIds ?? [] }
            : {
                segmentIds: item.segmentIds
                  .map(id => id.trim())
                  .filter(Boolean),
              }),
          ...write,
        },
      });
      imported.push(item.type);
    }
    return { imported };
  }

  /** Same shape `import` accepts, so a round trip is lossless. */
  async export() {
    const templates = await this.findAll();
    return {
      templates: templates.map(template => ({
        type: template.type,
        enabled: template.enabled,
        localHour: template.localHour,
        localMinute: template.localMinute ?? 0,
        localWeekday: template.localWeekday ?? null,
        deeplink: template.deeplink,
        imageUrl: template.imageUrl ?? null,
        segmentIds: template.segmentIds ?? [],
        // Legacy field, exported so a file taken from here still imports into an
        // older build.
        copies: this.toCopyList(template.copies),
        variants: variantsOf(template).map(item => ({
          key: item.key,
          copies: this.toCopyList(item.copies),
        })),
      })),
    };
  }

  /**
   * Assigns a key to every variant that arrives without one, drawing from the
   * document's own counter so a key is never reused (see
   * `NotificationTemplate.variantSeq`).
   */
  private toVariantWrite(
    variants: NotificationVariantDto[],
    existing?: {
      variants?: INotificationVariant[] | null;
      variantSeq?: number | null;
    } | null,
  ): IVariantWrite {
    let seq = Math.max(
      existing?.variantSeq ?? 0,
      highestVariantSeq(existing?.variants ?? []),
    );
    const taken = new Set<string>();
    const written: INotificationVariant[] = [];

    for (const item of variants) {
      const key = (item.key ?? '').trim();
      const unique = key !== '' && !taken.has(key) ? key : `v${(seq += 1)}`;
      taken.add(unique);
      written.push({ key: unique, copies: this.toCopyMap(item.copies) });
    }

    return {
      variants: written,
      copies: written[0]?.copies ?? {},
      // Also covers keys that arrived spelled out — an import file carries
      // `v1…v7` without this method allocating any of them, and leaving the
      // counter at 0 would hand `v1` to the next variant added by hand.
      variantSeq: Math.max(seq, highestVariantSeq(written)),
    };
  }

  private toLegacyCopyWrite(
    copies: NotificationCopyDto[],
    existing: { variants?: INotificationVariant[] | null; variantSeq?: number | null },
  ): IVariantWrite {
    const [first, ...rest] = variantsOf(existing);
    return {
      variants: [
        { key: first?.key ?? 'v1', copies: this.toCopyMap(copies) },
        ...rest,
      ],
      copies: this.toCopyMap(copies),
      variantSeq: Math.max(
        existing.variantSeq ?? 0,
        highestVariantSeq(existing.variants ?? []),
        1,
      ),
    };
  }

  private toCopyMap(copies: NotificationCopyDto[]) {
    const map: Record<string, INotificationCopy> = {};
    for (const copy of copies ?? []) {
      map[copy.locale.toLowerCase()] = { title: copy.title, body: copy.body };
    }
    return map;
  }

  private toCopyList(copies: Record<string, INotificationCopy> | undefined) {
    return Object.entries(copies ?? {}).map(([locale, copy]) => ({
      locale,
      title: copy?.title ?? '',
      body: copy?.body ?? '',
    }));
  }
}
