import { BadRequestException, Injectable } from '@nestjs/common';

import { RequestService } from '@base/service/request.service';

import { SaveOnboardingTaxonomyDto } from './dto/save-onboarding-taxonomy.dto';
import {
  IOnboardingBranch,
  IOnboardingLabel,
  IOnboardingPackage,
  IOnboardingTaxonomyPublic,
  IOnboardingTaxonomyTree,
} from './interface/onboarding-taxonomy.interface';
import { validateTaxonomyTree } from './onboarding-taxonomy.validator';
import { OnboardingBranchRepository } from './repository/onboarding-branch.repository';
import { OnboardingLabelRepository } from './repository/onboarding-label.repository';
import { OnboardingPackageRepository } from './repository/onboarding-package.repository';

@Injectable()
export class OnboardingTaxonomyService {
  constructor(
    private readonly branchRepository: OnboardingBranchRepository,
    private readonly packageRepository: OnboardingPackageRepository,
    private readonly labelRepository: OnboardingLabelRepository,
    private readonly requestService: RequestService,
  ) {}

  /** App: chỉ active, không kèm nhãn chi tiết (app không dùng). */
  async getPublic(): Promise<IOnboardingTaxonomyPublic> {
    const [branches, packages] = await Promise.all([
      this.branchRepository.findAll(true),
      this.packageRepository.findAll(true),
    ]);
    return {
      branches: branches.map(stripMeta),
      packages: packages.map(stripMeta),
    };
  }

  async getAdmin(): Promise<IOnboardingTaxonomyTree> {
    const [branches, packages, labels] = await Promise.all([
      this.branchRepository.findAll(false),
      this.packageRepository.findAll(false),
      this.labelRepository.findAll(),
    ]);
    return {
      branches: branches.map(stripMeta),
      packages: packages.map(stripMeta),
      labels: labels.map(stripMeta),
    };
  }

  /** Thay toàn bộ 3 collection sau khi validate; 400 kèm `errors[]` khi hỏng. */
  async replace(
    input: SaveOnboardingTaxonomyDto | IOnboardingTaxonomyTree,
  ): Promise<IOnboardingTaxonomyTree> {
    const tree = normalizeTree(input);
    // A tree with neither branches nor packages passes `validateTaxonomyTree`
    // trivially (there is nothing to check a relationship against), but this
    // is a PUT backed by `replaceAll` — delete-all-then-insert on all three
    // collections. An empty tree is therefore a legal way to wipe every
    // branch/package/label in one call, which is never what an admin means to
    // send; a genuine reset should go through re-seeding, not an accidental
    // empty payload.
    if (!tree.branches.length && !tree.packages.length) {
      throw new BadRequestException({
        message: 'Taxonomy không hợp lệ',
        errors: [
          {
            entity: 'branch',
            code: '',
            message: 'cây rỗng — không thể xoá toàn bộ taxonomy bằng PUT',
          },
        ],
      });
    }
    const issues = validateTaxonomyTree(tree);
    if (issues.length) {
      // Key must be `errors`, not `issues` — the global AllExceptionsFilter
      // (src/base/filters/all-exceptions.filter.ts) only forwards `errors`
      // and `meta` from an HttpException body; any other key is dropped and
      // the client falls back to the flat `message` string.
      throw new BadRequestException({
        message: 'Taxonomy không hợp lệ',
        errors: issues,
      });
    }
    const user = this.requestService.user;
    await this.branchRepository.replaceAll(tree.branches, user);
    await this.packageRepository.replaceAll(tree.packages, user);
    await this.labelRepository.replaceAll(tree.labels, user);
    return this.getAdmin();
  }
}

/** Điền mặc định + chuẩn hoá mã in hoa, để validator/DB thấy cùng một hình. */
export function normalizeTree(
  input: SaveOnboardingTaxonomyDto | IOnboardingTaxonomyTree,
): IOnboardingTaxonomyTree {
  const up = (s: string) => (s ?? '').trim().toUpperCase();
  const branches: IOnboardingBranch[] = (input.branches ?? []).map((b, i) => ({
    code: up(b.code),
    label: b.label ?? {},
    subtitle: b.subtitle ?? {},
    iconUrl: b.iconUrl ?? '',
    imageUrl: b.imageUrl ?? '',
    order: b.order ?? i + 1,
    isSelectable: b.isSelectable ?? true,
    categoryId: b.categoryId ?? null,
    isActive: b.isActive ?? true,
  }));
  const packages: IOnboardingPackage[] = (input.packages ?? []).map((p, i) => ({
    code: up(p.code),
    branchCode: up(p.branchCode),
    problemLabel: p.problemLabel ?? {},
    desireLabel: p.desireLabel ?? {},
    order: p.order ?? i + 1,
    isActive: p.isActive ?? true,
  }));
  const labels: IOnboardingLabel[] = (input.labels ?? []).map((l, i) => ({
    code: up(l.code),
    packageCode: up(l.packageCode),
    label: l.label ?? {},
    order: l.order ?? i + 1,
  }));
  return { branches, packages, labels };
}

function stripMeta<T extends Record<string, any>>(row: T): T {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const { _id, createdAt, updatedAt, createdBy, updatedBy, __v, ...rest } =
    row as any;
  return rest;
}
