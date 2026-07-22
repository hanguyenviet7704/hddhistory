// src/pages/study-themes/StudyThemeList.tsx
import { useEffect, useMemo, useState } from "react";
import {
  Box,
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  IconButton,
  MenuItem,
  Pagination,
  Paper,
  Select,
  Skeleton,
  Switch,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Tooltip,
  Typography,
} from "@mui/material";
import {
  DownloadIcon,
  FilmIcon,
  PaletteIcon,
  PencilIcon,
  PlusIcon,
  TrashIcon,
  UploadIcon,
} from "lucide-react";
import { studyThemeService } from "../../services/studyThemeService";
import {
  IStudyTheme,
  StudyThemeListResponse,
  StudyThemePayload,
} from "../../types/interface/study-theme.interface";
import { StudyThemeMode } from "../../types/enum/study-theme.enum";
import { OrderType } from "../../types/enum/common.enum";
import { useNotification } from "../../utils/hooks/useNotification";
import {
  downloadJson,
  pickJsonFile,
  stripServerFields,
} from "../../utils/jsonTransfer";
import CloudflareAssetPreview from "../../components/files/CloudflareAssetPreview";
import StudyThemeModal from "../../components/study-themes/StudyThemeModal";
import StudyThemeConfirm from "../../components/study-themes/StudyThemeConfirm";

// A row from an imported study-themes.json — validated minimally (must carry
// a non-empty `key`, since that's the only field the API can upsert on).
// Everything else is passed through best-effort; the backend rejects/ignores
// whatever it doesn't recognize.
type ImportableStudyTheme = Partial<Omit<IStudyTheme, "key">> & { key: string };

const isImportableStudyTheme = (value: unknown): value is ImportableStudyTheme => {
  if (!value || typeof value !== "object") return false;
  const key = (value as Record<string, unknown>).key;
  return typeof key === "string" && key.trim().length > 0;
};

interface ImportSummary {
  items: ImportableStudyTheme[];
  skipped: number;
}

const TAKE = 10;

const modeLabels: Record<StudyThemeMode, string> = {
  [StudyThemeMode.DEFAULT]: "Default",
  [StudyThemeMode.COLOR]: "Color",
  [StudyThemeMode.IMAGE]: "Image",
  [StudyThemeMode.VIDEO]: "Video",
};

// Preview swatch — prefers a real thumbnail over a live video/image fetch so
// a page of 10 rows never has 10 autoplaying videos competing for bandwidth.
function ThemePreviewSwatch({ item }: { item: IStudyTheme }) {
  const boxSx = {
    width: 56,
    height: 36,
    borderRadius: 1,
    border: "1px solid",
    borderColor: "divider",
    overflow: "hidden",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    flexShrink: 0,
  } as const;

  if (item.mode === StudyThemeMode.COLOR) {
    const colors = item.gradient?.length ? item.gradient : ["#e5e7eb"];
    const background =
      colors.length === 1 ? colors[0] : `linear-gradient(135deg, ${colors.join(", ")})`;
    return <Box sx={{ ...boxSx, background }} />;
  }

  if (item.mode === StudyThemeMode.IMAGE) {
    const src = item.thumbUrl || item.imageUrl;
    if (!src) {
      return (
        <Box sx={{ ...boxSx, bgcolor: "grey.100" }}>
          <Typography variant="caption" color="text.secondary">
            No image
          </Typography>
        </Box>
      );
    }
    return (
      <Box sx={boxSx}>
        <CloudflareAssetPreview
          src={src}
          alt={item.name}
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
        />
      </Box>
    );
  }

  if (item.mode === StudyThemeMode.VIDEO) {
    if (!item.thumbUrl) {
      return (
        <Tooltip title="No thumbnail set — add one so it previews here and in the app picker">
          <Box sx={{ ...boxSx, bgcolor: "grey.100" }}>
            <FilmIcon size={16} className="text-gray-400" />
          </Box>
        </Tooltip>
      );
    }
    return (
      <Box sx={boxSx}>
        <CloudflareAssetPreview
          src={item.thumbUrl}
          alt={item.name}
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
        />
      </Box>
    );
  }

  // DEFAULT mode has no colour or media of its own.
  return (
    <Box sx={{ ...boxSx, bgcolor: "grey.50", borderStyle: "dashed" }}>
      <PaletteIcon size={16} className="text-gray-400" />
    </Box>
  );
}

export default function StudyThemeList() {
  const { showSuccess, showError } = useNotification();

  const [items, setItems] = useState<IStudyTheme[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [category, setCategory] = useState("");
  const [debouncedCategory, setDebouncedCategory] = useState("");
  const [modeFilter, setModeFilter] = useState<StudyThemeMode | "">("");
  const [activeFilter, setActiveFilter] = useState<"" | "true" | "false">("");

  const [pagination, setPagination] = useState({ page: 1, totalPages: 1 });

  const [modalOpen, setModalOpen] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [selected, setSelected] = useState<IStudyTheme | null>(null);
  const [togglingKey, setTogglingKey] = useState<string | null>(null);

  const [exporting, setExporting] = useState(false);
  const [importPreview, setImportPreview] = useState<ImportSummary | null>(null);
  const [importing, setImporting] = useState(false);
  const [importProgress, setImportProgress] = useState(0);

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedSearch(search.trim()), 300);
    return () => clearTimeout(timer);
  }, [search]);

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedCategory(category.trim()), 300);
    return () => clearTimeout(timer);
  }, [category]);

  const fetchThemes = async (page = 1) => {
    setLoading(true);
    setError(null);
    try {
      const res = await studyThemeService.getList({
        page,
        take: TAKE,
        orderBy: "order",
        order: OrderType.ASC,
        ...(debouncedSearch && { search: debouncedSearch }),
        ...(debouncedCategory && { category: debouncedCategory }),
        ...(modeFilter && { mode: modeFilter }),
        ...(activeFilter && { isActive: activeFilter === "true" }),
      });
      setItems(res.items ?? []);
      setPagination({
        page: res.currentPage ?? page,
        totalPages: res.totalPages ?? 1,
      });
    } catch (err: any) {
      const message = err?.response?.data?.message ?? "Failed to load study themes";
      setError(message);
      showError(message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchThemes(1);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debouncedSearch, debouncedCategory, modeFilter, activeFilter]);

  const hasActiveFilters =
    !!debouncedSearch || !!debouncedCategory || !!modeFilter || !!activeFilter;

  const resetFilters = () => {
    setSearch("");
    setCategory("");
    setModeFilter("");
    setActiveFilter("");
  };

  const existingCategories = useMemo(
    () => Array.from(new Set(items.map((i) => i.category).filter(Boolean))).sort(),
    [items]
  );

  const openCreate = () => {
    setSelected(null);
    setModalOpen(true);
  };

  const openEdit = (theme: IStudyTheme) => {
    setSelected(theme);
    setModalOpen(true);
  };

  const openDelete = (theme: IStudyTheme) => {
    setSelected(theme);
    setConfirmOpen(true);
  };

  const handleSubmit = async (payload: StudyThemePayload, key?: string) => {
    if (key) {
      const { key: _drop, ...rest } = payload;
      await studyThemeService.update(key, rest);
      showSuccess("Study theme updated successfully");
    } else {
      await studyThemeService.create(payload);
      showSuccess("Study theme created successfully");
    }
    setModalOpen(false);
    setSelected(null);
    await fetchThemes(pagination.page);
  };

  const handleDelete = async () => {
    if (!selected) return;
    try {
      await studyThemeService.remove(selected.key);
      showSuccess("Study theme deleted successfully");
      setConfirmOpen(false);
      setSelected(null);
      await fetchThemes(pagination.page);
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Failed to delete study theme");
      throw err;
    }
  };

  const handleToggleActive = async (theme: IStudyTheme) => {
    setTogglingKey(theme.key);
    try {
      await studyThemeService.update(theme.key, { isActive: !theme.isActive });
      setItems((prev) =>
        prev.map((i) => (i.key === theme.key ? { ...i, isActive: !i.isActive } : i))
      );
      showSuccess(`Theme ${theme.isActive ? "deactivated" : "activated"}`);
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Failed to update theme status");
    } finally {
      setTogglingKey(null);
    }
  };

  const handleTogglePremium = async (theme: IStudyTheme) => {
    setTogglingKey(theme.key);
    try {
      await studyThemeService.update(theme.key, { isPremium: !theme.isPremium });
      setItems((prev) =>
        prev.map((i) => (i.key === theme.key ? { ...i, isPremium: !i.isPremium } : i))
      );
      showSuccess(`Theme ${theme.isPremium ? "made free" : "made premium"}`);
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Failed to update theme premium status");
    } finally {
      setTogglingKey(null);
    }
  };

  // Pulls every preset across all pages (list view is paginated at TAKE=10) —
  // used by both export and the import upsert (to know which keys already
  // exist). `take: 1000` should cover the whole library in one call; the loop
  // is only a safety net if that library ever grows past it.
  const fetchAllThemes = async (): Promise<IStudyTheme[]> => {
    const collected: IStudyTheme[] = [];
    let page = 1;
    // eslint-disable-next-line no-constant-condition
    while (true) {
      const res: StudyThemeListResponse = await studyThemeService.getList({
        page,
        take: 1000,
        orderBy: "order",
        order: OrderType.ASC,
      });
      const pageItems = res.items ?? [];
      collected.push(...pageItems);
      const totalPages = res.totalPages ?? 1;
      if (page >= totalPages || pageItems.length === 0) break;
      page += 1;
    }
    return collected;
  };

  const handleExport = async () => {
    setExporting(true);
    try {
      const all = await fetchAllThemes();
      const cleaned = all.map((item) =>
        stripServerFields(item as unknown as Record<string, any>)
      );
      downloadJson("study-themes.json", cleaned);
      showSuccess(
        `Exported ${cleaned.length} study theme${cleaned.length === 1 ? "" : "s"}`
      );
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Failed to export study themes");
    } finally {
      setExporting(false);
    }
  };

  const handleImportClick = async () => {
    try {
      const parsed = await pickJsonFile();
      if (!Array.isArray(parsed)) {
        showError("Import file must contain an array of study theme presets.");
        return;
      }
      const valid = parsed.filter(isImportableStudyTheme);
      if (valid.length === 0) {
        showError('No valid presets found — each entry needs a non-empty "key".');
        return;
      }
      setImportPreview({ items: valid, skipped: parsed.length - valid.length });
    } catch (err: any) {
      // A cancelled file picker isn't a real error — nothing to surface.
      if (err?.message !== "No file selected") {
        showError(err?.message ?? "Could not read that file.");
      }
    }
  };

  const handleConfirmImport = async () => {
    if (!importPreview) return;
    setImporting(true);
    setImportProgress(0);
    let created = 0;
    let updated = 0;
    let failed = 0;
    try {
      const existing = await fetchAllThemes();
      const existingKeys = new Set(existing.map((t) => t.key));

      for (const preset of importPreview.items) {
        try {
          const { key, ...rest } = stripServerFields(
            preset as unknown as Record<string, any>
          ) as ImportableStudyTheme;
          if (existingKeys.has(key)) {
            await studyThemeService.update(key, rest);
            updated += 1;
          } else {
            await studyThemeService.create({ key, ...rest } as StudyThemePayload);
            created += 1;
          }
        } catch {
          failed += 1;
        } finally {
          setImportProgress((p) => p + 1);
        }
      }
      showSuccess(
        `Imported: ${created} created, ${updated} updated${failed ? `, ${failed} failed` : ""}`
      );
      setImportPreview(null);
      await fetchThemes(1);
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Failed to import study themes");
    } finally {
      setImporting(false);
    }
  };

  const columns = [
    "Key",
    "Name",
    "Mode",
    "Category",
    "Preview",
    "Order",
    "Active",
    "Premium",
    "Actions",
  ];

  return (
    <Box className="p-6">
      <Box className="mb-4 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <Typography variant="h5">Study Themes</Typography>
        <Box className="flex items-center gap-2">
          <Button
            variant="outlined"
            startIcon={
              exporting ? (
                <CircularProgress size={16} color="inherit" />
              ) : (
                <DownloadIcon size={18} />
              )
            }
            onClick={handleExport}
            disabled={exporting}
          >
            Export
          </Button>
          <Button
            variant="outlined"
            startIcon={<UploadIcon size={18} />}
            onClick={handleImportClick}
            disabled={importing}
          >
            Import
          </Button>
          <Button variant="contained" startIcon={<PlusIcon size={18} />} onClick={openCreate}>
            Create theme
          </Button>
        </Box>
      </Box>

      <Paper variant="outlined" className="p-3 mb-4">
        <Box className="flex flex-wrap items-center gap-3">
          <TextField
            size="small"
            label="Search"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Key or name..."
            sx={{ minWidth: 200 }}
          />
          <TextField
            size="small"
            label="Category"
            value={category}
            onChange={(e) => setCategory(e.target.value)}
            placeholder="e.g. Nature"
            sx={{ minWidth: 160 }}
          />
          <Select
            size="small"
            displayEmpty
            value={modeFilter}
            onChange={(e) => setModeFilter(e.target.value as StudyThemeMode | "")}
            sx={{ minWidth: 140 }}
          >
            <MenuItem value="">All modes</MenuItem>
            {Object.values(StudyThemeMode).map((m) => (
              <MenuItem key={m} value={m}>
                {modeLabels[m]}
              </MenuItem>
            ))}
          </Select>
          <Select
            size="small"
            displayEmpty
            value={activeFilter}
            onChange={(e) => setActiveFilter(e.target.value as "" | "true" | "false")}
            sx={{ minWidth: 140 }}
          >
            <MenuItem value="">All statuses</MenuItem>
            <MenuItem value="true">Active</MenuItem>
            <MenuItem value="false">Inactive</MenuItem>
          </Select>
          {hasActiveFilters && (
            <Button size="small" onClick={resetFilters}>
              Reset filters
            </Button>
          )}
        </Box>
      </Paper>

      {loading ? (
        <TableContainer component={Paper} className="overflow-x-auto">
          <Table>
            <TableHead>
              <TableRow>
                {columns.map((c) => (
                  <TableCell key={c} sx={{ fontWeight: 600 }}>
                    {c}
                  </TableCell>
                ))}
              </TableRow>
            </TableHead>
            <TableBody>
              {Array.from({ length: 6 }).map((_, i) => (
                <TableRow key={i}>
                  {columns.map((c) => (
                    <TableCell key={c}>
                      <Skeleton variant="text" />
                    </TableCell>
                  ))}
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      ) : error ? (
        <Paper className="p-8 text-center">
          <Typography color="error" className="mb-3">
            {error}
          </Typography>
          <Button variant="outlined" onClick={() => fetchThemes(pagination.page)}>
            Retry
          </Button>
        </Paper>
      ) : items.length === 0 && !hasActiveFilters ? (
        <Paper className="p-8 text-center">
          <Typography className="mb-3">
            No study themes yet — create the first background preset for the
            mobile app's picker.
          </Typography>
          <Button variant="contained" startIcon={<PlusIcon size={18} />} onClick={openCreate}>
            Create the first theme
          </Button>
        </Paper>
      ) : items.length === 0 ? (
        <Paper className="p-8 text-center">
          <Typography className="mb-3">No study themes match your filters.</Typography>
          <Button variant="outlined" onClick={resetFilters}>
            Reset filters
          </Button>
        </Paper>
      ) : (
        <>
          <TableContainer component={Paper} className="overflow-x-auto">
            <Table>
              <TableHead>
                <TableRow>
                  {columns.map((c) => (
                    <TableCell key={c} sx={{ fontWeight: 600 }}>
                      {c}
                    </TableCell>
                  ))}
                </TableRow>
              </TableHead>
              <TableBody>
                {items.map((item) => (
                  <TableRow key={item.key} hover>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontFamily: "monospace" }}>
                        {item.key}
                      </Typography>
                    </TableCell>
                    <TableCell>{item.name}</TableCell>
                    <TableCell>{modeLabels[item.mode]}</TableCell>
                    <TableCell>{item.category}</TableCell>
                    <TableCell>
                      <ThemePreviewSwatch item={item} />
                    </TableCell>
                    <TableCell>{item.order}</TableCell>
                    <TableCell>
                      <Box className="flex items-center gap-1">
                        <Switch
                          size="small"
                          checked={item.isActive}
                          disabled={togglingKey === item.key}
                          onChange={() => handleToggleActive(item)}
                          inputProps={{
                            "aria-label": `${item.isActive ? "Deactivate" : "Activate"} ${item.name}`,
                          }}
                        />
                        <Typography variant="caption" color="text.secondary">
                          {item.isActive ? "Active" : "Inactive"}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Box className="flex items-center gap-1">
                        <Switch
                          size="small"
                          checked={item.isPremium}
                          disabled={togglingKey === item.key}
                          onChange={() => handleTogglePremium(item)}
                          inputProps={{
                            "aria-label": `${item.isPremium ? "Remove premium from" : "Make premium"} ${item.name}`,
                          }}
                        />
                        <Typography variant="caption" color="text.secondary">
                          {item.isPremium ? "Premium" : "Free"}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell align="right">
                      <IconButton
                        aria-label={`Edit ${item.name}`}
                        size="small"
                        onClick={() => openEdit(item)}
                      >
                        <PencilIcon size={16} className="text-blue-600" />
                      </IconButton>
                      <IconButton
                        aria-label={`Delete ${item.name}`}
                        size="small"
                        onClick={() => openDelete(item)}
                      >
                        <TrashIcon size={16} className="text-red-600" />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>

          {pagination.totalPages > 1 && (
            <Box className="flex justify-center mt-4">
              <Pagination
                count={pagination.totalPages}
                page={pagination.page}
                onChange={(_e, value) => fetchThemes(value)}
                color="primary"
              />
            </Box>
          )}
        </>
      )}

      <StudyThemeModal
        open={modalOpen}
        initial={selected}
        existingCategories={existingCategories}
        onClose={() => {
          setModalOpen(false);
          setSelected(null);
        }}
        onSubmit={handleSubmit}
      />

      <StudyThemeConfirm
        open={confirmOpen}
        theme={selected}
        onClose={() => {
          setConfirmOpen(false);
          setSelected(null);
        }}
        onConfirm={handleDelete}
      />

      <Dialog
        open={!!importPreview}
        onClose={() => !importing && setImportPreview(null)}
        maxWidth="xs"
        fullWidth
      >
        <DialogTitle>Import study themes</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Import {importPreview?.items.length ?? 0}{" "}
            preset{importPreview && importPreview.items.length === 1 ? "" : "s"}?
            Existing keys will be updated; new keys will be created. Nothing
            is deleted.
          </DialogContentText>
          {!!importPreview?.skipped && (
            <DialogContentText color="error" sx={{ mt: 1 }}>
              {importPreview.skipped} row(s) skipped — missing a valid "key" field.
            </DialogContentText>
          )}
          {importing && (
            <Box className="flex items-center gap-2 mt-3">
              <CircularProgress size={18} />
              <Typography variant="body2">
                Importing {importProgress}/{importPreview?.items.length ?? 0}...
              </Typography>
            </Box>
          )}
        </DialogContent>
        <DialogActions sx={{ px: 3, py: 2 }}>
          <Button onClick={() => setImportPreview(null)} disabled={importing}>
            Cancel
          </Button>
          <Button
            onClick={handleConfirmImport}
            variant="contained"
            disabled={importing}
            startIcon={importing ? <CircularProgress size={16} color="inherit" /> : undefined}
          >
            Import
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
