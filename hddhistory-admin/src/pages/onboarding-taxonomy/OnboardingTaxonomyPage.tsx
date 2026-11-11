import React, { useCallback, useEffect, useMemo, useState } from "react";
import { Alert, Autocomplete, Box, Button, CircularProgress, Paper, TextField, Typography } from "@mui/material";
import { DownloadIcon, FileSpreadsheetIcon, PlusIcon, SaveIcon } from "lucide-react";

import ExcelImportButton from "../../components/imports/ExcelImportButton";
import TaxonomyBranchCard, {
  LocalBranch,
  LocalLabel,
  LocalPackage,
} from "../../components/onboarding-taxonomy/TaxonomyBranchCard";
import { onboardingTaxonomyService } from "../../services/onboardingTaxonomyService";
import { categoryService } from "../../services/categoryService";
import type { OnboardingTaxonomyTree } from "../../types/interface/onboarding-taxonomy.interface";
import type { ICategory } from "../../types/interface/category.interface";
import { downloadBlob } from "../../utils/downloadBlob";
import { useNotification } from "../../utils/hooks/useNotification";
import { unwrapApi } from "../../utils/unwrapApi";

// Two payload shapes land here under the same `errors` key (see
// all-exceptions.filter.ts): `{entity, code, message}` from the PUT
// /onboarding-taxonomy validation path, and `{sheet, row, column, message}`
// from the Excel-import-shaped validator. Every field but `message` is
// therefore optional — render only what exists, never `undefined`.
interface Issue {
  entity?: string;
  code?: string;
  sheet?: string;
  row?: number;
  column?: string;
  message: string;
}

interface LocalTree {
  branches: LocalBranch[];
  packages: LocalPackage[];
  labels: LocalLabel[];
}

const emptyLocalTree = (): LocalTree => ({ branches: [], packages: [], labels: [] });

// UI-only id, monotonically increasing so it stays unique across reloads/adds
// within the page's lifetime — see the comment on LocalBranch/LocalPackage/
// LocalLabel in TaxonomyBranchCard.tsx for why this exists.
let localIdSeq = 0;
const nextLocalId = () => `local-${++localIdSeq}`;

const toLocalTree = (t: Partial<OnboardingTaxonomyTree> | null | undefined): LocalTree => ({
  branches: (t?.branches ?? []).map((b) => ({ ...b, _localId: nextLocalId() })),
  packages: (t?.packages ?? []).map((p) => ({ ...p, _localId: nextLocalId() })),
  labels: (t?.labels ?? []).map((l) => ({ ...l, _localId: nextLocalId() })),
});

const stripLocalIds = (t: LocalTree): OnboardingTaxonomyTree => ({
  branches: t.branches.map(({ _localId, ...rest }) => rest),
  packages: t.packages.map(({ _localId, ...rest }) => rest),
  labels: t.labels.map(({ _localId, ...rest }) => rest),
});

const OnboardingTaxonomyPage: React.FC = () => {
  const { showSuccess, showError } = useNotification();
  const [tree, setTree] = useState<LocalTree>(emptyLocalTree());
  const [saved, setSaved] = useState<string>("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [issues, setIssues] = useState<Issue[]>([]);
  const [categories, setCategories] = useState<ICategory[]>([]);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await onboardingTaxonomyService.getAdmin();
      const safe = toLocalTree(data);
      setTree(safe);
      setSaved(JSON.stringify(safe));
      setIssues([]);
    } catch (e: any) {
      showError(e?.response?.data?.message || "Không tải được taxonomy");
    } finally {
      setLoading(false);
    }
  }, [showError]);

  useEffect(() => {
    load();
  }, [load]);

  useEffect(() => {
    // Danh sách chủ đề để gắn cho nhánh — số chủ đề nhỏ (≈6), tải một lần.
    const loadCategories = async () => {
      try {
        const res: any = await categoryService.getList({ isAll: true, take: 1000 } as any);
        const page = unwrapApi<any>(res);
        setCategories(page?.items ?? []);
      } catch {
        setCategories([]);
      }
    };
    loadCategories();
  }, []);

  const dirty = JSON.stringify(tree) !== saved;

  const labelsByPackage = useMemo(() => {
    const map: Record<string, LocalLabel[]> = {};
    for (const l of tree.labels ?? []) (map[l.packageCode] ??= []).push(l);
    return map;
  }, [tree.labels]);

  const handleSave = async () => {
    setSaving(true);
    setIssues([]);
    try {
      const payload = stripLocalIds(tree);
      const next = await onboardingTaxonomyService.replace(payload);
      const safe = toLocalTree(next);
      setTree(safe);
      setSaved(JSON.stringify(safe));
      showSuccess("Đã lưu taxonomy");
    } catch (e: any) {
      const data = e?.response?.data;
      // `issues` covers a stale API build; `errors` is the key the global
      // exception filter actually forwards (all-exceptions.filter.ts) —
      // accept either so a validation failure never falls back to the
      // one-line toast.
      const list = data?.issues ?? data?.errors;
      if (Array.isArray(list)) setIssues(list);
      else showError(data?.message || "Lưu thất bại");
    } finally {
      setSaving(false);
    }
  };

  const download = async (call: () => Promise<any>, name: string) => {
    try {
      const res = await call();
      downloadBlob(res.data, name);
    } catch {
      showError("Tải file thất bại");
    }
  };

  // --- mutators (thuần trên state) ---
  // Every mutator below identifies the row it targets by `_localId`, never by
  // `code` — `code` is a user-editable field and can collide (two freshly
  // added rows share the same default/blank code until renamed), so using it
  // as a lookup key can silently edit or delete the wrong row. Cascades
  // (branch → its packages, package → its labels) still follow the actual
  // `branchCode`/`packageCode` relationships, since that's how the API links
  // them — only the *target* row itself is resolved by `_localId`.
  const updateBranch = (localId: string, next: LocalBranch) =>
    setTree((t) => {
      const prev = t.branches.find((b) => b._localId === localId);
      const oldCode = prev?.code;
      const codeChanged = !!prev && next.code !== oldCode;
      return {
        ...t,
        branches: t.branches.map((b) => (b._localId === localId ? next : b)),
        packages: !codeChanged ? t.packages : t.packages.map((p) => (p.branchCode === oldCode ? { ...p, branchCode: next.code } : p)),
      };
    });

  const deleteBranch = (localId: string) => {
    const branch = tree.branches.find((b) => b._localId === localId);
    const label = branch?.code || branch?.label?.vi || "(chưa đặt mã)";
    if (!window.confirm(`Xoá nhánh ${label} cùng toàn bộ gói và nhãn của nó?`)) return;
    setTree((t) => {
      const target = t.branches.find((b) => b._localId === localId);
      if (!target) return t;
      const pkgCodes = new Set(t.packages.filter((p) => p.branchCode === target.code).map((p) => p.code));
      return {
        branches: t.branches.filter((b) => b._localId !== localId),
        packages: t.packages.filter((p) => p.branchCode !== target.code),
        labels: t.labels.filter((l) => !pkgCodes.has(l.packageCode)),
      };
    });
  };

  const addBranch = () =>
    setTree((t) => {
      const maxOrder = t.branches.reduce((m, b) => Math.max(m, b.order ?? 0), 0);
      return {
        ...t,
        branches: [
          ...t.branches,
          {
            code: "",
            label: { vi: "" },
            subtitle: {},
            iconUrl: "",
            imageUrl: "",
            order: maxOrder + 1,
            isSelectable: true,
            categoryId: null,
            isActive: true,
            _localId: nextLocalId(),
          },
        ],
      };
    });

  const updatePackage = (localId: string, next: LocalPackage) =>
    setTree((t) => {
      const prev = t.packages.find((p) => p._localId === localId);
      const oldCode = prev?.code;
      const codeChanged = !!prev && next.code !== oldCode;
      return {
        ...t,
        packages: t.packages.map((p) => (p._localId === localId ? next : p)),
        labels: !codeChanged ? t.labels : t.labels.map((l) => (l.packageCode === oldCode ? { ...l, packageCode: next.code } : l)),
      };
    });

  // Default package code = smallest unused "<branchCode>-<n>" across the
  // WHOLE tree (not just this branch's packages) — two packages under
  // different branches could otherwise still land on the same code if one
  // branch's code is a prefix of another's default sequence.
  const addPackage = (branchCode: string) =>
    setTree((t) => {
      const usedCodes = new Set(t.packages.map((p) => p.code));
      let n = 1;
      while (usedCodes.has(`${branchCode}-${n}`)) n++;
      const siblingCount = t.packages.filter((p) => p.branchCode === branchCode).length;
      return {
        ...t,
        packages: [
          ...t.packages,
          {
            code: `${branchCode}-${n}`,
            branchCode,
            problemLabel: { vi: "" },
            desireLabel: { vi: "" },
            order: siblingCount + 1,
            isActive: true,
            _localId: nextLocalId(),
          },
        ],
      };
    });

  const deletePackage = (localId: string) =>
    setTree((t) => {
      const target = t.packages.find((p) => p._localId === localId);
      if (!target) return t;
      return {
        ...t,
        packages: t.packages.filter((p) => p._localId !== localId),
        labels: t.labels.filter((l) => l.packageCode !== target.code),
      };
    });

  const updateLabel = (localId: string, next: LocalLabel) =>
    setTree((t) => ({ ...t, labels: t.labels.map((l) => (l._localId === localId ? next : l)) }));

  // Default label code = smallest unused "<branchPrefix><NN>" across ALL
  // labels in the tree — branchPrefix is the package's actual `branchCode`,
  // not a guess parsed out of the package's own code (which may not follow
  // the "<branch>-<n>" shape once someone hand-edits it). Two packages under
  // the same branch previously produced the exact same default label code on
  // the first "Thêm nhãn" click each; this searches globally instead.
  const addLabel = (packageCode: string) =>
    setTree((t) => {
      const pkg = t.packages.find((p) => p.code === packageCode);
      const prefix = pkg?.branchCode || packageCode.split("-")[0] || "";
      const usedCodes = new Set(t.labels.map((l) => l.code));
      let n = 1;
      while (usedCodes.has(`${prefix}${String(n).padStart(2, "0")}`)) n++;
      const siblingCount = t.labels.filter((l) => l.packageCode === packageCode).length;
      return {
        ...t,
        labels: [
          ...t.labels,
          { code: `${prefix}${String(n).padStart(2, "0")}`, packageCode, label: { vi: "" }, order: siblingCount + 1, _localId: nextLocalId() },
        ],
      };
    });

  const deleteLabel = (localId: string) => setTree((t) => ({ ...t, labels: t.labels.filter((l) => l._localId !== localId) }));

  const categoryPicker = (branch: LocalBranch) => (
    <Autocomplete
      size="small"
      sx={{ minWidth: 240 }}
      options={categories}
      getOptionLabel={(s) => s.title?.vi || s.title?.en || s._id}
      isOptionEqualToValue={(a, b) => a._id === b._id}
      value={categories.find((s) => s._id === branch.categoryId) ?? null}
      onChange={(_, s) => updateBranch(branch._localId, { ...branch, categoryId: s?._id ?? null })}
      renderInput={(params) => <TextField {...params} label="Chủ đề (để Home xếp theo nhánh)" />}
    />
  );

  if (loading) {
    return (
      <Box className="p-8 flex justify-center">
        <CircularProgress />
      </Box>
    );
  }

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
          <Button variant="outlined" startIcon={<FileSpreadsheetIcon size={16} />} onClick={() => download(onboardingTaxonomyService.downloadTemplate, "onboarding-taxonomy-template.xlsx")}>
            Tải file mẫu
          </Button>
          <Button variant="outlined" startIcon={<DownloadIcon size={16} />} onClick={() => download(onboardingTaxonomyService.exportExcel, "onboarding-taxonomy-export.xlsx")}>
            Export Excel
          </Button>
          <ExcelImportButton
            label="Import Excel"
            fileName="onboarding-taxonomy-import-result.xlsx"
            importExcel={onboardingTaxonomyService.importExcel}
            onSuccess={() => {
              showSuccess("Import xong — kiểm tra sheet import_warnings trong file kết quả nếu có");
              load();
            }}
            onError={showError}
          />
          <Button variant="outlined" startIcon={<PlusIcon size={16} />} onClick={addBranch}>
            Thêm nhánh
          </Button>
          <Button variant="contained" startIcon={<SaveIcon size={16} />} disabled={!dirty || saving} onClick={handleSave}>
            Lưu
          </Button>
        </Box>
      </Box>

      <Alert severity="info">
        Import thay toàn bộ nhánh/gói/nhãn và gắn nhãn cho khoá có trong tab Mapping. File kết quả tải về có cột Course ID đã điền; nếu có sheet <code>import_warnings</code> là có khoá không tìm thấy.
      </Alert>

      {issues.length > 0 && (
        <Alert severity="error">
          <Typography sx={{ fontWeight: 600 }}>Taxonomy không hợp lệ:</Typography>
          <ul className="list-disc pl-5">
            {issues.map((i, idx) => {
              // Render only the fields this entry actually has — `entity`/
              // `code` come from the PUT-shaped issue, `sheet`/`row`/`column`
              // from the import-shaped one. Never print `undefined`.
              const parts: string[] = [];
              if (i.entity) parts.push(i.entity);
              if (i.code) parts.push(i.code);
              if (i.sheet) parts.push(i.sheet);
              if (i.row != null) parts.push(`dòng ${i.row}`);
              if (i.column) parts.push(i.column);
              const prefix = parts.join(" · ");
              return (
                <li key={idx}>{prefix ? `[${prefix}] ` : ""}{i.message}</li>
              );
            })}
          </ul>
        </Alert>
      )}

      <Paper variant="outlined" sx={{ p: 1 }}>
        {(tree.branches ?? []).length === 0 && (
          <Typography className="p-6 text-center" color="text.secondary">
            Chưa có nhánh nào — import file mẫu hoặc bấm "Thêm nhánh".
          </Typography>
        )}
        {[...(tree.branches ?? [])]
          .sort((a, b) => (a.order ?? 0) - (b.order ?? 0))
          .map((branch) => (
            <TaxonomyBranchCard
              key={branch._localId}
              branch={branch}
              packages={(tree.packages ?? []).filter((p) => p.branchCode === branch.code).sort((a, b) => (a.order ?? 0) - (b.order ?? 0))}
              labelsByPackage={labelsByPackage}
              onChangeBranch={(next) => updateBranch(branch._localId, next)}
              onDeleteBranch={() => deleteBranch(branch._localId)}
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
