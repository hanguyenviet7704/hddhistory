import React, { useState } from "react";
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Box,
  Button,
  Chip,
  Collapse,
  FormControlLabel,
  IconButton,
  Switch,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from "@mui/material";
import { ChevronDownIcon, ChevronRightIcon, PlusIcon, TrashIcon } from "lucide-react";

import type {
  OnboardingBranch,
  OnboardingLabel,
  OnboardingPackage,
} from "../../types/interface/onboarding-taxonomy.interface";

// Editing `code` inline changes the value used to identify a row. If `code`
// itself were used as the React `key`, every keystroke would swap the key and
// React would unmount+remount the row — losing input focus after each
// character. `_localId` is a stable, UI-only identifier attached when a
// branch/package/label enters local state (on load or on "add") and stripped
// again before the tree is sent to the API. It never leaves this admin page.
export type LocalBranch = OnboardingBranch & { _localId: string };
export type LocalPackage = OnboardingPackage & { _localId: string };
export type LocalLabel = OnboardingLabel & { _localId: string };

interface Props {
  branch: LocalBranch;
  packages: LocalPackage[];
  labelsByPackage: Record<string, LocalLabel[]>;
  onChangeBranch: (next: LocalBranch) => void;
  onDeleteBranch: () => void;
  onChangePackage: (code: string, next: LocalPackage) => void;
  onAddPackage: () => void;
  onDeletePackage: (code: string) => void;
  onChangeLabel: (code: string, next: LocalLabel) => void;
  onAddLabel: (packageCode: string) => void;
  onDeleteLabel: (code: string) => void;
  skillsetPicker: React.ReactNode; // typeahead do page cung cấp (cần service + debounce)
}

const small = { size: "small" as const, sx: { minWidth: 160 } };

const TaxonomyBranchCard: React.FC<Props> = ({
  branch,
  packages,
  labelsByPackage,
  onChangeBranch,
  onDeleteBranch,
  onChangePackage,
  onAddPackage,
  onDeletePackage,
  onChangeLabel,
  onAddLabel,
  onDeleteLabel,
  skillsetPicker,
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
          <TextField {...small} label="Mã nhánh" value={branch.code ?? ""} onChange={(e) => set({ code: e.target.value.toUpperCase() })} />
          <TextField {...small} label="Tên (vi)" value={branch.label?.vi ?? ""} onChange={(e) => set({ label: { ...branch.label, vi: e.target.value } })} />
          <TextField {...small} label="Tên (en)" value={branch.label?.en ?? ""} onChange={(e) => set({ label: { ...branch.label, en: e.target.value } })} />
          <TextField {...small} sx={{ minWidth: 260 }} label="Mô tả ngắn (vi)" value={branch.subtitle?.vi ?? ""} onChange={(e) => set({ subtitle: { ...branch.subtitle, vi: e.target.value } })} />
          <TextField {...small} sx={{ minWidth: 260 }} label="Mô tả ngắn (en)" value={branch.subtitle?.en ?? ""} onChange={(e) => set({ subtitle: { ...branch.subtitle, en: e.target.value } })} />
          <TextField {...small} sx={{ width: 90 }} type="number" label="Thứ tự" value={branch.order ?? 0} onChange={(e) => set({ order: Number(e.target.value) || 0 })} />
          <TextField {...small} sx={{ minWidth: 260 }} label="Icon URL" value={branch.iconUrl ?? ""} onChange={(e) => set({ iconUrl: e.target.value })} />
          {skillsetPicker}
          <FormControlLabel control={<Switch checked={!!branch.isSelectable} onChange={(e) => set({ isSelectable: e.target.checked })} />} label="Hiện ở câu 1" />
          <FormControlLabel control={<Switch checked={!!branch.isActive} onChange={(e) => set({ isActive: e.target.checked })} />} label="Đang bật" />
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
              <TableCell>Nhãn chi tiết</TableCell>
              <TableCell width={48} />
            </TableRow>
          </TableHead>
          <TableBody>
            {(packages ?? []).map((pkg) => {
              const labels = labelsByPackage[pkg.code] ?? [];
              const isOpen = !!open[pkg._localId];
              const setPkg = (patch: Partial<OnboardingPackage>) => onChangePackage(pkg.code, { ...pkg, ...patch });
              return (
                <React.Fragment key={pkg._localId}>
                  <TableRow>
                    <TableCell>
                      <IconButton size="small" onClick={() => setOpen((o) => ({ ...o, [pkg._localId]: !o[pkg._localId] }))}>
                        {isOpen ? <ChevronDownIcon size={16} /> : <ChevronRightIcon size={16} />}
                      </IconButton>
                    </TableCell>
                    <TableCell><TextField size="small" value={pkg.code ?? ""} onChange={(e) => setPkg({ code: e.target.value.toUpperCase() })} sx={{ width: 90 }} /></TableCell>
                    <TableCell><TextField size="small" fullWidth value={pkg.problemLabel?.vi ?? ""} onChange={(e) => setPkg({ problemLabel: { ...pkg.problemLabel, vi: e.target.value } })} /></TableCell>
                    <TableCell><TextField size="small" fullWidth value={pkg.problemLabel?.en ?? ""} onChange={(e) => setPkg({ problemLabel: { ...pkg.problemLabel, en: e.target.value } })} /></TableCell>
                    <TableCell><TextField size="small" fullWidth value={pkg.desireLabel?.vi ?? ""} onChange={(e) => setPkg({ desireLabel: { ...pkg.desireLabel, vi: e.target.value } })} /></TableCell>
                    <TableCell><TextField size="small" fullWidth value={pkg.desireLabel?.en ?? ""} onChange={(e) => setPkg({ desireLabel: { ...pkg.desireLabel, en: e.target.value } })} /></TableCell>
                    <TableCell><TextField size="small" type="number" value={pkg.order ?? 0} onChange={(e) => setPkg({ order: Number(e.target.value) || 0 })} /></TableCell>
                    <TableCell><Switch size="small" checked={!!pkg.isActive} onChange={(e) => setPkg({ isActive: e.target.checked })} /></TableCell>
                    <TableCell>
                      <Typography variant="caption" color="text.secondary">{labels.length}</Typography>
                    </TableCell>
                    <TableCell><IconButton size="small" color="error" onClick={() => onDeletePackage(pkg.code)}><TrashIcon size={16} /></IconButton></TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell colSpan={10} sx={{ p: 0, border: 0 }}>
                      <Collapse in={isOpen} unmountOnExit>
                        <Box sx={{ pl: 6, pr: 2, py: 1.5, bgcolor: "grey.50" }}>
                          <Typography variant="caption" color="text.secondary">
                            Nhãn chi tiết ({labels.length}) — user không thấy, chỉ để khớp khoá học.
                          </Typography>
                          {labels.map((label) => (
                            <Box key={label._localId} className="flex gap-2 items-center mt-1">
                              <TextField size="small" sx={{ width: 90 }} value={label.code ?? ""} onChange={(e) => onChangeLabel(label.code, { ...label, code: e.target.value.toUpperCase() })} />
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
