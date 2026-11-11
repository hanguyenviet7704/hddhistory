# Onboarding v3 — hddhistory-api Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Đưa taxonomy onboarding (nhánh → gói → nhãn chi tiết) + tag khoá vào MongoDB, thêm endpoint lưu câu trả lời và trả 3 khoá đã xếp hạng, import/export Excel, và loại noti "nhắc học theo giờ user chọn".

**Architecture:** Hai module Mongo mới, phẳng (`src/modules/onboarding-taxonomy/`, `src/modules/onboarding-answer/`), theo khuôn `study-theme` (schema + repository + service + controller, `forwardRef(() => AuthModule)`). Course thêm 2 field mảng string. Noti sao y `coach-plan-reminder.dispatcher.ts`: một dispatcher `@Cron` mỗi phút gọi `NotificationDispatchService.zonesDueAt` + `sendDirect`. Import Excel dùng `courses/src/modules/import/excel-import.util.ts`.

**Tech Stack:** NestJS 9, Mongoose, class-validator, exceljs 4 (`import * as ExcelJS`), @nestjs/schedule, jest (ts-jest).

**Spec:** `plans/260918-onboarding-v3-taxonomy/design.md`

## Global Constraints

- Layering: controller = transport; service = nghiệp vụ; **chỉ repository chạm DB** (`InjectModel` chỉ trong `repository/`).
- Alias `@base/*`, `@utils/*`; Prettier 2 space / 80 cột / single quote / trailing comma; file kebab-case + hậu tố Nest.
- Module nào dùng `@UseGuards(AuthGuard)` PHẢI `imports: [forwardRef(() => AuthModule)]`, nếu không boot crash-loop mà `tsc`/`nest build` không báo.
- Gate thật là **`npm run build`** (strict: implicit-any, null). `npx tsc --noEmit` chỉ là bước nhanh.
- **KHÔNG chạy `npm test` toàn bộ** (hết RAM). Chạy đúng 1 file: `npm test -- src/modules/onboarding-taxonomy/onboarding-taxonomy.validator.spec.ts`.
- `import * as ExcelJS from 'exceljs'` trong file mới (default import chết dưới jest vì tsconfig.json không bật esModuleInterop).
- Mọi response JSON tự bọc `{statusCode,message,data}`; tải file dùng `@Res()` + `res.send(buffer)`.
- Git: commit thẳng `develop`, `git add` **đúng từng file** (không add thư mục), message `type: <chủ ngữ tiếng Việt, thường, mệnh lệnh>` + dòng `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Mã: nhánh `^[A-Z]{2,4}$`, gói `^[A-Z]{2,4}-\d+$`, nhãn `^[A-Z]{2,4}\d{2,}$`, giờ nhắc `^([01]\d|2[0-3]):(00|15|30|45)$`.
- `ITranslation = { en?, vi?, zh?, ja?, ko? }` từ `@utils/interface/common.interface`; validator `IsMultiLangString` từ `@utils/dto/multi-languge`.

---

## File map

```
src/modules/onboarding-taxonomy/
  onboarding-taxonomy.module.ts
  onboarding-taxonomy.controller.ts
  onboarding-taxonomy.service.ts
  onboarding-taxonomy.validator.ts          (thuần, có spec)
  onboarding-taxonomy.validator.spec.ts
  onboarding-taxonomy-excel.ts              (thuần: parse workbook -> tree + course rows; build export)
  onboarding-taxonomy-excel.spec.ts
  onboarding-taxonomy-import.service.ts     (điều phối import: parse -> validate -> replace -> tag course)
  interface/onboarding-taxonomy.interface.ts
  dto/save-onboarding-taxonomy.dto.ts
  schema/onboarding-branch.schema.ts
  schema/onboarding-package.schema.ts
  schema/onboarding-label.schema.ts
  repository/onboarding-branch.repository.ts
  repository/onboarding-package.repository.ts
  repository/onboarding-label.repository.ts
src/modules/onboarding-answer/
  onboarding-answer.module.ts
  onboarding-answer.controller.ts
  onboarding-answer.service.ts
  onboarding-recommendation.ranker.ts       (thuần, có spec)
  onboarding-recommendation.ranker.spec.ts
  onboarding-study-reminder.dispatcher.ts
  interface/onboarding-answer.interface.ts
  dto/save-onboarding-answer.dto.ts
  schema/onboarding-answer.schema.ts
  repository/onboarding-answer.repository.ts
src/modules/courses/src/modules/course/{schema,interface,dto,repository}   (thêm field + query)
src/modules/user/src/modules/auth/{schema/user.schema.ts, repository/user.repository.ts}
src/modules/notification/{notification.enum.ts, notification.defaults.ts, notification-dispatch.service.ts}
src/modules/onboarding-config/{interface,schema,dto,service}               (4 section mới + fix paywall)
src/app.module.ts
```

---

### Task 1: Taxonomy — interface, schema, repository, module rỗng

**Files:**
- Create: `src/modules/onboarding-taxonomy/interface/onboarding-taxonomy.interface.ts`
- Create: `src/modules/onboarding-taxonomy/schema/onboarding-branch.schema.ts`
- Create: `src/modules/onboarding-taxonomy/schema/onboarding-package.schema.ts`
- Create: `src/modules/onboarding-taxonomy/schema/onboarding-label.schema.ts`
- Create: `src/modules/onboarding-taxonomy/repository/onboarding-branch.repository.ts`
- Create: `src/modules/onboarding-taxonomy/repository/onboarding-package.repository.ts`
- Create: `src/modules/onboarding-taxonomy/repository/onboarding-label.repository.ts`
- Create: `src/modules/onboarding-taxonomy/onboarding-taxonomy.module.ts`
- Modify: `src/app.module.ts` (thêm `OnboardingTaxonomyModule` sau `OnboardingConfigModule`)

**Interfaces — Produces:**
```ts
IOnboardingBranch { code; label: ITranslation; subtitle: ITranslation; iconUrl: string; imageUrl: string; order: number; isSelectable: boolean; categoryId: string | null; isActive: boolean }
IOnboardingPackage { code; branchCode; problemLabel: ITranslation; desireLabel: ITranslation; order: number; isActive: boolean }
IOnboardingLabel { code; packageCode; label: ITranslation; order: number }
IOnboardingTaxonomyTree { branches: IOnboardingBranch[]; packages: IOnboardingPackage[]; labels: IOnboardingLabel[] }
OnboardingBranchRepository.findAll(activeOnly: boolean): Promise<IOnboardingBranch[]>   // sort order asc
OnboardingBranchRepository.replaceAll(rows, user): Promise<void>                       // deleteMany({}) + insertMany
OnboardingPackageRepository.findAll(activeOnly) / replaceAll / findByCodes(codes)
OnboardingLabelRepository.findAll() / replaceAll / findByPackageCodes(codes)
```

- [ ] **Step 1: Interface**

```ts
// src/modules/onboarding-taxonomy/interface/onboarding-taxonomy.interface.ts
import { ITranslation } from '@utils/interface/common.interface';

/** Nhánh = đáp án câu 1 (lĩnh vực). `isSelectable=false` (vd Khám phá não bộ) chỉ để gắn khoá. */
export interface IOnboardingBranch {
  code: string;
  label: ITranslation;
  subtitle: ITranslation;
  iconUrl: string;
  imageUrl: string;
  order: number;
  isSelectable: boolean;
  /** Chủ đề tương ứng để Home xếp thứ tự theo nhánh đã chọn. */
  categoryId: string | null;
  isActive: boolean;
}

/** Gói = 1 đáp án câu 2 (vấn đề) = 1 đáp án câu 3 (mong muốn). Mã mong muốn == mã gói. */
export interface IOnboardingPackage {
  code: string;
  branchCode: string;
  problemLabel: ITranslation;
  desireLabel: ITranslation;
  order: number;
  isActive: boolean;
}

/** Nhãn chi tiết: không hiện cho user, chỉ khớp gói ↔ khoá (Course.onboardingLabelCodes). */
export interface IOnboardingLabel {
  code: string;
  packageCode: string;
  label: ITranslation;
  order: number;
}

export interface IOnboardingTaxonomyTree {
  branches: IOnboardingBranch[];
  packages: IOnboardingPackage[];
  labels: IOnboardingLabel[];
}

/** Bản public cho app: chỉ active, không kèm labels. */
export interface IOnboardingTaxonomyPublic {
  branches: IOnboardingBranch[];
  packages: IOnboardingPackage[];
}

export const BRANCH_CODE_REGEX = /^[A-Z]{2,4}$/;
export const PACKAGE_CODE_REGEX = /^[A-Z]{2,4}-\d+$/;
export const LABEL_CODE_REGEX = /^[A-Z]{2,4}\d{2,}$/;
```

- [ ] **Step 2: Ba schema** (mẫu chung; lặp cho package/label với field tương ứng)

```ts
// src/modules/onboarding-taxonomy/schema/onboarding-branch.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

import { IOnboardingBranch } from '../interface/onboarding-taxonomy.interface';

@Schema({ collection: 'onboarding_branches' })
export class OnboardingBranch
  extends AbstractDocument
  implements IOnboardingBranch
{
  @Prop({ required: true, unique: true, trim: true, uppercase: true })
  code: string;

  @Prop({ type: SchemaTypes.Mixed, default: {} })
  label: ITranslation;

  @Prop({ type: SchemaTypes.Mixed, default: {} })
  subtitle: ITranslation;

  @Prop({ default: '' })
  iconUrl: string;

  @Prop({ default: '' })
  imageUrl: string;

  @Prop({ default: 0 })
  order: number;

  @Prop({ default: true })
  isSelectable: boolean;

  @Prop({ type: String, default: null })
  categoryId: string | null;

  @Prop({ default: true })
  isActive: boolean;
}

export const OnboardingBranchSchema =
  SchemaFactory.createForClass(OnboardingBranch);
OnboardingBranchSchema.index({ code: 1 }, { unique: true });
OnboardingBranchSchema.index({ isActive: 1, order: 1 });
```

```ts
// src/modules/onboarding-taxonomy/schema/onboarding-package.schema.ts
@Schema({ collection: 'onboarding_packages' })
export class OnboardingPackage extends AbstractDocument implements IOnboardingPackage {
  @Prop({ required: true, unique: true, trim: true, uppercase: true }) code: string;
  @Prop({ required: true, trim: true, uppercase: true }) branchCode: string;
  @Prop({ type: SchemaTypes.Mixed, default: {} }) problemLabel: ITranslation;
  @Prop({ type: SchemaTypes.Mixed, default: {} }) desireLabel: ITranslation;
  @Prop({ default: 0 }) order: number;
  @Prop({ default: true }) isActive: boolean;
}
export const OnboardingPackageSchema = SchemaFactory.createForClass(OnboardingPackage);
OnboardingPackageSchema.index({ code: 1 }, { unique: true });
OnboardingPackageSchema.index({ branchCode: 1, order: 1 });
```

```ts
// src/modules/onboarding-taxonomy/schema/onboarding-label.schema.ts
@Schema({ collection: 'onboarding_labels' })
export class OnboardingLabel extends AbstractDocument implements IOnboardingLabel {
  @Prop({ required: true, unique: true, trim: true, uppercase: true }) code: string;
  @Prop({ required: true, trim: true, uppercase: true }) packageCode: string;
  @Prop({ type: SchemaTypes.Mixed, default: {} }) label: ITranslation;
  @Prop({ default: 0 }) order: number;
}
export const OnboardingLabelSchema = SchemaFactory.createForClass(OnboardingLabel);
OnboardingLabelSchema.index({ code: 1 }, { unique: true });
OnboardingLabelSchema.index({ packageCode: 1, order: 1 });
```

- [ ] **Step 3: Ba repository** (mẫu cho branch; package thêm `findByCodes`, label thêm `findByPackageCodes`)

```ts
// src/modules/onboarding-taxonomy/repository/onboarding-branch.repository.ts
import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';
import { IUserMeta } from '@base/database/mongodb/abstract.interface';

import { IOnboardingBranch } from '../interface/onboarding-taxonomy.interface';
import { OnboardingBranch } from '../schema/onboarding-branch.schema';

@Injectable()
export class OnboardingBranchRepository extends AbstractRepository<OnboardingBranch> {
  protected readonly logger = new Logger(OnboardingBranchRepository.name);

  constructor(
    @InjectModel(OnboardingBranch.name) model: Model<OnboardingBranch>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  async findAll(activeOnly = false): Promise<IOnboardingBranch[]> {
    return this.model
      .find(activeOnly ? { isActive: true } : {})
      .sort({ order: 1, code: 1 })
      .lean();
  }

  /**
   * Import/lưu cây là THAY TOÀN BỘ: xoá hết rồi chèn lại. Không transaction
   * (Mongo dev là standalone) — caller đã validate xong trước khi gọi, nên cửa
   * sổ lỗi chỉ còn là lỗi hạ tầng.
   */
  async replaceAll(rows: IOnboardingBranch[], user?: IUserMeta): Promise<void> {
    await this.model.deleteMany({});
    if (!rows.length) return;
    const meta = user
      ? { createdBy: user, updatedBy: user }
      : {};
    await this.model.insertMany(rows.map(row => ({ ...row, ...meta })));
  }
}
```

```ts
// onboarding-package.repository.ts — thêm:
async findByCodes(codes: string[]): Promise<IOnboardingPackage[]> {
  if (!codes.length) return [];
  return this.model.find({ code: { $in: codes } }).lean();
}
// onboarding-label.repository.ts — thêm:
async findByPackageCodes(packageCodes: string[]): Promise<IOnboardingLabel[]> {
  if (!packageCodes.length) return [];
  return this.model.find({ packageCode: { $in: packageCodes } }).sort({ order: 1 }).lean();
}
```

- [ ] **Step 4: Module + đăng ký**

```ts
// src/modules/onboarding-taxonomy/onboarding-taxonomy.module.ts
import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { OnboardingBranchRepository } from './repository/onboarding-branch.repository';
import { OnboardingLabelRepository } from './repository/onboarding-label.repository';
import { OnboardingPackageRepository } from './repository/onboarding-package.repository';
import { OnboardingBranch, OnboardingBranchSchema } from './schema/onboarding-branch.schema';
import { OnboardingLabel, OnboardingLabelSchema } from './schema/onboarding-label.schema';
import { OnboardingPackage, OnboardingPackageSchema } from './schema/onboarding-package.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: OnboardingBranch.name, schema: OnboardingBranchSchema },
      { name: OnboardingPackage.name, schema: OnboardingPackageSchema },
      { name: OnboardingLabel.name, schema: OnboardingLabelSchema },
    ]),
    forwardRef(() => AuthModule),
  ],
  controllers: [],
  providers: [
    OnboardingBranchRepository,
    OnboardingPackageRepository,
    OnboardingLabelRepository,
  ],
  exports: [
    OnboardingBranchRepository,
    OnboardingPackageRepository,
    OnboardingLabelRepository,
  ],
})
export class OnboardingTaxonomyModule {}
```
Trong `src/app.module.ts`: import và thêm `OnboardingTaxonomyModule,` ngay sau `OnboardingConfigModule,` (dòng ~67).

- [ ] **Step 5: Type-check + commit**

Run: `cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-api && npx tsc --noEmit`
Expected: không lỗi.
```bash
git add src/modules/onboarding-taxonomy/interface/onboarding-taxonomy.interface.ts src/modules/onboarding-taxonomy/schema/onboarding-branch.schema.ts src/modules/onboarding-taxonomy/schema/onboarding-package.schema.ts src/modules/onboarding-taxonomy/schema/onboarding-label.schema.ts src/modules/onboarding-taxonomy/repository/onboarding-branch.repository.ts src/modules/onboarding-taxonomy/repository/onboarding-package.repository.ts src/modules/onboarding-taxonomy/repository/onboarding-label.repository.ts src/modules/onboarding-taxonomy/onboarding-taxonomy.module.ts src/app.module.ts
git commit -m "feat: thêm collection nhánh/gói/nhãn onboarding (taxonomy v3)" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: Taxonomy — validator thuần + service + controller (GET public / GET admin / PUT)

**Files:**
- Create: `src/modules/onboarding-taxonomy/onboarding-taxonomy.validator.ts`
- Create: `src/modules/onboarding-taxonomy/onboarding-taxonomy.validator.spec.ts`
- Create: `src/modules/onboarding-taxonomy/dto/save-onboarding-taxonomy.dto.ts`
- Create: `src/modules/onboarding-taxonomy/onboarding-taxonomy.service.ts`
- Create: `src/modules/onboarding-taxonomy/onboarding-taxonomy.controller.ts`
- Modify: `src/modules/onboarding-taxonomy/onboarding-taxonomy.module.ts` (controllers + providers + exports thêm service)

**Interfaces — Produces:**
```ts
validateTaxonomyTree(tree: IOnboardingTaxonomyTree): TaxonomyIssue[]   // [] = hợp lệ
interface TaxonomyIssue { entity: 'branch'|'package'|'label'; code: string; message: string }
OnboardingTaxonomyService.getPublic(): Promise<IOnboardingTaxonomyPublic>
OnboardingTaxonomyService.getAdmin(): Promise<IOnboardingTaxonomyTree>
OnboardingTaxonomyService.replace(tree: IOnboardingTaxonomyTree): Promise<IOnboardingTaxonomyTree>  // throw BadRequest {message, issues}
Routes: GET /api/v1/onboarding-taxonomy (Public) · GET /api/v1/onboarding-taxonomy/admin · PUT /api/v1/onboarding-taxonomy
```

- [ ] **Step 1: Spec thất bại cho validator**

```ts
// src/modules/onboarding-taxonomy/onboarding-taxonomy.validator.spec.ts
import { validateTaxonomyTree } from './onboarding-taxonomy.validator';
import { IOnboardingTaxonomyTree } from './interface/onboarding-taxonomy.interface';

const branch = (code: string) => ({
  code, label: { vi: code }, subtitle: {}, iconUrl: '', imageUrl: '',
  order: 1, isSelectable: true, categoryId: null, isActive: true,
});
const pkg = (code: string, branchCode: string) => ({
  code, branchCode, problemLabel: { vi: 'p ' + code }, desireLabel: { vi: 'd ' + code },
  order: 1, isActive: true,
});
const label = (code: string, packageCode: string) => ({
  code, packageCode, label: { vi: 'l ' + code }, order: 1,
});

const valid: IOnboardingTaxonomyTree = {
  branches: [branch('CX')],
  packages: [pkg('CX-1', 'CX')],
  labels: [label('CX01', 'CX-1')],
};

describe('validateTaxonomyTree', () => {
  it('accepts a consistent tree', () => {
    expect(validateTaxonomyTree(valid)).toEqual([]);
  });

  it('rejects duplicated codes across the same entity', () => {
    const issues = validateTaxonomyTree({
      ...valid,
      labels: [label('CX01', 'CX-1'), label('CX01', 'CX-1')],
    });
    expect(issues).toEqual([
      expect.objectContaining({ entity: 'label', code: 'CX01', message: expect.stringContaining('trùng') }),
    ]);
  });

  it('rejects a package whose branch does not exist', () => {
    const issues = validateTaxonomyTree({ ...valid, packages: [pkg('LV-1', 'LV')], labels: [label('LV01', 'LV-1')] });
    expect(issues.map(i => i.code)).toContain('LV-1');
  });

  it('rejects a label whose package does not exist', () => {
    const issues = validateTaxonomyTree({ ...valid, labels: [label('CX01', 'CX-9')] });
    expect(issues.map(i => i.code)).toEqual(expect.arrayContaining(['CX01']));
  });

  it('rejects a package with no label and with blank vi labels', () => {
    const issues = validateTaxonomyTree({
      ...valid,
      packages: [{ ...pkg('CX-1', 'CX'), problemLabel: { vi: ' ' } }],
      labels: [],
    });
    expect(issues.filter(i => i.code === 'CX-1')).toHaveLength(2);
  });

  it('rejects malformed codes', () => {
    const issues = validateTaxonomyTree({
      branches: [branch('cx')],
      packages: [pkg('CX_1', 'cx')],
      labels: [label('CX-01', 'CX_1')],
    });
    expect(issues.length).toBeGreaterThanOrEqual(3);
  });
});
```

- [ ] **Step 2: Chạy spec, phải FAIL** — `npm test -- src/modules/onboarding-taxonomy/onboarding-taxonomy.validator.spec.ts` → "Cannot find module './onboarding-taxonomy.validator'".

- [ ] **Step 3: Validator**

```ts
// src/modules/onboarding-taxonomy/onboarding-taxonomy.validator.ts
import {
  BRANCH_CODE_REGEX,
  IOnboardingTaxonomyTree,
  LABEL_CODE_REGEX,
  PACKAGE_CODE_REGEX,
} from './interface/onboarding-taxonomy.interface';

export interface TaxonomyIssue {
  entity: 'branch' | 'package' | 'label';
  code: string;
  message: string;
}

const blank = (value?: string) => !value || !value.trim();

/**
 * Luật toàn cây, thuần để test được: mã đúng định dạng và duy nhất, quan hệ
 * cha–con tồn tại, mỗi gói có ≥1 nhãn, nhãn tiếng Việt không rỗng.
 * Trả [] khi hợp lệ.
 */
export function validateTaxonomyTree(tree: IOnboardingTaxonomyTree): TaxonomyIssue[] {
  const issues: TaxonomyIssue[] = [];
  const seen = { branch: new Set<string>(), package: new Set<string>(), label: new Set<string>() };

  const checkCode = (entity: TaxonomyIssue['entity'], code: string, regex: RegExp) => {
    if (!regex.test(code)) {
      issues.push({ entity, code, message: `mã ${entity} không đúng định dạng` });
    }
    if (seen[entity].has(code)) {
      issues.push({ entity, code, message: `mã ${entity} bị trùng` });
    }
    seen[entity].add(code);
  };

  for (const branch of tree.branches) {
    checkCode('branch', branch.code, BRANCH_CODE_REGEX);
    if (blank(branch.label?.vi)) {
      issues.push({ entity: 'branch', code: branch.code, message: 'tên nhánh (vi) rỗng' });
    }
  }

  const labelsPerPackage = new Map<string, number>();
  for (const label of tree.labels) {
    checkCode('label', label.code, LABEL_CODE_REGEX);
    labelsPerPackage.set(label.packageCode, (labelsPerPackage.get(label.packageCode) ?? 0) + 1);
    if (blank(label.label?.vi)) {
      issues.push({ entity: 'label', code: label.code, message: 'nhãn chi tiết (vi) rỗng' });
    }
  }

  for (const pkg of tree.packages) {
    checkCode('package', pkg.code, PACKAGE_CODE_REGEX);
    if (!seen.branch.has(pkg.branchCode)) {
      issues.push({ entity: 'package', code: pkg.code, message: `nhánh ${pkg.branchCode} không tồn tại` });
    }
    if (blank(pkg.problemLabel?.vi)) {
      issues.push({ entity: 'package', code: pkg.code, message: 'vấn đề (vi) rỗng' });
    }
    if (blank(pkg.desireLabel?.vi)) {
      issues.push({ entity: 'package', code: pkg.code, message: 'mong muốn (vi) rỗng' });
    }
    if (!labelsPerPackage.get(pkg.code)) {
      issues.push({ entity: 'package', code: pkg.code, message: 'gói không có nhãn chi tiết nào' });
    }
  }

  for (const label of tree.labels) {
    if (!seen.package.has(label.packageCode)) {
      issues.push({ entity: 'label', code: label.code, message: `gói ${label.packageCode} không tồn tại` });
    }
  }

  return issues;
}
```
Lưu ý spec "rejects a package with no label and with blank vi labels" đợi đúng 2 issue cho `CX-1` (vấn đề rỗng + không có nhãn) — kiểm tra lại số lượng khi chạy, chỉnh spec nếu bạn cố ý gộp.

- [ ] **Step 4: Chạy spec → PASS.**

- [ ] **Step 5: DTO cho PUT**

```ts
// src/modules/onboarding-taxonomy/dto/save-onboarding-taxonomy.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray, IsBoolean, IsInt, IsObject, IsOptional, IsString, Matches, ValidateNested,
} from 'class-validator';

import { ITranslation } from '@utils/interface/common.interface';

export class TaxonomyBranchDto {
  @ApiProperty({ example: 'CX' }) @IsString() @Matches(/^[A-Z]{2,4}$/) code: string;
  @ApiProperty({ example: { vi: 'Cảm xúc & tinh thần' } }) @IsObject() label: ITranslation;
  @ApiPropertyOptional() @IsOptional() @IsObject() subtitle?: ITranslation;
  @ApiPropertyOptional() @IsOptional() @IsString() iconUrl?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() imageUrl?: string;
  @ApiPropertyOptional() @IsOptional() @IsInt() order?: number;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() isSelectable?: boolean;
  @ApiPropertyOptional({ nullable: true }) @IsOptional() @IsString() categoryId?: string | null;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() isActive?: boolean;
}

export class TaxonomyPackageDto {
  @ApiProperty({ example: 'CX-1' }) @IsString() @Matches(/^[A-Z]{2,4}-\d+$/) code: string;
  @ApiProperty({ example: 'CX' }) @IsString() branchCode: string;
  @ApiProperty() @IsObject() problemLabel: ITranslation;
  @ApiProperty() @IsObject() desireLabel: ITranslation;
  @ApiPropertyOptional() @IsOptional() @IsInt() order?: number;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() isActive?: boolean;
}

export class TaxonomyLabelDto {
  @ApiProperty({ example: 'CX01' }) @IsString() @Matches(/^[A-Z]{2,4}\d{2,}$/) code: string;
  @ApiProperty({ example: 'CX-1' }) @IsString() packageCode: string;
  @ApiProperty() @IsObject() label: ITranslation;
  @ApiPropertyOptional() @IsOptional() @IsInt() order?: number;
}

export class SaveOnboardingTaxonomyDto {
  @ApiProperty({ type: [TaxonomyBranchDto] }) @IsArray() @ValidateNested({ each: true }) @Type(() => TaxonomyBranchDto) branches: TaxonomyBranchDto[];
  @ApiProperty({ type: [TaxonomyPackageDto] }) @IsArray() @ValidateNested({ each: true }) @Type(() => TaxonomyPackageDto) packages: TaxonomyPackageDto[];
  @ApiProperty({ type: [TaxonomyLabelDto] }) @IsArray() @ValidateNested({ each: true }) @Type(() => TaxonomyLabelDto) labels: TaxonomyLabelDto[];
}
```

- [ ] **Step 6: Service**

```ts
// src/modules/onboarding-taxonomy/onboarding-taxonomy.service.ts
import { BadRequestException, Injectable } from '@nestjs/common';

import { RequestService } from '@base/service/request.service';

import { SaveOnboardingTaxonomyDto } from './dto/save-onboarding-taxonomy.dto';
import {
  IOnboardingBranch, IOnboardingLabel, IOnboardingPackage,
  IOnboardingTaxonomyPublic, IOnboardingTaxonomyTree,
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
    return { branches: branches.map(stripMeta), packages: packages.map(stripMeta) };
  }

  async getAdmin(): Promise<IOnboardingTaxonomyTree> {
    const [branches, packages, labels] = await Promise.all([
      this.branchRepository.findAll(false),
      this.packageRepository.findAll(false),
      this.labelRepository.findAll(),
    ]);
    return { branches: branches.map(stripMeta), packages: packages.map(stripMeta), labels: labels.map(stripMeta) };
  }

  /** Thay toàn bộ 3 collection sau khi validate; 400 kèm `issues[]` khi hỏng. */
  async replace(input: SaveOnboardingTaxonomyDto | IOnboardingTaxonomyTree): Promise<IOnboardingTaxonomyTree> {
    const tree = normalizeTree(input);
    const issues = validateTaxonomyTree(tree);
    if (issues.length) {
      throw new BadRequestException({ message: 'Taxonomy không hợp lệ', issues });
    }
    const user = this.requestService.user;
    await this.branchRepository.replaceAll(tree.branches, user);
    await this.packageRepository.replaceAll(tree.packages, user);
    await this.labelRepository.replaceAll(tree.labels, user);
    return this.getAdmin();
  }
}

/** Điền mặc định + chuẩn hoá mã in hoa, để validator/DB thấy cùng một hình. */
export function normalizeTree(input: SaveOnboardingTaxonomyDto | IOnboardingTaxonomyTree): IOnboardingTaxonomyTree {
  const up = (s: string) => (s ?? '').trim().toUpperCase();
  const branches: IOnboardingBranch[] = (input.branches ?? []).map((b, i) => ({
    code: up(b.code), label: b.label ?? {}, subtitle: b.subtitle ?? {},
    iconUrl: b.iconUrl ?? '', imageUrl: b.imageUrl ?? '', order: b.order ?? i + 1,
    isSelectable: b.isSelectable ?? true, categoryId: b.categoryId ?? null, isActive: b.isActive ?? true,
  }));
  const packages: IOnboardingPackage[] = (input.packages ?? []).map((p, i) => ({
    code: up(p.code), branchCode: up(p.branchCode), problemLabel: p.problemLabel ?? {},
    desireLabel: p.desireLabel ?? {}, order: p.order ?? i + 1, isActive: p.isActive ?? true,
  }));
  const labels: IOnboardingLabel[] = (input.labels ?? []).map((l, i) => ({
    code: up(l.code), packageCode: up(l.packageCode), label: l.label ?? {}, order: l.order ?? i + 1,
  }));
  return { branches, packages, labels };
}

function stripMeta<T extends Record<string, any>>(row: T): T {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const { _id, createdAt, updatedAt, createdBy, updatedBy, __v, ...rest } = row as any;
  return rest;
}
```

- [ ] **Step 7: Controller + cập nhật module**

```ts
// src/modules/onboarding-taxonomy/onboarding-taxonomy.controller.ts
import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { Public } from '@base/decorator/public';
import { AuthGuard } from '@base/guard/auth.guard';

import { SaveOnboardingTaxonomyDto } from './dto/save-onboarding-taxonomy.dto';
import { OnboardingTaxonomyService } from './onboarding-taxonomy.service';

@ApiTags('ONBOARDING-TAXONOMY')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'onboarding-taxonomy', version: '1' })
export class OnboardingTaxonomyController {
  constructor(private readonly svc: OnboardingTaxonomyService) {}

  /** App đọc ở S4 trước khi chắc có token ẩn danh → public như /onboarding-config. */
  @Public()
  @Get('')
  getPublic() {
    return this.svc.getPublic();
  }

  @Get('admin')
  getAdmin() {
    return this.svc.getAdmin();
  }

  @Put('')
  replace(@Body() dto: SaveOnboardingTaxonomyDto) {
    return this.svc.replace(dto);
  }
}
```
Module: `controllers: [OnboardingTaxonomyController]`, thêm `OnboardingTaxonomyService` vào `providers` và `exports`.

- [ ] **Step 8: Build + commit**

Run: `npm run build` → Expected: exit 0.
```bash
git add src/modules/onboarding-taxonomy/onboarding-taxonomy.validator.ts src/modules/onboarding-taxonomy/onboarding-taxonomy.validator.spec.ts src/modules/onboarding-taxonomy/dto/save-onboarding-taxonomy.dto.ts src/modules/onboarding-taxonomy/onboarding-taxonomy.service.ts src/modules/onboarding-taxonomy/onboarding-taxonomy.controller.ts src/modules/onboarding-taxonomy/onboarding-taxonomy.module.ts
git commit -m "feat: endpoint đọc/lưu taxonomy onboarding, validate cả cây" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: Course — 2 field tag mới + query ứng viên gợi ý

**Files:**
- Modify: `src/modules/courses/src/modules/course/schema/course.schema.ts` (sau `onboardingSymptoms` dòng 26-27; index sau dòng 101)
- Modify: `src/modules/courses/src/modules/course/interface/course.interface.ts` (sau `onboardingSymptoms`)
- Modify: `src/modules/courses/src/modules/course/dto/create-course.dto.ts` (sau khối `onboardingSymptoms` dòng 55-66)
- Modify: `src/modules/courses/src/modules/course/repository/course.repository.ts` (thêm 2 method sau `findBriefByIds`)

**Interfaces — Produces:**
```ts
Course.onboardingLabelCodes: string[]; Course.onboardingDesireCodes: string[]
CourseRepository.findOnboardingCandidates(params: { labelCodes: string[]; desireCode: string | null; viewerMarkets?: string[] | null }): Promise<IOnboardingCourseCandidate[]>
CourseRepository.findPublishedFallback(params: { excludeIds: string[]; desireCodes: string[]; limit: number; viewerMarkets?: string[] | null }): Promise<IOnboardingCourseCandidate[]>
CourseRepository.updateOnboardingTags(courseId: string, tags: { onboardingLabelCodes: string[]; onboardingDesireCodes: string[] }): Promise<void>
CourseRepository.findIdByViTitle(title: string): Promise<string | null>
export interface IOnboardingCourseCandidate { _id: Types.ObjectId; title; description; image; categoryId; numberOfLesson; status; createdAt; onboardingLabelCodes: string[]; onboardingDesireCodes: string[] }
```

- [ ] **Step 1: Schema + interface + DTO**

```ts
// course.schema.ts — thêm sau onboardingSymptoms
// Onboarding v3 (plans/260918-onboarding-v3-taxonomy): nhãn chi tiết (vấn đề)
// và mã gói (mong muốn) — dữ liệu, không enum. Rỗng = khoá chưa gắn.
@Prop({ type: [String], default: [] })
onboardingLabelCodes: string[];

@Prop({ type: [String], default: [] })
onboardingDesireCodes: string[];
// ...và sau CourseSchema.index({ onboardingSymptoms: 1, status: 1 }):
CourseSchema.index({ onboardingLabelCodes: 1, status: 1 });
CourseSchema.index({ onboardingDesireCodes: 1, status: 1 });
```
```ts
// course.interface.ts — trong ICourse, sau onboardingSymptoms
/** Onboarding v3: mã nhãn chi tiết (vấn đề) khoá này giải quyết. */
onboardingLabelCodes?: string[];
/** Onboarding v3: mã gói (mong muốn) khoá này phục vụ. */
onboardingDesireCodes?: string[];
```
```ts
// create-course.dto.ts — sau khối onboardingSymptoms
@ApiPropertyOptional({ type: [String], example: ['CX01', 'CX03'] })
@IsOptional()
@IsArray()
@IsString({ each: true })
onboardingLabelCodes?: string[];

@ApiPropertyOptional({ type: [String], example: ['CX-1'] })
@IsOptional()
@IsArray()
@IsString({ each: true })
onboardingDesireCodes?: string[];
```
`UpdateCourseDto = PartialType(CreateCourseDto)` và `course.service.update()` spread cả dto → không cần sửa service.

- [ ] **Step 2: Repository**

```ts
// course.repository.ts — thêm export interface gần COURSE_CARD_FIELDS
export interface IOnboardingCourseCandidate {
  _id: Types.ObjectId;
  title: Record<string, string>;
  description?: Record<string, string>;
  image: string;
  categoryId: string;
  numberOfLesson?: number;
  status: CourseStatus;
  createdAt?: Date;
  onboardingLabelCodes: string[];
  onboardingDesireCodes: string[];
}

const ONBOARDING_CANDIDATE_FIELDS =
  '_id title description image categoryId numberOfLesson status createdAt onboardingLabelCodes onboardingDesireCodes';

// ...trong class:
/** Ứng viên cho gợi ý onboarding: published + hiện được ở thị trường + chạm ≥1 nhãn hoặc mong muốn. */
async findOnboardingCandidates(params: {
  labelCodes: string[];
  desireCode: string | null;
  viewerMarkets?: string[] | null;
}): Promise<IOnboardingCourseCandidate[]> {
  const or: FilterQuery<Course>[] = [];
  if (params.labelCodes.length) or.push({ onboardingLabelCodes: { $in: params.labelCodes } });
  if (params.desireCode) or.push({ onboardingDesireCodes: params.desireCode });
  if (!or.length) return [];
  const where: FilterQuery<Course> = { status: CourseStatus.PUBLISHED, $or: or };
  return this.model
    .find(withMarketVisibility(where, params.viewerMarkets))
    .select(ONBOARDING_CANDIDATE_FIELDS)
    .lean() as unknown as Promise<IOnboardingCourseCandidate[]>;
}

/** Bù cho đủ 3: trước hết khoá có mong muốn cùng nhánh, rồi khoá published mới nhất. */
async findPublishedFallback(params: {
  excludeIds: string[];
  desireCodes: string[];
  limit: number;
  viewerMarkets?: string[] | null;
}): Promise<IOnboardingCourseCandidate[]> {
  if (params.limit <= 0) return [];
  const exclude = params.excludeIds.map(id => new Types.ObjectId(id));
  const base: FilterQuery<Course> = {
    status: CourseStatus.PUBLISHED,
    _id: { $nin: exclude },
    numberOfLesson: { $gt: 0 },
  };
  const rows: IOnboardingCourseCandidate[] = [];
  if (params.desireCodes.length) {
    const byDesire = await this.model
      .find(withMarketVisibility({ ...base, onboardingDesireCodes: { $in: params.desireCodes } }, params.viewerMarkets))
      .select(ONBOARDING_CANDIDATE_FIELDS)
      .sort({ createdAt: -1 })
      .limit(params.limit)
      .lean();
    rows.push(...(byDesire as unknown as IOnboardingCourseCandidate[]));
  }
  if (rows.length < params.limit) {
    const taken = [...exclude, ...rows.map(r => r._id)];
    const newest = await this.model
      .find(withMarketVisibility({ ...base, _id: { $nin: taken } }, params.viewerMarkets))
      .select(ONBOARDING_CANDIDATE_FIELDS)
      .sort({ createdAt: -1 })
      .limit(params.limit - rows.length)
      .lean();
    rows.push(...(newest as unknown as IOnboardingCourseCandidate[]));
  }
  return rows;
}

async updateOnboardingTags(
  courseId: string,
  tags: { onboardingLabelCodes: string[]; onboardingDesireCodes: string[] },
): Promise<void> {
  await this.model.updateOne({ _id: courseId }, { $set: tags });
}

/** Import khớp khoá theo tiêu đề tiếng Việt khi sheet không có Course ID. */
async findIdByViTitle(title: string): Promise<string | null> {
  const normalized = title.trim().replace(/\s+/g, ' ');
  if (!normalized) return null;
  const escaped = normalized.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const row = await this.model
    .findOne({ 'title.vi': { $regex: `^\\s*${escaped}\\s*$`, $options: 'i' } })
    .select('_id')
    .lean();
  return row ? String(row._id) : null;
}
```

- [ ] **Step 3: Build + commit**

Run: `npm run build` → exit 0.
```bash
git add src/modules/courses/src/modules/course/schema/course.schema.ts src/modules/courses/src/modules/course/interface/course.interface.ts src/modules/courses/src/modules/course/dto/create-course.dto.ts src/modules/courses/src/modules/course/repository/course.repository.ts
git commit -m "feat: course gắn nhãn vấn đề + mã gói mong muốn cho onboarding v3" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: Excel — parser thuần + builder export/template + import service + 3 endpoint

**Files:**
- Create: `src/modules/onboarding-taxonomy/onboarding-taxonomy-excel.ts`
- Create: `src/modules/onboarding-taxonomy/onboarding-taxonomy-excel.spec.ts`
- Create: `src/modules/onboarding-taxonomy/onboarding-taxonomy-import.service.ts`
- Modify: `src/modules/onboarding-taxonomy/onboarding-taxonomy.controller.ts` (thêm import/export/template)
- Modify: `src/modules/onboarding-taxonomy/onboarding-taxonomy.module.ts` (import `CourseModule` bằng `forwardRef`, provider mới)

**Interfaces — Consumes:** `readWorkbook, getSheet, getRows, splitList, text, numberValue, setCellByHeader, workbookToBuffer, ImportRow, ImportValidationError` từ `src/modules/courses/src/modules/import/excel-import.util.ts`; `CourseRepository.findIdByViTitle / updateOnboardingTags` (Task 3); `OnboardingTaxonomyService.replace / getAdmin` (Task 2).
**Produces:**
```ts
SHEET_BRANCH = 'Nhánh'; SHEET_PACKAGE = ['Gói nhãn', 'Nhãn']; SHEET_MAPPING = ['Mapping Khoá học', 'Mapping Khoa hoc']
parseTaxonomyWorkbook(workbook, existingBranches: IOnboardingBranch[]): { tree: IOnboardingTaxonomyTree; courseRows: ParsedCourseRow[]; errors: ImportValidationError[] }
interface ParsedCourseRow { rowNumber: number; courseId: string; title: string; labelCodes: string[]; desireCodes: string[] }
buildTaxonomyWorkbook(tree: IOnboardingTaxonomyTree, courses: { _id: string; titleVi: string; branchCode: string; status: string; labelCodes: string[]; desireCodes: string[] }[]): ExcelJS.Workbook
OnboardingTaxonomyImportService.import(file): Promise<{ buffer: Buffer; warnings: number }>
OnboardingTaxonomyImportService.export(): Promise<Buffer>
OnboardingTaxonomyImportService.template(): Promise<Buffer>
Routes: POST /onboarding-taxonomy/import (multipart 'file') · GET /onboarding-taxonomy/export · GET /onboarding-taxonomy/template
```

Header chính thức (khớp `onboarding-taxonomy-template.xlsx`):
- `Nhánh`: `Mã nhánh | Tên nhánh (vi) | Tên nhánh (en) | Mô tả ngắn (vi) | Mô tả ngắn (en) | Thứ tự | Hiện ở câu 1 (Y/N) | Chủ đề ID (tuỳ chọn)`
- `Gói nhãn`: `Mã nhánh | Mã gói | Vấn đề — đáp án câu 2 (vi) | Vấn đề — đáp án câu 2 (en) | Mong muốn — đáp án câu 3 (vi) | Mong muốn — đáp án câu 3 (en) | Nhãn chi tiết (vi) | Mã nhãn chi tiết | Thứ tự`
- `Mapping Khoá học`: `Course ID (tuỳ chọn) | Khoá học | Nhánh nội dung | Trạng thái (tham khảo) | Mã nhãn vấn đề | Mã gói mong muốn`
Alias chấp nhận thêm: header không hậu tố `(vi)` (= vi); `Nhánh` (tên nhánh, khi sheet gốc chưa có `Mã nhánh`) → tra `Tên nhánh (vi)` trong sheet `Nhánh` hoặc `existingBranches`; `Mã nhãn mong muốn` (= `Mã gói mong muốn`); `Nhãn chi tiết` (= vi). Cột `(zh)/(ja)/(ko)` tuỳ chọn cùng quy tắc.

- [ ] **Step 1: Spec thất bại cho parser** (dựng workbook thật bằng ExcelJS trong test — vì thế phải `import * as ExcelJS`)

```ts
// src/modules/onboarding-taxonomy/onboarding-taxonomy-excel.spec.ts
import * as ExcelJS from 'exceljs';

import { buildTaxonomyWorkbook, parseTaxonomyWorkbook } from './onboarding-taxonomy-excel';

function sheet(wb: ExcelJS.Workbook, name: string, rows: any[][]) {
  const ws = wb.addWorksheet(name);
  rows.forEach(r => ws.addRow(r));
}

describe('parseTaxonomyWorkbook', () => {
  it('parses the three sheets of the template into a tree + course rows', () => {
    const wb = new ExcelJS.Workbook();
    sheet(wb, 'Nhánh', [
      ['Mã nhánh', 'Tên nhánh (vi)', 'Tên nhánh (en)', 'Mô tả ngắn (vi)', 'Mô tả ngắn (en)', 'Thứ tự', 'Hiện ở câu 1 (Y/N)', 'Category ID (tuỳ chọn)'],
      ['CX', 'Cảm xúc & tinh thần', 'Emotions', 'sub vi', 'sub en', 1, 'Y', ''],
      ['KP', 'Khám phá não bộ', '', '', '', 6, 'N', '64abc'],
    ]);
    sheet(wb, 'Gói nhãn', [
      ['Mã nhánh', 'Mã gói', 'Vấn đề — đáp án câu 2 (vi)', 'Vấn đề — đáp án câu 2 (en)', 'Mong muốn — đáp án câu 3 (vi)', 'Mong muốn — đáp án câu 3 (en)', 'Nhãn chi tiết (vi)', 'Mã nhãn chi tiết', 'Thứ tự'],
      ['CX', 'CX-1', 'Dễ căng thẳng', 'Stressed', 'Thả lỏng được trong ngày', 'Relax', 'A | B', 'CX01 | CX02', 1],
    ]);
    sheet(wb, 'Mapping Khoá học', [
      ['Course ID (tuỳ chọn)', 'Khoá học', 'Nhánh nội dung', 'Trạng thái (tham khảo)', 'Mã nhãn vấn đề', 'Mã gói mong muốn'],
      ['', 'Nội cảm thụ', 'CX', 'published', 'CX01 | CX02', 'CX-1'],
      ['64def', 'Khoá có id', 'KP', 'published', '', 'CX-1'],
    ]);

    const { tree, courseRows, errors } = parseTaxonomyWorkbook(wb, []);

    expect(errors).toEqual([]);
    expect(tree.branches.map(b => [b.code, b.isSelectable, b.categoryId])).toEqual([['CX', true, null], ['KP', false, '64abc']]);
    expect(tree.packages).toEqual([
      expect.objectContaining({ code: 'CX-1', branchCode: 'CX', problemLabel: { vi: 'Dễ căng thẳng', en: 'Stressed' }, desireLabel: { vi: 'Thả lỏng được trong ngày', en: 'Relax' }, order: 1 }),
    ]);
    expect(tree.labels).toEqual([
      expect.objectContaining({ code: 'CX01', packageCode: 'CX-1', label: { vi: 'A' }, order: 1 }),
      expect.objectContaining({ code: 'CX02', packageCode: 'CX-1', label: { vi: 'B' }, order: 2 }),
    ]);
    expect(courseRows).toEqual([
      { rowNumber: 2, courseId: '', title: 'Nội cảm thụ', labelCodes: ['CX01', 'CX02'], desireCodes: ['CX-1'] },
      { rowNumber: 3, courseId: '64def', title: 'Khoá có id', labelCodes: [], desireCodes: ['CX-1'] },
    ]);
  });

  it('accepts the BA sheet layout: tab "Nhãn" with branch NAME and no (vi) suffix, branches reused from DB', () => {
    const wb = new ExcelJS.Workbook();
    sheet(wb, 'Nhãn', [
      ['Nhánh', 'Mã gói', 'Vấn đề — đáp án câu 2', 'Mong muốn — đáp án câu 3', 'Số nhãn chi tiết', 'Nhãn chi tiết', 'Mã nhãn chi tiết'],
      ['Cảm xúc & tinh thần', 'CX-2', 'Suy nghĩ nhiều', 'Đầu óc yên hơn', 2, 'X | Y', 'CX06 | CX07'],
    ]);
    const existing = [{ code: 'CX', label: { vi: 'Cảm xúc & tinh thần' }, subtitle: {}, iconUrl: '', imageUrl: '', order: 1, isSelectable: true, categoryId: null, isActive: true }];

    const { tree, errors } = parseTaxonomyWorkbook(wb, existing);

    expect(errors).toEqual([]);
    expect(tree.branches).toEqual(existing);
    expect(tree.packages[0]).toEqual(expect.objectContaining({ code: 'CX-2', branchCode: 'CX', problemLabel: { vi: 'Suy nghĩ nhiều' } }));
    expect(tree.labels.map(l => l.code)).toEqual(['CX06', 'CX07']);
  });

  it('reports mismatched label/code counts, unknown codes in the mapping sheet and a missing package sheet', () => {
    const wb = new ExcelJS.Workbook();
    sheet(wb, 'Gói nhãn', [
      ['Mã nhánh', 'Mã gói', 'Vấn đề — đáp án câu 2 (vi)', 'Mong muốn — đáp án câu 3 (vi)', 'Nhãn chi tiết (vi)', 'Mã nhãn chi tiết'],
      ['CX', 'CX-1', 'p', 'd', 'A | B', 'CX01'],
    ]);
    sheet(wb, 'Mapping Khoá học', [
      ['Course ID (tuỳ chọn)', 'Khoá học', 'Mã nhãn vấn đề', 'Mã gói mong muốn'],
      ['', 'K', 'ZZ99', 'CX-7'],
    ]);
    const { errors } = parseTaxonomyWorkbook(wb, []);
    expect(errors.map(e => e.message)).toEqual(expect.arrayContaining([
      expect.stringContaining('số nhãn'),
      expect.stringContaining('ZZ99'),
      expect.stringContaining('CX-7'),
    ]));

    const empty = parseTaxonomyWorkbook(new ExcelJS.Workbook(), []);
    expect(empty.errors[0].message).toContain('Gói nhãn');
  });
});

describe('buildTaxonomyWorkbook', () => {
  it('writes the three sheets with the template headers and joins lists with " | "', () => {
    const wb = buildTaxonomyWorkbook(
      {
        branches: [{ code: 'CX', label: { vi: 'Cảm xúc', en: 'Emo' }, subtitle: { vi: 's' }, iconUrl: '', imageUrl: '', order: 1, isSelectable: true, categoryId: null, isActive: true }],
        packages: [{ code: 'CX-1', branchCode: 'CX', problemLabel: { vi: 'p' }, desireLabel: { vi: 'd' }, order: 1, isActive: true }],
        labels: [{ code: 'CX01', packageCode: 'CX-1', label: { vi: 'A' }, order: 1 }, { code: 'CX02', packageCode: 'CX-1', label: { vi: 'B' }, order: 2 }],
      },
      [{ _id: 'id1', titleVi: 'Khoá', branchCode: 'CX', status: 'published', labelCodes: ['CX01'], desireCodes: ['CX-1'] }],
    );
    expect(wb.worksheets.map(w => w.name)).toEqual(['Hướng dẫn', 'Nhánh', 'Gói nhãn', 'Mapping Khoá học']);
    const pkg = wb.getWorksheet('Gói nhãn')!;
    expect(pkg.getRow(1).getCell(1).value).toBe('Mã nhánh');
    expect(pkg.getRow(2).getCell(7).value).toBe('A | B');
    expect(pkg.getRow(2).getCell(8).value).toBe('CX01 | CX02');
    const map = wb.getWorksheet('Mapping Khoá học')!;
    expect(map.getRow(2).getCell(1).value).toBe('id1');
  });
});
```

- [ ] **Step 2: Chạy → FAIL** (`npm test -- src/modules/onboarding-taxonomy/onboarding-taxonomy-excel.spec.ts`).

- [ ] **Step 3: Parser + builder**

```ts
// src/modules/onboarding-taxonomy/onboarding-taxonomy-excel.ts
import * as ExcelJS from 'exceljs';

import {
  getRows, getSheet, ImportRow, ImportValidationError, numberValue, splitList, text,
} from 'src/modules/courses/src/modules/import/excel-import.util';

import {
  IOnboardingBranch, IOnboardingLabel, IOnboardingPackage, IOnboardingTaxonomyTree,
} from './interface/onboarding-taxonomy.interface';

export const SHEET_GUIDE = 'Hướng dẫn';
export const SHEET_BRANCH = 'Nhánh';
export const SHEET_PACKAGE = ['Gói nhãn', 'Nhãn'];
export const SHEET_MAPPING = ['Mapping Khoá học', 'Mapping Khoa hoc'];

const LANGS = ['vi', 'en', 'zh', 'ja', 'ko'] as const;

export const BRANCH_HEADERS = ['Mã nhánh', 'Tên nhánh (vi)', 'Tên nhánh (en)', 'Mô tả ngắn (vi)', 'Mô tả ngắn (en)', 'Thứ tự', 'Hiện ở câu 1 (Y/N)', 'Category ID (tuỳ chọn)'];
export const PACKAGE_HEADERS = ['Mã nhánh', 'Mã gói', 'Vấn đề — đáp án câu 2 (vi)', 'Vấn đề — đáp án câu 2 (en)', 'Mong muốn — đáp án câu 3 (vi)', 'Mong muốn — đáp án câu 3 (en)', 'Nhãn chi tiết (vi)', 'Mã nhãn chi tiết', 'Thứ tự'];
export const MAPPING_HEADERS = ['Course ID (tuỳ chọn)', 'Khoá học', 'Nhánh nội dung', 'Trạng thái (tham khảo)', 'Mã nhãn vấn đề', 'Mã gói mong muốn'];

export interface ParsedCourseRow {
  rowNumber: number;
  courseId: string;
  title: string;
  labelCodes: string[];
  desireCodes: string[];
}

export interface ParsedTaxonomyWorkbook {
  tree: IOnboardingTaxonomyTree;
  courseRows: ParsedCourseRow[];
  errors: ImportValidationError[];
}

/** Đọc ô theo danh sách header chấp nhận (header đầu tiên có mặt thắng). */
function pick(row: ImportRow, headers: string[]): any {
  for (const h of headers) {
    if (row.values[h] !== undefined && row.values[h] !== null && row.values[h] !== '') return row.values[h];
  }
  return undefined;
}

/** `Base (vi)`/`Base (en)`/… + `Base` trần = vi. Bỏ ngôn ngữ rỗng; {} khi không có gì. */
function translationOf(row: ImportRow, base: string): Record<string, string> {
  const out: Record<string, string> = {};
  for (const lang of LANGS) {
    const value = text(pick(row, lang === 'vi' ? [`${base} (vi)`, base] : [`${base} (${lang})`]));
    if (value) out[lang] = value;
  }
  return out;
}

const up = (v: any) => text(v).toUpperCase();
const upList = (v: any) => splitList(v).map(s => s.toUpperCase());

/**
 * Workbook → cây + dòng khoá + lỗi theo dòng. Thuần: không chạm DB; người gọi
 * đưa `existingBranches` để sheet "Nhãn" gốc (chỉ có TÊN nhánh, không có sheet
 * "Nhánh") vẫn import được.
 */
export function parseTaxonomyWorkbook(
  workbook: ExcelJS.Workbook,
  existingBranches: IOnboardingBranch[],
): ParsedTaxonomyWorkbook {
  const errors: ImportValidationError[] = [];

  // ---- Nhánh (tuỳ chọn) ----
  const branchSheet = getSheet(workbook, [SHEET_BRANCH]);
  let branches: IOnboardingBranch[];
  if (branchSheet) {
    branches = getRows(branchSheet).map((row, i) => ({
      code: up(pick(row, ['Mã nhánh'])),
      label: translationOf(row, 'Tên nhánh'),
      subtitle: translationOf(row, 'Mô tả ngắn'),
      iconUrl: text(pick(row, ['Icon URL'])),
      imageUrl: text(pick(row, ['Ảnh URL'])),
      order: numberValue(pick(row, ['Thứ tự'])) ?? i + 1,
      isSelectable: text(pick(row, ['Hiện ở câu 1 (Y/N)', 'Hiện ở câu 1'])).toUpperCase() !== 'N',
      categoryId: text(pick(row, ['Category ID (tuỳ chọn)', 'Category ID'])) || null,
      isActive: true,
    }));
    branches.forEach((b, i) => {
      if (!b.code) errors.push({ sheet: SHEET_BRANCH, row: i + 2, column: 'Mã nhánh', message: 'thiếu mã nhánh' });
    });
  } else {
    branches = existingBranches;
  }
  const branchByName = new Map(branches.map(b => [norm(b.label?.vi ?? ''), b.code]));
  const branchCodes = new Set(branches.map(b => b.code));

  // ---- Gói nhãn (bắt buộc) ----
  const packageSheet = getSheet(workbook, SHEET_PACKAGE);
  const packages: IOnboardingPackage[] = [];
  const labels: IOnboardingLabel[] = [];
  if (!packageSheet) {
    errors.push({ sheet: SHEET_PACKAGE[0], row: 1, message: `thiếu sheet "${SHEET_PACKAGE[0]}"` });
  } else {
    const sheetName = packageSheet.name;
    const orderByBranch = new Map<string, number>();
    for (const row of getRows(packageSheet)) {
      let branchCode = up(pick(row, ['Mã nhánh']));
      if (!branchCode) {
        const name = text(pick(row, ['Nhánh']));
        branchCode = branchByName.get(norm(name)) ?? '';
        if (!branchCode) {
          errors.push({ sheet: sheetName, row: row.rowNumber, column: 'Nhánh', message: `không tìm thấy nhánh "${name}"` });
          continue;
        }
      } else if (!branchCodes.has(branchCode)) {
        errors.push({ sheet: sheetName, row: row.rowNumber, column: 'Mã nhánh', message: `nhánh ${branchCode} không có trong sheet "${SHEET_BRANCH}"` });
      }
      const code = up(pick(row, ['Mã gói']));
      if (!code) {
        errors.push({ sheet: sheetName, row: row.rowNumber, column: 'Mã gói', message: 'thiếu mã gói' });
        continue;
      }
      const labelTexts = splitList(pick(row, ['Nhãn chi tiết (vi)', 'Nhãn chi tiết']));
      const labelCodes = upList(pick(row, ['Mã nhãn chi tiết']));
      if (labelTexts.length !== labelCodes.length) {
        errors.push({ sheet: sheetName, row: row.rowNumber, column: 'Mã nhãn chi tiết', message: `số nhãn (${labelTexts.length}) khác số mã (${labelCodes.length})` });
      }
      const nextOrder = (orderByBranch.get(branchCode) ?? 0) + 1;
      orderByBranch.set(branchCode, nextOrder);
      packages.push({
        code, branchCode,
        problemLabel: translationOf(row, 'Vấn đề — đáp án câu 2'),
        desireLabel: translationOf(row, 'Mong muốn — đáp án câu 3'),
        order: numberValue(pick(row, ['Thứ tự'])) ?? nextOrder,
        isActive: true,
      });
      labelCodes.forEach((labelCode, i) => {
        labels.push({ code: labelCode, packageCode: code, label: { vi: labelTexts[i] ?? '' }, order: i + 1 });
      });
    }
  }
  const knownLabels = new Set(labels.map(l => l.code));
  const knownPackages = new Set(packages.map(p => p.code));

  // ---- Mapping Khoá học (tuỳ chọn) ----
  const courseRows: ParsedCourseRow[] = [];
  const mappingSheet = getSheet(workbook, SHEET_MAPPING);
  if (mappingSheet) {
    for (const row of getRows(mappingSheet)) {
      const labelCodes = upList(pick(row, ['Mã nhãn vấn đề']));
      const desireCodes = upList(pick(row, ['Mã gói mong muốn', 'Mã nhãn mong muốn']));
      for (const c of labelCodes) {
        if (!knownLabels.has(c)) errors.push({ sheet: mappingSheet.name, row: row.rowNumber, column: 'Mã nhãn vấn đề', message: `mã nhãn ${c} không có trong taxonomy` });
      }
      for (const c of desireCodes) {
        if (!knownPackages.has(c)) errors.push({ sheet: mappingSheet.name, row: row.rowNumber, column: 'Mã gói mong muốn', message: `mã gói ${c} không có trong taxonomy` });
      }
      courseRows.push({
        rowNumber: row.rowNumber,
        courseId: text(pick(row, ['Course ID (tuỳ chọn)', 'Course ID', 'id'])),
        title: text(pick(row, ['Khoá học'])),
        labelCodes, desireCodes,
      });
    }
  }

  return { tree: { branches, packages, labels }, courseRows, errors };
}

/** So tên nhánh: bỏ hoa/thường + gộp khoảng trắng (không bỏ dấu, tên là tiếng Việt có dấu). */
export function norm(s: string): string {
  return s.trim().replace(/\s+/g, ' ').toLowerCase();
}

export interface ExportCourseRow {
  _id: string;
  titleVi: string;
  branchCode: string;
  status: string;
  labelCodes: string[];
  desireCodes: string[];
}

/** Export == template: cùng builder; dữ liệu rỗng thì chỉ còn header + hướng dẫn. */
export function buildTaxonomyWorkbook(tree: IOnboardingTaxonomyTree, courses: ExportCourseRow[]): ExcelJS.Workbook {
  const wb = new ExcelJS.Workbook();
  const guide = wb.addWorksheet(SHEET_GUIDE);
  [
    ['File import Onboarding taxonomy (nhánh → gói → nhãn chi tiết → khoá học)'],
    [''],
    ['Tab', 'Import đọc gì', 'Ghi chú'],
    [SHEET_BRANCH, BRANCH_HEADERS.join(' | '), 'Mã nhánh in hoa (CX, LV…). "N" ở "Hiện ở câu 1" = chỉ dùng để gắn khoá.'],
    [SHEET_PACKAGE[0], PACKAGE_HEADERS.join(' | '), '1 gói = 1 vấn đề = 1 mong muốn. Nhãn và mã nhãn ngăn bằng |, số phần tử bằng nhau, mã duy nhất toàn file.'],
    [SHEET_MAPPING[0], MAPPING_HEADERS.join(' | '), 'Có Course ID thì khớp theo ID, trống thì khớp tiêu đề tiếng Việt. Khoá không tìm thấy → cảnh báo, bỏ qua dòng.'],
    [''],
    ['Import THAY TOÀN BỘ taxonomy và cập nhật nhãn cho khoá có trong tab Mapping; khoá không có trong tab giữ nguyên.'],
    ['Cột ngôn ngữ (en/zh/ja/ko) để trống thì app dùng bản tiếng Việt.'],
  ].forEach(r => guide.addRow(r));

  const bs = wb.addWorksheet(SHEET_BRANCH);
  bs.addRow(BRANCH_HEADERS);
  for (const b of [...tree.branches].sort((a, z) => a.order - z.order)) {
    bs.addRow([b.code, b.label?.vi ?? '', b.label?.en ?? '', b.subtitle?.vi ?? '', b.subtitle?.en ?? '', b.order, b.isSelectable ? 'Y' : 'N', b.categoryId ?? '']);
  }

  const ps = wb.addWorksheet(SHEET_PACKAGE[0]);
  ps.addRow(PACKAGE_HEADERS);
  const labelsByPackage = new Map<string, IOnboardingLabel[]>();
  for (const l of tree.labels) {
    const list = labelsByPackage.get(l.packageCode) ?? [];
    list.push(l);
    labelsByPackage.set(l.packageCode, list);
  }
  for (const p of [...tree.packages].sort((a, z) => a.branchCode.localeCompare(z.branchCode) || a.order - z.order)) {
    const ls = (labelsByPackage.get(p.code) ?? []).sort((a, z) => a.order - z.order);
    ps.addRow([p.branchCode, p.code, p.problemLabel?.vi ?? '', p.problemLabel?.en ?? '', p.desireLabel?.vi ?? '', p.desireLabel?.en ?? '', ls.map(l => l.label?.vi ?? '').join(' | '), ls.map(l => l.code).join(' | '), p.order]);
  }

  const ms = wb.addWorksheet(SHEET_MAPPING[0]);
  ms.addRow(MAPPING_HEADERS);
  for (const c of courses) {
    ms.addRow([c._id, c.titleVi, c.branchCode, c.status, c.labelCodes.join(' | '), c.desireCodes.join(' | ')]);
  }
  return wb;
}
```

- [ ] **Step 4: Chạy spec → PASS.** Chỉnh số cột/header theo spec nếu lệch.

- [ ] **Step 5: Import service**

```ts
// src/modules/onboarding-taxonomy/onboarding-taxonomy-import.service.ts
import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import * as ExcelJS from 'exceljs';

import { CourseRepository } from 'src/modules/courses/src/modules/course/repository/course.repository';
import {
  ImportValidationError, readWorkbook, setCellByHeader, workbookToBuffer,
} from 'src/modules/courses/src/modules/import/excel-import.util';

import {
  buildTaxonomyWorkbook, ExportCourseRow, parseTaxonomyWorkbook, SHEET_MAPPING,
} from './onboarding-taxonomy-excel';
import { OnboardingTaxonomyService } from './onboarding-taxonomy.service';
import { OnboardingBranchRepository } from './repository/onboarding-branch.repository';

const WARNING_SHEET = 'import_warnings';

@Injectable()
export class OnboardingTaxonomyImportService {
  private readonly logger = new Logger(OnboardingTaxonomyImportService.name);

  constructor(
    private readonly taxonomyService: OnboardingTaxonomyService,
    private readonly branchRepository: OnboardingBranchRepository,
    private readonly courseRepository: CourseRepository,
  ) {}

  /**
   * Hai pha, theo khuôn `keypoint.service.importKeypoints`: validate hết rồi
   * mới ghi. Lỗi taxonomy/mã lạ → 400 huỷ cả file; khoá không tìm thấy → cảnh
   * báo, bỏ dòng, ghi vào sheet `import_warnings`, các dòng khác vẫn ghi.
   * Trả lại chính workbook với cột Course ID đã điền cho dòng khớp theo tiêu đề.
   */
  async import(file: Express.Multer.File): Promise<{ buffer: Buffer; warnings: number }> {
    const workbook = await readWorkbook(file);
    const existing = await this.branchRepository.findAll(false);
    const { tree, courseRows, errors } = parseTaxonomyWorkbook(workbook, existing);
    if (errors.length) {
      throw new BadRequestException({ message: 'Excel import validation failed', errors });
    }

    // Pha 1b: tìm khoá trước khi ghi gì — để lỗi hạ tầng không để lại nửa taxonomy.
    const resolved: { row: typeof courseRows[number]; courseId: string }[] = [];
    const warnings: ImportValidationError[] = [];
    for (const row of courseRows) {
      const courseId = row.courseId || (await this.courseRepository.findIdByViTitle(row.title));
      if (!courseId) {
        warnings.push({ sheet: SHEET_MAPPING[0], row: row.rowNumber, column: 'Khoá học', message: `không tìm thấy khoá "${row.title}" — bỏ qua dòng` });
        continue;
      }
      if (row.courseId && !(await this.courseRepository.findById(row.courseId))) {
        warnings.push({ sheet: SHEET_MAPPING[0], row: row.rowNumber, column: 'Course ID (tuỳ chọn)', message: `Course ID ${row.courseId} không tồn tại — bỏ qua dòng` });
        continue;
      }
      resolved.push({ row, courseId });
    }

    // Pha 2: ghi.
    await this.taxonomyService.replace(tree);
    const mappingSheet = workbook.getWorksheet(SHEET_MAPPING[0]) ?? workbook.getWorksheet(SHEET_MAPPING[1]);
    for (const { row, courseId } of resolved) {
      await this.courseRepository.updateOnboardingTags(courseId, {
        onboardingLabelCodes: row.labelCodes,
        onboardingDesireCodes: row.desireCodes,
      });
      if (mappingSheet && !row.courseId) {
        setCellByHeader(mappingSheet, row.rowNumber, 'Course ID (tuỳ chọn)', courseId);
      }
    }

    if (warnings.length) {
      const sheet = workbook.addWorksheet(WARNING_SHEET);
      sheet.addRow(['sheet', 'row', 'column', 'message']);
      for (const w of warnings) sheet.addRow([w.sheet, w.row, w.column ?? '', w.message]);
    }
    this.logger.log(`Onboarding taxonomy imported: ${tree.packages.length} packages, ${resolved.length} courses tagged, ${warnings.length} warnings`);
    return { buffer: await workbookToBuffer(workbook), warnings: warnings.length };
  }

  async export(): Promise<Buffer> {
    const tree = await this.taxonomyService.getAdmin();
    const courses = await this.courseRepository.findAllForExport();
    const branchOfPackage = new Map(tree.packages.map(p => [p.code, p.branchCode]));
    const rows: ExportCourseRow[] = courses.map((c: any) => ({
      _id: String(c._id),
      titleVi: c.title?.vi ?? c.title?.en ?? '',
      branchCode: branchOfPackage.get((c.onboardingDesireCodes ?? [])[0]) ?? '',
      status: c.status ?? '',
      labelCodes: c.onboardingLabelCodes ?? [],
      desireCodes: c.onboardingDesireCodes ?? [],
    }));
    return workbookToBuffer(buildTaxonomyWorkbook(tree, rows));
  }

  /** Mẫu = export hiện tại; DB trống thì thêm 1 dòng ví dụ mỗi sheet. */
  async template(): Promise<Buffer> {
    const tree = await this.taxonomyService.getAdmin();
    if (tree.packages.length) return this.export();
    const wb: ExcelJS.Workbook = buildTaxonomyWorkbook(
      {
        branches: [{ code: 'CX', label: { vi: 'Cảm xúc & tinh thần', en: 'Emotions & mind' }, subtitle: { vi: 'Hiểu cảm xúc để làm chủ cuộc sống' }, iconUrl: '', imageUrl: '', order: 1, isSelectable: true, categoryId: null, isActive: true }],
        packages: [{ code: 'CX-1', branchCode: 'CX', problemLabel: { vi: 'Dễ căng thẳng' }, desireLabel: { vi: 'Thả lỏng được trong ngày' }, order: 1, isActive: true }],
        labels: [{ code: 'CX01', packageCode: 'CX-1', label: { vi: 'Người lúc nào cũng căng cứng' }, order: 1 }],
      },
      [{ _id: '', titleVi: 'Nội cảm thụ: Lắng nghe tín hiệu cơ thể', branchCode: 'CX', status: 'published', labelCodes: ['CX01'], desireCodes: ['CX-1'] }],
    );
    return workbookToBuffer(wb);
  }
}
```
`findAllForExport()` đã có trên CourseRepository (trả `.lean()` toàn bộ course) — dùng lại.

- [ ] **Step 6: Controller thêm 3 route + module**

```ts
// onboarding-taxonomy.controller.ts — thêm import:
import { Get, Post, Res, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiConsumes } from '@nestjs/swagger';
import { Response } from 'express';
import { OnboardingTaxonomyImportService } from './onboarding-taxonomy-import.service';
// constructor thêm: private readonly importService: OnboardingTaxonomyImportService

@Get('template')
async template(@Res() res: Response) {
  this.sendExcel(res, await this.importService.template(), 'onboarding-taxonomy-template.xlsx');
}

@Get('export')
async export(@Res() res: Response) {
  this.sendExcel(res, await this.importService.export(), 'onboarding-taxonomy-export.xlsx');
}

@Post('import')
@ApiConsumes('multipart/form-data')
@UseInterceptors(FileInterceptor('file'))
async import(@UploadedFile() file: Express.Multer.File, @Res() res: Response) {
  const { buffer, warnings } = await this.importService.import(file);
  res.setHeader('X-Import-Warnings', String(warnings));
  res.setHeader('Access-Control-Expose-Headers', 'X-Import-Warnings, Content-Disposition');
  this.sendExcel(res, buffer, 'onboarding-taxonomy-import-result.xlsx');
}

private sendExcel(res: Response, buffer: Buffer, filename: string) {
  res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
  res.send(buffer);
}
```
Đặt `@Get('template')`/`@Get('export')` TRƯỚC `@Get('admin')` không quan trọng (không có `:param`), nhưng giữ sau `@Get('')`.
Module: `imports` thêm `forwardRef(() => CourseModule)` (`src/modules/courses/src/modules/course/course.module`); `providers` thêm `OnboardingTaxonomyImportService`.

- [ ] **Step 7: Build + thử tay + commit**

Run: `npm run build` → exit 0. (Nếu dev server đang chạy: `curl -sS -H "Authorization: Bearer $TOKEN" -o /tmp/t.xlsx -w '%{http_code}\n' http://localhost:4000/api/v1/onboarding-taxonomy/template` → 200 và file mở được.)
```bash
git add src/modules/onboarding-taxonomy/onboarding-taxonomy-excel.ts src/modules/onboarding-taxonomy/onboarding-taxonomy-excel.spec.ts src/modules/onboarding-taxonomy/onboarding-taxonomy-import.service.ts src/modules/onboarding-taxonomy/onboarding-taxonomy.controller.ts src/modules/onboarding-taxonomy/onboarding-taxonomy.module.ts
git commit -m "feat: import/export/mẫu Excel taxonomy onboarding, gắn nhãn khoá theo id hoặc tiêu đề" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: Ranker gợi ý khoá (thuần) + module onboarding-answer (schema, repo, DTO, service, controller)

**Files:**
- Create: `src/modules/onboarding-answer/onboarding-recommendation.ranker.ts`
- Create: `src/modules/onboarding-answer/onboarding-recommendation.ranker.spec.ts`
- Create: `src/modules/onboarding-answer/interface/onboarding-answer.interface.ts`
- Create: `src/modules/onboarding-answer/schema/onboarding-answer.schema.ts`
- Create: `src/modules/onboarding-answer/repository/onboarding-answer.repository.ts`
- Create: `src/modules/onboarding-answer/dto/save-onboarding-answer.dto.ts`
- Create: `src/modules/onboarding-answer/onboarding-answer.service.ts`
- Create: `src/modules/onboarding-answer/onboarding-answer.controller.ts`
- Create: `src/modules/onboarding-answer/onboarding-answer.module.ts`
- Modify: `src/modules/user/src/modules/auth/schema/user.schema.ts` (thêm `studyReminderTime` sau `timezone`)
- Modify: `src/modules/user/src/modules/auth/repository/user.repository.ts` (thêm `setStudyReminderTime`, `distinctStudyReminderTimes`)
- Modify: `src/app.module.ts` (thêm `OnboardingAnswerModule`)

**Interfaces — Consumes:** `CourseRepository.findOnboardingCandidates/findPublishedFallback`, `IOnboardingCourseCandidate` (Task 3); `OnboardingPackageRepository.findByCodes`, `OnboardingLabelRepository.findByPackageCodes` (Task 1); `viewerMarketsForRequest(headers)` từ `@utils/market-query.util`.
**Produces:**
```ts
rankCourses(candidates: IOnboardingCourseCandidate[], input: { packageCodes: string[]; desireCode: string | null; labelsByPackage: Map<string, string[]> }): RankedCourse[]
interface RankedCourse { course: IOnboardingCourseCandidate; matchReason: { desire: boolean; labelCodes: string[]; packageCodes: string[] } }
IOnboardingAnswer { userId; branchCodes; packageCodes; desireCode; reminderEnabled; reminderTime; recommendedCourseIds; chosenCourseId; ageKey; completedAt }
OnboardingAnswerService.save(dto): Promise<{ answers: IOnboardingAnswer; recommendations: IRecommendedCourse[] }>
OnboardingAnswerService.me(): Promise<{ answers: IOnboardingAnswer | null; recommendations: IRecommendedCourse[] }>
OnboardingAnswerRepository.findByUserIds(ids: string[]): Promise<IOnboardingAnswer[]>
UserRepository.setStudyReminderTime(userId: string, time: string | null): Promise<void>
UserRepository.distinctStudyReminderTimes(): Promise<string[]>
Routes: POST /api/v1/onboarding-answers · GET /api/v1/onboarding-answers/me (Auth)
```

- [ ] **Step 1: Spec thất bại cho ranker**

```ts
// src/modules/onboarding-answer/onboarding-recommendation.ranker.spec.ts
import { Types } from 'mongoose';

import { CourseStatus } from 'src/modules/courses/src/modules/course/enum/course.enum';
import { IOnboardingCourseCandidate } from 'src/modules/courses/src/modules/course/repository/course.repository';

import { rankCourses } from './onboarding-recommendation.ranker';

const course = (title: string, labels: string[], desires: string[], lessons = 5): IOnboardingCourseCandidate => ({
  _id: new Types.ObjectId(), title: { vi: title }, image: '', categoryId: 's', numberOfLesson: lessons,
  status: CourseStatus.PUBLISHED, createdAt: new Date('2026-01-01'),
  onboardingLabelCodes: labels, onboardingDesireCodes: desires,
});
const labelsByPackage = new Map([
  ['LV-1', ['TT01', 'TT02', 'TT03']],
  ['CX-2', ['CX06', 'CX07']],
]);

describe('rankCourses', () => {
  it('puts a course matching BOTH desire and a problem label first', () => {
    const both = course('both', ['TT01'], ['LV-1']);
    const problemOnly = course('problem', ['TT01', 'TT02'], []);
    const desireOnly = course('desire', [], ['LV-1']);
    const ranked = rankCourses([desireOnly, problemOnly, both], { packageCodes: ['LV-1'], desireCode: 'LV-1', labelsByPackage });
    expect(ranked.map(r => r.course.title.vi)).toEqual(['both', 'desire', 'problem']);
    expect(ranked[0].matchReason).toEqual({ desire: true, labelCodes: ['TT01'], packageCodes: ['LV-1'] });
  });

  it('prefers touching more selected packages, then more labels, then the earlier-picked package', () => {
    const twoPkgs = course('two', ['TT01', 'CX06'], []);
    const oneManyLabels = course('many', ['TT01', 'TT02', 'TT03'], []);
    const secondPkg = course('second', ['CX06'], []);
    const firstPkg = course('first', ['TT02'], []);
    const ranked = rankCourses([secondPkg, oneManyLabels, firstPkg, twoPkgs], { packageCodes: ['LV-1', 'CX-2'], desireCode: null, labelsByPackage });
    expect(ranked.map(r => r.course.title.vi)).toEqual(['two', 'many', 'first', 'second']);
  });

  it('drops courses matching nothing and ranks lesson-less courses last', () => {
    const empty = course('empty', ['TT01'], [], 0);
    const full = course('full', ['TT01'], [], 3);
    const none = course('none', ['QH01'], ['QH-1']);
    const ranked = rankCourses([empty, none, full], { packageCodes: ['LV-1'], desireCode: null, labelsByPackage });
    expect(ranked.map(r => r.course.title.vi)).toEqual(['full', 'empty']);
  });
});
```

- [ ] **Step 2: Chạy → FAIL** (`npm test -- src/modules/onboarding-answer/onboarding-recommendation.ranker.spec.ts`).

- [ ] **Step 3: Ranker**

```ts
// src/modules/onboarding-answer/onboarding-recommendation.ranker.ts
import { IOnboardingCourseCandidate } from 'src/modules/courses/src/modules/course/repository/course.repository';

export interface RecommendationInput {
  /** Gói đã chọn ở câu 2, theo thứ tự chọn. */
  packageCodes: string[];
  /** Mã gói đã chọn ở câu 3 (mong muốn), null nếu bỏ qua. */
  desireCode: string | null;
  /** Nhãn chi tiết của từng gói đã chọn. */
  labelsByPackage: Map<string, string[]>;
}

export interface MatchReason {
  desire: boolean;
  labelCodes: string[];
  packageCodes: string[];
}

export interface RankedCourse {
  course: IOnboardingCourseCandidate;
  matchReason: MatchReason;
}

interface Scored extends RankedCourse {
  /** 0 = khớp cả mong muốn + nhãn, 1 = chỉ mong muốn, 2 = chỉ nhãn vấn đề. */
  tier: number;
  packageHits: number;
  labelHits: number;
  earliestPackage: number;
  hasLessons: number;
  title: string;
}

/**
 * Luật §3.4 của design.md — ba TẦNG rồi mới so trong tầng: tầng 0 khớp cả
 * mong muốn và ≥1 nhãn, tầng 1 chỉ khớp mong muốn, tầng 2 chỉ khớp nhãn vấn
 * đề; trong tầng: số gói chạm được, số nhãn trùng, chạm gói chọn sớm hơn, có
 * bài học, tiêu đề. Thuần để test bảng xếp hạng không cần DB.
 */
export function rankCourses(
  candidates: IOnboardingCourseCandidate[],
  input: RecommendationInput,
): RankedCourse[] {
  const packageOfLabel = new Map<string, string>();
  for (const [pkg, labels] of input.labelsByPackage) {
    for (const label of labels) packageOfLabel.set(label, pkg);
  }
  const packageIndex = new Map(input.packageCodes.map((code, i) => [code, i]));

  const scored: Scored[] = [];
  for (const course of candidates) {
    const labelCodes = (course.onboardingLabelCodes ?? []).filter(code => packageOfLabel.has(code));
    const packageCodes = [...new Set(labelCodes.map(code => packageOfLabel.get(code) as string))]
      .sort((a, b) => (packageIndex.get(a) ?? 99) - (packageIndex.get(b) ?? 99));
    const desire = Boolean(input.desireCode) && (course.onboardingDesireCodes ?? []).includes(input.desireCode as string);
    if (!desire && !labelCodes.length) continue;

    scored.push({
      course,
      matchReason: { desire, labelCodes, packageCodes },
      tier: desire && labelCodes.length ? 0 : desire ? 1 : 2,
      packageHits: packageCodes.length,
      labelHits: labelCodes.length,
      earliestPackage: packageCodes.length ? (packageIndex.get(packageCodes[0]) ?? 99) : 99,
      hasLessons: (course.numberOfLesson ?? 0) > 0 ? 1 : 0,
      title: course.title?.vi ?? course.title?.en ?? '',
    });
  }

  scored.sort(
    (a, b) =>
      a.tier - b.tier ||
      b.packageHits - a.packageHits ||
      b.labelHits - a.labelHits ||
      a.earliestPackage - b.earliestPackage ||
      b.hasLessons - a.hasLessons ||
      a.title.localeCompare(b.title, 'vi'),
  );

  return scored.map(({ course, matchReason }) => ({ course, matchReason }));
}
```

- [ ] **Step 4: Chạy → PASS.**

- [ ] **Step 5: Interface + schema + repository cho answers; User thêm field**

```ts
// src/modules/onboarding-answer/interface/onboarding-answer.interface.ts
export interface IOnboardingAnswer {
  userId: string;
  branchCodes: string[];
  packageCodes: string[];
  desireCode: string | null;
  reminderEnabled: boolean;
  reminderTime: string | null;
  recommendedCourseIds: string[];
  chosenCourseId: string | null;
  ageKey: string | null;
  completedAt: Date | null;
}

export interface IRecommendedCourse {
  _id: string;
  title: Record<string, string>;
  description?: Record<string, string>;
  image: string;
  categoryId: string;
  numberOfLesson: number;
  status: string;
  matchReason: { desire: boolean; labelCodes: string[]; packageCodes: string[] };
}

export const REMINDER_TIME_REGEX = /^([01]\d|2[0-3]):(00|15|30|45)$/;
```

```ts
// src/modules/onboarding-answer/schema/onboarding-answer.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { IOnboardingAnswer } from '../interface/onboarding-answer.interface';

@Schema({ collection: 'onboarding_answers' })
export class OnboardingAnswer extends AbstractDocument implements IOnboardingAnswer {
  @Prop({ required: true, unique: true }) userId: string;
  @Prop({ type: [String], default: [] }) branchCodes: string[];
  @Prop({ type: [String], default: [] }) packageCodes: string[];
  @Prop({ type: String, default: null }) desireCode: string | null;
  @Prop({ default: false }) reminderEnabled: boolean;
  @Prop({ type: String, default: null }) reminderTime: string | null;
  @Prop({ type: [String], default: [] }) recommendedCourseIds: string[];
  @Prop({ type: String, default: null }) chosenCourseId: string | null;
  @Prop({ type: String, default: null }) ageKey: string | null;
  @Prop({ type: Date, default: null }) completedAt: Date | null;
}
export const OnboardingAnswerSchema = SchemaFactory.createForClass(OnboardingAnswer);
OnboardingAnswerSchema.index({ userId: 1 }, { unique: true });
```

```ts
// src/modules/onboarding-answer/repository/onboarding-answer.repository.ts
@Injectable()
export class OnboardingAnswerRepository extends AbstractRepository<OnboardingAnswer> {
  protected readonly logger = new Logger(OnboardingAnswerRepository.name);
  constructor(@InjectModel(OnboardingAnswer.name) model: Model<OnboardingAnswer>, @InjectConnection() connection: Connection) {
    super(model, connection);
  }

  async findByUserId(userId: string): Promise<IOnboardingAnswer | null> {
    return this.model.findOne({ userId }).lean();
  }

  async findByUserIds(userIds: string[]): Promise<IOnboardingAnswer[]> {
    if (!userIds.length) return [];
    return this.model.find({ userId: { $in: userIds } }).lean();
  }

  /** Upsert theo user, chỉ $set các field caller đưa (undefined bị bỏ). */
  async upsertByUserId(userId: string, patch: Partial<IOnboardingAnswer>): Promise<IOnboardingAnswer> {
    const $set: Record<string, unknown> = { updatedAt: new Date() };
    for (const [k, v] of Object.entries(patch)) if (v !== undefined) $set[k] = v;
    return this.model
      .findOneAndUpdate({ userId }, { $set, $setOnInsert: { userId, createdAt: new Date() } }, { upsert: true, new: true, setDefaultsOnInsert: true })
      .lean() as unknown as Promise<IOnboardingAnswer>;
  }
}
```

```ts
// user.schema.ts — sau `timezone`
/**
 * Giờ nhắc học user chọn ở onboarding (HH:mm, bước 15 phút, giờ ĐỊA PHƯƠNG theo
 * `timezone`). Null = không nhắc. Nằm trên users (không trong onboarding_answers)
 * để dispatcher lọc chung một query với push candidates.
 */
@Prop({ type: String, default: null })
studyReminderTime: string | null;
// ...cuối file, cạnh các index khác của UserSchema (nếu chưa có khai báo index thì thêm):
UserSchema.index({ studyReminderTime: 1 });
```
```ts
// user.repository.ts — thêm cạnh distinctPushCandidateTimezones
async setStudyReminderTime(userId: string, time: string | null): Promise<void> {
  await this.model.updateOne({ _id: userId }, { $set: { studyReminderTime: time } });
}

/** Các giờ HH:mm đang có người đặt (≤96 giá trị) — để dispatcher chỉ hỏi zone cho các giờ ấy. */
async distinctStudyReminderTimes(): Promise<string[]> {
  const values = await this.model.distinct('studyReminderTime', {
    studyReminderTime: { $exists: true, $nin: [null, ''] },
    status: UserStatus.ACTIVE,
  });
  return (values as unknown as string[]).filter(Boolean);
}
```

- [ ] **Step 6: DTO + service + controller + module**

```ts
// src/modules/onboarding-answer/dto/save-onboarding-answer.dto.ts
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsBoolean, IsOptional, IsString, Matches, ValidateIf } from 'class-validator';

export class SaveOnboardingAnswerDto {
  @ApiPropertyOptional({ type: [String], example: ['LV', 'CX'] }) @IsOptional() @IsArray() @IsString({ each: true }) branchCodes?: string[];
  @ApiPropertyOptional({ type: [String], example: ['LV-1', 'CX-2'] }) @IsOptional() @IsArray() @IsString({ each: true }) packageCodes?: string[];
  @ApiPropertyOptional({ example: 'LV-1', nullable: true }) @IsOptional() @ValidateIf(o => o.desireCode !== null) @IsString() desireCode?: string | null;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() reminderEnabled?: boolean;
  @ApiPropertyOptional({ example: '21:00', nullable: true }) @IsOptional() @ValidateIf(o => o.reminderTime !== null) @Matches(/^([01]\d|2[0-3]):(00|15|30|45)$/) reminderTime?: string | null;
  @ApiPropertyOptional({ nullable: true }) @IsOptional() @ValidateIf(o => o.chosenCourseId !== null) @IsString() chosenCourseId?: string | null;
  @ApiPropertyOptional({ example: '25_34', nullable: true }) @IsOptional() @ValidateIf(o => o.ageKey !== null) @IsString() ageKey?: string | null;
  @ApiPropertyOptional({ description: 'true khi user bấm xong màn kết quả' }) @IsOptional() @IsBoolean() completed?: boolean;
}
```

```ts
// src/modules/onboarding-answer/onboarding-answer.service.ts
import { Injectable, UnauthorizedException } from '@nestjs/common';

import { RequestService } from '@base/service/request.service';
import { viewerMarketsForRequest } from '@utils/market-query.util';
import { CourseRepository, IOnboardingCourseCandidate } from 'src/modules/courses/src/modules/course/repository/course.repository';
import { OnboardingLabelRepository } from 'src/modules/onboarding-taxonomy/repository/onboarding-label.repository';
import { OnboardingPackageRepository } from 'src/modules/onboarding-taxonomy/repository/onboarding-package.repository';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import { SaveOnboardingAnswerDto } from './dto/save-onboarding-answer.dto';
import { IOnboardingAnswer, IRecommendedCourse } from './interface/onboarding-answer.interface';
import { rankCourses } from './onboarding-recommendation.ranker';
import { OnboardingAnswerRepository } from './repository/onboarding-answer.repository';

const RECOMMENDATION_COUNT = 3;

@Injectable()
export class OnboardingAnswerService {
  constructor(
    private readonly answerRepository: OnboardingAnswerRepository,
    private readonly packageRepository: OnboardingPackageRepository,
    private readonly labelRepository: OnboardingLabelRepository,
    private readonly courseRepository: CourseRepository,
    private readonly userRepository: UserRepository,
    private readonly requestService: RequestService,
  ) {}

  private get userId(): string {
    // `id`, KHÔNG phải `_id`: AuthGuard gán thẳng payload JWT vào req.user và
    // token ký `id: String(user._id)` (auth.service.ts). `IUser extends IUserMeta`
    // khai `_id` nên tsc không bắt được — đọc `_id` là 401 mọi lúc.
    const id = this.requestService.user?.id;
    if (!id) throw new UnauthorizedException();
    return String(id);
  }

  /** Upsert phần dto gửi, đồng bộ giờ nhắc lên users, rồi tính lại gợi ý từ answers đã merge. */
  async save(dto: SaveOnboardingAnswerDto) {
    const userId = this.userId;
    const up = (codes?: string[]) => codes?.map(c => c.trim().toUpperCase()).filter(Boolean);
    const patch: Partial<IOnboardingAnswer> = {
      branchCodes: up(dto.branchCodes),
      packageCodes: up(dto.packageCodes),
      desireCode: dto.desireCode === undefined ? undefined : dto.desireCode ? dto.desireCode.toUpperCase() : null,
      reminderEnabled: dto.reminderEnabled,
      reminderTime: dto.reminderTime,
      chosenCourseId: dto.chosenCourseId,
      ageKey: dto.ageKey,
      completedAt: dto.completed ? new Date() : undefined,
    };
    if (dto.reminderEnabled === false) patch.reminderTime = null;

    let answers = await this.answerRepository.upsertByUserId(userId, patch);

    if (dto.reminderEnabled !== undefined || dto.reminderTime !== undefined) {
      const time = answers.reminderEnabled ? answers.reminderTime : null;
      await this.userRepository.setStudyReminderTime(userId, time);
    }

    const recommendations = await this.recommend(answers);
    const ids = recommendations.map(r => r._id);
    if (ids.join(',') !== (answers.recommendedCourseIds ?? []).join(',')) {
      answers = await this.answerRepository.upsertByUserId(userId, { recommendedCourseIds: ids });
    }
    return { answers, recommendations };
  }

  async me() {
    const answers = await this.answerRepository.findByUserId(this.userId);
    if (!answers) return { answers: null, recommendations: [] as IRecommendedCourse[] };
    return { answers, recommendations: await this.recommend(answers) };
  }

  /** §3.4 design.md: ứng viên → rankCourses → bù đủ 3. */
  private async recommend(answers: IOnboardingAnswer): Promise<IRecommendedCourse[]> {
    const viewerMarkets = viewerMarketsForRequest(this.requestService.headers);
    const packageCodes = answers.packageCodes ?? [];
    const labels = await this.labelRepository.findByPackageCodes(packageCodes);
    const labelsByPackage = new Map<string, string[]>();
    for (const l of labels) labelsByPackage.set(l.packageCode, [...(labelsByPackage.get(l.packageCode) ?? []), l.code]);

    const candidates = await this.courseRepository.findOnboardingCandidates({
      labelCodes: labels.map(l => l.code),
      desireCode: answers.desireCode,
      viewerMarkets,
    });
    const ranked = rankCourses(candidates, { packageCodes, desireCode: answers.desireCode, labelsByPackage }).slice(0, RECOMMENDATION_COUNT);

    if (ranked.length < RECOMMENDATION_COUNT) {
      const packages = await this.packageRepository.findByCodes(packageCodes);
      const branchCodes = new Set([...(answers.branchCodes ?? []), ...packages.map(p => p.branchCode)]);
      const allPackages = await this.packageRepository.findAll(true);
      const desireCodes = allPackages.filter(p => branchCodes.has(p.branchCode)).map(p => p.code);
      const fill = await this.courseRepository.findPublishedFallback({
        excludeIds: ranked.map(r => String(r.course._id)),
        desireCodes,
        limit: RECOMMENDATION_COUNT - ranked.length,
        viewerMarkets,
      });
      for (const course of fill) ranked.push({ course, matchReason: { desire: false, labelCodes: [], packageCodes: [] } });
    }

    return ranked.map(({ course, matchReason }) => toRecommended(course, matchReason));
  }
}

function toRecommended(c: IOnboardingCourseCandidate, matchReason: IRecommendedCourse['matchReason']): IRecommendedCourse {
  return {
    _id: String(c._id), title: c.title, description: c.description, image: c.image,
    categoryId: c.categoryId, numberOfLesson: c.numberOfLesson ?? 0, status: c.status, matchReason,
  };
}
```

```ts
// src/modules/onboarding-answer/onboarding-answer.controller.ts
@ApiTags('ONBOARDING-ANSWERS')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'onboarding-answers', version: '1' })
export class OnboardingAnswerController {
  constructor(private readonly svc: OnboardingAnswerService) {}

  @Post('')
  save(@Body() dto: SaveOnboardingAnswerDto) {
    return this.svc.save(dto);
  }

  @Get('me')
  me() {
    return this.svc.me();
  }
}
```

```ts
// src/modules/onboarding-answer/onboarding-answer.module.ts
@Module({
  imports: [
    MongooseModule.forFeature([{ name: OnboardingAnswer.name, schema: OnboardingAnswerSchema }]),
    forwardRef(() => AuthModule),
    forwardRef(() => CourseModule),
    OnboardingTaxonomyModule,
  ],
  controllers: [OnboardingAnswerController],
  providers: [OnboardingAnswerRepository, OnboardingAnswerService],
  exports: [OnboardingAnswerRepository, OnboardingAnswerService],
})
export class OnboardingAnswerModule {}
```
`app.module.ts`: thêm `OnboardingAnswerModule,` sau `OnboardingTaxonomyModule,`.

- [ ] **Step 7: Build + commit**

Run: `npm run build` → exit 0.
```bash
git add src/modules/onboarding-answer/onboarding-recommendation.ranker.ts src/modules/onboarding-answer/onboarding-recommendation.ranker.spec.ts src/modules/onboarding-answer/interface/onboarding-answer.interface.ts src/modules/onboarding-answer/schema/onboarding-answer.schema.ts src/modules/onboarding-answer/repository/onboarding-answer.repository.ts src/modules/onboarding-answer/dto/save-onboarding-answer.dto.ts src/modules/onboarding-answer/onboarding-answer.service.ts src/modules/onboarding-answer/onboarding-answer.controller.ts src/modules/onboarding-answer/onboarding-answer.module.ts src/modules/user/src/modules/auth/schema/user.schema.ts src/modules/user/src/modules/auth/repository/user.repository.ts src/app.module.ts
git commit -m "feat: lưu câu trả lời onboarding và trả 3 khoá xếp hạng theo gói/mong muốn" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: Noti `onboarding_study_reminder` — enum, seed, bỏ qua trong vòng template, dispatcher theo giờ user

**Files:**
- Modify: `src/modules/notification/notification.enum.ts` (append vào `NotificationType`)
- Modify: `src/modules/notification/notification.defaults.ts` (append seed trước `];` đóng `DEFAULT_NOTIFICATION_TEMPLATES`)
- Modify: `src/modules/notification/notification-dispatch.service.ts:141` (skip thêm type mới)
- Create: `src/modules/onboarding-answer/onboarding-study-reminder.dispatcher.ts`
- Modify: `src/modules/onboarding-answer/onboarding-answer.module.ts` (import `NotificationModule`, `forwardRef(() => SegmentModule)`; provider dispatcher)

**Interfaces — Consumes:** `NotificationDispatchService.zonesDueAt(hour, minute, now)`, `.sendDirect({...})`; `NotificationTemplateService.findAll()`; `pickVariant, variantsOf, copyForLocale` từ `notification-variant.helper`; `UserRepository.distinctStudyReminderTimes / findPushCandidatesByTimezones(zones, limit, extraFilter)`; `SegmentMemberFilterService.memberFilterForSegments(ids)` (export của `SegmentModule`); `OnboardingAnswerRepository.findByUserIds`; `CourseRepository.findBriefByIds(ids)`.

- [ ] **Step 1: Enum + seed + skip**

```ts
// notification.enum.ts — append trong enum NotificationType, sau COACH_PLAN_REMINDER
/**
 * Nhắc học theo GIỜ USER CHỌN ở onboarding (S8). `localHour` của template trơ
 * như coach_plan_reminder; giờ thật nằm ở `users.studyReminderTime`. Xem
 * `OnboardingStudyReminderDispatcher`.
 */
ONBOARDING_STUDY_REMINDER = 'onboarding_study_reminder',
```
```ts
// notification.defaults.ts — append vào DEFAULT_NOTIFICATION_TEMPLATES
{
  type: NotificationType.ONBOARDING_STUDY_REMINDER,
  enabled: false,
  localHour: 0,
  deeplink: NotificationDeeplink.HOME,
  variants: [
    variant('v1', {
      vi: { title: 'Đến giờ tập trung 🌟', body: 'Bài học 2 phút của bạn đã sẵn sàng, {user_name}.' },
      en: { title: 'Time to focus 🌟', body: 'Your 2-minute lesson is ready, {user_name}.' },
      ko: { title: '집중할 시간이에요 🌟', body: '{user_name}님, 2분 레슨이 준비되었어요.' },
      zh: { title: '专注时间到 🌟', body: '{user_name}，你的2分钟课程已准备好。' },
      ja: { title: '集中の時間です 🌟', body: '{user_name}さん、2分レッスンの準備ができました。' },
    }),
    variant('v2', {
      vi: { title: 'Giữ nhịp học hôm nay', body: 'Tiếp tục «{course_name}» — 2 phút là đủ.' },
      en: { title: 'Keep today\'s streak', body: 'Continue “{course_name}” — two minutes is enough.' },
      ko: { title: '오늘의 학습 리듬 유지하기', body: '“{course_name}” 이어서 — 2분이면 충분해요.' },
      zh: { title: '保持今天的学习节奏', body: '继续《{course_name}》— 两分钟就够。' },
      ja: { title: '今日の学習リズムを保とう', body: '「{course_name}」を続けよう — 2分で十分。' },
    }),
  ],
},
```
Kiểm tra tên helper `variant(...)` trong file (dòng ~26 "Shorthand for the seeds below") và dùng đúng chữ ký.
```ts
// notification-dispatch.service.ts ~dòng 141 — thay dòng skip coach bằng:
if (
  template.type === NotificationType.COACH_PLAN_REMINDER ||
  template.type === NotificationType.ONBOARDING_STUDY_REMINDER
) {
  continue; // giờ gửi thuộc về user, dispatcher riêng lo
}
```

- [ ] **Step 2: Dispatcher**

```ts
// src/modules/onboarding-answer/onboarding-study-reminder.dispatcher.ts
import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';

import { CourseRepository } from 'src/modules/courses/src/modules/course/repository/course.repository';
import { NotificationDispatchService } from 'src/modules/notification/notification-dispatch.service';
import { NotificationTemplateService } from 'src/modules/notification/notification-template.service';
import { pickVariant, variantsOf } from 'src/modules/notification/notification-variant.helper';
import { NotificationType } from 'src/modules/notification/notification.enum';
import { SegmentMemberFilterService } from 'src/modules/segment/segment-member-filter.service';
import { UserRepository } from 'src/modules/user/src/modules/auth/repository/user.repository';

import { OnboardingAnswerRepository } from './repository/onboarding-answer.repository';

const TIME_REGEX = /^(\d{2}):(\d{2})$/;

/**
 * Nhắc học theo giờ USER chọn ở onboarding — sao y `CoachPlanReminderDispatcher`:
 * mọi thứ sau "ai, lúc nào" (trần/ngày, claim, FCM, log) là của
 * `NotificationDispatchService.sendDirect`. Ở đây chỉ: giờ nào đang có người
 * đặt → zone nào vừa tới giờ đó → user nào trong zone có đúng giờ đó (+ segment
 * của template) → chọn biến thể → gửi.
 */
@Injectable()
export class OnboardingStudyReminderDispatcher {
  private readonly logger = new Logger(OnboardingStudyReminderDispatcher.name);
  private isRunning = false;

  constructor(
    private readonly dispatchService: NotificationDispatchService,
    private readonly templateService: NotificationTemplateService,
    private readonly userRepository: UserRepository,
    private readonly answerRepository: OnboardingAnswerRepository,
    private readonly courseRepository: CourseRepository,
    private readonly segmentFilterService: SegmentMemberFilterService,
  ) {}

  @Cron('* * * * *')
  async dispatchDue() {
    if (this.isRunning) {
      this.logger.warn('Previous study reminder tick still running, skipping');
      return;
    }
    this.isRunning = true;
    try {
      const sent = await this.run();
      if (sent > 0) this.logger.log(`Onboarding study reminders sent: ${sent}`);
    } catch (error: any) {
      this.logger.error(`Study reminder tick failed: ${error?.message}`);
    } finally {
      this.isRunning = false;
    }
  }

  async run(now = new Date()): Promise<number> {
    const times = await this.userRepository.distinctStudyReminderTimes();
    if (!times.length) return 0;

    const template = (await this.templateService.findAll()).find(
      t => t.type === NotificationType.ONBOARDING_STUDY_REMINDER,
    );
    if (!template?.enabled) return 0;

    const segmentFilter = await this.segmentFilterService.memberFilterForSegments(template.segmentIds);

    let sent = 0;
    for (const time of times) {
      const match = TIME_REGEX.exec(time);
      if (!match) continue;
      sent += await this.dispatchTime(template, time, Number(match[1]), Number(match[2]), segmentFilter, now);
    }
    return sent;
  }

  private async dispatchTime(
    template: Awaited<ReturnType<NotificationTemplateService['findAll']>>[number],
    time: string,
    hour: number,
    minute: number,
    segmentFilter: Record<string, unknown> | null,
    now: Date,
  ): Promise<number> {
    const zones = await this.dispatchService.zonesDueAt(hour, minute, now);
    if (!zones.length) return 0;

    const candidates = await this.userRepository.findPushCandidatesByTimezones(zones, undefined, {
      studyReminderTime: time,
      ...(segmentFilter ?? {}),
    } as any);
    if (!candidates.length) return 0;

    // {course_name}: khoá đã chọn ở S10, không có thì khoá gợi ý đầu.
    const answers = await this.answerRepository.findByUserIds(candidates.map((c: any) => String(c._id)));
    const courseIdOf = new Map(answers.map(a => [a.userId, a.chosenCourseId ?? a.recommendedCourseIds?.[0] ?? null]));
    const courseIds = [...new Set([...courseIdOf.values()].filter((id): id is string => Boolean(id)))];
    const courses = courseIds.length ? await this.courseRepository.findBriefByIds(courseIds) : [];
    const titleOf = new Map(courses.map((c: any) => [String(c._id), c.title ?? {}]));

    const variants = variantsOf(template);
    let sent = 0;
    for (const candidate of candidates as any[]) {
      const userId = String(candidate._id);
      const lang = (candidate.language ?? 'en').toLowerCase().split(/[-_]/)[0];
      const courseTitle = titleOf.get(courseIdOf.get(userId) ?? '');
      const variables: Record<string, string> = {
        user_name: (candidate.name ?? '').trim(),
        course_name: courseTitle?.[lang] ?? courseTitle?.en ?? courseTitle?.vi ?? '',
      };
      const pick = pickVariant({ variants, language: candidate.language, variables });
      if (!pick) continue;

      try {
        const didSend = await this.dispatchService.sendDirect({
          candidate,
          type: NotificationType.ONBOARDING_STUDY_REMINDER,
          deeplink: template.deeplink,
          title: pick.title,
          body: pick.body,
          imageUrl: template.imageUrl,
          meta: { variantKey: pick.variant.key, reminderTime: time },
          now,
        });
        if (didSend) sent += 1;
      } catch (error: any) {
        this.logger.warn(`Study reminder failed for user=${userId}: ${error?.message}`);
      }
    }
    return sent;
  }
}
```
Đối chiếu `INotificationVariantPick` (notification-variant.helper.ts:42-46) để lấy đúng tên field `title`/`body`/`variant.key`; nếu tên khác, sửa theo helper chứ không sửa helper.

- [ ] **Step 3: Module wiring**

`onboarding-answer.module.ts`: `imports` thêm `NotificationModule` (plain — NotificationModule không import ngược) và `forwardRef(() => SegmentModule)` (`src/modules/segment/segment.module`); `providers` thêm `OnboardingStudyReminderDispatcher`.

- [ ] **Step 4: Build + kiểm DI + commit**

Run: `npm run build` → exit 0. Nếu có API dev đang chạy local, khởi động lại và grep log `OnboardingAnswerModule dependencies initialized` (memory: module cha init không có nghĩa module con init).
```bash
git add src/modules/notification/notification.enum.ts src/modules/notification/notification.defaults.ts src/modules/notification/notification-dispatch.service.ts src/modules/onboarding-answer/onboarding-study-reminder.dispatcher.ts src/modules/onboarding-answer/onboarding-answer.module.ts
git commit -m "feat: noti nhắc học theo giờ user chọn ở onboarding (type onboarding_study_reminder)" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: onboarding-config — 4 section mới + fix toggle paywall không lưu

**Files:**
- Modify: `src/modules/onboarding-config/interface/onboarding-config.interface.ts`
- Modify: `src/modules/onboarding-config/schema/onboarding-config.schema.ts` (default + @Prop cho 4 section)
- Modify: `src/modules/onboarding-config/dto/create-onboarding-config.dto.ts` (4 class DTO + 4 field optional trên `CreateOnboardingConfigDto`)
- Modify: `src/modules/onboarding-config/onboarding-config.service.ts:43-97` (merge 4 section + copy `showPaywallAfterOnboarding`)

**Interfaces — Produces (JSON app + admin đọc):**
```ts
desire:   { heading: ITranslation; headingHighlight: ITranslation; helper: ITranslation }
how:      { eyebrow: ITranslation; heading: ITranslation; headingHighlight: ITranslation; steps: { title: ITranslation; body: ITranslation }[]; footer: ITranslation; ctaLabel: ITranslation }
reminder: { heading: ITranslation; headingHighlight: ITranslation; subtitle: ITranslation; timeSectionLabel: ITranslation; presets: { label: ITranslation; time: string }[]; ctaLabel: ITranslation; secondaryCtaLabel: ITranslation }
loading:  { heading: ITranslation; headingHighlight: ITranslation; lines: ITranslation[] }
```

- [ ] **Step 1: Interface + default + schema**

```ts
// interface — thêm
export interface IOnboardingDesireSection { heading: ITranslation; headingHighlight: ITranslation; helper: ITranslation }
export interface IOnboardingHowStep { title: ITranslation; body: ITranslation }
export interface IOnboardingHowSection { eyebrow: ITranslation; heading: ITranslation; headingHighlight: ITranslation; steps: IOnboardingHowStep[]; footer: ITranslation; ctaLabel: ITranslation }
export interface IOnboardingReminderPreset { label: ITranslation; time: string }
export interface IOnboardingReminderSection { heading: ITranslation; headingHighlight: ITranslation; subtitle: ITranslation; timeSectionLabel: ITranslation; presets: IOnboardingReminderPreset[]; ctaLabel: ITranslation; secondaryCtaLabel: ITranslation }
export interface IOnboardingLoadingSection { heading: ITranslation; headingHighlight: ITranslation; lines: ITranslation[] }
// IOnboardingConfig thêm: desire, how, reminder, loading
```
```ts
// schema — defaults (chép copy từ design):
export const DEFAULT_ONBOARDING_DESIRE_SECTION: IOnboardingDesireSection = {
  heading: { vi: 'Nếu chỉ được thay đổi một thứ trong 10 ngày tới,', en: 'If you could change just one thing in the next 10 days,' },
  headingHighlight: { vi: 'bạn chọn gì?', en: 'what would it be?' },
  helper: { vi: 'Chọn một điều quan trọng nhất với bạn.', en: 'Pick the one that matters most.' },
};
export const DEFAULT_ONBOARDING_HOW_SECTION: IOnboardingHowSection = {
  eyebrow: { vi: 'HDDhistory giúp bạn thế nào', en: 'How HDDhistory helps' },
  heading: { vi: 'Không dừng ở biết', en: 'Not just knowing' },
  headingHighlight: { vi: 'Mà phải ứng dụng được', en: 'But putting it to use' },
  steps: [
    { title: { vi: 'Hiểu', en: 'Learn' }, body: { vi: 'Bài học siêu ngắn, vừa với lịch của bạn', en: 'Bite-size lessons that fit your day' } },
    { title: { vi: 'Thử', en: 'Try' }, body: { vi: 'Luyện tập cùng AI ngay sau khi học', en: 'Practice with AI right after' } },
    { title: { vi: 'Ôn', en: 'Review' }, body: { vi: 'HDDhistory nhắc lại trước khi bạn kịp quên', en: 'HDDhistory reminds you before you forget' } },
    { title: { vi: 'Dùng', en: 'Apply' }, body: { vi: 'Hướng dẫn mang bài học vào việc thật mỗi ngày', en: 'Guidance to use it in real life every day' } },
  ],
  footer: { vi: 'HDDhistory đi cùng bạn ở từng bước, từ bài học đầu tiên đến thói quen bạn giữ được mỗi ngày.', en: 'HDDhistory walks with you from the first lesson to the habit you keep.' },
  ctaLabel: { vi: 'Bắt đầu thôi', en: 'Let\'s go' },
};
export const DEFAULT_ONBOARDING_REMINDER_SECTION: IOnboardingReminderSection = {
  heading: { vi: 'Khó nhất không phải bắt đầu,', en: 'The hard part isn\'t starting,' },
  headingHighlight: { vi: 'mà là duy trì', en: 'it\'s keeping going' },
  subtitle: { vi: 'Lời nhắc đúng giờ giúp bạn không bỏ lỡ ngày nào', en: 'A well-timed reminder keeps every day on track' },
  timeSectionLabel: { vi: 'CHỌN KHUNG GIỜ HỌC ƯA THÍCH', en: 'PICK YOUR STUDY TIME' },
  presets: [
    { label: { vi: 'Sáng · 7:00', en: 'Morning · 7:00' }, time: '07:00' },
    { label: { vi: 'Trưa · 12:30', en: 'Noon · 12:30' }, time: '12:30' },
    { label: { vi: 'Tối · 21:00', en: 'Evening · 21:00' }, time: '21:00' },
  ],
  ctaLabel: { vi: 'Bật thông báo', en: 'Turn on notifications' },
  secondaryCtaLabel: { vi: 'Để sau', en: 'Maybe later' },
};
export const DEFAULT_ONBOARDING_LOADING_SECTION: IOnboardingLoadingSection = {
  heading: { vi: 'Đề xuất khoá học', en: 'Picking a course' },
  headingHighlight: { vi: 'dành cho bạn', en: 'for you' },
  lines: [
    { vi: 'Lĩnh vực bạn quan tâm', en: 'What you care about' },
    { vi: 'Điều bạn đang vướng', en: 'What\'s in your way' },
    { vi: 'Điều bạn muốn thay đổi', en: 'What you want to change' },
    { vi: 'Khung giờ học ưa thích', en: 'Your study time' },
  ],
};
// class OnboardingConfig thêm 4 @Prop({ type: SchemaTypes.Mixed, default: DEFAULT_... }) desire/how/reminder/loading
```

- [ ] **Step 2: DTO** — 4 class theo khuôn `OnboardingNotifSectionDto` (mỗi field `@IsOptional() @IsObject()` cho ITranslation; `steps`/`presets`/`lines` là `@IsOptional() @IsArray()`), rồi trên `CreateOnboardingConfigDto` thêm 4 field `@IsOptional() @ValidateNested() @Type(() => XDto)`. Nhớ: DTO không khai báo field = field bị `whitelist` XOÁ ÂM THẦM.

- [ ] **Step 3: Service merge + fix paywall**

```ts
// onboarding-config.service.ts — trong updateConfig, sau khối `theme`:
if (dto.desire) patch.desire = { ...current.desire, ...dto.desire } as IOnboardingDesireSection;
if (dto.how) patch.how = { ...current.how, ...dto.how } as IOnboardingHowSection;
if (dto.reminder) patch.reminder = { ...current.reminder, ...dto.reminder } as IOnboardingReminderSection;
if (dto.loading) patch.loading = { ...current.loading, ...dto.loading } as IOnboardingLoadingSection;
// Bug cũ: toggle admin gửi field này nhưng patch không copy → chưa bao giờ lưu.
if (dto.showPaywallAfterOnboarding !== undefined) {
  patch.showPaywallAfterOnboarding = dto.showPaywallAfterOnboarding;
}
```
Cũng thêm 4 section vào `findOrCreateDefault`'s `$setOnInsert` trong repository (dòng ~51-58) cho đồng bộ với `theme`.

- [ ] **Step 4: Build + commit**

Run: `npm run build` → exit 0.
```bash
git add src/modules/onboarding-config/interface/onboarding-config.interface.ts src/modules/onboarding-config/schema/onboarding-config.schema.ts src/modules/onboarding-config/dto/create-onboarding-config.dto.ts src/modules/onboarding-config/onboarding-config.service.ts src/modules/onboarding-config/repository/onboarding-config.repository.ts
git commit -m "feat: onboarding config thêm 4 màn mới (mong muốn/cách dạy/nhắc học/loading), lưu được toggle paywall" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: Kiểm chứng đầu-cuối trên API dev

- [ ] **Step 1:** `npm run build` sạch; `npm test -- src/modules/onboarding-taxonomy` và `npm test -- src/modules/onboarding-answer` (2 lệnh riêng) PASS.
- [ ] **Step 2:** Deploy api-dev theo `/deploy-api` (hoặc push `develop` để Jenkins chạy). Grep log container: `OnboardingTaxonomyModule dependencies initialized`, `OnboardingAnswerModule dependencies initialized`.
- [ ] **Step 3:** Import file mẫu: `curl -sS -X POST -H "Authorization: Bearer $ADMIN_TOKEN" -F "file=@plans/260918-onboarding-v3-taxonomy/onboarding-taxonomy-template.xlsx" -o /tmp/result.xlsx -D - https://<api-dev>/api/v1/onboarding-taxonomy/import` → 201, header `X-Import-Warnings: 14` (14 khoá coming soon/draft có thể không có trong DB dev — số thật tuỳ dữ liệu).
- [ ] **Step 4:** `curl -sS https://<api-dev>/api/v1/onboarding-taxonomy | jq '.data.branches|length, .data.packages|length'` → `5` (KP không selectable nhưng vẫn active → 6) và `26`.
- [ ] **Step 5:** Token ẩn danh (xem memory `probe-hddhistory-apis-with-curl-not-python`): `curl -sS -X POST -H "Authorization: Bearer $ANON" -H 'Content-Type: application/json' -d '{"branchCodes":["LV","CX"],"packageCodes":["LV-1","CX-2"],"desireCode":"LV-1","reminderEnabled":true,"reminderTime":"21:00"}' https://<api-dev>/api/v1/onboarding-answers | jq '.data.recommendations[].title.vi'` → 3 tiêu đề, dòng đầu là "Khoa học về sự trì hoãn" hoặc "Đừng để cầu toàn cản bước bạn" (cả hai khớp LV-1 + nhãn TT).
- [ ] **Step 6:** Ghi kết quả (số/mã lỗi) vào `plans/260918-onboarding-v3-taxonomy/design.md` mục "Kiểm chứng" nếu lệch spec.
