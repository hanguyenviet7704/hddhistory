# Onboarding v3 — hddhistory-admin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Admin quản trị được taxonomy onboarding (nhánh/gói/nhãn) qua trang mới + import/export Excel, gắn nhãn v3 cho khoá trong CourseModal, thấy type noti mới trong "Thông báo định kỳ", và sửa copy 4 màn mới ở Onboarding Config.

**Architecture:** React 19 + CRA, MUI + Tailwind, axios qua `axiosClient` (mọi body API bọc `{statusCode,message,data}` → đọc `res.data.data`, hoặc `unwrapApi`). Trang mới theo khuôn `pages/segments/SegmentsPage.tsx`; nút import theo `components/imports/ExcelImportButton.tsx`.

**Tech Stack:** React 19, TypeScript, MUI, Tailwind, axios, lucide-react / heroicons.

**Spec:** `hddhistory-api/plans/260918-onboarding-v3-taxonomy/design.md` (§5). API contract: `plan-api.md` Task 2/4/5/6/7.

## Global Constraints

- `cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-admin`; gate: `npx tsc --noEmit` (không `npm test`, không `eject`).
- Field đọc ra `undefined` trong render làm TRẮNG cả trang admin — mọi list mặc định `?? []`, mọi object mặc định `?? {}`.
- API strip field lạ âm thầm (`whitelist: true`): admin chỉ gửi field API đã khai báo DTO; **deploy api trước admin**.
- Git: commit thẳng `develop`, `git add` đúng từng file, message `type: <tiếng Việt>` + `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Tiếng Việt cho nhãn UI (trang admin mới đang viết tiếng Việt, xem NotificationsPage).

---

## File map

```
src/types/interface/onboarding-taxonomy.interface.ts        (mới)
src/services/onboardingTaxonomyService.ts                    (mới)
src/pages/onboarding-taxonomy/OnboardingTaxonomyPage.tsx     (mới)
src/components/onboarding-taxonomy/TaxonomyBranchCard.tsx    (mới: 1 nhánh = card, chứa bảng gói + nhãn)
src/routes/index.tsx, src/components/layout/Sidebar.tsx      (route + menu)
src/components/courses/CourseModal.tsx                        (khối "Nhãn onboarding v3")
src/types/interface/course.interface.ts                       (2 field)
src/types/interface/notification.interface.ts                 (union)
src/pages/notifications/NotificationsPage.tsx                 (TYPE_LABELS/HINTS/VARIABLES)
src/types/interface/onboarding-config.interface.ts            (4 section)
src/pages/onboarding-config/OnboardingConfigPage.tsx          (4 accordion, relabel, draft/payload)
```

---

### Task 1: Kiểu dữ liệu + service taxonomy; hằng số noti type mới

**Files:**
- Create: `src/types/interface/onboarding-taxonomy.interface.ts`
- Create: `src/services/onboardingTaxonomyService.ts`
- Modify: `src/types/interface/notification.interface.ts:2-10`
- Modify: `src/pages/notifications/NotificationsPage.tsx:34-43, 49-59, 69-80`
- Modify: `src/types/interface/course.interface.ts` (sau `onboardingSymptoms`)

**Interfaces — Produces:**
```ts
OnboardingBranch, OnboardingPackage, OnboardingLabel, OnboardingTaxonomyTree { branches; packages; labels }
onboardingTaxonomyService.getAdmin(): Promise<OnboardingTaxonomyTree>
onboardingTaxonomyService.replace(tree): Promise<OnboardingTaxonomyTree>
onboardingTaxonomyService.importExcel(file: File): Promise<AxiosResponse<Blob>>
onboardingTaxonomyService.exportExcel(): Promise<AxiosResponse<Blob>>
onboardingTaxonomyService.downloadTemplate(): Promise<AxiosResponse<Blob>>
ICourse.onboardingLabelCodes?: string[]; ICourse.onboardingDesireCodes?: string[]
```

- [ ] **Step 1: Types**

```ts
// src/types/interface/onboarding-taxonomy.interface.ts
// Mirrors hddhistory-api src/modules/onboarding-taxonomy (plans/260918-onboarding-v3-taxonomy).
import { ITranslation } from "../../utils/translate";

export interface OnboardingBranch {
  code: string;
  label: ITranslation;
  subtitle: ITranslation;
  iconUrl: string;
  imageUrl: string;
  order: number;
  /** Hiện ở câu 1. false = chỉ để gắn khoá (vd Khám phá não bộ). */
  isSelectable: boolean;
  categoryId: string | null;
  isActive: boolean;
}

/** 1 gói = 1 đáp án câu 2 (vấn đề) = 1 đáp án câu 3 (mong muốn). */
export interface OnboardingPackage {
  code: string;
  branchCode: string;
  problemLabel: ITranslation;
  desireLabel: ITranslation;
  order: number;
  isActive: boolean;
}

/** Nhãn chi tiết: chỉ để khớp gói ↔ khoá, user không thấy. */
export interface OnboardingLabel {
  code: string;
  packageCode: string;
  label: ITranslation;
  order: number;
}

export interface OnboardingTaxonomyTree {
  branches: OnboardingBranch[];
  packages: OnboardingPackage[];
  labels: OnboardingLabel[];
}

export const emptyTaxonomyTree = (): OnboardingTaxonomyTree => ({ branches: [], packages: [], labels: [] });
```
Kiểm tra `ITranslation` thật sự nằm ở `src/utils/translate` (course.interface.ts import từ đó) — nếu tên khác, dùng đúng tên đó.

- [ ] **Step 2: Service**

```ts
// src/services/onboardingTaxonomyService.ts
import type { OnboardingTaxonomyTree } from "../types/interface/onboarding-taxonomy.interface";
import { unwrapApi } from "../utils/unwrapApi";
import axiosClient from "./axiosClient";

const BASE = "/onboarding-taxonomy";

export const onboardingTaxonomyService = {
  async getAdmin() {
    const res = await axiosClient.get(`${BASE}/admin`);
    return unwrapApi<OnboardingTaxonomyTree>(res.data);
  },
  /** Thay toàn bộ cây; API validate và trả 400 {message, issues[]} khi hỏng. */
  async replace(tree: OnboardingTaxonomyTree) {
    const res = await axiosClient.put(BASE, tree);
    return unwrapApi<OnboardingTaxonomyTree>(res.data);
  },
  async importExcel(file: File) {
    const formData = new FormData();
    formData.append("file", file);
    return axiosClient.post<Blob>(`${BASE}/import`, formData, {
      responseType: "blob",
      headers: { "Content-Type": "multipart/form-data" },
    });
  },
  async exportExcel() {
    return axiosClient.get<Blob>(`${BASE}/export`, { responseType: "blob" });
  },
  async downloadTemplate() {
    return axiosClient.get<Blob>(`${BASE}/template`, { responseType: "blob" });
  },
};
```

- [ ] **Step 3: Noti type + hằng số**

```ts
// notification.interface.ts — thêm vào union NotificationType:
  | "onboarding_study_reminder";
```
```ts
// NotificationsPage.tsx
// TYPE_LABELS thêm:
  onboarding_study_reminder: "8. Nhắc học theo giờ đã chọn (onboarding)",
// TYPE_HINTS thêm:
  onboarding_study_reminder:
    "Giờ gửi do USER chọn ở màn Nhắc nhở của onboarding (bước 15 phút), nên ô \"giờ\" ở đây không có tác dụng. Chỉ gửi cho user có đặt giờ; tối đa 1 lần/ngày và chịu trần 4 noti/ngày chung.",
// TYPE_VARIABLES thêm:
  onboarding_study_reminder: "{user_name}, {course_name}",
```
`TYPE_ORDER = Object.keys(TYPE_LABELS)` tự có thứ tự đúng.

- [ ] **Step 4: Course type**

```ts
// course.interface.ts — trong ICourse sau onboardingSymptoms
/** Onboarding v3: mã nhãn chi tiết (vấn đề) — xem onboarding-taxonomy. */
onboardingLabelCodes?: string[];
/** Onboarding v3: mã gói (mong muốn). */
onboardingDesireCodes?: string[];
```

- [ ] **Step 5: Type-check + commit**

Run: `npx tsc --noEmit` → không lỗi.
```bash
git add src/types/interface/onboarding-taxonomy.interface.ts src/services/onboardingTaxonomyService.ts src/types/interface/notification.interface.ts src/pages/notifications/NotificationsPage.tsx src/types/interface/course.interface.ts
git commit -m "feat: kiểu + service taxonomy onboarding v3, thêm type noti nhắc học theo giờ" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: Trang "Onboarding Taxonomy" (cây sửa inline + Import/Export/Mẫu/Lưu) + route + sidebar

**Files:**
- Create: `src/components/onboarding-taxonomy/TaxonomyBranchCard.tsx`
- Create: `src/pages/onboarding-taxonomy/OnboardingTaxonomyPage.tsx`
- Modify: `src/routes/index.tsx` (import + `<Route path="onboarding-taxonomy" .../>` cạnh `onboarding-config`)
- Modify: `src/components/layout/Sidebar.tsx:126` (thêm mục dưới "Onboarding Config")

**Interfaces — Consumes:** `onboardingTaxonomyService` (Task 1), `ExcelImportButton`, `downloadBlob`, `useNotification`, `categoryService.getList` (typeahead chủ đề — tái dùng cách CourseModal.tsx:88-100 debounce query).

UI:
- Header: tiêu đề "Onboarding Taxonomy", mô tả 1 dòng; nút: `Tải file mẫu` (outlined) · `Export Excel` (outlined) · `<ExcelImportButton label="Import Excel" fileName="onboarding-taxonomy-import-result.xlsx" importExcel={onboardingTaxonomyService.importExcel} onSuccess={reload+toast} onError={showError}/>` · `Thêm nhánh` · `Lưu` (contained, disabled khi không dirty).
- Cảnh báo (Alert info): "Import thay toàn bộ nhánh/gói/nhãn và gắn nhãn cho khoá có trong tab Mapping. File kết quả tải về có cột Course ID đã điền; nếu có sheet `import_warnings` là có khoá không tìm thấy."
- Thân: mỗi nhánh 1 `TaxonomyBranchCard` (Accordion): header = `code` + label.vi + chip "Không hiện ở câu 1" khi `!isSelectable` + chip "Tắt" khi `!isActive` + số gói; details = form nhánh (code, label vi/en, subtitle vi/en, order, isSelectable switch, isActive switch, chủ đề typeahead) + bảng gói (cột: Mã gói · Vấn đề (vi) · Vấn đề (en) · Mong muốn (vi) · Mong muốn (en) · Thứ tự · Bật · Nhãn chi tiết (n) · xoá) — mỗi hàng gói có nút mở rộng hiện danh sách nhãn (Mã · Nhãn (vi) · Nhãn (en) · xoá) + "Thêm nhãn"; nút "Thêm gói".
- Lưu: `onboardingTaxonomyService.replace(tree)`; lỗi 400 → hiện `issues` (entity · code · message) trong Alert error, không toast một dòng.
- Xoá nhánh xoá luôn gói + nhãn thuộc nó (confirm dialog); xoá gói xoá nhãn thuộc nó.

- [ ] **Step 1: TaxonomyBranchCard**

```tsx
// src/components/onboarding-taxonomy/TaxonomyBranchCard.tsx
import React, { useState } from "react";
import {
  Accordion, AccordionDetails, AccordionSummary, Box, Button, Chip, Collapse, FormControlLabel,
  IconButton, Switch, Table, TableBody, TableCell, TableHead, TableRow, TextField, Typography,
} from "@mui/material";
import { ChevronDownIcon, ChevronRightIcon, PlusIcon, TrashIcon } from "lucide-react";

import type { OnboardingBranch, OnboardingLabel, OnboardingPackage } from "../../types/interface/onboarding-taxonomy.interface";

interface Props {
  branch: OnboardingBranch;
  packages: OnboardingPackage[];
  labelsByPackage: Record<string, OnboardingLabel[]>;
  onChangeBranch: (next: OnboardingBranch) => void;
  onDeleteBranch: () => void;
  onChangePackage: (code: string, next: OnboardingPackage) => void;
  onAddPackage: () => void;
  onDeletePackage: (code: string) => void;
  onChangeLabel: (code: string, next: OnboardingLabel) => void;
  onAddLabel: (packageCode: string) => void;
  onDeleteLabel: (code: string) => void;
  categoryPicker: React.ReactNode; // typeahead do page cung cấp (cần service + debounce)
}

const small = { size: "small" as const, sx: { minWidth: 160 } };

const TaxonomyBranchCard: React.FC<Props> = ({
  branch, packages, labelsByPackage, onChangeBranch, onDeleteBranch, onChangePackage, onAddPackage,
  onDeletePackage, onChangeLabel, onAddLabel, onDeleteLabel, categoryPicker,
}) => {
  const [open, setOpen] = useState<Record<string, boolean>>({});
  const set = (patch: Partial<OnboardingBranch>) => onChangeBranch({ ...branch, ...patch });

  return (
    <Accordion>
      <AccordionSummary expandIcon={<ChevronDownIcon size={18} />}>
        <Box className="flex items-center gap-2 flex-wrap">
          <Chip label={branch.code || "?"} size="small" color="primary" />
          <Typography sx={{ fontWeight: 600 }}>{branch.label?.vi || "(chưa có tên)"}</Typography>
          <Typography variant="caption" color="text.secondary">{packages.length} gói</Typography>
          {!branch.isSelectable && <Chip label="Không hiện ở câu 1" size="small" />}
          {!branch.isActive && <Chip label="Tắt" size="small" color="warning" />}
        </Box>
      </AccordionSummary>
      <AccordionDetails>
        <Box className="flex flex-wrap gap-3 mb-3">
          <TextField {...small} label="Mã nhánh" value={branch.code} onChange={(e) => set({ code: e.target.value.toUpperCase() })} />
          <TextField {...small} label="Tên (vi)" value={branch.label?.vi ?? ""} onChange={(e) => set({ label: { ...branch.label, vi: e.target.value } })} />
          <TextField {...small} label="Tên (en)" value={branch.label?.en ?? ""} onChange={(e) => set({ label: { ...branch.label, en: e.target.value } })} />
          <TextField {...small} sx={{ minWidth: 260 }} label="Mô tả ngắn (vi)" value={branch.subtitle?.vi ?? ""} onChange={(e) => set({ subtitle: { ...branch.subtitle, vi: e.target.value } })} />
          <TextField {...small} sx={{ minWidth: 260 }} label="Mô tả ngắn (en)" value={branch.subtitle?.en ?? ""} onChange={(e) => set({ subtitle: { ...branch.subtitle, en: e.target.value } })} />
          <TextField {...small} sx={{ width: 90 }} type="number" label="Thứ tự" value={branch.order} onChange={(e) => set({ order: Number(e.target.value) || 0 })} />
          <TextField {...small} sx={{ minWidth: 260 }} label="Icon URL" value={branch.iconUrl ?? ""} onChange={(e) => set({ iconUrl: e.target.value })} />
          {categoryPicker}
          <FormControlLabel control={<Switch checked={branch.isSelectable} onChange={(e) => set({ isSelectable: e.target.checked })} />} label="Hiện ở câu 1" />
          <FormControlLabel control={<Switch checked={branch.isActive} onChange={(e) => set({ isActive: e.target.checked })} />} label="Đang bật" />
          <Button color="error" startIcon={<TrashIcon size={16} />} onClick={onDeleteBranch}>Xoá nhánh</Button>
        </Box>

        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell />
              <TableCell>Mã gói</TableCell>
              <TableCell>Vấn đề (vi)</TableCell>
              <TableCell>Vấn đề (en)</TableCell>
              <TableCell>Mong muốn (vi)</TableCell>
              <TableCell>Mong muốn (en)</TableCell>
              <TableCell width={80}>Thứ tự</TableCell>
              <TableCell>Bật</TableCell>
              <TableCell width={48} />
            </TableRow>
          </TableHead>
          <TableBody>
            {packages.map((pkg) => {
              const labels = labelsByPackage[pkg.code] ?? [];
              const setPkg = (patch: Partial<OnboardingPackage>) => onChangePackage(pkg.code, { ...pkg, ...patch });
              return (
                <React.Fragment key={pkg.code}>
                  <TableRow>
                    <TableCell>
                      <IconButton size="small" onClick={() => setOpen((o) => ({ ...o, [pkg.code]: !o[pkg.code] }))}>
                        {open[pkg.code] ? <ChevronDownIcon size={16} /> : <ChevronRightIcon size={16} />}
                      </IconButton>
                    </TableCell>
                    <TableCell><TextField size="small" value={pkg.code} onChange={(e) => setPkg({ code: e.target.value.toUpperCase() })} sx={{ width: 90 }} /></TableCell>
                    <TableCell><TextField size="small" fullWidth value={pkg.problemLabel?.vi ?? ""} onChange={(e) => setPkg({ problemLabel: { ...pkg.problemLabel, vi: e.target.value } })} /></TableCell>
                    <TableCell><TextField size="small" fullWidth value={pkg.problemLabel?.en ?? ""} onChange={(e) => setPkg({ problemLabel: { ...pkg.problemLabel, en: e.target.value } })} /></TableCell>
                    <TableCell><TextField size="small" fullWidth value={pkg.desireLabel?.vi ?? ""} onChange={(e) => setPkg({ desireLabel: { ...pkg.desireLabel, vi: e.target.value } })} /></TableCell>
                    <TableCell><TextField size="small" fullWidth value={pkg.desireLabel?.en ?? ""} onChange={(e) => setPkg({ desireLabel: { ...pkg.desireLabel, en: e.target.value } })} /></TableCell>
                    <TableCell><TextField size="small" type="number" value={pkg.order} onChange={(e) => setPkg({ order: Number(e.target.value) || 0 })} /></TableCell>
                    <TableCell><Switch size="small" checked={pkg.isActive} onChange={(e) => setPkg({ isActive: e.target.checked })} /></TableCell>
                    <TableCell><IconButton size="small" color="error" onClick={() => onDeletePackage(pkg.code)}><TrashIcon size={16} /></IconButton></TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell colSpan={9} sx={{ p: 0, border: 0 }}>
                      <Collapse in={!!open[pkg.code]} unmountOnExit>
                        <Box sx={{ pl: 6, pr: 2, py: 1.5, bgcolor: "grey.50" }}>
                          <Typography variant="caption" color="text.secondary">
                            Nhãn chi tiết ({labels.length}) — user không thấy, chỉ để khớp khoá học.
                          </Typography>
                          {labels.map((label) => (
                            <Box key={label.code} className="flex gap-2 items-center mt-1">
                              <TextField size="small" sx={{ width: 90 }} value={label.code} onChange={(e) => onChangeLabel(label.code, { ...label, code: e.target.value.toUpperCase() })} />
                              <TextField size="small" sx={{ flex: 1 }} placeholder="Nhãn (vi)" value={label.label?.vi ?? ""} onChange={(e) => onChangeLabel(label.code, { ...label, label: { ...label.label, vi: e.target.value } })} />
                              <TextField size="small" sx={{ flex: 1 }} placeholder="Nhãn (en)" value={label.label?.en ?? ""} onChange={(e) => onChangeLabel(label.code, { ...label, label: { ...label.label, en: e.target.value } })} />
                              <IconButton size="small" color="error" onClick={() => onDeleteLabel(label.code)}><TrashIcon size={14} /></IconButton>
                            </Box>
                          ))}
                          <Button size="small" startIcon={<PlusIcon size={14} />} sx={{ mt: 1 }} onClick={() => onAddLabel(pkg.code)}>Thêm nhãn</Button>
                        </Box>
                      </Collapse>
                    </TableCell>
                  </TableRow>
                </React.Fragment>
              );
            })}
          </TableBody>
        </Table>
        <Button size="small" startIcon={<PlusIcon size={14} />} sx={{ mt: 1 }} onClick={onAddPackage}>Thêm gói</Button>
      </AccordionDetails>
    </Accordion>
  );
};

export default TaxonomyBranchCard;
```
Lưu ý: sửa `code` inline làm đổi key React của hàng — chấp nhận (blur mất focus). Nếu khó chịu khi thử, giữ một `_localId` như `OnboardingConfigPage.makeListHelpers` làm.

- [ ] **Step 2: Page**

```tsx
// src/pages/onboarding-taxonomy/OnboardingTaxonomyPage.tsx
import React, { useCallback, useEffect, useMemo, useState } from "react";
import { Alert, Autocomplete, Box, Button, CircularProgress, Paper, TextField, Typography } from "@mui/material";
import { DownloadIcon, FileSpreadsheetIcon, PlusIcon, SaveIcon } from "lucide-react";

import ExcelImportButton from "../../components/imports/ExcelImportButton";
import TaxonomyBranchCard from "../../components/onboarding-taxonomy/TaxonomyBranchCard";
import { onboardingTaxonomyService } from "../../services/onboardingTaxonomyService";
import { categoryService } from "../../services/categoryService";
import type { OnboardingBranch, OnboardingLabel, OnboardingPackage, OnboardingTaxonomyTree } from "../../types/interface/onboarding-taxonomy.interface";
import { emptyTaxonomyTree } from "../../types/interface/onboarding-taxonomy.interface";
import { downloadBlob } from "../../utils/downloadBlob";
import { useNotification } from "../../utils/hooks/useNotification";

interface Issue { entity: string; code: string; message: string }

const OnboardingTaxonomyPage: React.FC = () => {
  const { showSuccess, showError } = useNotification();
  const [tree, setTree] = useState<OnboardingTaxonomyTree>(emptyTaxonomyTree());
  const [saved, setSaved] = useState<string>("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [issues, setIssues] = useState<Issue[]>([]);
  const [categories, setCategories] = useState<{ _id: string; title?: Record<string, string> }[]>([]);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await onboardingTaxonomyService.getAdmin();
      const safe: OnboardingTaxonomyTree = {
        branches: data?.branches ?? [], packages: data?.packages ?? [], labels: data?.labels ?? [],
      };
      setTree(safe);
      setSaved(JSON.stringify(safe));
      setIssues([]);
    } catch (e: any) {
      showError(e?.response?.data?.message || "Không tải được taxonomy");
    } finally {
      setLoading(false);
    }
  }, [showError]);

  useEffect(() => { load(); }, [load]);
  useEffect(() => {
    // Danh sách chủ đề để gắn cho nhánh — số chủ đề nhỏ (≈6), tải một lần.
    categoryService.getList({ take: 100 } as any).then((res: any) => setCategories(res?.items ?? res?.data?.items ?? [])).catch(() => setCategories([]));
  }, []);

  const dirty = JSON.stringify(tree) !== saved;
  const labelsByPackage = useMemo(() => {
    const map: Record<string, OnboardingLabel[]> = {};
    for (const l of tree.labels) (map[l.packageCode] ??= []).push(l);
    return map;
  }, [tree.labels]);

  const handleSave = async () => {
    setSaving(true);
    setIssues([]);
    try {
      const next = await onboardingTaxonomyService.replace(tree);
      const safe = { branches: next?.branches ?? [], packages: next?.packages ?? [], labels: next?.labels ?? [] };
      setTree(safe);
      setSaved(JSON.stringify(safe));
      showSuccess("Đã lưu taxonomy");
    } catch (e: any) {
      const data = e?.response?.data;
      if (Array.isArray(data?.issues)) setIssues(data.issues);
      else showError(data?.message || "Lưu thất bại");
    } finally {
      setSaving(false);
    }
  };

  const download = async (call: () => Promise<any>, name: string) => {
    try { const res = await call(); downloadBlob(res.data, name); }
    catch { showError("Tải file thất bại"); }
  };

  // --- mutators (thuần trên state) ---
  const updateBranch = (code: string, next: OnboardingBranch) => setTree((t) => ({
    ...t,
    branches: t.branches.map((b) => (b.code === code ? next : b)),
    packages: next.code === code ? t.packages : t.packages.map((p) => (p.branchCode === code ? { ...p, branchCode: next.code } : p)),
  }));
  const deleteBranch = (code: string) => {
    if (!window.confirm(`Xoá nhánh ${code} cùng toàn bộ gói và nhãn của nó?`)) return;
    setTree((t) => {
      const pkgCodes = new Set(t.packages.filter((p) => p.branchCode === code).map((p) => p.code));
      return {
        branches: t.branches.filter((b) => b.code !== code),
        packages: t.packages.filter((p) => p.branchCode !== code),
        labels: t.labels.filter((l) => !pkgCodes.has(l.packageCode)),
      };
    });
  };
  const addBranch = () => setTree((t) => ({
    ...t,
    branches: [...t.branches, { code: "", label: { vi: "" }, subtitle: {}, iconUrl: "", imageUrl: "", order: t.branches.length + 1, isSelectable: true, categoryId: null, isActive: true }],
  }));
  const updatePackage = (code: string, next: OnboardingPackage) => setTree((t) => ({
    ...t,
    packages: t.packages.map((p) => (p.code === code ? next : p)),
    labels: next.code === code ? t.labels : t.labels.map((l) => (l.packageCode === code ? { ...l, packageCode: next.code } : l)),
  }));
  const addPackage = (branchCode: string) => setTree((t) => {
    const n = t.packages.filter((p) => p.branchCode === branchCode).length + 1;
    return { ...t, packages: [...t.packages, { code: `${branchCode}-${n}`, branchCode, problemLabel: { vi: "" }, desireLabel: { vi: "" }, order: n, isActive: true }] };
  });
  const deletePackage = (code: string) => setTree((t) => ({
    ...t, packages: t.packages.filter((p) => p.code !== code), labels: t.labels.filter((l) => l.packageCode !== code),
  }));
  const updateLabel = (code: string, next: OnboardingLabel) => setTree((t) => ({ ...t, labels: t.labels.map((l) => (l.code === code ? next : l)) }));
  const addLabel = (packageCode: string) => setTree((t) => {
    const n = (labelsByPackage[packageCode]?.length ?? 0) + 1;
    const prefix = packageCode.split("-")[0];
    return { ...t, labels: [...t.labels, { code: `${prefix}${String(n).padStart(2, "0")}`, packageCode, label: { vi: "" }, order: n }] };
  });
  const deleteLabel = (code: string) => setTree((t) => ({ ...t, labels: t.labels.filter((l) => l.code !== code) }));

  const categoryPicker = (branch: OnboardingBranch) => (
    <Autocomplete
      size="small"
      sx={{ minWidth: 240 }}
      options={categories}
      getOptionLabel={(s) => s.title?.vi || s.title?.en || s._id}
      value={categories.find((s) => s._id === branch.categoryId) ?? null}
      onChange={(_, s) => updateBranch(branch.code, { ...branch, categoryId: s?._id ?? null })}
      renderInput={(params) => <TextField {...params} label="Category (để Home xếp theo nhánh)" />}
    />
  );

  if (loading) return <Box className="p-8 flex justify-center"><CircularProgress /></Box>;

  return (
    <Box className="p-6 flex flex-col gap-4">
      <Box className="flex flex-wrap items-center justify-between gap-3">
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 700 }}>Onboarding Taxonomy</Typography>
          <Typography variant="body2" color="text.secondary">
            Nhánh (câu 1) → gói (câu 2 = vấn đề, câu 3 = mong muốn) → nhãn chi tiết khớp khoá học.
          </Typography>
        </Box>
        <Box className="flex flex-wrap gap-2">
          <Button variant="outlined" startIcon={<FileSpreadsheetIcon size={16} />} onClick={() => download(onboardingTaxonomyService.downloadTemplate, "onboarding-taxonomy-template.xlsx")}>Tải file mẫu</Button>
          <Button variant="outlined" startIcon={<DownloadIcon size={16} />} onClick={() => download(onboardingTaxonomyService.exportExcel, "onboarding-taxonomy-export.xlsx")}>Export Excel</Button>
          <ExcelImportButton
            label="Import Excel"
            fileName="onboarding-taxonomy-import-result.xlsx"
            importExcel={onboardingTaxonomyService.importExcel}
            onSuccess={() => { showSuccess("Import xong — kiểm tra sheet import_warnings trong file kết quả nếu có"); load(); }}
            onError={showError}
          />
          <Button variant="outlined" startIcon={<PlusIcon size={16} />} onClick={addBranch}>Thêm nhánh</Button>
          <Button variant="contained" startIcon={<SaveIcon size={16} />} disabled={!dirty || saving} onClick={handleSave}>Lưu</Button>
        </Box>
      </Box>

      <Alert severity="info">
        Import <b>thay toàn bộ</b> nhánh/gói/nhãn và gắn nhãn cho các khoá có trong tab "Mapping Khoá học". Khoá không tìm thấy được ghi vào sheet <code>import_warnings</code> của file kết quả.
      </Alert>

      {issues.length > 0 && (
        <Alert severity="error">
          <Typography sx={{ fontWeight: 600 }}>Taxonomy không hợp lệ:</Typography>
          <ul className="list-disc pl-5">
            {issues.map((i, idx) => <li key={idx}>[{i.entity}] {i.code}: {i.message}</li>)}
          </ul>
        </Alert>
      )}

      <Paper variant="outlined" sx={{ p: 1 }}>
        {tree.branches.length === 0 && (
          <Typography className="p-6 text-center" color="text.secondary">Chưa có nhánh nào — import file mẫu hoặc bấm "Thêm nhánh".</Typography>
        )}
        {[...tree.branches].sort((a, b) => a.order - b.order).map((branch) => (
          <TaxonomyBranchCard
            key={branch.code || Math.random()}
            branch={branch}
            packages={tree.packages.filter((p) => p.branchCode === branch.code).sort((a, b) => a.order - b.order)}
            labelsByPackage={labelsByPackage}
            onChangeBranch={(next) => updateBranch(branch.code, next)}
            onDeleteBranch={() => deleteBranch(branch.code)}
            onChangePackage={updatePackage}
            onAddPackage={() => addPackage(branch.code)}
            onDeletePackage={deletePackage}
            onChangeLabel={updateLabel}
            onAddLabel={addLabel}
            onDeleteLabel={deleteLabel}
            categoryPicker={categoryPicker(branch)}
          />
        ))}
      </Paper>
    </Box>
  );
};

export default OnboardingTaxonomyPage;
```
Kiểm tra chữ ký `categoryService.getList` (src/services/categoryService.ts:8) và hình trả về (`unwrapApi`?) rồi chỉnh dòng set chủ đề cho đúng — đừng để `undefined.map`.

- [ ] **Step 3: Route + sidebar**

```tsx
// routes/index.tsx — import cạnh OnboardingConfigPage (dòng ~77)
import OnboardingTaxonomyPage from "../pages/onboarding-taxonomy/OnboardingTaxonomyPage";
// cạnh Route onboarding-config (dòng ~221)
<Route path="onboarding-taxonomy" element={<OnboardingTaxonomyPage />} />
```
```tsx
// Sidebar.tsx — trong nhóm "Onboarding", sau Onboarding Config
{ name: "Onboarding Taxonomy", icon: AdjustmentsHorizontalIcon, path: "/onboarding-taxonomy" },
```

- [ ] **Step 4: Type-check + thử tay + commit**

Run: `npx tsc --noEmit` → không lỗi. `npm start`, mở `/onboarding-taxonomy`: tải mẫu về, import lại file `hddhistory-api/plans/260918-onboarding-v3-taxonomy/onboarding-taxonomy-template.xlsx`, thấy 6 nhánh / 26 gói; sửa 1 nhãn, Lưu → toast thành công.
```bash
git add src/components/onboarding-taxonomy/TaxonomyBranchCard.tsx src/pages/onboarding-taxonomy/OnboardingTaxonomyPage.tsx src/routes/index.tsx src/components/layout/Sidebar.tsx
git commit -m "feat: trang Onboarding Taxonomy — sửa cây nhánh/gói/nhãn, import/export/mẫu Excel" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: CourseModal — khối "Nhãn onboarding (v3)"

**Files:**
- Modify: `src/components/courses/CourseModal.tsx` (state ~72-100, hydrate ~111-135, submit ~236, JSX sau khối "Onboarding Symptoms" ~640-681)

**Interfaces — Consumes:** `onboardingTaxonomyService.getAdmin()`, `ICourse.onboardingLabelCodes/onboardingDesireCodes`.

- [ ] **Step 1: State + hydrate + payload**

```tsx
// state (cạnh onboardingSymptoms)
const [onboardingLabelCodes, setOnboardingLabelCodes] = useState<string[]>([]);
const [onboardingDesireCodes, setOnboardingDesireCodes] = useState<string[]>([]);
const [taxonomy, setTaxonomy] = useState<OnboardingTaxonomyTree>(emptyTaxonomyTree());

// hydrate (nhánh initial): 
setOnboardingLabelCodes(initial.onboardingLabelCodes ?? []);
setOnboardingDesireCodes(initial.onboardingDesireCodes ?? []);
// nhánh reset: setOnboardingLabelCodes([]); setOnboardingDesireCodes([]);

// tải taxonomy khi mở modal (cạnh effect symptomLabels)
useEffect(() => {
  if (!isOpen) return;
  let cancelled = false;
  onboardingTaxonomyService.getAdmin()
    .then((t) => { if (!cancelled) setTaxonomy({ branches: t?.branches ?? [], packages: t?.packages ?? [], labels: t?.labels ?? [] }); })
    .catch(() => { /* khối hiện rỗng, không chặn form */ });
  return () => { cancelled = true; };
}, [isOpen]);

// submit payload: thêm
onboardingLabelCodes,
onboardingDesireCodes,
```

- [ ] **Step 2: JSX** (đặt NGAY SAU khối "Onboarding Symptoms"; đổi label khối cũ thành "Onboarding Symptoms (legacy — app cũ)")

```tsx
{/* Nhãn onboarding v3 */}
<div>
  <label className="block text-sm font-medium text-gray-700 mb-1">Nhãn onboarding (v3)</label>
  <p className="text-xs text-gray-500 mb-2">
    Gợi ý khoá sau onboarding: khoá lên đầu khi khớp <b>cả</b> mong muốn đã chọn <b>và</b> ít nhất một nhãn vấn đề. Quản lý danh mục ở trang Onboarding Taxonomy.
  </p>
  <div className="flex flex-col gap-3">
    <Autocomplete
      multiple
      size="small"
      options={[...taxonomy.labels].sort((a, b) => a.packageCode.localeCompare(b.packageCode) || a.order - b.order)}
      groupBy={(l) => {
        const pkg = taxonomy.packages.find((p) => p.code === l.packageCode);
        return pkg ? `${pkg.code} · ${pkg.problemLabel?.vi ?? ""}` : l.packageCode;
      }}
      getOptionLabel={(l) => `${l.code} — ${l.label?.vi ?? ""}`}
      value={taxonomy.labels.filter((l) => onboardingLabelCodes.includes(l.code))}
      onChange={(_, v) => setOnboardingLabelCodes(v.map((l) => l.code))}
      renderInput={(params) => <TextField {...params} label="Nhãn vấn đề (chi tiết)" placeholder="Chọn nhãn…" />}
    />
    <Autocomplete
      multiple
      size="small"
      options={[...taxonomy.packages].sort((a, b) => a.branchCode.localeCompare(b.branchCode) || a.order - b.order)}
      groupBy={(p) => taxonomy.branches.find((b) => b.code === p.branchCode)?.label?.vi ?? p.branchCode}
      getOptionLabel={(p) => `${p.code} — ${p.desireLabel?.vi ?? ""}`}
      value={taxonomy.packages.filter((p) => onboardingDesireCodes.includes(p.code))}
      onChange={(_, v) => setOnboardingDesireCodes(v.map((p) => p.code))}
      renderInput={(params) => <TextField {...params} label="Mong muốn (gói)" placeholder="Chọn gói…" />}
    />
    {onboardingLabelCodes.some((c) => !taxonomy.labels.find((l) => l.code === c)) && (
      <p className="text-xs text-amber-600">Có mã nhãn không còn trong taxonomy (sẽ bị bỏ qua khi gợi ý): {onboardingLabelCodes.filter((c) => !taxonomy.labels.find((l) => l.code === c)).join(", ")}</p>
    )}
  </div>
</div>
```
Import `Autocomplete, TextField` từ `@mui/material` nếu file chưa có (file đang dùng Tailwind + input thường; MUI đã có trong dự án).

- [ ] **Step 3: Type-check + commit**

Run: `npx tsc --noEmit` → không lỗi. Mở một khoá, chọn 2 nhãn + 1 gói, Lưu, mở lại thấy giữ.
```bash
git add src/components/courses/CourseModal.tsx
git commit -m "feat: form khoá học gắn nhãn vấn đề + gói mong muốn onboarding v3" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: Onboarding Config — 4 section mới + đổi nhãn accordion

**Files:**
- Modify: `src/types/interface/onboarding-config.interface.ts` (4 interface + 4 field trên `OnboardingConfig`)
- Modify: `src/pages/onboarding-config/OnboardingConfigPage.tsx` (`ConfigDraft`, `toDraft`, `buildPayload`, `CONFIG_SCREEN_KEYS`, 4 `Accordion` mới, relabel 3 accordion)

**Interfaces — Consumes:** API contract Task 7 plan-api (`desire/how/reminder/loading`).

- [ ] **Step 1: Types**

```ts
export interface OnboardingDesireConfig { heading: OnboardingMultilang; headingHighlight?: OnboardingMultilang; helper: OnboardingMultilang }
export interface OnboardingHowStep { title: OnboardingMultilang; body: OnboardingMultilang }
export interface OnboardingHowConfig { eyebrow: OnboardingMultilang; heading: OnboardingMultilang; headingHighlight?: OnboardingMultilang; steps: OnboardingHowStep[]; footer: OnboardingMultilang; ctaLabel: OnboardingMultilang }
export interface OnboardingReminderPreset { label: OnboardingMultilang; time: string }
export interface OnboardingReminderConfig { heading: OnboardingMultilang; headingHighlight?: OnboardingMultilang; subtitle: OnboardingMultilang; timeSectionLabel: OnboardingMultilang; presets: OnboardingReminderPreset[]; ctaLabel: OnboardingMultilang; secondaryCtaLabel: OnboardingMultilang }
export interface OnboardingLoadingConfig { heading: OnboardingMultilang; headingHighlight?: OnboardingMultilang; lines: OnboardingMultilang[] }
// OnboardingConfig thêm: desire: OnboardingDesireConfig; how: OnboardingHowConfig; reminder: OnboardingReminderConfig; loading: OnboardingLoadingConfig;
```

- [ ] **Step 2: Draft/payload**

`ConfigDraft` thêm 4 field cùng kiểu. `toDraft` thêm:
```ts
desire: { heading: ml(config?.desire?.heading), headingHighlight: ml(config?.desire?.headingHighlight), helper: ml(config?.desire?.helper) },
how: {
  eyebrow: ml(config?.how?.eyebrow), heading: ml(config?.how?.heading), headingHighlight: ml(config?.how?.headingHighlight),
  steps: (config?.how?.steps ?? []).map((s) => ({ title: ml(s?.title), body: ml(s?.body) })),
  footer: ml(config?.how?.footer), ctaLabel: ml(config?.how?.ctaLabel),
},
reminder: {
  heading: ml(config?.reminder?.heading), headingHighlight: ml(config?.reminder?.headingHighlight), subtitle: ml(config?.reminder?.subtitle),
  timeSectionLabel: ml(config?.reminder?.timeSectionLabel),
  presets: (config?.reminder?.presets ?? []).map((p) => ({ label: ml(p?.label), time: p?.time || "" })),
  ctaLabel: ml(config?.reminder?.ctaLabel), secondaryCtaLabel: ml(config?.reminder?.secondaryCtaLabel),
},
loading: { heading: ml(config?.loading?.heading), headingHighlight: ml(config?.loading?.headingHighlight), lines: (config?.loading?.lines ?? []).map((l) => ml(l)) },
```
`buildPayload` thêm `desire: draft.desire, how: draft.how, reminder: draft.reminder, loading: draft.loading`. `CONFIG_SCREEN_KEYS` thêm `"desire", "how", "reminder", "loading"`.

- [ ] **Step 3: Accordion** — thêm sau accordion "Symptoms (screen 7)" (dòng ~1460) theo đúng mẫu accordion Notifications (dòng 1573-1660), dùng `MultilangField`. Tạo `updateDesire/updateHow/updateReminder/updateLoading` giống `updateNotif` hiện có (grep `const updateNotif`). Nội dung:
  - **"Câu 3 — Mong muốn (S6)"**: Heading, Heading highlight, Helper.
  - **"HDDhistory dạy thế nào (S7)"**: Eyebrow, Heading, Heading highlight, 4 hàng `Step N` (Title + Body, nút "Thêm bước"/xoá — dùng `rowSx`), Footer (multiline), CTA label.
  - **"Nhắc nhở học (S8)"**: Heading, Heading highlight, Subtitle, Time section label, 3 hàng preset (Label multilang + `<TextField type="time" step={900}>` cho `time`), CTA label, Secondary CTA label. Helper: "Thẻ preview dùng copy của accordion Notifications bên dưới."
  - **"Đang tạo lộ trình (S9)"**: Heading, Heading highlight, 4 dòng Line N (multilang, thêm/xoá).
  - Relabel: "Symptoms (screen 7)" → "Câu 2 — Vấn đề (S5) — data key `habit`"; "Pick course" → "Kết quả (S10) — data key `pick`"; "Paths" → "Câu 1 — Lĩnh vực (S4): heading/helper; danh sách path items là LEGACY cho app cũ, app mới đọc Onboarding Taxonomy"; "Notifications" → "Nhắc nhở (S8) — thẻ preview + CTA".

- [ ] **Step 4: Type-check + thử + commit**

Run: `npx tsc --noEmit`. Mở trang, Lưu, tải lại thấy 4 section giữ giá trị (API Task 7 phải đã deploy — không thì field bị strip và biến mất sau reload; đó là dấu hiệu api chưa lên).
```bash
git add src/types/interface/onboarding-config.interface.ts src/pages/onboarding-config/OnboardingConfigPage.tsx
git commit -m "feat: Onboarding Config sửa được copy 4 màn mới (mong muốn, cách dạy, nhắc học, loading)" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```
