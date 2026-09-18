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
import { skillsetService } from "../../services/skillsetService";
import type { OnboardingTaxonomyTree } from "../../types/interface/onboarding-taxonomy.interface";
import type { ISkillset } from "../../types/interface/skillset.interface";
import { downloadBlob } from "../../utils/downloadBlob";
import { useNotification } from "../../utils/hooks/useNotification";
import { unwrapApi } from "../../utils/unwrapApi";

interface Issue {
  entity: string;
  code: string;
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
  const [skillsets, setSkillsets] = useState<ISkillset[]>([]);

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
    // Danh sách skillset để gắn cho nhánh — số skillset nhỏ (≈6), tải một lần.
    const loadSkillsets = async () => {
      try {
        const res: any = await skillsetService.getList({ take: 100 } as any);
        const page = unwrapApi<any>(res);
        setSkillsets(page?.items ?? []);
      } catch {
        setSkillsets([]);
      }
    };
    loadSkillsets();
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
      if (Array.isArray(data?.issues)) setIssues(data.issues);
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
  const updateBranch = (code: string, next: LocalBranch) =>
    setTree((t) => ({
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

  const addBranch = () =>
    setTree((t) => ({
      ...t,
      branches: [
        ...t.branches,
        {
          code: "",
          label: { vi: "" },
          subtitle: {},
          iconUrl: "",
          imageUrl: "",
          order: t.branches.length + 1,
          isSelectable: true,
          skillsetId: null,
          isActive: true,
          _localId: nextLocalId(),
        },
      ],
    }));

  const updatePackage = (code: string, next: LocalPackage) =>
    setTree((t) => ({
      ...t,
      packages: t.packages.map((p) => (p.code === code ? next : p)),
      labels: next.code === code ? t.labels : t.labels.map((l) => (l.packageCode === code ? { ...l, packageCode: next.code } : l)),
    }));

  const addPackage = (branchCode: string) =>
    setTree((t) => {
      const n = t.packages.filter((p) => p.branchCode === branchCode).length + 1;
      return {
        ...t,
        packages: [
          ...t.packages,
          {
            code: `${branchCode}-${n}`,
            branchCode,
            problemLabel: { vi: "" },
            desireLabel: { vi: "" },
            order: n,
            isActive: true,
            _localId: nextLocalId(),
          },
        ],
      };
    });

  const deletePackage = (code: string) =>
    setTree((t) => ({
      ...t,
      packages: t.packages.filter((p) => p.code !== code),
      labels: t.labels.filter((l) => l.packageCode !== code),
    }));

  const updateLabel = (code: string, next: LocalLabel) =>
    setTree((t) => ({ ...t, labels: t.labels.map((l) => (l.code === code ? next : l)) }));

  const addLabel = (packageCode: string) =>
    setTree((t) => {
      const n = (labelsByPackage[packageCode]?.length ?? 0) + 1;
      const prefix = packageCode.split("-")[0];
      return {
        ...t,
        labels: [
          ...t.labels,
          { code: `${prefix}${String(n).padStart(2, "0")}`, packageCode, label: { vi: "" }, order: n, _localId: nextLocalId() },
        ],
      };
    });

  const deleteLabel = (code: string) => setTree((t) => ({ ...t, labels: t.labels.filter((l) => l.code !== code) }));

  const skillsetPicker = (branch: LocalBranch) => (
    <Autocomplete
      size="small"
      sx={{ minWidth: 240 }}
      options={skillsets}
      getOptionLabel={(s) => s.title?.vi || s.title?.en || s._id}
      isOptionEqualToValue={(a, b) => a._id === b._id}
      value={skillsets.find((s) => s._id === branch.skillsetId) ?? null}
      onChange={(_, s) => updateBranch(branch.code, { ...branch, skillsetId: s?._id ?? null })}
      renderInput={(params) => <TextField {...params} label="Skillset (để Home xếp theo nhánh)" />}
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
            {issues.map((i, idx) => (
              <li key={idx}>[{i.entity}] {i.code}: {i.message}</li>
            ))}
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
              onChangeBranch={(next) => updateBranch(branch.code, next)}
              onDeleteBranch={() => deleteBranch(branch.code)}
              onChangePackage={updatePackage}
              onAddPackage={() => addPackage(branch.code)}
              onDeletePackage={deletePackage}
              onChangeLabel={updateLabel}
              onAddLabel={addLabel}
              onDeleteLabel={deleteLabel}
              skillsetPicker={skillsetPicker(branch)}
            />
          ))}
      </Paper>
    </Box>
  );
};

export default OnboardingTaxonomyPage;
