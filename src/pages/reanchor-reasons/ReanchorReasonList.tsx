// src/pages/reanchor-reasons/ReanchorReasonList.tsx
import React, { useEffect, useMemo, useState } from "react";
import {
  Box,
  Button,
  Chip,
  IconButton,
  MenuItem,
  Paper,
  Skeleton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import { reanchorReasonService } from "../../services/reanchorReasonService";
import { courseService } from "../../services/courseService";
import {
  IReanchorReason,
  ReanchorReasonPayload,
} from "../../types/interface/reanchor-reason.interface";
import { ReanchorReasonStatus } from "../../types/enum/reanchor-reason.enum";
import { ICourse } from "../../types/interface/course.interface";
import { getTranslationValue } from "../../utils/translation";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { useNotification } from "../../utils/hooks/useNotification";
import ReanchorReasonModal from "../../components/reanchor-reasons/ReanchorReasonModal";
import ReanchorReasonConfirm from "../../components/reanchor-reasons/ReanchorReasonConfirm";

const statusChipProps: Record<
  ReanchorReasonStatus,
  { label: string; color: "default" | "success" }
> = {
  [ReanchorReasonStatus.DRAFT]: { label: "Draft", color: "default" },
  [ReanchorReasonStatus.PUBLISHED]: { label: "Published", color: "success" },
};

const ReanchorReasonList: React.FC = () => {
  const { showSuccess, showError } = useNotification();
  const lang = useSelector((state: RootState) => state.lang.code);

  const [reasons, setReasons] = useState<IReanchorReason[]>([]);
  const [courses, setCourses] = useState<ICourse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<ReanchorReasonStatus | "">(
    ""
  );
  const [courseFilter, setCourseFilter] = useState("");

  const [modalOpen, setModalOpen] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [selected, setSelected] = useState<IReanchorReason | null>(null);

  const courseNameById = useMemo(() => {
    const map = new Map<string, string>();
    courses.forEach((course) => {
      map.set(course._id, getTranslationValue(course.title, lang));
    });
    return map;
  }, [courses, lang]);

  const fetchCourses = async () => {
    try {
      const response = await courseService.getList({
        isAll: true,
        take: 1000,
      });
      setCourses(response.data?.items ?? []);
    } catch (err) {
      console.error("Failed to load courses", err);
    }
  };

  // The API ignores `status` whenever `isAll` is set (isAll wins), so the
  // admin list always fetches every status and filters by status client
  // side. `courseId` is not affected by that rule and is still sent to
  // narrow the query server side.
  const fetchReasons = async (courseIdFilter = courseFilter) => {
    setLoading(true);
    setError(null);
    try {
      const response = await reanchorReasonService.getList({
        isAll: true,
        ...(courseIdFilter && { courseId: courseIdFilter }),
      });
      setReasons(response.data ?? []);
    } catch (err: any) {
      const message =
        err?.response?.data?.message ?? "Failed to load re-anchor reasons";
      setError(message);
      showError(message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCourses();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    fetchReasons(courseFilter);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseFilter]);

  const filteredReasons = useMemo(() => {
    return reasons.filter((item) => {
      if (statusFilter && item.status !== statusFilter) return false;
      if (search.trim()) {
        const term = search.trim().toLowerCase();
        // Search across every locale so a reason is findable regardless of
        // the language the admin is currently viewing.
        const matches = Object.values(item.reason ?? {}).some((value) =>
          (value ?? "").toLowerCase().includes(term)
        );
        if (!matches) return false;
      }
      return true;
    });
  }, [reasons, search, statusFilter]);

  const hasActiveFilters =
    !!search.trim() || !!statusFilter || !!courseFilter;

  const resetFilters = () => {
    setSearch("");
    setStatusFilter("");
    setCourseFilter("");
  };

  const openCreateModal = () => {
    setSelected(null);
    setModalOpen(true);
  };

  const openEditModal = (reason: IReanchorReason) => {
    setSelected(reason);
    setModalOpen(true);
  };

  const openDeleteConfirm = (reason: IReanchorReason) => {
    setSelected(reason);
    setConfirmOpen(true);
  };

  const handleSubmit = async (payload: ReanchorReasonPayload, id?: string) => {
    if (id) {
      await reanchorReasonService.update(id, payload);
      showSuccess("Re-anchor reason updated successfully");
    } else {
      await reanchorReasonService.create(payload);
      showSuccess("Re-anchor reason created successfully");
    }
    setModalOpen(false);
    await fetchReasons();
  };

  const handleDelete = async () => {
    if (!selected) return;
    try {
      await reanchorReasonService.remove(selected._id);
      showSuccess("Re-anchor reason deleted successfully");
      setConfirmOpen(false);
      setSelected(null);
      await fetchReasons();
    } catch (err: any) {
      showError(
        err?.response?.data?.message ?? "Failed to delete re-anchor reason"
      );
    }
  };

  return (
    <Box className="p-6">
      <Box className="mb-4 flex items-center justify-between gap-3">
        <Typography variant="h5">Re-anchor reasons</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={openCreateModal}
        >
          Create re-anchor reason
        </Button>
      </Box>

      <Box className="mb-4 flex flex-wrap items-center gap-3">
        <TextField
          size="small"
          label="Search reason"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-64"
        />
        <TextField
          select
          size="small"
          label="Course"
          value={courseFilter}
          onChange={(e) => setCourseFilter(e.target.value)}
          className="w-56"
        >
          <MenuItem value="">All courses</MenuItem>
          {courses.map((course) => (
            <MenuItem key={course._id} value={course._id}>
              {getTranslationValue(course.title, lang)}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          select
          size="small"
          label="Status"
          value={statusFilter}
          onChange={(e) =>
            setStatusFilter(e.target.value as ReanchorReasonStatus | "")
          }
          className="w-40"
        >
          <MenuItem value="">All statuses</MenuItem>
          <MenuItem value={ReanchorReasonStatus.DRAFT}>Draft</MenuItem>
          <MenuItem value={ReanchorReasonStatus.PUBLISHED}>
            Published
          </MenuItem>
        </TextField>
      </Box>

      {loading ? (
        <TableContainer component={Paper} className="overflow-x-auto">
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Course</TableCell>
                <TableCell>Reason</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Order</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {Array.from({ length: 5 }).map((_, i) => (
                <TableRow key={i}>
                  {Array.from({ length: 5 }).map((__, j) => (
                    <TableCell key={j}>
                      <Skeleton variant="text" />
                    </TableCell>
                  ))}
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      ) : error ? (
        <Paper className="p-6 text-center">
          <Typography color="error" className="mb-2">
            {error}
          </Typography>
          <Button variant="outlined" onClick={() => fetchReasons()}>
            Retry
          </Button>
        </Paper>
      ) : reasons.length === 0 ? (
        <Paper className="p-6 text-center">
          <Typography className="mb-2">
            No re-anchor reasons yet — create the first one to power the
            mobile app's "why did you pause?" prompt.
          </Typography>
          <Button variant="contained" onClick={openCreateModal}>
            Create the first reason
          </Button>
        </Paper>
      ) : filteredReasons.length === 0 ? (
        <Paper className="p-6 text-center">
          <Typography className="mb-2">
            No re-anchor reasons match your filters.
          </Typography>
          <Button
            variant="outlined"
            disabled={!hasActiveFilters}
            onClick={resetFilters}
          >
            Reset filters
          </Button>
        </Paper>
      ) : (
        <TableContainer component={Paper} className="overflow-x-auto">
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Course</TableCell>
                <TableCell>Reason</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Order</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredReasons.map((item) => (
                <TableRow key={item._id} hover>
                  <TableCell>
                    {courseNameById.get(item.courseId) || "Unknown course"}
                  </TableCell>
                  <TableCell>
                    {getTranslationValue(item.reason, lang) || "—"}
                  </TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      label={statusChipProps[item.status].label}
                      color={statusChipProps[item.status].color}
                    />
                  </TableCell>
                  <TableCell>{item.order}</TableCell>
                  <TableCell align="right">
                    <IconButton
                      aria-label="Edit re-anchor reason"
                      size="small"
                      onClick={() => openEditModal(item)}
                    >
                      <EditIcon fontSize="small" />
                    </IconButton>
                    <IconButton
                      aria-label="Delete re-anchor reason"
                      size="small"
                      onClick={() => openDeleteConfirm(item)}
                    >
                      <DeleteIcon fontSize="small" color="error" />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      <ReanchorReasonModal
        isOpen={modalOpen}
        initial={selected}
        courses={courses}
        onClose={() => setModalOpen(false)}
        onSubmit={handleSubmit}
      />

      <ReanchorReasonConfirm
        isOpen={confirmOpen}
        reanchorReason={selected}
        onClose={() => {
          setConfirmOpen(false);
          setSelected(null);
        }}
        onConfirm={handleDelete}
      />
    </Box>
  );
};

export default ReanchorReasonList;
