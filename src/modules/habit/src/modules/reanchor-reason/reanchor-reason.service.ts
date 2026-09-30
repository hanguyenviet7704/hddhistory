import { Injectable, NotFoundException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { UserMetaDto } from '@base/database/mongodb/abstract.dto';
import { RequestService } from '@base/service/request.service';

import { CreateReanchorReasonDto } from './dto/create-reanchor-reason.dto';
import { GetListReanchorReasonDto } from './dto/get-list-reanchor-reason.dto';
import { ImportReanchorReasonDto } from './dto/import-reanchor-reason.dto';
import { UpdateReanchorReasonDto } from './dto/update-reanchor-reason.dto';
import { ReanchorReasonStatus } from './enum/reanchor-reason.enum';
import { ReanchorReasonRepository } from './repository/reanchor-reason.repository';
import { ReanchorReason } from './schema/reanchor-reason.schema';
import { HabitContentResolver } from '../../shared/habit-content-resolver.service';

const LANG_KEYS = ['vi', 'en', 'zh', 'ja', 'ko'] as const;

@Injectable()
export class ReanchorReasonService {
  constructor(
    private readonly reanchorReasonRepository: ReanchorReasonRepository,
    private readonly requestService: RequestService,
    private readonly resolver: HabitContentResolver,
    private readonly i18n: I18nService,
  ) {}

  private get user() {
    return this.requestService.user;
  }

  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  private notFoundError() {
    return new NotFoundException(
      this.i18n.t('error.REANCHOR.NOT_FOUND', { lang: this.lang }),
    );
  }

  private pickLangs(value: any): Record<string, string> {
    const out: Record<string, string> = {};
    for (const k of LANG_KEYS) {
      const v = value?.[k];
      if (typeof v === 'string' && v.trim()) out[k] = v;
    }
    return out;
  }

  private meta() {
    return plainToInstance(UserMetaDto, this.user, {
      excludeExtraneousValues: true,
    });
  }

  private stamp<T extends Record<string, any>>(doc: T): T {
    const cleanUser = this.meta();
    return { ...doc, createdBy: cleanUser, updatedBy: cleanUser };
  }

  async findAll(dto: GetListReanchorReasonDto) {
    // End-user default stays published-only; admin passes `isAll` (every
    // status) or an explicit `status` filter.
    const status = dto.isAll
      ? undefined
      : (dto.status ?? ReanchorReasonStatus.PUBLISHED);
    return this.reanchorReasonRepository.findList({
      courseId: dto.courseId,
      status,
    });
  }

  async findOne(id: string) {
    const reason = await this.reanchorReasonRepository.findById(id);
    if (!reason) throw this.notFoundError();
    return reason;
  }

  async create(dto: CreateReanchorReasonDto) {
    return this.reanchorReasonRepository.create(
      { ...dto } as unknown as Partial<ReanchorReason>,
      this.user,
    );
  }

  async update(id: string, dto: UpdateReanchorReasonDto) {
    const updated = await this.reanchorReasonRepository.findOneAndUpdate(
      { _id: id },
      { $set: dto },
    );
    if (!updated) throw this.notFoundError();
    return updated;
  }

  async remove(id: string) {
    const reason = await this.reanchorReasonRepository.findById(id);
    if (!reason) throw this.notFoundError();
    await this.reanchorReasonRepository.deleteOne({ _id: id });
    return { deleted: true };
  }

  // Portable export: every published reason keyed by the course's English
  // title (so it can be re-imported into another environment).
  async exportAll() {
    const { byId } = await this.resolver.buildCourseIndex();
    const rows = await this.reanchorReasonRepository.findAllPublished();
    const out: Array<{
      id?: string;
      course: string;
      index: number;
      reason: Record<string, string>;
    }> = [];
    for (const r of rows as any[]) {
      const course = byId.get(r.courseId?.toString());
      if (!course?.titleEn) continue; // orphan / untitled course — skip
      out.push({
        id: r._id?.toString(),
        course: course.titleEn,
        index: (r.order ?? 0) + 1,
        reason: this.pickLangs(r.reason),
      });
    }
    return out;
  }

  // Upsert per course present in the file: match incoming rows to the course's
  // existing reasons by `id` (falling back to position/order) and UPDATE them
  // in place — preserving each reason's _id so any user reference by id stays
  // valid — creating rows with no match and deleting reasons no longer present
  // in the file. Courses missing on this environment are reported, never
  // created.
  async importReplace(dto: ImportReanchorReasonDto) {
    const { byTitleEn, byLooseTitleEn, ambiguousTitleEn } =
      await this.resolver.buildCourseIndex();
    const grouped = new Map<string, ImportReanchorReasonDto['rows']>();
    for (const row of dto.rows) {
      const key = this.resolver.normalizeTitle(row.course);
      if (!grouped.has(key)) grouped.set(key, []);
      grouped.get(key)!.push(row);
    }

    let created = 0;
    let updated = 0;
    let deleted = 0;
    const coursesMissing: string[] = [];
    const errors: Array<{ course: string; index?: number; message: string }> =
      [];
    const matched = new Set<string>();
    const coursesMatchedLoosely: string[] = [];
    const coursesAmbiguous: string[] = [];

    for (const [key, rows] of grouped) {
      let course = byTitleEn.get(key);
      if (!course) {
        const loose = byLooseTitleEn.get(this.resolver.looseTitleKey(key));
        if (loose) {
          course = loose;
          coursesMatchedLoosely.push(`${rows[0].course} -> ${loose.titleEn}`);
        }
      }
      if (!course) {
        coursesMissing.push(`${rows[0].course} (${rows.length} rows)`);
        continue;
      }
      if (ambiguousTitleEn.has(course.titleEn)) {
        coursesAmbiguous.push(course.titleEn);
      }
      matched.add(key);
      try {
        const existing = (await this.reanchorReasonRepository.findList({
          courseId: course.courseId,
        })) as any[];

        // Match each incoming row to an existing reason and UPDATE it in
        // place, preserving its _id (the app can reference a chosen reason by
        // id). Prefer the row's `id` (the export round-trips it) so editing/
        // reordering the sheet still hits the same doc; fall back to position
        // (`order`) for rows with no id. Unmatched rows are created; reasons
        // no matching row touched are deleted below.
        const existingById = new Map<string, any>();
        const byOrder = new Map<number, any[]>();
        for (const e of existing) {
          existingById.set(e._id.toString(), e);
          const arr = byOrder.get(e.order) ?? [];
          arr.push(e);
          byOrder.set(e.order, arr);
        }
        const matchedIds = new Set<string>();

        const fieldsFor = (r: ImportReanchorReasonDto['rows'][number]) => ({
          courseId: course.courseId,
          reason: this.pickLangs(r.reason),
          order: (r.index ?? 1) - 1,
          status: ReanchorReasonStatus.PUBLISHED,
        });
        const updateInPlace = async (docId: any, r: any) => {
          await this.reanchorReasonRepository.findOneAndUpdate(
            { _id: docId },
            { $set: { ...fieldsFor(r), updatedBy: this.meta() } },
          );
          matchedIds.add(docId.toString());
          updated++;
        };

        // Pass 1: id matches (immune to row reordering in the sheet).
        const pending: ImportReanchorReasonDto['rows'] = [];
        for (const r of rows) {
          const byId = r.id ? existingById.get(r.id) : undefined;
          if (byId && !matchedIds.has(byId._id.toString())) {
            await updateInPlace(byId._id, r);
          } else {
            pending.push(r);
          }
        }
        // Pass 2: position matches for the rest, else create.
        for (const r of pending) {
          const order = (r.index ?? 1) - 1;
          const queue = byOrder.get(order);
          let match: any;
          while (queue && queue.length) {
            const cand = queue.shift();
            if (!matchedIds.has(cand._id.toString())) {
              match = cand;
              break;
            }
          }
          if (match) {
            await updateInPlace(match._id, r);
          } else {
            const inserted = await this.reanchorReasonRepository.insertManyDocs([
              this.stamp(fieldsFor(r)) as unknown as Partial<ReanchorReason>,
            ]);
            created += inserted.length;
          }
        }

        // Reasons with no matching row were removed from the sheet → delete.
        for (const e of existing) {
          if (matchedIds.has(e._id.toString())) continue;
          await this.reanchorReasonRepository.deleteOne({ _id: e._id });
          deleted++;
        }
      } catch (e: any) {
        errors.push({ course: rows[0].course, message: e?.message ?? 'error' });
      }
    }

    return {
      // Differ exactly when rows were skipped — see the habit import for why
      // these two numbers matter more than created/updated on their own.
      rowsReceived: dto.rows.length,
      rowsApplied: created + updated,
      coursesMatched: matched.size,
      coursesMissing,
      coursesMatchedLoosely,
      coursesAmbiguous,
      created,
      updated,
      deleted,
      errors,
    };
  }
}
