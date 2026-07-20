// src/pages/study-themes/StudyThemeList.tsx
import { useEffect, useMemo, useState } from "react";
import {
  Box,
  Button,
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
import { FilmIcon, PaletteIcon, PencilIcon, PlusIcon, TrashIcon } from "lucide-react";
import { studyThemeService } from "../../services/studyThemeService";
import {
  IStudyTheme,
  StudyThemePayload,
} from "../../types/interface/study-theme.interface";
import { StudyThemeMode } from "../../types/enum/study-theme.enum";
import { OrderType } from "../../types/enum/common.enum";
import { useNotification } from "../../utils/hooks/useNotification";
import CloudflareAssetPreview from "../../components/files/CloudflareAssetPreview";
import StudyThemeModal from "../../components/study-themes/StudyThemeModal";
import StudyThemeConfirm from "../../components/study-themes/StudyThemeConfirm";

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

  const columns = ["Key", "Name", "Mode", "Category", "Preview", "Order", "Active", "Actions"];

  return (
    <Box className="p-6">
      <Box className="mb-4 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <Typography variant="h5">Study Themes</Typography>
        <Button variant="contained" startIcon={<PlusIcon size={18} />} onClick={openCreate}>
          Create theme
        </Button>
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
    </Box>
  );
}
